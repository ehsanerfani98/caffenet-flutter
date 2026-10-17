# Mobile Token Auth — API Contract Addendum (BE-1..BE-5)

> تاریخ: 2026-10-18 — این سند فقط **افزودنی‌های موبایل** را مستند می‌کند؛ قرارداد اصلی §13 در `docs/PROJECT_DOCUMENTATION.md` بدون تغییر است و PWA با رفتار قبلی کار می‌کند.

## 1. ورود موبایل با توکن (BE-1)

`POST /api/auth/verify-otp`

```json
{ "phone": "09123456789", "code": "12345", "mode": "token" }
```

- پاسخ موفق `200`:
```json
{
  "id": "usr_x", "phone": "09123456789", "name": "…", "role": "customer",
  "permissions": [], "walletBalance": 0, "createdAt": "…", "isBlocked": false,
  "token": "1|xxxxxxxx…"
}
```
- توکن Sanctum است (`personal_access_tokens` table — مهاجرت `2026_10_18_000001`).
- **بدون `mode`** → رفتار قبلی (session + csrf) — PWA دست‌نخورده.
- خطاها همان قرارداد قبلی: 400 (شما/کد نامعتبر)، 429 (سقف تلاش)، 403 (مسدود)، 503 (پیامک خاموش).

## 2. استفاده از توکن

همه endpointهای محافظت‌شده با `Authorization: Bearer <token>` کار می‌کنند (BE-2 — `EnsureAuth`/`OptionalAuth` دوگانه: session یا Bearer):

```http
GET /api/auth/me
Authorization: Bearer 1|xxxxxxxx…
```

401 → `{"error": "برای این عملیات باید وارد شوید."}` — کلاینت موبایل باید force-logout کند. مسدود شدن → 403 و **ابطال توکن**.

## 3. CSRF (BE-3)

درخواست‌های دارای هدر `Authorization: Bearer` از بررسی CSRF معاف‌اند (احراز stateless). درخواست‌های session محور PWA همچنان کامل محافظت می‌شوند (`419` بدون توکن CSRF).

## 4. دانلود فایل سفارش با توکن (BE-4)

`GET /api/uploads/{filename}` — همان بررسی مالکیت مسیر `/uploads/{filename}` در web (staff = admin/operator، مشتری فقط فایل‌های سفارش خودش)، این بار با `auth.session` دوگانه؛ اپ موبایل با Bearer فایل نتیجه را می‌گیرد. پاسخ = جریان فایل (inline).

## 5. خروج توکنی (BE-5)

`POST /api/auth/logout` با `Authorization: Bearer` → توکن فعلی ابطال می‌شود:

```json
{ "message": "خروج انجام شد.", "csrf": null }
```

پس از آن همان توکن روی همه endpointها 401 می‌دهد. مسیر session قبلی بدون تغییر است.

## 6. نصب/استقرار

```bash
composer install          # laravel/sanctum ^4.0 اضافه شده
php artisan migrate       # personal_access_tokens
```

## 7. تست

`php artisan test --filter=MobileTokenAuthTest` — سناریوها: ورود token/جلسه، دسترسی Bearer به `/auth/me` و `/orders`، logout و ابطال، skip CSRF با Bearer، دانلود فایل با مالکیت.
