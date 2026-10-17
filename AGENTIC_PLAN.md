# پلن جامع و ایجنتیک بازنویسی CaffeNet — Flutter (Customer App) + Laravel API

> **ریپو فرانت (مقصد):** `ehsanerfani98/caffenet-flutter`
> **ریپو بک‌اند (مرجع قرارداد):** `ehsanerfani98/caffenet-laravel`
> **معماری:** Pragmatic / MVP-Ready — ماژولار، خوانا، DI ساده با GetX، کش‌محور
> **نوشته‌شده بر اساس:** Audit واقعی کد بک‌اند (routes/api.php، کنترلرها، سرویس‌ها، QUEUE_SYSTEM.md، docs/PROJECT_DOCUMENTATION.md)

---

## 0. خلاصه اجرایی

پروژه «کافی‌نت احسان» یک سرویس آنلاین ارائه خدمات کافی‌نت است (پرینت و چاپ، خدمات دانشجویی و ثبت‌نام، خدمات دولتی و اداری، امور مالیاتی و وام). نسخه فعلی یک PWA جاوااسکریپتی (jQuery) روی بک‌اند Laravel 13 است. هدف این پلن، ساخت **اپلیکیشن موبایل Flutter** برای نقش **مشتری** با اتصال کامل به همان Laravel API است — بدون شکستن PWA فعلی.

این سند «قابل اجرای ایجنتیک» است: هر فاز به تسک‌های اتمیک با **معیار پذیرش (AC)** و **دستور راستی‌آزمایی** تقسیم شده و پروتکل اجرا (worklog، الگوی commit، Definition of Done) در بخش 11 تعریف شده است. هر ایجنتی که تسکی را برمی‌دارد باید فقط از روی همین سند و WORKLOG.md کار کند.

**سه تصمیم معماری کلیدی که کل پلن روی آن‌ها بنا شده (تأییدشده با کد بک‌اند):**

| # | تصمیم | دلیل مستند به کد |
|---|---|---|
| D1 | **احراز هویت موبایل با Bearer Token (Sanctum)** به‌جای Session Cookie | بک‌اند فعلاً Fortify + Session + CSRF دارد (`bootstrap/app.php` گروه `web`). برای اپ موبایل، تسک BE-1 توکن Sanctum را کنار session اضافه می‌کند؛ PWA دست‌نخورده می‌ماند |
| D2 | **Realtime با Polling + Local Notification، بدون WebSocket** | `QUEUE_SYSTEM.md` صریحاً Redis/WebSocket/Reverb را خارج از محدوده اعلام کرده (cPanel بدون SSH/Supervisor). endpoint آماده `GET /orders/{id}/updates` (rate 12/min) همین کار را می‌کند. پکیج `pusher_reverb_flutter` فعلاً استفاده نمی‌شود |
| D3 | **پرداخت: بازکردن درگاه در مرورگر خارجی + polling وضعیت** | `POST /payments/request` برمی‌گرداند `{paymentId, redirectUrl, authority}`؛ callback سرور ریدایرکت به `appUrl/?payment=success\|failed` می‌کند و `GET /payments/status?authority=` وضعیت قطعی را می‌دهد. پرداخت سفارش فقط از کیف پول است (`code: WALLET_ONLY`) |

---

## 1. یافته‌های Audit

### 1.1 بک‌اند Laravel (`caffenet-laravel`)

- **فریم‌ورک:** Laravel ^13.17، PHP ^8.3، SQLite (فایل‌محور، cPanel shared hosting)، Fortify ^1.40 برای auth، spatie/laravel-permission ^8.3 برای RBAC، پکیج داخلی `caffenet/bazaar-iap` (خرید درون‌برنامه‌ای کافه‌بازار برای شارژ کیف پول).
- **نقش‌ها:** `customer` / `operator` / `admin` (ستون `role` + مجوزهای spatie با `effectivePermissions()`). اپ Flutter این پلن، **مخصوص مشتری** است؛ صفحات operator/admin فاز اختیاری 8 هستند.
- **احراز هویت:** OTP پیامکی ۵ رقمی (TTL دو دقیقه، ۵ تلاش، سقف ۳ کد/۱۰ دقیقه/شماره)، ورود از طریق pipeline استاندارد Fortify (`/auth/send-otp` → `/auth/verify-otp`)، ریسپانس login = `Formatter::user(user) + {csrf}`. مسیرهای محافظت‌شده با `auth.session` (EnsureAuth) و عمومی با `auth.optional`. رد شدن: `401 {error: 'برای این عملیات باید وارد شوید.'}`، مسدود: `403 {error: 'حساب کاربری شما مسدود شده است.'}`.
- **قرارداد ریسپانس:** flat و camelCase (بدون envelope)؛ خطا همیشه `{"error": "...", "code"?: "..."}` با پیام فارسی. اعتبارسنجی = `400` (نه 422). خطای دسترسی = `403`. سرور داخلی = `500` با پیام ثابت فارسی. Throttle سراسری 300/min، OTP send 6/min، verify 15/min، polling سفارش 12/min (پیام 429 فارسی).
- **مدل داده اصلی:** `User` (phone, name, role, walletBalance, isBlocked, permissions[])، `Category` (title, iconName, iconColor, sortOrder)، `Service` (title, basePrice, estimatedTime, icon, isFeatured، **fields[] فرم داینامیک**، pricingFormula)، `Order` (وضعیت‌ها: `pending_payment → submitted → processing → ready → delivered` + `failed/cancelled/refunded`؛ فیلدهای صف: queueType, queuePosition, estimatedWait/DurationMinutes, estimatedStartAt/EndAt, noResponseDeadline, trackToken، فایل‌های مشتری/نتیجه، ticketMessages، logs، rating)، `Payment` (authority, gateway: zarinpal|bazaarpay|bazaar|test, status: pending|paid|failed)، `WalletTransaction` (ledger کامل با balanceAfter)، `Coupon` (percent, maxAmount, minOrderAmount, expireDate)، `CapacitySlot` (نوبت‌های ۳۰ دقیقه‌ای اپراتور).
- **ظرفیت و صف:** `GET /capacity/current` (عمومی، کش ۳۰ ثانیه) → `{tier: green|yellow|orange|red, title, eta_minutes, first_slot_at, updated_at}`. سه نوع سفارش: quick (۵ دقیقه) / normal (۲۰) / long (۶۰، نیازمند رزرو اسلات).
- **پرداخت:** شارژ کیف پول با درگاه `online` (Zarinpal، پیش‌فرض) یا `bazaarpay` (وب‌گیت بازارپی) یا `bazaar` (IAP کافه‌بازار با deep link). پرداخت سفارش فقط `POST /orders/{id}/pay-wallet` (تراکنشی، idempotent). کمبود موجودی → `400` با `code: INSUFFICIENT_WALLET` و `{required, balance, shortfall}` — UI باید مستقیم به شارژ هدایت کند.
- **Polling:** `GET /orders/{id}/updates` → `{order, notifications[], server_time}` با محاسبه زنده ETA و موقعیت صف. `GET /orders/track/{token}` → پیگیری عمومی بدون لاگین.
- **FCM:** endpoint کامل وجود دارد (`/fcm/config` عمومی، `/fcm/token` ثبت توکن، ارسال توسط ادمین). سرویس `FirebasePushService` آماده است؛ فقط کلاینت موبایل FCM باید (اختیاری) اضافه شود.
- **فایل‌ها:** `POST /upload` (multipart) و `DELETE /upload`؛ فایل‌های سفارش در `public/uploads` با بررسی مالکیت در `GET /uploads/{filename}` (نیازمند session؛ برای موبایل در BE-1 مسیر token-friendly می‌شود).
- **صفحه‌های وب مرتبط:** `/` شل SPA، `/test-gateway` (درگاه تست وقتی paymentTestMode فعال است).

### 1.2 ریپو Flutter (`caffenet-flutter`)

ریپو **خالص (Empty)** است — هیچ کدی، هیچ برنچ محتوایی. پس کل اپ از صفر (Greenfield) با معماری بخش 2 ساخته می‌شود و دغدغه مهاجرت کد قدیمی وجود ندارد. منابع طراحی UI: اسکرین‌های PWA فعلی (`public/js/screens/*.js`: landing, auth, order-form, order-tracker, wallet, payment, terms) و فونت‌های برند (`public/fonts/PeydaFaNumWeb-*.woff2` و `Vazir.woff2`) که به assets فلاتر منتقل می‌شوند.

### 1.3 محدودیت‌های سخت (اینها را دور بزن، بازنویسی نکن)

1. WebSocket/Reverb/Pusher/Redis/Supervisor روی هاست فعلی **ممنوع** → realtime فقط polling.
2. قرارداد API و پیام‌های فارسی **ثابت** است؛ کلاینت مجاز به تغییر شکل ریسپانس نیست (مستند §13).
3. قیمت‌گذاری **همیشه سمت سرور** نهایی می‌شود (`PricingService`)؛ محاسبه سمت کلاینت فقط برای پیش‌نمایش UX است.
4. فقط مشتریِ `role=customer` اجازه ثبت سفارش دارد.
5. تسک‌های بک‌اند فقط از نوع **افزودنی و non-breaking** (Sanctum، مسیر فایل توکن‌دار) — معماری session محور PWA حفظ می‌شود.

---
## 2. معماری هدف Flutter — Pragmatic / MVP-Ready با GetX

### 2.1 اصول (به ترتیب اولویت)

1. **Pragmatic قبل از Clean:** هیچ لایه UseCase/Entity جداگانه‌ای ساخته نمی‌شود. یک ماژول = Controller + Views + Binding. داده از Repository می‌آید، مدل‌ها مشترک‌اند. اگر بین دو راه، یکی ساده‌تر و یکی «معماری‌تر» است، ساده‌تر انتخاب می‌شود.
2. **DI ساده GetX:** سرویس‌های زیرساختی در `InitialBinding` با `Get.put(permanent: true)`؛ Repositoryها `Get.lazyPut(fenix: true)`؛ Controllerها در Binding هر ماژول با `Get.lazyPut`. هیچ DI گرافیکی، هیچ get_it، هیچ injectable.
3. **کش‌محور (Cache-First):** هر Repository قبل از network از کش می‌خواند و بلافاصله برمی‌گرداند (stale-while-revalidate): داده کش فوراً رندر می‌شود، سپس درخواست شبکه پاسخ تازه را می‌نویسد و UI بی‌صدا رفرش می‌شود. کاربر در حالت آفلاین همیشه آخرین داده را می‌بیند.
4. **State با RxStatus:** هر Controller وضعیت را با `RxStatus.loading/success/empty/error` ابراز می‌کند؛ هیچ state class سفارشی پیچیده‌ای ساخته نمی‌شود.
5. **یک زبان مشترک:** پیام‌های خطای فارسی سرور عیناً نمایش داده می‌شوند؛ متن‌های UI در `core/values/strings.dart` متمرکز می‌شوند (بدون intl arb برای MVP).
6. **RTL-First:** کل اپ `Directionality: rtl` و locale `fa` است؛ اعداد برای نمایش با `persian_number_utility` فارسی می‌شوند، مقدار ذخیره‌شده همیشه لاتین است.

