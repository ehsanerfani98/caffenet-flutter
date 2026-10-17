<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Symfony\Component\HttpFoundation\Response;

/**
 * requireAuth equivalent — dual authentication (BE-2, 2026-10-18).
 *
 *  1) Fortify session (the PWA — unchanged default)
 *  2) Sanctum Bearer token (the Flutter mobile app)
 *
 * Resolution: session user first; when absent and an Authorization: Bearer
 * header exists, the sanctum guard resolves the token user. Blocked accounts
 * are rejected identically in both paths (403); for token users the current
 * token is revoked too so a blocked device cannot keep polling.
 */
class EnsureAuth
{
    public function handle(Request $request, Closure $next): Response
    {
        $user = $request->user();

        if (! $user && $request->bearerToken()) {
            $user = Auth::guard('sanctum')->user();
        }

        if (! $user) {
            return response()->json(['error' => 'برای این عملیات باید وارد شوید.'], 401);
        }

        if ($user->is_blocked) {
            // Session path: kill the session. Token path: revoke the token.
            Auth::guard('web')->logout();
            if ($request->hasSession()) {
                $request->session()->invalidate();
            }
            if ($request->bearerToken() && method_exists($user, 'currentAccessToken')) {
                $user->tokens()->where('id', $user->currentAccessToken()?->id ?? 0)->delete();
            }

            return response()->json(['error' => 'حساب کاربری شما مسدود شده است.'], 403);
        }

        $request->attributes->set('authUser', $user);
        $request->attributes->set('authPermissions', $user->effectivePermissions());

        return $next($request);
    }
}
