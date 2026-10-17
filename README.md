# CaffeNet Flutter — اپلیکیشن مشتری کافی‌نت احسان

اپ موبایل مشتری (Flutter + GetX) برای سرویس آنلاین «کافی‌نت احسان» — پرینت و چاپ، خدمات دانشجویی، امور اداری و مالیاتی. به‌همراه **بک‌اند Laravel وندورشده** در پوشه `laravel/`.

> **پلن جامع:** [`AGENTIC_PLAN.md`](./AGENTIC_PLAN.md) — معماری، قرارداد API، فازبندی و پروتکل اجرای ایجنتیک.

## ساختار ریپو

```text
.
├── lib/                  # اپ Flutter (معماری Pragmatic/MVP-Ready — بخش 2 پلن)
│   ├── main.dart
│   └── app/
│       ├── core/         # زیرساخت: شبکه، کش، سرویس‌ها، تم، ویجت‌ها، مسیرها
│       ├── data/         # models / providers / repositories (کش‌محور)
│       └── modules/      # splash, onboarding, auth, home, catalog, order_form,
│                         # checkout, payment_pending, orders, tracker, wallet,
│                         # profile, settings
├── assets/fonts/         # PeydaFaNum + Vazir (تبدیل‌شده از woff2 پله)
├── laravel/              # بک‌اند وندورشده (API قرارداد + اجرای توسعه)
├── test/                 # تست‌های واحد (utils, models, poller)
└── .github/workflows/    # CI: flutter create . → analyze → test
```

## راه‌اندازی سریع

**پیش‌نیاز:** Flutter SDK نسخه پایدار (3.24+)، PHP 8.3 + Composer (فقط برای بک‌اند).

```bash
# 1) ساخت پوشه‌های پلتفرم (android/ios در گیت نگه‌داری نمی‌شوند)
flutter create . --project-name caffenet --org ir.caffenet --platforms android,ios

# 2) پکیج‌ها
flutter pub get

# 3) اجرا با آدرس API (امولاتور اندروید: 10.0.2.2 = localhost هاست)
flutter run --dart-define=CAFFENET_API_BASE_URL=http://10.0.2.2:8000

# تولید APK
flutter build apk --release --dart-define=CAFFENET_API_BASE_URL=https://YOUR-DOMAIN
```

### اجرای بک‌اند توسعه (پوشه `laravel/`)

```bash
cd laravel
cp .env.example .env            # مقدارهای دیتابیس/پیامک را تنظیم کنید
composer install
php artisan key:generate
php artisan migrate --seed
php artisan serve               # http://127.0.0.1:8000
```

حالت آزمایشی برای توسعه بدون پیامک/درگاه: `SMS_TEST_MODE=true` و `PAYMENT_TEST_MODE=true` در `.env` — کد OTP در پاسخ `send-otp` (`testCode`) برگردانده می‌شود و درگاه تست `/test-gateway` فعال می‌گردد.

### تغییرات Sanctum این ریپو (BE-1..BE-6)

بک‌اند وندورشده یک لایه **توکن Sanctum موبایلی** دارد که PWA را نمی‌شکند:

- `laravel/composer.json` → `laravel/sanctum` (نیاز به `composer install` پس از pull)
- `POST /auth/verify-otp` با `mode:'token'` → `user + {token}`
- `EnsureAuth`/`OptionalAuth` دوگانه: Bearer یا session
- CSRF برای درخواست‌های Bearer skip می‌شود (session محور حفظ است)
- `GET /api/uploads/{filename}` دانلود فایل با توکن (مالکیت بررسی می‌شود)
- `POST /auth/logout` توکن فعلی را ابطال می‌کند
- مستندات: `laravel/docs/api-contract.md` + `laravel/CHANGELOG.md`

## پکیج‌های استفاده‌شده و دلیل (نگاشت بخش 3 پلن)

| پکیج | نقش |
|---|---|
| `get` | state/DI/routing/snackbar — ستون معماری |
| `http` | ApiClient با پارس خطای flat و force-logout 401 |
| `flutter_secure_storage` | ذخیره توکن Sanctum |
| `get_storage` | کش L2 (settings/capacity/draft/pending payment) با TTL |
| `sqflite` | کش L3 رابطه‌ای (catalog/orders/wallet_tx) |
| `intl` + `persian_number_utility` | فرمت تومان/تاریخ + ارقام فارسی |
| `url_launcher` | بازکردن درگاه در مرورگر خارجی، تماس، قوانین |
| `flutter_local_notifications` | اعلان محلی تغییر وضعیت سفارش (جانشین WebSocket) |
| `image_picker` + `file_picker` | آپلود فایل سفارش (`POST /upload` multipart) |

خارج از MVP (تصمیم باز پلن §13): `flutter_map`/`geolocator`/`geocoding`/`app_links`/`shared_preferences` (کامنت در pubspec) و `pusher_reverb_flutter` (بک‌اند cPanel WebSocket ندارد).

## جریان‌های کلیدی

- **Auth:** OTP ۵ رقمی → `verify-otp(mode:'token')` → ذخیره توکن در secure storage → restart امن.
- **سفارش:** فرم داینامیک از `fields[]` سرویس → پیش‌نمایش قیمت (سرور حقیقت است) → `POST /orders` → اگر `INSUFFICIENT_WALLET` → دیالوگ شارژ → `POST /orders/{id}/pay-wallet`.
- **شارژ کیف پول:** `POST /payments/request` → مرورگر خارجی (هرگز WebView) → صفحه polling با `GET /payments/status` (هر ۳ ثانیه، سقف ۱۰ دقیقه) → self-heal در شروع بعدی اپ (T6.5).
- **Realtime:** Poller ۱۵ ثانیه‌ای روی `/orders/{id}/updates` (سقف سرور ۱۲/min)، backoff نمایی، توقف روی 429، اعلان محلی روی تغییر وضعیت.

## CI

هر push روی `main`: `flutter create .` (بازسازی پوشه‌های پلتفرم) → `flutter pub get` → `flutter analyze --fatal-infos` → `flutter test`.