### 2.2 ساختار پوشه‌ها (نهایی و الزامی)

```text
lib/
├── main.dart                        # bootstrap: WidgetsFlutterBinding، InitServices، runApp
├── app/
│   ├── core/                        # زیرساخت مشترک — هیچ منطق بیزنسی اینجا نیست
│   │   ├── config/
│   │   │   ├── env.dart             # خواندن --dart-define (baseUrl, reverb…, فلاگ‌ها)
│   │   │   └── app_constants.dart   # نام اپ، پکیج‌ها، اندازه‌ها
│   │   ├── constants/
│   │   │   ├── api_endpoints.dart   # تک‌منبع حقیقت مسیرهای API (بخش 5)
│   │   │   ├── storage_keys.dart    # کلیدهای GetStorage/secure storage (پیشوند cn_)
│   │   │   └── order_status.dart    # وضعیت‌ها/عنوان فارسی/رنگ‌های وضعیت سفارش
│   │   ├── network/
│   │   │   ├── api_client.dart      # پوشه http با token/timeout/پارس خطا
│   │   │   └── api_error.dart       # ApiError{kind, message, code, fields}
│   │   ├── cache/
│   │   │   ├── kv_cache.dart        # GetStorage + TTL helper
│   │   │   └── db_cache.dart        # sqflite cache.db (orders/catalog/transactions)
│   │   ├── services/
│   │   │   ├── auth_service.dart    # توکن + کش user + logout + force-logout 401
│   │   │   ├── poller.dart          # Poller عمومی visibility-aware با backoff
│   │   │   ├── local_notification.dart
│   │   │   ├── location_service.dart# geolocator + geocoding wrapper
│   │   │   └── launcher_service.dart# url_launcher (درگاه، tel، صفحات وب)
│   │   ├── theme/
│   │   │   ├── app_theme.dart       # رنگ‌ها از برند + Material3 + dark
│   │   │   └── app_text_styles.dart # فونت Peyda/Vazir
│   │   ├── values/strings.dart      # تمام متن‌های UI فارسی
│   │   ├── utils/
│   │   │   ├── formatters.dart      # تومان، تاریخ، ارقام فارسی (intl + persian_number_utility)
│   │   │   └── validators.dart      # موبایل 09xxxxxxxxx، مبلغ، …
│   │   ├── widgets/                 # CnButton, CnTextField, CnEmptyState, CnErrorRetry, CapacityBadge, StatusChip, PriceRow …
│   │   ├── routes/app_pages.dart
│   │   ├── routes/app_routes.dart
│   │   └── bindings/initial_binding.dart
│   ├── data/
│   │   ├── models/                  # user, category, service, service_field, order, order_update, wallet_transaction, coupon, capacity_snapshot, capacity_slot, payment_status, app_settings, notification_item
│   │   ├── providers/               # api_provider(ها) — فقط HTTP، بدون کش
│   │   └── repositories/            # auth, catalog, order, wallet, capacity, settings + cache-first
│   └── modules/                     # هر ماژول: bindings/ controllers/ views/ widgets/
│       ├── splash/
│       ├── onboarding/
│       ├── auth/                    # phone → otp
│       ├── home/                    # capacity + slider + دسته‌ها + featured + پیگیر سفارش فعال
│       ├── catalog/                 # خدمات دسته + جزئیات خدمت
│       ├── order_form/              # فرم داینامیک + قیمت + کپشن/فایل + ارسال
│       ├── checkout/                # پرداخت کیف پولی + کمبود موجودی
│       ├── orders/                  # لیست + جزئیات + تیکت + امتیاز
│       ├── tracker/                 # پیگیری زنده (polling) + نسخه عمومی token
│       ├── wallet/                  # موجودی + تراکنش‌ها + شارژ (presets) + پرداخت در جریان
│       ├── profile/                 # پروفایل، خروج، قواعد
│       └── settings/                # تم، لینک‌ها (قوانین/حریم خصوصی)، درباره
assets/
├── fonts/                           # PeydaFaNumWeb-Regular/Medium/SemiBold/Bold.ttf (+Vazir برای fallback)
└── images/                          # لوگو، placeholder اسلایدر
```

**قانون وابستگی:** `modules → repositories → providers/network` و همه → `core`. مدل‌ها از هیچ‌چیز import نمی‌گیرند. دو ماژول هرگز مستقیم Controller هم را صدا نمی‌زنند — ارتباط از طریق Repository/سرویس یا Route با آرگومان.

### 2.3 قوانین GetX (قرارداد تیمی)

- **Route:** فقط named route (`Get.toNamed(Routes.ORDER_FORM, arguments: service)`)؛ return داده با `Get.back(result: …)`.
- **Middleware:** `AuthMiddleware` (هدایت به auth اگر توکن نیست) و `GuestMiddleware` (اگر لاگین است، به home).
- **Controller:** برای هر view یک Controller؛ ورودی سرویس/ریپو از طریق constructor؛ `onInit` → بارگذاری کش‌محور؛ `onClose` → بستن Poller/Timer. بدون BuildContext در منطق.
- **Error UX:** هر صفحه سه حالت دارد: loading skeleton، error با دکمه «تلاش مجدد» (`CnErrorRetry`)، empty با تصویر (`CnEmptyState`).
- **دیالوگ/اسنک‌بار:** فقط `Get.snackbar` / `Get.dialog` با متن از strings.dart.
- **Snackbar خطا:** `ApiError.message` را مستقیم نشان بده (پیام فارسی سرور)، به‌جز 401 که force-logout می‌شود.

### 2.4 دکترین کش (سه لایه)

| لایه | ابزار | محتوا | TTL / نابودی |
|---|---|---|---|
| L1 حافظه | Rx داخل Controller | داده صفحه جاری | تا بسته شدن Controller |
| L2 KV | GetStorage (`kv_cache.dart`) | settings کسب‌وکار، capacity snapshot، آخرین user، فلاگ onboarding، draft فرم سفارش | settings: ۱۰ دقیقه، capacity: ۳۰ ثانیه، user: تا logout |
| L3 رابطه‌ای | sqflite `cache.db` (`db_cache.dart`) | catalog (categories/services)، orders (برای جستجو/آفلاین)، wallet transactions | هر بار موفقیت network → write-through؛ کلید نسخه‌دار `v{n}` برای invalidation ساختاری |

قواعد:
1. هیچ Repository، http را مستقیم صدا نمی‌زند؛ از `ApiClient` استفاده می‌کند و خودش read/write کش را انجام می‌دهد.
2. عملیات write (ثبت سفارش، پرداخت، تیکت) همیشه network-first است؛ بعد از موفقیت کش مربوطه invalidates می‌شود (`catalog`, `orders`, `wallet`).
3. در حالت آفلاین، writeها خطای شبکه می‌دهند و فرم دیتا را نگه می‌دارد (draft در L2) — صف ارسال آفلاین از محدوده MVP خارج است.
4. لاگین/خروج → پاک‌سازی L2/L3 بخش داده کاربر (به‌جز ترجیحات).

---
## 3. نگاشت پکیج‌ها — هر پکیج از لیست، کجا و چرا

قاعده: «هر کدام که با توجه به کد بک‌اند لازم است» — پس هر پکیج سه وضعیت دارد: **فاز X (لازم)** / **اختیاری** / **فعلاً نه**.

| پکیج | نسخه | وضعیت | نقش دقیق در اپ | مستند به بک‌اند |
|---|---|---|---|---|
| `get` | ^4.6.6 | فاز 0 | هسته معماری: state، DI (Bindings)، routing، snackbar/dialog | — |
| `http` | ^1.2.0 | فاز 1 | `ApiClient` (پوشه با token/timeout/پارس خطای flat `{error}`) | قرارداد `bootstrap/app.php` |
| `flutter_secure_storage` | ^10.3.1 | فاز 1 | ذخیره توکن Sanctum و نسخه پشتیبان session | BE-1 |
| `get_storage` | ^2.1.1 | فاز 1 | لایه کش L2 (settings، capacity، draft فرم، فلاگ onboarding) | کش‌محوری |
| `sqflite` | ^2.3.0 | فاز 1 | لایه کش L3: catalog، orders، transactions (جستجوی آفلاین) | کش‌محوری |
| `intl` | ^0.20.2 | فاز 0 | locale `fa`، `DateFormat`، `NumberFormat` برای قیمت/تاریخ | نمایش واترمارک‌دار زمان‌های ISO سرور |
| `persian_number_utility` | ^1.1.6 | فاز 1 | ارقام فارسی قیمت‌ها/شماره‌ها در UI | سرور اعداد لاتین می‌فرستد |
| `url_launcher` | ^6.3.2 | فاز 1 | بازکردن `redirectUrl` درگاه پرداخت، تماس `tel:`، صفحات قوانین | `PaymentController::request` |
| `flutter_local_notifications` | ^22.1.0 | فاز 7 | اعلان محلی روی تغییر وضعیت polling (شروع/آماده/نوبت مجدد) — جانشین Browser Notification در PWA | `QUEUE_SYSTEM.md` |
| `geolocator` | ^14.0.2 | فاز 8 (اختیاری) | موقعیت فعلی کاربر در انتخاب آدرس پیک | `deliveryMethod=courier` |
| `geocoding` | ^5.0.0 | فاز 8 (اختیاری) | تبدیل مختصات به متن آدرس فارسی برای `deliveryAddress` | آدرس در بک‌اند رشته متنی است |
| `flutter_map` + `latlong2` | ^8.3.1 / ^0.10.1 | فاز 8 (اختیاری) | AddressPicker روی نقشه OSM برای سفارش پیک | همان بالا |
| `app_links` | ^6.4.1 | فاز 8 (اختیاری) | گرفتن بازگشت پرداخت/لینک ترکر اگر در آینده callback به scheme `caffenet://` تغییر کند؛ MVP با polling کار می‌کند | `verify()` ریدایرکت به وب |
| `shared_preferences` | ^2.5.5 | فاز 8 (اختیاری) | فقط اگر ترجیحاتی خارج از کش داده لازم شد (theme mode). با GetStorage همپوشان است — پیش‌فرض: استفاده نمی‌شود | — |
| `pusher_reverb_flutter` | ^0.0.9 | **فعلاً نه** | بک‌اند صریحاً WebSocket را در cPanel ممنوع کرده؛ اگر زیرساخت بعداً Reverb گرفت، همین پکیج جایگزین Poller می‌شود (Interface آماده نگه داشته شود) | `QUEUE_SYSTEM.md §Out of Scope` |

