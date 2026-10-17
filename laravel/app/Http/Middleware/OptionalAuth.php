<?php

namespace App\Http\Middleware;

use App\Models\User;
use Closure;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Symfony\Component\HttpFoundation\Response;

/**
 * optionalAuth: fills the request attributes when a valid credential exists,
 * never rejects. Dual auth (BE-2, 2026-10-18): session first, then Bearer.
 * Used for public catalog/slider endpoints where admins see extra data.
 */
class OptionalAuth
{
    public function handle(Request $request, Closure $next): Response
    {
        $user = $request->user();

        if (! $user instanceof User && $request->bearerToken()) {
            $user = Auth::guard('sanctum')->user();
        }

        if ($user instanceof User && ! $user->is_blocked) {
            $request->attributes->set('authUser', $user);
            $request->attributes->set('authPermissions', $user->effectivePermissions());
        }

        return $next($request);
    }
}
