<?php

namespace Tests\Feature;

use App\Models\User;
use App\Services\SettingsService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\DB;
use Tests\TestCase;

/**
 * BE-1..BE-5 regression suite (2026-10-18) — mobile Sanctum token layer.
 *
 *  - verify-otp with mode:'token'  → user + token (BE-1)
 *  - verify-otp without mode       → previous session behaviour (BE-1)
 *  - Bearer access to /auth/me and /orders (BE-2)
 *  - blocked token user            → 403 + revoked token (BE-2)
 *  - token logout revokes          (BE-5)
 *  - Bearer request skips CSRF     (BE-3)
 *  - token file download ownership (BE-4)
 */
class MobileTokenAuthTest extends TestCase
{
    use RefreshDatabase;

    private function customer(array $overrides = []): User
    {
        return User::create(array_merge([
            'phone' => '09120000001',
            'name' => 'مشتری موبایل',
            'role' => 'customer',
            'wallet_balance' => 0,
            'created_at' => now()->toIso8601String(),
        ], $overrides));
    }

    /** Login through the real endpoint and return the token. */
    private function loginWithToken(string $phone = '09120000001'): array
    {
        $this->postJson('/api/auth/send-otp', ['phone' => $phone])->assertOk();

        // Push the known code into the OTP store (AuthService cache).
        \App\Services\AuthService::storeOtp($phone, '54321', '127.0.0.1');

        $res = $this->postJson('/api/auth/verify-otp', [
            'phone' => $phone,
            'code' => '54321',
            'mode' => 'token',
        ]);

        $res->assertOk()->assertJsonStructure(['id', 'phone', 'role', 'token']);

        return $res->json();
    }

    // ── BE-1 ─────────────────────────────────────────────────────────────

    public function test_verify_otp_with_token_mode_returns_sanctum_token(): void
    {
        $this->customer();

        $payload = $this->loginWithToken();

        $this->assertNotEmpty($payload['token']);
        $this->assertDatabaseHas('personal_access_tokens', [
            'tokenable_id' => $payload['id'],
            'name' => 'mobile',
        ]);
    }

    public function test_verify_otp_without_mode_keeps_session_contract(): void
    {
        $this->customer();

        $this->postJson('/api/auth/send-otp', ['phone' => '09120000001'])->assertOk();
        \App\Services\AuthService::storeOtp('09120000001', '54321', '127.0.0.1');

        $res = $this->postJson('/api/auth/verify-otp', [
            'phone' => '09120000001',
            'code' => '54321',
        ]);

        // PWA contract: user + csrf, no token key.
        $res->assertOk();
        $this->assertArrayNotHasKey('token', $res->json());
        $this->assertArrayHasKey('csrf', $res->json());
    }

    // ── BE-2 ─────────────────────────────────────────────────────────────

    public function test_bearer_token_grants_access_to_protected_endpoints(): void
    {
        $this->customer();
        $payload = $this->loginWithToken();
        $token = $payload['token'];

        $this->withToken($token)->getJson('/api/auth/me')
            ->assertOk()
            ->assertJsonPath('phone', '09120000001');

        $this->withToken($token)->getJson('/api/orders')
            ->assertOk()
            ->assertJsonIsArray();
    }

    public function test_blocked_token_user_gets_403_and_revoked_token(): void
    {
        $this->customer();
        $payload = $this->loginWithToken();
        $token = $payload['token'];

        User::where('phone', '09120000001')->update(['is_blocked' => true]);

        $res = $this->withToken($token)->getJson('/api/auth/me');
        $res->assertStatus(403); // blocked → 403 + token revoked (BE-2)

        // The token must not authenticate anymore → 401.
        $this->withToken($token)->getJson('/api/auth/me')->assertStatus(401);
    }

    public function test_missing_token_is_401(): void
    {
        $this->getJson('/api/auth/me')->assertStatus(401);
        $this->withToken('1|invalid-token-value')->getJson('/api/auth/me')->assertStatus(401);
    }

    // ── BE-3 ─────────────────────────────────────────────────────────────

    public function test_bearer_request_skips_csrf(): void
    {
        $this->customer();
        $token = $this->loginWithToken()['token'];

        // POST without X-CSRF-TOKEN must still pass when Bearer is present.
        $this->withToken($token)->postJson('/api/coupons/validate', [
            'code' => 'NOPE',
            'totalPrice' => 1000,
        ])->assertStatus(400); // contract validation error, NOT 419
    }

    // ── BE-5 ─────────────────────────────────────────────────────────────

    public function test_token_logout_revokes_current_token(): void
    {
        $this->customer();
        $token = $this->loginWithToken()['token'];

        $this->withToken($token)->postJson('/api/auth/logout')
            ->assertOk()
            ->assertJsonPath('message', 'خروج انجام شد.');

        // Same token is now dead → 401.
        $this->withToken($token)->getJson('/api/auth/me')->assertStatus(401);
    }

    // ── BE-4 ─────────────────────────────────────────────────────────────

    public function test_customer_downloads_own_order_file_with_token(): void
    {
        $user = $this->customer();
        $token = $this->loginWithToken()['token'];

        $order = \App\Models\Order::create([
            'order_number' => 'CN-TEST-1',
            'service_id' => 'srv-test',
            'service_title' => 'خدمت تست',
            'customer_id' => $user->id,
            'customer_phone' => $user->phone,
            'customer_name' => $user->name,
            'status' => 'delivered',
            'urgency' => 'normal',
            'delivery_method' => 'download',
            'result_files_json' => json_encode([[
                'id' => 'f1', 'name' => 'result.pdf', 'size' => 3,
                'type' => 'application/pdf', 'url' => '/uploads/up-test-result.pdf',
            ]]),
            'total_price' => 1000,
            'discount_amount' => 0,
            'paid_amount' => 1000,
            'payment_method' => 'wallet',
            'created_at' => now()->toIso8601String(),
            'updated_at' => now()->toIso8601String(),
        ]);

        \Illuminate\Support\Facades\Storage::disk('uploads')->put('up-test-result.pdf', 'PDF');

        $this->withToken($token)->getJson('/api/uploads/up-test-result.pdf')
            ->assertOk();

        // Another customer's file must be forbidden.
        $this->customer(['phone' => '09120000003']);
        \App\Services\AuthService::storeOtp('09120000003', '54321', '127.0.0.1');
        $this->postJson('/api/auth/send-otp', ['phone' => '09120000003'])->assertOk();
        \App\Services\AuthService::storeOtp('09120000003', '54321', '127.0.0.1');
        $otherToken = $this->postJson('/api/auth/verify-otp', [
            'phone' => '09120000003', 'code' => '54321', 'mode' => 'token',
        ])->assertOk()->json('token');

        $this->withToken($otherToken)->getJson('/api/uploads/up-test-result.pdf')
            ->assertStatus(403);
    }
}