**افزودنی‌های لازم خارج لیست (باید با موافقت اعمال شوند؛ بدون آن‌ها هسته کار نمی‌کند):**

| پکیج | فاز | چرا بدون آن نمی‌شود |
|---|---|---|
| `image_picker` | فاز 5 | آپلود «فایل/عکس» مشتری هسته کسب‌وکار است (`customerFiles` + `POST /upload` multipart) |
| `file_picker` | فاز 5 | انتخاب PDF/سند برای پرینت (عکس تنها کافی نیست) |
| BazaarPay Android SDK (ناتیو، JitPack `com.github.cafebazaar:bazaarpay:5.4.0` — پلاگین pub رسمی وجود ندارد) | فاز 8 (اختیاری — T8.6a/b) | UX پرداخت درون‌اپ اندروید از طریق پل MethodChannel؛ نیاز به API 17+ و checkout_token/PaymentURL ساخته‌شده سمت سرور. مسیر پیش‌فرض پرداخت وب است و SDK فقط بهبود UX اندروید با fallback خودکار |

**افزودنی‌های پیشنهادی (تصمیم باز — بخش 13):** `firebase_core` + `firebase_messaging` (پوش بک‌گراند؛ بک‌اند endpoint دارد ولی نیاز به پروژه Firebase/google-services.json دارد)، `shamsi_date` (اگر تاریخ جلالی خواست شد؛ راه دیگر: فرمت از سرور).

---

## 4. قرارداد API و نگاشت Dart

### 4.1 Endpoint map (تک‌منبع حقیقت → `api_endpoints.dart`)

مبنای همه: `{BASE_URL}/api/...` با هدر `Accept: application/json` و در صورت لاگین `Authorization: Bearer <token>`.

| # | Endpoint | Auth | کاربرد در اپ | ماژول |
|---|---|---|---|---|
| 1 | `GET /health` | — | health-check + ping کش | core |
| 2 | `POST /auth/send-otp` | — | ارسال کد `{phone}` → `{message[, testCode]}` | auth |
| 3 | `POST /auth/verify-otp` | — | `{phone, code, mode:'token'}` → `user + {token}` (BE-1) | auth |
| 4 | `POST /auth/logout` | token | ابطال توکن و پاک‌سازی کش | auth |
| 5 | `GET /auth/me` | token | رفرش پروفایل/مجوزها | profile |
| 6 | `GET /settings` | optional | تنظیمات کسب‌وکار + فلاگ‌های درگاه → کش L2 (۱۰دقیقه) | home/wallet |
| 7 | `GET /categories` | optional | لیست دسته‌ها → L2/L3 | catalog |
| 8 | `GET /services` | optional | لیست خدمات با fields → L2/L3 | catalog/order_form |
| 9 | `GET /capacity/current` | — | نشانگر ظرفیت (کش ۳۰ ثانیه) | home |
| 10 | `GET /capacity/slots?hours=48` | token | اسلات‌های قابل رزرو | tracker |
| 11 | `GET /orders` | token | لیست سفارش‌ها (کامل، بدون صفحه‌بندی) → L3 | orders |
| 12 | `POST /orders` | token | ثبت سفارش (فرم داینامیک) → `201 Order` | order_form |
| 13 | `GET /orders/{id}` | token | جزئیات کامل | orders |
| 14 | `POST /orders/{id}/pay-wallet` | token | پرداخت کیف پولی | checkout |
| 15 | `POST /orders/{id}/updates` polling: `GET /orders/{id}/updates` | token | Poller ۱۵ ثانیه‌ای → `{order, notifications[], server_time}` | tracker |
| 16 | `POST /orders/{id}/reserve` | token | `{slot_id}` رزرو اسلات سفارش long | tracker |
| 17 | `POST /orders/{id}/notify-me` | token | پرچم «به من اطلاع بده» | tracker |
| 18 | `DELETE /orders/{id}/cancel` | token | لغو + خروج از صف | tracker |
| 19 | `GET /orders/track/{token}` | — | پیگیری عمومی با لینک اشتراکی | tracker |
| 20 | `POST /payments/request` | token | شارژ کیف پول `{amount, gateway}` → `{paymentId, redirectUrl, authority}` | wallet |
| 21 | `GET /payments/status?authority=` | token | polling نتیجه پرداخت | wallet |
| 22 | `GET /wallet/transactions` | token | ledger کیف پول → L3 | wallet |
| 23 | `GET /coupons` + `POST /coupons/validate` | token | کدهای تخفیف فعال/اعتبارسنجی | order_form |
| 24 | `POST /upload` + `DELETE /upload` | token | آپلود multipart فایل مشتری | order_form |
| 25 | `POST /orders/{id}/ticket` | token | گفتگوی سفارش | orders |
| 26 | `PATCH /orders/{id}` + `DELETE /orders/{id}` | token | ویرایش/حذف سفارش (در وضعیت مجاز) | orders |
| 27 | `GET /slider` | optional | بنرهای صفحه اصلی → L2 | home |
| 28 | `POST /orders/{id}/pay-bazaarpay` + `GET /payments/bazaarpay/contract` | token/— | Direct Pay بازارپی (فاز 8؛ جریان کامل در بخش 4.5): خروجی `paid/pending/failed` یا `contract_pending{contractRedirectUrl, paymentId, orderId}`؛ مسیر دوم فقط callback مرورگر پس از امضای قرارداد است و اپ آن را صدا نمی‌زند | wallet |
| 29 | `GET /fcm/config` + `POST /fcm/token` | token/mixed | پوش (اختیاری فاز 8) | core |

**پارامترهای ثبت سفارش (12):** `{serviceId, formData{}, contactMethods[], urgency: normal|urgent|immediate, deliveryMethod: download|courier|in_person, deliveryAddress?, deliveryPostalCode?, couponCode?, customerNote?, customerFiles[{id,name,size,type,url}]}`. خطاهای معنایی: `WALLET_ONLY`، `INSUFFICIENT_WALLET{required,balance,shortfall}`، خطای فیلد اجباری با label فارسی.

### 4.2 مدل‌های Dart (فهرست نهایی `data/models/`)

تمام مدل‌ها: `final`، `fromJson`، `toJson` (برای کش)، null-safe؛ تاریخ‌ها به‌صورت `DateTime?` با پارس ISO؛ مقادیر پولی `int` (تومان).

- `UserModel{id, phone, name, role, permissions[], walletBalance, createdAt, isBlocked}`
- `CategoryModel{id, title, iconName, iconColor, sortOrder, description}`
- `ServiceModel{id, categoryId, title, description, basePrice, estimatedTime, icon, iconColor, sortOrder, isActive, isFeatured, featuredSort, fields: List<ServiceField>, pricingFormulaDescription}`
- `ServiceField{id, label, type, required, options?, …}` — **فرم‌ساز داینامیک**؛ انواع حداقلی: text/number/select/textarea/date/checkbox
- `OrderModel{id, orderNumber, serviceId, serviceTitle, status, urgency, deliveryMethod, deliveryAddress?, formData, customerFiles[], resultFiles[], totalPrice, discountAmount, paidAmount, refundAmount?, paymentMethod, queueType, queuePosition?, estimatedWaitMinutes?, estimatedDurationMinutes?, estimatedStartAt?, estimatedEndAt?, noResponseDeadline?, trackToken?, logs[], ticketMessages[], rating?, createdAt, updatedAt}` + map عنوان فارسی وضعیت‌ها (`STATUS_PENDING_PAYMENT → «در انتظار پرداخت» …`)
- `OrderUpdateModel{order, notifications: List<NotificationItem>, serverTime}`
- `NotificationItem{id, title, body, type, timestamp, read}`
- `WalletTransactionModel{id, type, typeTitle, direction, amount, balanceAfter, reference, note, createdAt}`
- `CouponModel{...}, CapacitySnapshot{tier, title, etaMinutes, firstSlotAt}, CapacitySlot{id, operatorName, startAt, endAt, status}, PaymentStatus{status, purpose, amount, refId, orderId}, AppSettings{bazaar, bazaarPay, smsEnabled, enableCoupons, walletTopUpPresets, courierCost, urgencyMultipliers, …}`

### 4.3 استراتژی Realtime (Polling) — جایگزین WebSocket

`core/services/poller.dart` یک Poller عمومی می‌سازد؛ `tracker` و `home` از آن استفاده می‌کنند:

- سفارش فعال: هر **۱۵ ثانیه** `GET /orders/{id}/updates` (سقف سرور ۱۲/min رعایت می‌شود)؛ تغییر وضعیت → به‌روزرسانی UI + **Local Notification** («سفارش شما شروع شد» / «سفارش آماده است» / «نوبت شما منتقل شد»).
- سازگار با چرخه عمر: وقتی اپ در background است فاصله → ۶۰ ثانیه؛ وقتی foreground شد یک fetch فوری. (با `AppLifecycleState`؛ بدون پکیج اضافه.)
- Backoff نمایی روی خطا: ۱s → 2s → 4s → … → سقف ۳۰s؛ روی 401 توقف و force-logout؛ روی 429 احترام به سرور (توقف تا سر دقیقه بعد).
- آفلاین: توقف polling + بنر «اتصال برقرار نیست» + تلاش مجدد خودکار با `ConnectivityEvent` ساده (متد own با Timer، بدون پکیج اضافه برای MVP).

### 4.4 استراتژی پرداخت (MVP)

```text
شارژ کیف پول:
1) کاربر preset/مبلغ را انتخاب می‌کند (validate سمت UI با MIN/MAX بک‌اند)
2) POST /payments/request {amount, gateway:'online'} → {paymentId, redirectUrl, authority}
3) url_launcher → مرورگر خارجی درگاه (Zarinpal/BazaarPay) — هرگز WebView داخل اپ برای پرداخت (خطای 3DS/OTP بانک)
4) صفحه «پرداخت در جریان است» با Poller هر ۳ ثانیه GET /payments/status?authority= (سقف ۱۰ دقیقه)
5) paid → رفرش /auth/me + کش wallet → snackbar موفقیت → back به wallet
   failed/timeout → پیام + دکمه «بررسی مجدد» (سرور idempotent است)
پرداخت سفارش:
1) POST /orders (همیشه با guard موجودی) → اگر 400 INSUFFICIENT_WALLET → دیالوگ «شارژ X تومان» → جریان شارژ
2) در غیر این صورت POST /orders/{id}/pay-wallet → موفق → tracker سفارش
```

