# CaffeNet — Flutter (Customer App)

اپلیکیشن موبایل مشتری «کافی‌نت احسان» — Flutter + GetX، متصل به Laravel API (`ehsanerfani98/caffenet-laravel`).

## معماری

Pragmatic / MVP-Ready — ماژولار، DI ساده GetX، کش‌محور (stale-while-revalidate با سه لایه حافظه/GetStorage/sqflite).

## شروع کار (برای ایجنت‌ها و توسعه‌دهنده)

1. **اول این را بخوان:** [`AGENTIC_PLAN.md`](./AGENTIC_PLAN.md) — پلن کامل بازنویسی، قرارداد API، فازها، تسک‌ها و پروتکل اجرای ایجنتیک.
2. کارها روی `main` با commitهای قراردادی انجام می‌شود؛ هر تسک با شناسه خودش (مثلاً `feat(T1.3): ...`).
3. `WORKLOG.md` پس از شروع فاز 0 ساخته و به‌روزرسانی می‌شود.

## اجرا

```bash
flutter pub get
flutter run --dart-define=CAFFENET_API_BASE_URL=https://<your-backend-host>
```

## وضعیت

- [ ] فاز 0 — Bootstrap
- [ ] فاز 1 — هسته زیرساخت
- [ ] فاز P2 — هم‌راستاسازی بک‌اند (Sanctum Token)
- [ ] فاز 3 — Auth (OTP)
- [ ] فاز 4 — Home / Catalog
- [ ] فاز 5 — فرم سفارش داینامیک
- [ ] فاز 6 — کیف پول و پرداخت
- [ ] فاز 7 — سفارش‌ها و پیگیری زنده
- [ ] فاز 8 — Polish / Release
