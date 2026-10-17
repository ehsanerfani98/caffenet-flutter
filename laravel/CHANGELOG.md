# Changelog

تمام تغییرات مهم این پروژه در این فایل ثبت می‌شود.
قالب بر اساس [Keep a Changelog](https://keepachangelog.com/) و نسخه‌بندی SemVer.

## [Unreleased]

### Added — Mobile Token Auth (BE-1..BE-6، 2026-10-18)

- `laravel/sanctum ^4.0` به composer و مهاجرت `personal_access_tokens` اضافه شد (BE-1).
- `POST /api/auth/verify-otp` با `mode:'token'` → پاسخ `Formatter::user + {token}` (Sanctum PAT)؛ بدون mode رفتار session قبلی حفظ شد (BE-1).
- `EnsureAuth` / `OptionalAuth` دوگانه شدند: session (PWA) یا `Authorization: Bearer` (اپ موبایل)؛ مسدود شدن کاربر توکنی توکن را ابطال می‌کند (BE-2).
- Middleware سفارشی `VerifyCsrfToken`: درخواست‌های Bearer از CSRF معاف‌اند؛ session کامل محافظت می‌شود (BE-3).
- `GET /api/uploads/{filename}` داخل API با همان بررسی مالکیت web — دانلود فایل نتیجه با توکن موبایل (BE-4).
- `POST /api/auth/logout` با Bearer → ابطال توکن جاری (BE-5).
- مستندات `docs/api-contract.md` + تست Feature `tests/Feature/MobileTokenAuthTest.php` (BE-6).
- PWA فعلی هیچ تغییر رفتاری ندارد؛ تمام تسک‌ها non-breaking هستند.