`app_links` در MVP استفاده نمی‌شود چون callback درگاه به وب SPA برمی‌گردد؛ polling روی `/payments/status` منبع حقیقت است (سرور idempotent و self-healing طراحی شده). اگر بعداً خواستیم UX را بدون polling قطع کنیم، تسک T8.x ریدایرکت `verify()` را برای user-agent اپ به `caffenet://payment?authority=…` تغییر می‌دهد و `app_links` فعال می‌شود.

### 4.5 پرداخت درون‌برنامه‌ای بازارپی (BazaarPay) — مستند بر اساس منابع رسمی

این بخش عیناً بر اساس مستندات رسمی نوشته و با کد فعلی بک‌اند تطبیق داده شده است:

- **payment.md** (checkout/init، trace، commit، refund): `github.com/BazaarPay/Docs/blob/main/fa/payment.md`
- **direct-pay.md** (قرارداد پرداخت مستقیم): `github.com/BazaarPay/Docs/blob/main/fa/direct-pay.md`
- **Android SDK**: `github.com/cafebazaar/BazaarPay` — JitPack `com.github.cafebazaar:bazaarpay:5.4.0`، حداقل Android API 17، نیازمند **Checkout Token / PaymentURL ساخته‌شده سمت سرور قبل از شروع پرداخت**

**نقشه مسئولیت‌ها:** تمام APIهای مرچنت بازارپی فقط سمت سرور لاراول صدا زده می‌شوند — `BazaarPayService` همین حالا کامل پیاده دارد: `initCheckout` (`POST /badje/v1/checkout/init/` با `{amount(rial), destination, service_name}`)، `gatewayRedirectUrl`، `trace`، `commit` (204)، `refund`، `initContract`، `contractPageUrl`، `traceContract`، `payWithContract` (v2 برای خطای ساخت‌یافته) و `payableAmount` + حالت تست `TEST-`. اپ فلاتر **هرگز** توکن مرچنت ندارد و فقط با endpointهای خود بک‌اند کار می‌کند: `/payments/request`، `/payments/status`، `/orders/{id}/pay-bazaarpay`.

#### 4.5.1 سه مسیر پرداخت با بازارپی

| مسیر | پلتفرم | UX | وضعیت در پلن |
|---|---|---|---|
| A) وب ریدایرکت (checkout) | هر دو | مرورگر خارجی → بازگشت به وب + polling | **MVP (T6.4)** — بدون کد ناتیو |
| B) SDK اندروید (پرداخت درون‌اپ) | فقط Android | صفحه پرداخت بازارپی داخل اپ (Activity Result API) | فاز 8 — T8.6a/b |
| C) Direct Pay (قرارداد؛ پرداخت خودکار سفارش بدون دخالت کاربر) | هر دو (امضای قرارداد: وب یا SDK) | یک دکمه → پرداخت کامل | فاز 8 — T8.6c/d/e |

#### 4.5.2 جریان A — شارژ کیف پول با وب‌گیت بازارپی (پیاده‌شده در بک‌اند؛ مرجع T6.4)

1. `POST /payments/request {amount, gateway:'bazaarpay'}` → `{gateway:'bazaarpay', paymentId, authority(=checkout_token), redirectUrl}` — بک‌اند `checkout/init` رسمی را صدا زده و `redirectUrl` را طبق مستندات با `redirect_url` کدشده (→ `…/payments/verify?authority=…&gw=bazaarpay`) و `phone` (پیش‌پرکردن لاگین درگاه) ساخته است.
2. `url_launcher` → کاربر در `app.bazaar-pay.ir` پرداخت می‌کند → درگاه به `redirect_url` برمی‌گرداند.
3. سرور روی callback: **trace منبع حقیقت است** (پارامترهای ریدایرکت هرگز معتبر فرض نمی‌شوند)؛ اگر `paid_not_committed` → `commit` (⚠️ اگر کامیت نشود، طبق مستند رسمی کل مبلغ بعد از چند دقیقه به کیف پول کاربر در بازارپی برمی‌گردد) → fulfillment (شارژ کیف پول CaffeNet) → ریدایرکت به `appUrl/?payment=success\|failed`.
4. اپ: Poller هر ۳ ثانیه روی `GET /payments/status?authority=` — سرور پرداخت‌های pending بازارپی را reconcile می‌کند (self-healing اگر callback گم شود) → paid/failed.

وضعیت‌های trace (enum رسمی): `invalid_token`، `unpaid`، `paid_not_committed`، `paid_not_committed_refunded`، `paid_committed`، `refunded`، `timed_out` — دو حالت paid = موفق؛ unpaid = هنوز در جریان؛ بقیه = failed.

#### 4.5.3 جریان B — پرداخت درون‌اپ با SDK اندروید (T8.6a/b)

- **پیش‌نیاز سرور:** همان مرحله ۱ جریان A است؛ همان `redirectUrl` (payment_url + redirect_url + phone) به SDK داده می‌شود (پارامتر redirect_url در سناریوی SDK بی‌اثر است چون نتیجه از Activity Result می‌آید).
- **پل فلاتر:** `MethodChannel('caffenet/bazaar_pay')` + کد ناتیو Kotlin در `MainActivity` — launcher باید **به‌صورت فیلد کلاس** ثبت شود (الزام Activity Result API: ثبت پیش از onStart):

```kotlin
// MainActivity.kt
private val bazaarPayLauncher = registerForActivityResult(StartBazaarPay()) { isSuccessful ->
    methodChannelResult?.success(isSuccessful)
}
// متد pay در MethodChannel: options = BazaarPayOptions.paymentUrl(paymentUrl)
//     .phoneNumber(phone).build()  →  bazaarPayLauncher.launch(options)
```

```dart
// core/services/bazaar_pay_bridge.dart
static const _ch = MethodChannel('caffenet/bazaar_pay');
Future<bool> payInApp({required String paymentUrl, String? phone}) async {
  try {
    return await _ch.invokeMethod('pay', {'paymentUrl': paymentUrl, 'phone': phone});
  } on PlatformException {
    return false; // SDK در دسترس نیست → fallback به جریان A (وب)
  }
}
```

- پس از `isSuccessful == true`: اپ فقط `GET /payments/status?authority=` را صدا می‌زند — **کامیت همیشه سمت سرور** انجام می‌شود، طبق توصیه صریح README SDK («we recommend this happens on the server side»). کامیت از داخل اپ با SDK هرگز انجام نمی‌شود.
- iOS یا خطای دسترسی SDK → fallback خودکار به جریان A.
- سایر قابلیت‌های SDK (برای آینده): `StartDirectPayFinalizeContract` (امضای قرارداد — 4.5.4)، `StartIncreaseBalance` (صفحه شارژ مستقیم کیف پول بازارپی)، `StartLogin`/`getBazaarPayBalance` (فقط اگر موجودی بازارپی خواستیم)؛ autoLogin token فعلاً نداریم → ارسال نمی‌شود.

#### 4.5.4 جریان C — Direct Pay: پرداخت خودکار سفارش (T8.6c/d/e)

بر اساس direct-pay.md؛ بک‌اند کامل پیاده دارد (`requestDirectOrder` + `contractCallback` + `executeDirectPay` اتمیک):

1. `POST /orders/{id}/pay-bazaarpay` → دو حالت:
   - **قرارداد فعال دارد** → سرور در یک تراکنش اتمیک: `checkout/init` → `POST /badje/v2/direct-pay/ {contract_token, checkout_token}` (طبق مستند نیازی به commit نیست — اتوکامیت) → پاسخ `{status:'paid'\|'pending', message, orderId}` یا `{status:'failed', error}` با 400.
   - **قرارداد ندارد** → سرور قرارداد می‌سازد (`contract/init` با type/period/amountLimit از تنظیمات ادمین) و پاسخ `{status:'contract_pending', message, contractRedirectUrl, paymentId, orderId}` می‌دهد. `contract_token` داخل query پارامترهای `contractRedirectUrl` است (اپ پارس می‌کند؛ BE-9 اختیاری: فیلد صریح).
2. حالت `contract_pending` → کاربر به صفحه امضا می‌رود:
   - **وب:** همان `contractRedirectUrl` = `https://app.bazaar-pay.ir/contract/direct-pay?contract_token=…&redirect_url=…&phone=…&message=…` (بک‌اند ساخته)
   - **یا SDK اندروید:** استخراج `contract_token` از URL → MethodChannel → `StartDirectPayFinalizeContract(DirectPayContractOptions(contractToken, message, phoneNumber))`
3. پس از امضا: مسیر وب به `GET /payments/bazaarpay/contract` روی سرور برمی‌گردد — سرور trace قرارداد می‌گیرد، اگر `active` بود و پرداخت pending مانده، خودش `executeDirectPay` را ادامه می‌دهد. اپ صرفاً Poller روی `/payments/status` را ادامه می‌دهد (وضعیت سفارش خودکار به‌روز می‌شود).
4. وضعیت‌های قرارداد (trace-contract رسمی): `new \| active \| declined \| cancelled \| expired` + `amount_limit` و `limit_remaining_amount` (مانده سقف دوره جاری). نوع/دوره/سقف قرارداد از تنظیمات ادمین (`bazaarPay.direct*`) می‌آید — اپ تصمیمی نمی‌گیرد.
5. **نگاشت خطاهای v2** (`{detail, code}`) در `strings.dart`:
   - `account.insufficient_balance` → «موجودی کیف پول بازارپی کافی نیست» + دکمه شارژ (وب یا `StartIncreaseBalance`)
   - `purchase.timeout` → «توکن پرداخت منقضی شده؛ از اول تلاش کنید» + دکمه تکرار (سرور idempotent است و توکن تازه می‌سازد)
   - `direct_pay.inactive_contract` / `direct_pay.period_amount_limit_violation` → نمایش مانده سقف (`limit_remaining_amount`) + راهنمای تمدید/روش جایگزین
   - `direct_debit.*` → پیام فارسی `detail` سرور عیناً نمایش داده شود
6. اختیاری: `payable-amount` (فقط قرارداد wallet-type) برای نمایش «مبلغ قابل پرداخت تا پایان دوره» — سرویس بک‌اند دارد ولی endpoint اپ ندارد؛ در صورت نیاز، BE endpoint نازک اضافه می‌کند (خارج MVP).

#### 4.5.5 قواعد مشترک هر سه مسیر

