<?php

namespace App\Http\Middleware;

use Illuminate\Foundation\Http\Middleware\ValidateCsrfToken as Middleware;

/**
 * BE-3 (2026-10-18): CSRF exemption for stateless Bearer-token requests.
 *
 * The mobile app authenticates with `Authorization: Bearer <sanctum-token>`
 * — there is no session cookie involved, so CSRF is not applicable to those
 * requests. Session-based requests (the PWA) keep the full CSRF protection:
 * the exemption triggers only when a Bearer header is present.
 */
class VerifyCsrfToken extends Middleware
{
    /**
     * The URIs that should be excluded from CSRF verification (unchanged).
     *
     * @var array<int, string>
     */
    protected $except = [
        //
    ];

    protected function tokensMatch($request): bool
    {
        // Stateless token request — the token itself is the proof of intent.
        // (Sanctum validates it later in the auth layer; an invalid token
        // fails there with 401, never silently passes CSRF.)
        if ($request->bearerToken()) {
            return true;
        }

        return parent::tokensMatch($request);
    }
}