- **Idempotency:** trace/commit/status همیشه قابل تکرارند؛ refund فقط **یک‌بار** per checkout_token معتبر است و مبلغ = اولین فراخوانی موفق — پس اپ هرگز refund صدا نمی‌زند (فقط ادمین/سرور).
- **واحد پول:** API بازارپی **ریال** است؛ بک‌اند با `bazaarPayRialRate` (پیش‌فرض ×۱۰) تبدیل می‌کند. اپ همیشه با بک‌اند **تومان** کار می‌کند — هر تبدیل ریالی سمت فلاتر ممنوع.
- **حالت تست:** `paymentTestMode` → توکن‌های `TEST-…` + صفحه `/test-gateway` — کل جریان‌های A/B/C بدون اعتبار مرچنت قابل E2E هستند؛ AC تست‌های T8.6 با همین حالت پذیرفته می‌شود.
- **امنیت:** توکن مرچنت هرگز به اپ نمی‌رسد؛ verify فقط با trace؛ پارامترهای ریدایرکت معتبر فرض نمی‌شوند.

---
## 5. فازهای اجرایی (Task Graph)

**فرمت هر تسک:** `ID | شرح | خروجی/فایل‌ها | معیار پذیرش (AC)`. دستور راستی‌آزمایی هر فاز در انتهای همان فاز آمده. فاز P2 (بک‌اند) با فاز P1 موازی قابل اجراست. هیچ تسکی شروع نمی‌شود مگر اینکه وابستگی‌هایش (ستون «نیاز به») کامل شده باشند.

### فاز 0 — Bootstrap پروژه Flutter (زمان تخمینی: نیم روز)

| ID | شرح | خروجی | AC |
|---|---|---|---|
| T0.1 | `flutter create` با org `ir.caffenet.app`، نام `caffenet`؛ تعیین SDK constraint بر اساس نسخه نصب‌شده | کل اسکلت پروژه | `flutter run` روی ایمیلیتور بدون خطا compile می‌شود |
| T0.2 | pubspec: افزودن پکیج‌های فاز 0/1 (get, http, get_storage, flutter_secure_storage, sqflite, intl, persian_number_utility, url_launcher) + assets fonts | pubspec.yaml | `flutter pub get` بدون conflict |
| T0.3 | انتقال فونت‌ها: کپی `PeydaFaNumWeb-{Regular,Medium,SemiBold,Bold}.ttf` (+`Vazir.ttf` fallback) از ریپو لاراول به `assets/fonts/` و تعریف در pubspec | assets/fonts, pubspec | یک Text نمونه با Peyda رندر می‌شود |
| T0.4 | Theme + RTL: `app_theme.dart` (رنگ برند آبی تیره/کرم، Material 3، دارک‌مود)، `main.dart` با `locale: fa`، `fallbackLocale: fa`، `Directionality rtl`، GetMaterial | core/theme, main.dart | اپ راست‌چین فارسی با فونت برند بالا می‌آید |
| T0.5 | اسکلت پوشه‌ها مطابق بخش 2.2 + `app_routes.dart`/`app_pages.dart` با مسیرهای splash/onboarding/auth/home (viewهای placeholder) | مسیرها + ماژول‌های خالی | `Get.toNamed` بین همه placeholderها کار می‌کند |
| T0.6 | `strings.dart` + `formatters.dart` (تومان با ارقام فارسی، فرمت تاریخ) + `validators.dart` (موبایل ایرانی) | core/values, core/utils | تست واحد فرمترها پاس است |
| T0.7 | `env.dart` با `--dart-define=CAFFENET_API_BASE_URL` (+ آدرس dev/prod در `launch configs`) | core/config | مقدار env در runtime خوانده و در لوگ debug نمایش داده می‌شود (بدون چاپ توکن‌ها) |
| T0.8 | `analysis_options.yaml` سخت‌گیرانه + GitHub Action ساده (analyze + test) + README و AGENTIC بدنه ریپو | CI, docs | `flutter analyze` صفر issue |

**Verify فاز 0:** `flutter analyze && flutter test` سبز؛ `flutter build apk --debug` موفق.

### فاز 1 — هسته زیرساخت (زمان: ۱ تا ۲ روز)

| ID | شرح | خروجی | AC |
|---|---|---|---|
| T1.1 | `ApiError` + `ApiClient` (پوشه http): timeout 25s، هدرها، attach token از AuthService، پارس خطای flat `{error[, code]}` به ApiError{kind: network/timeout/auth/validation/permission/server}، هندل 401→forceLogout، متدهای get/post/patch/delete/delete-with-body + `multipart` برای upload | core/network | تست واحد با http MockClient: پاسخ موفق، 400 با error فارسی، 401، timeout، قطع شبکه |
| T1.2 | `AuthService`: نگهداری توکن (secure storage) + user کش‌شده (L2)، `isAuthenticated`، `forceLogout()` (پاک‌سازی + پرش به auth)، `refreshMe()` | core/services | چرخه login→restart اپ→کاربر برمی‌گردد؛ logout همه‌چیز را پاک می‌کند |
| T1.3 | `kv_cache.dart` (GetStorage + TTL + کلیدهای پیشونددار `cn_`) و `db_cache.dart` (sqflite: جداول `catalog_items`, `orders`, `wallet_tx` با ستون json + updated_at + کلید نسخه) | core/cache | تست: نوشتن/خواندن/TTL؛ مهاجرت نسخه با `onUpgrade` |
| T1.4 | `InitialBinding`: ثبت ApiClient، AuthService، کش‌ها، سرویس‌ها (permanent) | core/bindings | رزولوشن همه وابستگی‌ها در test binding پاس می‌شود |
| T1.5 | `Poller` عمومی (پریود، backoff، pause/resume با lifecycle، توقف روی 401) + `LauncherService` + `LocalNotificationService` (کانال‌های فارسی، مجوز Android 13، init در main) | core/services | تست Poller با FakeTimers: backoff و pause |
| T1.6 | ویجت‌های مشترک: CnButton, CnTextField (RTL)، CnScaffold (هدر برند)، CnEmptyState, CnErrorRetry(onRetry)، StatusChip، CapacityBadge، PriceRow، LoadingSkeleton | core/widgets | اپ دمو (placeholder pages) همه را رندر می‌کند |
| T1.7 | Splash ماژول واقعی: تصمیم اولین مسیر (onboarding? auth? home) بر اساس فلاگ‌ها + انیمیشن لوگو | modules/splash | هر سه مسیر با کش خالی/پر درست انتخاب می‌شود |

**Verify فاز 1:** `flutter test test/core` سبز؛ `flutter analyze` صفر.

### فاز P2 — هم‌راستاسازی بک‌اند (موازی با فاز 1؛ non-breaking)

| ID | شرح | فایل‌ها | AC |
|---|---|---|---|
| BE-1 | افزودن `laravel/sanctum`؛ در `AuthController::verifyOtp` وقتی body دارای `mode:'token'` است، پس از pipeline موفق Fortify: `$user->createToken('mobile')` و برگرداندن `Formatter::user($user) + ['token' => $plainToken]` (PWA بدون mode دست‌نخورده می‌ماند) | composer.json, AuthController.php, tests | تست Feature: verify-otp با mode=token، توکن برمی‌گردد؛ بدون mode، مثل قبل session + csrf |
| BE-2 | `EnsureAuth` دوگانه: اگر `Authorization: Bearer` بود → `auth('sanctum')->user()` وگرنه `$request->user()`؛ مسدود بودن کاربر توکنی هم همان 403 | Middleware/EnsureAuth.php | تست: با Bearer به `/auth/me` و `/orders` دسترسی درست |
| BE-3 | CSRF: کلاس `VerifyCsrfToken` سفارشی که وقتی هدر `Authorization: Bearer` معتبر وجود دارد skip می‌کند (درخواست‌های session محور همچنان محافظت‌شده) | bootstrap/app.php, Middleware | تست: POST با token بدون CSRF → 200؛ POST session بدون CSRF → 419 |
| BE-4 | دانلود فایل توکن‌دار: قبول Bearer در `GET /uploads/{filename}` (همان منطق مالکیت) یا endpoint `GET /api/uploads/{filename}` با auth.session دوگانه؛ خروجی برای اپ: url + هدر | routes/web.php یا api.php | تست: دانلود فایل سفارش خود کاربر با Bearer |
| BE-5 | `POST /auth/logout` حالت توکنی: revoke توکن جاری (`$request->user('sanctum')->currentAccessToken()->delete()`) | AuthController.php | تست: بعد از logout، همان توکن 401 می‌دهد |
| BE-6 | کالکشن Postman/فایل `docs/api-contract.md` برای ۳ endpoint جدید + ثبت تغییرات در CHANGELOG ریپو لاراول | docs | مرور یکپارچگی: PWA تست دستی login/order بدون تغییر رفتار |

**Verify فاز P2:** `php artisan test` سبز (تست‌های قبلی + ۴ تست جدید)؛ curl: `verify-otp(mode=token)` → `GET /orders` با Bearer → 200.

### فاز 3 — Auth (زمان: ۱ روز)

| ID | شرح | AC |
|---|---|---|
| T3.1 | `AuthRepository`: sendOtp(phone) → پیام سرور (+testCode در حالت آزمایشی)، verifyOtp(phone, code, mode:'token') → ذخیره توکن/user، logout | تست واحد ریپو با MockClient |
| T3.2 | UI ورود دو مرحله‌ای: صفحه شماره موبایل (اعتبارسنجی + فرمت ارقام فارسی)، صفحه OTP (۵ خانه، شمارش معکوس ۲ دقیقه، ارسال مجدد، حالت testCode برای توسعه) | جریان کامل در UI |
| T3.3 | هندل خطاها: 429 (پیام سرور)، 403 مسدود، 503 پیامک خاموش، کد اشتباه → shake فیلد؛ snackbar با متن فارسی سرور | هر سناریو تست دستی/تست واحد |
| T3.4 | بعد از موفقیت: کش user (L2) → `Get.offAllNamed(Home)`؛ GuestMiddleware روی auth؛ AuthMiddleware روی مسیرهای خصوصی | restart اپ → لاگین می‌ماند |
| T3.5 | Logout: POST logout (best-effort) + پاک‌سازی کش‌ها + `Get.offAllNamed(Auth)` | خروج کامل و بدون کرش |

**Verify فاز 3:** لاگین واقعی با شماره تست (paymentTestMode/smsTestMode بک‌اند یا testCode) → home.

### فاز 4 — Home و Catalog (زمان: ۲ روز)

| ID | شرح | AC |
|---|---|---|
| T4.1 | `SettingsRepository.getBusiness()` کش‌محور (L2، TTL ۱۰ دقیقه) + مدل AppSettings | آفلاین: آخرین settings رندر می‌شود |
| T4.2 | `CatalogRepository` (categories/services) کش‌محور L2+L3 با write-through | بار اول: شبکه؛ بار دوم: فوری از کش + silent refresh |
| T4.3 | `CapacityRepository.current()` با کش ۳۰ ثانیه + Poller ۶۰ ثانیه در Home | نشانگر 🟢🟡🟠🔴 با رنگ/متن فارسی از مدل |
| T4.4 | Home: هدر برند + نشانگر ظرفیت + اسلایدر (`GET /slider`, PageView با autoScroll) + گرید دسته‌ها + «خدمات پرطرفدار» (isFeatured) + کارت «سفارش فعال» (اگر سفارش در submitted/processing هست → لینک tracker) | اسکرول روان؛ آفلاین رندر می‌شود |
| T4.5 | Catalog: صفحه دسته → لیست خدمات (icon, iconColor, basePrice فارسی، estimatedTime) + جستجوی محلی روی کش L3 | فیلتر/جستجو بدون network |
| T4.6 | Service detail: توضیحات + قیمت پایه + فرمول قیمت + دکمه «ثبت سفارش» (role=customer) | کاربر operator/admin مسیر ثبت را نمی‌بیند (پیام مناسب) |
| T4.7 | Icons دسته‌ها: نگاشت `iconName` بک‌اند به آیکون‌های Material (جدول نگاشت + fallback) | همه دسته‌های سی‌شده آیکون دارند |
| T4.8 | Pull-to-refresh + حالت empty + error retry در هر سه صفحه | — |

**Verify فاز 4:** قطع اینترنت → Home/Catalog از کش بالا می‌آید؛ اتصال → رفرش بی‌صدا. `flutter test test/modules/home test/modules/catalog`.

---
### فاز 5 — فرم سفارش داینامیک (زمان: ۲ تا ۳ روز) — قلب اپ

| ID | شرح | AC |
|---|---|---|
| T5.1 | `ServiceField` → فرم‌ساز: رندر داینامیک بر اساس `fields[]` سرویس (text/number/select/textarea/date/checkbox) با اعتبارسنجی required سمت کلاینت + `draft` فرم در L2 (کلید `cn_draft_{serviceId}`) | هر نوع فیلد رندر و ذخیره/بازیابی می‌شود |
| T5.2 | انتخاب urgency (normal/urgent/immediate با ضریب‌ها از settings) و deliveryMethod (download/courier/in_person)؛ برای courier: فیلد آدرس متنی + کد پستی (اختیاری) | اعتبارسنجی مشترک با سرور |
| T5.3 | **پیش‌نمایش قیمت محلی** (mirror ساده PricingService برای UX؛ فقط نمایشی — سرور حقیقت است): basePrice + فرمول‌های ساده + ضریب urgency + هزینه پیک | تفاوت با نهایی سرور فقط با toast «قیمت نهایی توسط سرور محاسبه شد» هندل می‌شود |
| T5.4 | آپلود فایل مشتری: image_picker/file_picker → POST /upload multipart (با پیشرفت) → افزودن به `customerFiles[]` + حذف با DELETE /upload؛ محدودیت نوع/سایز از settings (fileRetentionDays…) | آپلود موفق/ناموفق با retry؛ لیست فایل‌ها قابل حذف |
| T5.5 | کد تخفیف: `POST /coupons/validate` → نمایش مبلغ تخفیف؛ خواندن فعال‌بودن از settings (`enableCoupons`) | کد نامعتبر → پیام فارسی سرور |
| T5.6 | راه‌های ارتباطی (contactMethods: چک‌باکس چندتایی — حداقل یکی) + customerNote | submit بدون انتخاب → خطا |
| T5.7 | `OrderRepository.store()` → 201 Order → مسیر checkout؛ خطاها: 400 (فیلد اجباری با label)، 403 (staff)، INSUFFICIENT_WALLET | هر خطا UX مشخص دارد |
| T5.8 | صفحه Checkout: خلاصه سفارش + دکمه «پرداخت از کیف پول» + نمایش موجودی لحظه‌ای (`/auth/me`) + مسیر کمبود موجودی → دیالوگ شارژ | — |

**Verify فاز 5:** ثبت سفارش واقعی E2E روی بک‌اند dev (test gateway)؛ `flutter test test/modules/order_form`.

### فاز 6 — کیف پول و پرداخت (زمان: ۱.۵ روز)

| ID | شرح | AC |
|---|---|---|
| T6.1 | `WalletRepository`: balance از `/auth/me`، `transactions` (کش L3، pull-to-refresh) | آفلاین: ledger کش رندر می‌شود |
| T6.2 | صفحه Wallet: کارت موجودی (ارقام فارسی) + لیست تراکنش‌ها (typeTitle فارسی، ورود سبز/خروج قرمز، balanceAfter) | — |
| T6.3 | شارژ: presets از settings (`walletTopUpPresets`) + مبلغ دلخواه (validate MIN/MAX) + انتخاب درگاه (online/bazaarpay بر اساس flags) | مبلغ خارج محدوده → خطا قبل از درخواست |
| T6.4 | جریان پرداخت مطابق بخش 4.4: `POST /payments/request` → url_launcher → صفحه «پرداخت در جریان» با Poller روی `/payments/status` (۳ ثانیه، سقف ۱۰ دقیقه) → نتیجه | paid/failed/timeout هر سه مسیر تست شده؛ بعد از paid موجودی و کش رفرش می‌شود |
| T6.5 | چک‌پرداخت بازیابی: هنگام باز شدن اپ اگر `cn_pending_payment` وجود دارد → یک بار status بگیر (self-healing بک‌اند) | بستن اپ وسط پرداخت → بعد از باز شدن نتیجه دیده می‌شود |
| T6.6 | عدم نمایش درگاه غیرفعال (bazaar/bazaarpay flags) + آدرس‌های تماس/توضیح | — |

**Verify فاز 6:** شارژ واقعی با test-gateway بک‌اند (paymentTestMode) E2E؛ `flutter test test/modules/wallet`.

### فاز 7 — سفارش‌ها و پیگیری زنده (زمان: ۲ روز)

| ID | شرح | AC |
|---|---|---|
| T7.1 | `OrderRepository`: list (کش L3 + write-through)، show، update، delete؛ sync پس از هر polling | جستجوی آفلاین روی کش |
| T7.2 | لیست سفارش‌ها با فیلتر وضعیت + StatusChip رنگ‌بندی‌شده + شماره سفارش | — |
| T7.3 | جزئیات سفارش: تایم‌لاین وضعیت (logs)، فرم داینامیک فقط‌خواندنی (formData)، فایل‌ها (دانلود resultFiles با BE-4)، بازکردن/حذف در وضعیت مجاز، ویرایش | — |
| T7.4 | **Tracker زنده:** Poller ۱۵ ثانیه روی `/orders/{id}/updates` → نشانگر «نوبت شما: #N»، زمان انتظار/انجام (جدا!)، ETA شروع/پایان، رزرو اسلات (long type → `GET /capacity/slots` + `POST /reserve`)، دکمه «به من اطلاع بده» (notify-me)، لغو (cancel با تأیید) | تغییر وضعیت توسط operator در dev → UI زیر ۱۵ ثانیه آپدیت می‌شود |
| T7.5 | Local Notifications روی تغییرات: order_started («کار روی سفارش شروع شد»)، order_ready («سفارش آماده است»)، requeued («نوبت شما منتقل شد») + کانال‌های جدا + کلیک → صفحه سفارش | نوتیف در foreground و background درست می‌آید |
| T7.6 | گفتگوی تیکت سفارش: لیست ticketMessages + ارسال (`POST /orders/{id}/ticket`) + polling جزئیات هنگام باز بودن صفحه | — |
| T7.7 | امتیازدهی بعد از delivered: rating + reviewComment | فقط یک‌بار؛ سرور权威 |
| T7.8 | پیگیری عمومی (track token): ورود با لینک/کد → `GET /orders/track/{token}` بدون لاگین (صفحه سبک با همان UI تایم‌لاین) | لینک اشتراکی روی دستگاه دیگر کار می‌کند |

**Verify فاز 7:** E2E کامل روی dev: ثبت → شارژ → پرداخت → شروع توسط operator (پنل PWA) → نوتیف دریافت → تکمیل → امتیاز.

### فاز 8 — Polish و اختیاری‌ها (زمان: متناسب با انتخاب‌های بخش 13)

| ID | شرح | وضعیت |
|---|---|---|
| T8.1 | Onboarding سه‌اسلایدی (اولین اجرا) | توصیه‌شده |
| T8.2 | Profile: ویرایش نام، نمایش نقش/مجوزها (اگر operator بود بج «اپراتور»)، لینک قوانین/حریم خصوصی (url_launcher به صفحات وب) | توصیه‌شده |
| T8.3 | Map AddressPicker (flutter_map + geolocator + geocoding) برای سفارش پیک → متن آدرس | اختیاری — نیاز تصمیم کاربر |
| T8.4 | FCM: firebase_core/messaging + `/fcm/config` + ثبت توکن + نمایش پوش | اختیاری — نیاز پروژه Firebase و فایل‌های google-services.json از کاربر |
| T8.5 | app_links: scheme `caffenet://` + تغییر ریدایرکت verify بک‌اند برای user-agent اپ (BE-7) → حذف صفحه polling | اختیاری |
| T8.6a | پل ناتیو SDK بازارپی: JitPack `com.github.cafebazaar:bazaarpay:5.4.0` در `android/app/build.gradle` + `MainActivity` با `StartBazaarPay()` به‌صورت فیلد کلاس + `MethodChannel('caffenet/bazaar_pay')` + `BazaarPayBridge` در Dart با fallback وب (بخش 4.5.3) | اختیاری — اندروید API 17+؛ AC: پرداخت درون‌اپ با test-gateway paid برمی‌گرداند؛ iOS بدون کرش fallback می‌شود |
| T8.6b | گزینه «پرداخت داخل اپ» در صفحه شارژ (فقط Android و وقتی SDK present): مسیر B بخش 4.5.3 → پس از isSuccessful حتماً `/payments/status` (کامیت سمت سرور) → رفرش موجودی | اختیاری — AC: هر سه نتیجه paid/failed/cancel تست شده |
| T8.6c | Direct Pay در Checkout: دکمه «پرداخت مستقیم بازارپی» وقتی settings فلاگ direct را روشن کرده → هندل سه پاسخ paid/pending/failed + مسیر `contract_pending` (بخش 4.5.4) | اختیاری — AC: با قرارداد فعال، سفارش paid می‌شود؛ بدون قرارداد → contract_pending |
| T8.6d | جریان امضای قرارداد: وب (`contractRedirectUrl`) یا SDK (`StartDirectPayFinalizeContract` با contract_token پارس‌شده از URL؛ BE-9 اختیاری برای فیلد صریح) + Poller ادامه‌دار روی `/payments/status` تا نتیجه | اختیاری — AC: پس از امضا در مرورگر، سفارش زیر ۱۵ ثانیه paid می‌شود |
| T8.6e | نگاشت کدهای خطای v2 به UX (بخش 4.5.4-5): `account.insufficient_balance` → مسیر شارژ، `purchase.timeout` → تکرار، `direct_pay.*` → راهنمای سقف/تمدید + رگرسیون هر سه مسیر A/B/C روی test-gateway | اختیاری — AC: هر کد خطا پیام و اکشن مشخص دارد |
| T8.6f | IAP کافه‌بازار (درگاه legacy `gateway:'bazaar'`): deepLink SKU-محور فقط با presets و کدهای `BAZAAR_FIXED_AMOUNT`/`BAZAAR_SKU_MISSING` — نیازمند پلاگین IAP بازار جداگانه | اختیاری — به‌تعویق؛ تصمیم باز |
| T8.7 | صفحات Operator/Admin در فلاتر (صف، تغییر وضعیت، آپلود نتیجه) | اختیاری — فاز مستقل بزرگ؛ PWA فعلی همچنان پوشش می‌دهد |
| T8.8 | Release prep: applicationId، signing، flavors (dev/prod)، versionCode، آیکون/اسپلش ناتیو، ProGuard، تست روی دستگاه واقعی، checklist استور | الزامی قبل انتشار |

**Verify فاز 8:** `flutter build apk --release` + اجرای دود E2E روی نسخه release.

---

## 6. تسک‌های کمکی بک‌اند (خلاصه)

تمام تسک‌های BE در فاز P2 تعریف شدند (Sanctum، CSRF، فایل توکن‌دار، logout، مستندات) و عمداً **محدود و non-breaking** هستند. تسک‌های احتمالی آینده: BE-7 (deep link redirect)، BE-8 (فعال‌سازی Reverb اگر زیرساخت عوض شد) و BE-9 (افزودن فیلد صریح `contractToken` به پاسخ `contract_pending` Direct Pay بازارپی — فعلاً اپ آن را از query پارامترهای `contractRedirectUrl` پارس می‌کند) — هر سه در بخش تصمیم‌های باز. هیچ refactor ساختاری روی بک‌اند لازم نیست؛ قرارداد فعلی پایدار و تست‌پوشش است.

**مستندسازی بازارپی:** کلیدهای سیاست درگاه (enabled/testMode/direct*) از پنل ادمین بک‌اند خوانده می‌شوند و جریان‌های A/B/C مطابق بخش 4.5 با مستندات رسمی تطبیق داده شده‌اند — هر تغییر آینده در `BazaarPayService` باید همزمان بخش 4.5 همین سند را به‌روز کند.

---
## 7. پروتکل اجرای ایجنتیک (این بخش را هر ایجنت قبل از شروع بخواند)

### 7.1 ساختار هویت تسک

- تسک‌های فرانت: `T{phase}.{n}` (مثال T1.3) — تسک‌های بک‌اند: `BE-{n}`.
- هر تسک **اتمیک** است: در یک نشست ایجنت قابل انجام، با AC قابل تست، و یک commit مستقل.
- وابستگی‌ها به ترتیب فازهاست؛ درون یک فاز، تسک‌ها را به ترتیب شماره انجام بده مگر تسکی مستقل باشد (نشان داده نشده = ترتیبی).

### 7.2 حلقه اجرای هر ایجنت (Agent Loop)

```text
1. این سند (AGENTIC_PLAN.md) + WORKLOG.md را کامل بخوان.
2. اولین تسک done-نشده را بردار و در WORKLOG.md بنویس: «T{x.y} — started».
3. فقط فایل‌های همان تسک را بساز/تغییر بده. فایل خارج از محدوده تسک = خطا.
4. self-verify: دستور Verify همان فاز + flutter analyze (باید صفر issue باشد).
5. اگر AC پاس شد → commit با قالب زیر → در WORKLOG.md: «T{x.y} — done» + نکات.
   اگر پاس نشد → commit نکن؛ اصلاح کن؛ بعد از ۳ تلاش ناموفق، در WORKLOG بنویس «blocked: دلیل».
6. تسک بعدی.
```

قالب commit (Conventional + شماره تسک):
```text
feat(T1.3): add kv/db cache layer with TTL helpers
test(T1.1): cover api error parsing
fix(T7.4): respect server 429 in order updates poller
```

### 7.3 قواعد سخت (Guardrails)

1. هیچ secret (توکن، کلید) در ریپو commit نمی‌شود؛ همه از `--dart-define`/env می‌آیند.
2. نسخه پکیج‌ها را بدون ثبت در WORKLOG تغییر نده؛ پکیج جدید = ابتدا در WORKLOG با دلیل، بعد pubspec.
3. شکل ریسپانس بک‌اند را «انتظاری» ننویس — فقط همان چیزی که بخش 4 مستند است؛ اگر کد واقعی با مستند فرق داشت، مستند را با PR به بک‌اند اصلاح کن نه کلاینت را کثیف.
4. قرارداد API تغییر کرد؟ اول بخش 4 همین سند را آپدیت کن (commit جدا: `docs: …`)، بعد کد.
5. `flutter analyze` تمیز شرط merge است؛ تست‌های شکسته = برگشت به تسک قبلی.
6. متن فارسی را هرگز hard-code داخل ویجت ننویس — از `strings.dart`.
7. روی برنچ `main` کار کن (پروژه تک‌توسعه‌دهنده/ایجنتی)؛ هر فاز تمام شد tag بزن: `phase-N-done`.
8. هر ۱۰ commit یک‌بار `flutter test` کامل اجرا شود.

### 7.4 Definition of Done (هر تسک)

- [ ] کد پیاده شده و فقط در مسیرهای تعیین‌شده
- [ ] `flutter analyze` صفر / (بک‌اند: `php artisan pint --test` صفر)
- [ ] تست واحد مرتبط سبز (هر تسک لایه data/core حداقل یک تست)
- [ ] AC سند به‌صورت دستی/تستی تأیید
- [ ] WORKLOG.md آپدیت؛ commit با ID تسک
- [ ] بدون TODO بی‌تاریخ؛ بدون کد کامنت‌شده مرده

---

## 8. تست و کیفیت

| لایه | ابزار | پوشش هدف |
|---|---|---|
| Unit | `flutter_test` + MockClient برای http | ApiError/ApiClient، فرمترها، Poller backoff، ریپوهای کش‌محور (hit/miss/TTL)، مدل‌ها (fromJson سناریوهای null) |
| Widget | flutter_test | فرم‌ساز داینامیک (هر نوع فیلد)، جریان OTP، لیست سفارش در سه وضعیت RxStatus |
| Integration/دود | تست دستی اسکریپت‌شده روی dev (test-gateway + smsTestMode بک‌اند) | E2E هر فاز طبق Verify همان فاز |
| بک‌اند | `php artisan test` | تست‌های جدید BE-1..BE-6 + رگرسیون کامل قبلی |

**تست‌گانه‌های بحرانی E2E (قبل از هر release تکرار شود):**
1. OTP → لاگین → restart → نشست برقرار
2. شارژ test-gateway → موجودی آپدیت
3. ثبت سفارش (فیلد اجباری + فایل + کد تخفیف) → پرداخت کیف پولی → ردیف صف
4. operator در PWA شروع می‌کند → اپ زیر ۱۵ ثانیه + نوتیف محلی
5. قطع اینترنت وسط هر جریان → بدون کرش، کش رندر، ریکاور

---

## 9. ریسک‌ها و پیش‌گیری

| ریسک | احتمال | پیش‌گیری طراحی‌شده |
|---|---|---|
| Session/CSRF با اپ موبایل ناسازگار بماند | بالاست بدون BE-1..3 | تسک‌های P2 الزامیِ پیش از فاز 3 هستند؛ بدون آن‌ها فاز 3 شروع نمی‌شود |
| Rate-limit polling (12/min) با چند سفارش فعال | متوسط | Poller فقط برای «سفارش فعال» فعال است؛ ۱۵ ثانیه = ۴ req/min در محدوده؛ صفحه‌های غیر فعال polling ندارند |
| قطع callback درگاه در مرورگر (کاربر برنمی‌گردد) | متوسط | T6.5 self-healing: وضعیت pending در شروع اپ چک می‌شود؛ سرور هم idempotent است |
| آپلود فایل روی اینترنت ضعیف ایران | متوسط | progress + retry + سقف سایز از settings؛ فشرده‌سازی تصویر قبل آپلود |
| تغییر شکل fields داینامیک (فیلد جدید بک‌اند) | متوسط | فرم‌ساز، نوع ناشناخته را به‌صورت text می‌رندر می‌کند + لاگ |
| زمان/تقویم جلالی | قطعی (intl جلالی ندارد) | MVP: نمایش میلادی-فارسی؛ تصمیم باز 13-3 (shamsi_date یا فرمت از سرور) |
| حذف/تغییر endpoint توسط PWA-team | کم | این سند = قرارداد؛ تغییر باید در هر دو ریپو مستند شود |
| عدم کامیت بازارپی → بازگشت خودکار پول به کیف پول کاربر | کم | کامیت همیشه سمت سرور بعد از trace انجام می‌شود (توصیه رسمی README SDK)؛ status-poll و T6.5 self-healing کامیت گم‌شده را جبران می‌کند |
| منقضی‌شدن checkout_token یا رسیدن به سقف دوره قرارداد Direct Pay | متوسط | کد `purchase.timeout` → تکرار با توکن تازه (سرور idempotent)؛ `period_amount_limit_violation` → نمایش مانده سقف + مسیر پرداخت جایگزین (شارژ کیف پول) |
| نبود SDK بازارپی برای iOS/فلاتر | قطعی | مسیر پیش‌فرض همه‌جا وب است (T6.4)؛ SDK فقط بهبود UX اندروید (T8.6a/b) با fallback خودکار — هیچ جریانی به SDK وابسته نیست |

---

## 10. جدول زمانی پیشنهادی (MVP)

| فاز | زمان | خروجی قابل نمایش |
|---|---|---|
| P0+P1 | ۲-۳ روز | اپ راست‌چین با هسته شبکه/کش |
| P2 (موازی) | ۰.۵ روز | بک‌اند آماده توکن |
| P3 | ۱ روز | لاگین کامل |
| P4 | ۲ روز | Home/Catalog زنده |
| P5 | ۲-۳ روز | ثبت سفارش داینامیک |
| P6 | ۱.۵ روز | شارژ و پرداخت |
| P7 | ۲ روز | پیگیری زنده + نوتیف |
| P8 (حداقلی: 8.1/8.2/8.8) | ۲ روز | قابل انتشار |
| **جمع MVP** | **~۲-۳ هفته کاری ایجنتی** | اپ مشتری کامل |

---

## 11. تصمیم‌های باز (قبل از فاز 8 از کاربر پرسیده شود)

1. **پوش FCM** — نیاز به ساخت پروژه Firebase و فایل‌های config دارد؛ بدون آن پوش بک‌گراند نیست (فقط polling + نوتیف محلی در اپ باز). پیشنهاد: فاز 8 بعد از MVP.
2. **تاریخ جلالی** — افزودن `shamsi_date` (پیشنهاد) یا فرمت از سرور؟
3. **AddressPicker نقشه‌ای** — فلاتر-مپ برای سفارش پیک؛ در MVP فیلد متنی ساده کافی است.
4. **صفحات Operator/Admin در فلاتر** — PWA فعلی این نقش‌ها را دارد؛ آیا انتقال لازم است؟ (فاز بزرگ جدا)
5. **BazaarPay درون‌اپ / Direct Pay** — طراحی کامل بر اساس مستندات رسمی در بخش 4.5 و تسک‌های T8.6a..f آمده است؛ فقط زمان‌بندی اجرا (بعد از MVP؟) و فعال‌سازی مرچنت (توکن/destination/سقف قرارداد در پنل ادمین) باقی است. IAP کافه‌بازار (T8.6f) همچنان به‌تعویق.
6. **branding رنگی** — پالت دقیق از PWA فعلی استخراج شد؛ اگر بسته هویتی جدید هست، قبل از فاز 0 اعلام شود.

---

## 12. پیوست — اسکلت‌های کد مرجع (ایجنت‌ها موظف‌اند با این سبک کد بزنند)

### A. ApiClient (هسته)

```dart
class ApiClient extends GetxService {
  ApiClient(this._auth);
  final AuthService _auth;
  final http.Client _http = http.Client();
  static const _timeout = Duration(seconds: 25);

  Uri _uri(String path, [Map<String, String>? q]) =>
      Uri.parse('${Env.baseUrl}/api/${path.replaceAll(RegExp(r'^/'), '')}')
        .replace(queryParameters: q);

  Map<String, String> _headers({bool auth = true}) => {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        if (auth && _auth.token != null) 'Authorization': 'Bearer ${_auth.token}',
      };

  Future<dynamic> get(String p, {Map<String, String>? q, bool auth = true}) => _send('GET', p, query: q, auth: auth);
  Future<dynamic> post(String p, {Object? body, bool auth = true}) => _send('POST', p, body: body, auth: auth);
  Future<dynamic> patch(String p, {Object? body, bool auth = true}) => _send('PATCH', p, body: body, auth: auth);
  Future<dynamic> delete(String p, {Object? body, bool auth = true}) => _send('DELETE', p, body: body, auth: auth);

  Future<dynamic> _send(String m, String p, {Map<String, String>? query, Object? body, bool auth = true}) async {
    late http.Response res;
    try {
      final req = http.Request(m, _uri(p, query))..headers.addAll(_headers(auth: auth));
      if (body != null) req.body = jsonEncode(body);
      res = await http.Response.fromStream(await _http.send(req).timeout(_timeout));
    } on TimeoutException {
      throw ApiError.timeout();
    } on SocketException {
      throw ApiError.network(Strings.errNetwork);
    }
    dynamic json;
    try { json = res.body.isEmpty ? null : jsonDecode(utf8.decode(res.bodyBytes)); } catch (_) {}
    if (res.statusCode >= 200 && res.statusCode < 300) return json;
    final msg = (json is Map && json['error'] is String) ? json['error'] : Strings.errUnknown;
    final code = (json is Map && json['code'] is String) ? json['code'] as String : null;
    switch (res.statusCode) {
      case 401:
        await _auth.forceLogout();
        throw ApiError.auth(msg);
      case 400:
        throw ApiError.validation(msg, code: code, payload: json);
      case 403:
        throw ApiError.permission(msg);
      case 429:
        throw ApiError.rateLimited(msg);
      default:
        throw ApiError.server(msg, status: res.statusCode);
    }
  }
}
```

### B. ریپوی کش‌محور (الگوی مرجع)

```dart
class CatalogRepository extends GetxService {
  final ApiClient _api; final KvCache _kv; final DbCache _db;
  CatalogRepository(this._api, this._kv, this._db);
  static const _ttl = Duration(hours: 6);

  Future<List<CategoryModel>> categories({bool fresh = false}) async {
    final cached = fresh ? null : _kv.readJson('cn_categories', maxAge: _ttl);
    if (cached != null) return (cached as List).map(CategoryModel.fromJson).toList();
    final res = await _api.get(ApiEndpoints.categories, auth: false);
    final list = (res as List).map(CategoryModel.fromJson).toList();
    _kv.writeJson('cn_categories', res);
    _db.upsertCatalog(list);
    return list;
  }
}
```

### C. Controller استاندارد ماژول

```dart
class CatalogController extends GetxController {
  CatalogController(this._repo);
  final CatalogRepository _repo;
  final status = RxStatus.empty().obs;
  final services = <ServiceModel>[].obs;
  final query = ''.obs;

  @override
  void onInit() { _load(); super.onInit(); }

  Future<void> _load({bool fresh = false}) async {
    status(RxStatus.loading());
    try {
      services.value = await _repo.services(fresh: fresh);
      status(services.isEmpty ? RxStatus.empty() : RxStatus.success());
    } on ApiError catch (e) {
      if (services.isNotEmpty) { status(RxStatus.success()); Get.snackbar(...e.message...); }
      else status(RxStatus.error(e.message));
    }
  }
  List<ServiceModel> get filtered { /* جستجوی محلی روی services */ }
}
```

### D. Poller (قلب Realtime)

```dart
class Poller {
  Poller({required this.task, this.period = const Duration(seconds: 15),
          this.maxPeriod = const Duration(seconds: 30)});
  final Future<void> Function() task;
  final Duration period, maxPeriod;
  Timer? _t; Duration _backoff = const Duration(seconds: 1);
  bool _paused = false;

  void start() { _schedule(period); }
  void _schedule(Duration d) { _t?.cancel(); _t = Timer(d, _tick); }
  Future<void> _tick() async {
    if (_paused) return;
    try { await task(); _backoff = const Duration(seconds: 1); _schedule(period); }
    on ApiError catch (e) {
      if (e.kind == ApiErrorKind.auth) return;           // forceLogout انجام شد
      if (e.kind == ApiErrorKind.rateLimited) { _schedule(const Duration(seconds: 65)); return; }
      _schedule(_backoff = _backoff * 2 > maxPeriod ? maxPeriod : _backoff * 2);
    }
  }
  void setBackground(bool bg) { _paused = bg; if (!bg) _tick(); } // lifecycle-aware
  void stop() { _t?.cancel(); _t = null; }
}
```

### E. InitialBinding

```dart
class InitialBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(KvCache(), permanent: true);
    Get.put(DbCache(), permanent: true);
    Get.put(AuthService(Get.find()), permanent: true);
    Get.put(ApiClient(Get.find()), permanent: true);
    Get.put(LocalNotificationService(), permanent: true);
    Get.lazyPut(() => AuthRepository(Get.find()), fenix: true);
    Get.lazyPut(() => CatalogRepository(Get.find(), Get.find(), Get.find()), fenix: true);
    Get.lazyPut(() => OrderRepository(Get.find(), Get.find(), Get.find()), fenix: true);
    Get.lazyPut(() => WalletRepository(Get.find(), Get.find(), Get.find()), fenix: true);
    Get.lazyPut(() => CapacityRepository(Get.find(), Get.find()), fenix: true);
    Get.lazyPut(() => SettingsRepository(Get.find(), Get.find()), fenix: true);
  }
}
```

### F. pubspec.yaml (بخش dependencies)

```yaml
dependencies:
  flutter: { sdk: flutter }
  get: ^4.6.6
  http: ^1.2.0
  sqflite: ^2.3.0
  shared_preferences: ^2.5.5        # فقط در صورت نیاز فاز 8
  intl: ^0.20.2
  url_launcher: ^6.3.2
  persian_number_utility: ^1.1.6
  flutter_secure_storage: ^10.3.1
  get_storage: ^2.1.1
  flutter_local_notifications: ^22.1.0
  image_picker: ^1.1.2              # افزوده لازم (فایل سفارش)
  file_picker: ^8.1.6               # افزوده لازم (PDF/سند)
  # فاز 8 (تصمیم باز): flutter_map ^8.3.1, latlong2 ^0.10.1, geolocator ^14.0.2,
  # geocoding ^5.0.0, app_links ^6.4.1, firebase_core, firebase_messaging
  # فعلاً خارج: pusher_reverb_flutter (بک‌اند WebSocket ندارد)
```

### G. Endpoint map کد

```dart
class ApiEndpoints {
  static const health = 'health';
  static const sendOtp = 'auth/send-otp';
  static const verifyOtp = 'auth/verify-otp';
  static const logout = 'auth/logout';
  static const me = 'auth/me';
  static const settings = 'settings';
  static const categories = 'categories';
  static const services = 'services';
  static const capacityCurrent = 'capacity/current';
  static const capacitySlots = 'capacity/slots';
  static const orders = 'orders';
  static String order(String id) => 'orders/$id';
  static String orderUpdates(String id) => 'orders/$id/updates';
  static String orderPayWallet(String id) => 'orders/$id/pay-wallet';
  static String orderReserve(String id) => 'orders/$id/reserve';
  static String orderNotifyMe(String id) => 'orders/$id/notify-me';
  static String orderCancel(String id) => 'orders/$id/cancel';
  static String orderTicket(String id) => 'orders/$id/ticket';
  static String track(String token) => 'orders/track/$token';
  static const paymentRequest = 'payments/request';
  static const paymentStatus = 'payments/status';
  static const bazaarPayContractCallback = 'payments/bazaarpay/contract'; // callback مرورگر قرارداد (اپ صدا نمی‌زند)
  static String payBazaarPay(String orderId) => 'orders/$orderId/pay-bazaarpay';
  static const walletTransactions = 'wallet/transactions';
  static const coupons = 'coupons';
  static const couponValidate = 'coupons/validate';
  static const upload = 'upload';
  static const slider = 'slider';
}
```

---

*پایان پلن — نسخه 1.1 — (1.0: 2026-10-18 بر اساس audit کد caffenet-laravel؛ 1.1: 2026-10-18 افزودن بخش 4.5 «پرداخت درون‌برنامه‌ای بازارپی» بر اساس مستندات رسمی payment.md / direct-pay.md و Android SDK + تفکیک تسک‌های T8.6a..f + ریسک‌ها و نگاشت خطاهای v2). هر تغییر قرارداد = آپدیت همین سند.*
