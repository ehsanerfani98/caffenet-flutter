/// تمام متن‌های UI اپ — تک‌منبع (قاعده ۶ پروتکل: متن فارسی hard-code ممنوع).
class Strings {
  Strings._();

  // ── عمومی ──
  static const String appName = 'کافی‌نت احسان';
  static const String retry = 'تلاش مجدد';
  static const String confirm = 'تایید';
  static const String cancel = 'انصراف';
  static const String delete = 'حذف';
  static const String edit = 'ویرایش';
  static const String save = 'ذخیره';
  static const String send = 'ارسال';
  static const String back = 'بازگشت';
  static const String next = 'بعدی';
  static const String skip = 'رد کردن';
  static const String continueLabel = 'ادامه';
  static const String loading = 'در حال بارگذاری…';
  static const String seeAll = 'مشاهده همه';
  static const String search = 'جستجو…';
  static const String toman = 'تومان';
  static const String minutes = 'دقیقه';
  static const String unknownError = 'خطای ناشناخته رخ داد.';
  static const String errNetwork = 'اتصال برقرار نیست؛ اتصال اینترنت را بررسی کنید.';
  static const String errTimeout = 'پاسخی از سرور دریافت نشد؛ دوباره تلاش کنید.';
  static const String offlineBanner = 'اتصال برقرار نیست — داده‌ها از آخرین نسخه ذخیره‌شده نمایش داده می‌شود.';

  // ── Bottom nav ──
  static const String navHome = 'خانه';
  static const String navOrders = 'سفارش‌ها';
  static const String navWallet = 'کیف پول';
  static const String navProfile = 'پروفایل';

  // ── Splash / Onboarding ──
  static const String splashTagline = 'خدمات دانشجویی، چاپ و امور اداری — سریع و مطمئن';
  static const String onb1Title = 'ثبت سفارش در چند ثانیه';
  static const String onb1Body = 'خدمت موردنظر را انتخاب کنید، فرم را پر کنید و سفارش شما در صف انجام قرار می‌گیرد.';
  static const String onb2Title = 'پرداخت امن با کیف پول';
  static const String onb2Body = 'کیف پول خود را با درگاه بانکی شارژ کنید و سفارش‌ها را بدون معطلی پرداخت کنید.';
  static const String onb3Title = 'پیگیری زنده صف';
  static const String onb3Body = 'نوبت شما، زمان تخمینی شروع و اتمام کار را لحظه‌ای ببینید و باخبر شوید.';

  // ── Auth ──
  static const String loginTitle = 'ورود | ثبت‌نام';
  static const String loginSubtitle = 'شماره موبایل خود را وارد کنید تا کد تایید برایتان ارسال شود.';
  static const String phoneLabel = 'شماره موبایل';
  static const String phoneHint = '۰۹۱۲۳۴۵۶۷۸۹';
  static const String sendOtp = 'دریافت کد تایید';
  static const String otpTitle = 'کد تایید';
  static const String otpSentTo = 'کد ۵ رقمی به شماره';
  static const String otpSentToSuffix = 'ارسال شد';
  static const String otpHint = '- - - - -';
  static const String otpVerify = 'تایید و ورود';
  static const String otpResend = 'ارسال مجدد کد';
  static const String otpResendIn = 'ارسال مجدد تا';
  static const String otpChangePhone = 'تغییر شماره';
  static const String otpWrongCode = 'کد وارد شده صحیح نیست.';
  static const String testCodeChip = 'کد آزمایشی:';

  // ── Home ──
  static const String homeGreeting = 'سلام';
  static const String homeGuest = 'مهمان';
  static const String homeCategories = 'دسته‌بندی خدمات';
  static const String homeFeatured = 'خدمات پرطرفدار';
  static const String homeActiveOrder = 'سفارش فعال شما';
  static const String homeTrackOrder = 'پیگیری سفارش';
  static const String homeNewOrder = 'ثبت سفارش جدید';
  static const String capacityTitle = 'ظرفیت فعلی';
  static const String capacityEta = 'زمان تخمینی شروع';
  static const String noCategories = 'فعلاً دسته‌بندی‌ای ثبت نشده است.';
  static const String noFeatured = 'فعلاً خدمت ویژه‌ای ثبت نشده است.';

  // ── Catalog ──
  static const String services = 'خدمات';
  static const String noServices = 'خدمتی در این دسته ثبت نشده است.';
  static const String noServicesFound = 'خدمتی با این عبارت پیدا نشد.';
  static const String basePrice = 'قیمت پایه';
  static const String estimatedTime = 'زمان تقریبی';
  static const String pricingFormula = 'فرمول قیمت‌گذاری';
  static const String orderThisService = 'ثبت سفارش این خدمت';
  static const String staffOrderNotAllowed = 'ثبت سفارش تنها با حساب مشتری امکان‌پذیر است.';

  // ── Order form ──
  static const String orderFormTitle = 'ثبت سفارش';
  static const String formSectionDetails = 'مشخصات سفارش';
  static const String formSectionUrgency = 'فوریت انجام';
  static const String formSectionDelivery = 'روش تحویل';
  static const String formSectionFiles = 'فایل‌های پیوست';
  static const String formSectionContact = 'راه‌های ارتباطی';
  static const String formSectionNote = 'توضیحات شما';
  static const String formSectionCoupon = 'کد تخفیف';
  static const String couponPlaceholder = 'کد تخفیف (اختیاری)';
  static const String couponApply = 'بررسی کد';
  static const String couponApplied = 'کد تخفیف اعمال شد';
  static const String urgencyNormal = 'معمولی';
  static const String urgencyUrgent = 'فوری';
  static const String urgencyImmediate = 'آنی';
  static const String deliveryDownload = 'دریافت فایل';
  static const String deliveryCourier = 'ارسال با پیک';
  static const String deliveryInPerson = 'تحویل حضوری';
  static const String deliveryAddressLabel = 'آدرس تحویل';
  static const String deliveryAddressRequired = 'برای ارسال با پیک، وارد کردن آدرس الزامی است.';
  static const String deliveryPostalCode = 'کد پستی (اختیاری)';
  static const String addFile = 'افزودن فایل / عکس';
  static const String pickImage = 'انتخاب عکس';
  static const String pickDocument = 'انتخاب سند / PDF';
  static const String uploadFailed = 'آپلود فایل ناموفق بود.';
  static const String fileTooLarge = 'حجم فایل بیشتر از ۳۰ مگابایت است.';
  static const String contactPhoneCall = 'تماس تلفنی';
  static const String contactSms = 'پیامک';
  static const String contactTelegram = 'تلگرام';
  static const String contactWhatsapp = 'واتس‌اپ';
  static const String contactMethodsHint = 'حداقل یک راه ارتباطی انتخاب کنید.';
  static const String noteHint = 'اگر توضیحی درباره سفارش دارید بنویسید…';
  static const String pricePreviewTitle = 'برآورد هزینه';
  static const String priceServerNote = 'مبلغ نهایی پس از ثبت، توسط سرور محاسبه می‌شود.';
  static const String submitOrder = 'ادامه و پرداخت';
  static const String submitOrderConfirmTitle = 'ثبت سفارش';
  static const String submitOrderConfirmBody = 'با ثبت این سفارش، مبلغ از کیف پول شما کسر می‌شود. ادامه می‌دهید؟';
  static const String draftRestored = 'پیش‌نویس قبلی فرم بازیابی شد.';
  static const String requiredField = 'تکمیل این فیلد الزامی است.';
  static const String uploadProgress = 'در حال آپلود…';

  // ── Checkout ──
  static const String checkoutTitle = 'پرداخت سفارش';
  static const String checkoutSummary = 'خلاصه سفارش';
  static const String checkoutWalletPay = 'پرداخت از کیف پول';
  static const String checkoutBalance = 'موجودی کیف پول';
  static const String insufficientBalanceTitle = 'موجودی کافی نیست';
  static const String insufficientBalanceBody = 'برای پرداخت این سفارش، کیف پول خود را شارژ کنید.';
  static const String shortage = 'کسری موجودی';
  static const String topUpNow = 'شارژ کیف پول';
  static const String orderPaidSuccess = 'پرداخت انجام شد؛ سفارش شما در صف قرار گرفت.';
  static const String discount = 'تخفیف';
  static const String payable = 'قابل پرداخت';

  // ── Wallet ──
  static const String walletTitle = 'کیف پول';
  static const String walletBalance = 'موجودی';
  static const String walletTopUp = 'شارژ کیف پول';
  static const String walletTransactions = 'تراکنش‌ها';
  static const String walletNoTransactions = 'هنوز تراکنشی ثبت نشده است.';
  static const String topUpAmount = 'مبلغ شارژ';
  static const String topUpCustom = 'مبلغ دلخواه';
  static const String topUpInvalidAmount = 'مبلغ شارژ باید بین ۱۰٬۰۰۰ تا ۵۰٬۰۰۰٬۰۰۰ تومان باشد.';
  static const String topUpGateway = 'درگاه پرداخت';
  static const String gatewayOnline = 'درگاه بانکی';
  static const String gatewayBazaarPay = 'بازارپی';
  static const String gatewayBazaarIap = 'پرداخت درون‌برنامه‌ای کافه‌بازار';
  static const String topUpPay = 'پرداخت و شارژ';
  static const String paymentPendingTitle = 'پرداخت در جریان است';
  static const String paymentPendingBody = 'پس از تکمیل پرداخت در مرورگر، به این صفحه برگردید. نتیجه به‌صورت خودکار بررسی می‌شود.';
  static const String paymentCheckNow = 'بررسی نتیجه';
  static const String paymentReturnToApp = 'به برنامه برگشتم — بررسی کن';
  static const String paymentSuccess = 'پرداخت با موفقیت انجام شد.';
  static const String paymentFailed = 'پرداخت ناموفق بود یا لغو شد.';
  static const String paymentTimeout = 'پاسخی از درگاه دریافت نشد؛ بعداً از بخش تراکنش‌ها پیگیری کنید.';
  static const String txCredit = 'واریز به کیف پول';
  static const String txDebit = 'برداشت از کیف پول';

  // ── Orders ──
  static const String ordersTitle = 'سفارش‌های من';
  static const String noOrders = 'هنوز سفارشی ثبت نکرده‌اید.';
  static const String ordersAll = 'همه';
  static const String orderNumber = 'شماره سفارش';
  static const String orderService = 'خدمت';
  static const String orderStatus = 'وضعیت';
  static const String orderDate = 'تاریخ ثبت';
  static const String orderTotal = 'مبلغ کل';
  static const String orderTimeline = 'رویدادهای سفارش';
  static const String orderFormData = 'مشخصات ثبت‌شده';
  static const String orderFiles = 'فایل‌ها';
  static const String orderCustomerFiles = 'فایل‌های شما';
  static const String orderResultFiles = 'فایل‌های نتیجه';
  static const String orderDownloadFile = 'دانلود';
  static const String orderTicketTitle = 'گفتگوی سفارش';
  static const String orderTicketHint = 'پیام خود را بنویسید…';
  static const String orderTicketSend = 'ارسال پیام';
  static const String orderNoTicket = 'گفتگویی برای این سفارش وجود ندارد.';
  static const String orderRateTitle = 'به این سفارش امتیاز بدهید';
  static const String orderRateHint = 'نظر خود را بنویسید (اختیاری)';
  static const String orderRateSubmit = 'ثبت امتیاز';
  static const String orderRated = 'امتیاز شما ثبت شد؛ سپاسگزاریم.';
  static const String orderCancelTitle = 'لغو سفارش';
  static const String orderCancelBody = 'سفارش از صف خارج می‌شود و در صورت پرداخت، مبلغ به کیف پول بازمی‌گردد. مطمئنید؟';
  static const String orderCancelSuccess = 'سفارش لغو شد.';
  static const String orderDeleted = 'سفارش حذف شد.';
  static const String trackTokenLink = 'لینک پیگیری اشتراکی';

  // ── Tracker ──
  static const String trackerTitle = 'پیگیری زنده';
  static const String trackerQueuePosition = 'نوبت شما';
  static const String trackerQueuePositionValue = 'نوبت #';
  static const String trackerWait = 'زمان انتظار تخمینی';
  static const String trackerDuration = 'مدت انجام تخمینی';
  static const String trackerStartAt = 'شروع تخمینی';
  static const String trackerEndAt = 'پایان تخمینی';
  static const String trackerInQueue = 'سفارش شما در صف انجام است.';
  static const String trackerProcessing = 'کار روی سفارش شما در جریان است.';
  static const String trackerReady = 'سفارش شما آماده است.';
  static const String trackerLive = 'زنده';
  static const String trackerNotifyMe = 'به من اطلاع بده';
  static const String trackerNotifyMeDone = 'هنگام شروع کار به شما اطلاع می‌دهیم.';
  static const String trackerReserveSlot = 'رزرو نوبت ۳۰ دقیقه‌ای';
  static const String trackerPickSlot = 'انتخاب نوبت';
  static const String trackerSlotReserved = 'نوبت رزرو شد.';
  static const String trackerNoSlots = 'فعلاً نوبتی برای رزرو وجود ندارد.';
  static const String trackerOperator = 'اپراتور';
  static const String trackerNoResponse = 'مهلت پاسخ‌دهی';
  static const String trackPublicTitle = 'پیگیری سفارش';
  static const String trackPublicHint = 'کد یا لینک پیگیری را وارد کنید';
  static const String trackPublicTrack = 'پیگیری';
  static const String trackNotFound = 'سفارشی با این کد پیدا نشد.';

  // ── Notifications (local) ──
  static const String notifChannelOrders = 'orders';
  static const String notifChannelOrdersName = 'وضعیت سفارش‌ها';
  static const String notifChannelWallet = 'wallet';
  static const String notifChannelWalletName = 'کیف پول و پرداخت';
  static const String notifOrderStarted = 'کار روی سفارش شروع شد';
  static const String notifOrderReady = 'سفارش آماده است';
  static const String notifRequeued = 'نوبت شما منتقل شد';
  static const String notifCancelled = 'سفارش لغو شد';
  static const String notifWalletCredited = 'کیف پول شارژ شد';

  // ── Profile / Settings ──
  static const String profileTitle = 'پروفایل';
  static const String profileName = 'نام و نام خانوادگی';
  static const String profilePhone = 'شماره موبایل';
  static const String profileRole = 'نقش';
  static const String roleCustomer = 'مشتری';
  static const String roleOperator = 'اپراتور';
  static const String roleAdmin = 'مدیر';
  static const String profileLogout = 'خروج از حساب';
  static const String logoutConfirmTitle = 'خروج از حساب';
  static const String logoutConfirmBody = 'مطمئنید که می‌خواهید خارج شوید؟';
  static const String logoutDone = 'از حساب خارج شدید.';
  static const String settingsTitle = 'تنظیمات';
  static const String settingsTheme = 'حالت نمایش';
  static const String themeSystem = 'سیستم';
  static const String themeLight = 'روشن';
  static const String themeDark = 'تیره';
  static const String settingsLinks = 'لینک‌های مفید';
  static const String settingsTerms = 'قوانین و مقررات';
  static const String settingsPrivacy = 'حریم خصوصی';
  static const String settingsAbout = 'درباره برنامه';
  static const String settingsAboutBody =
      'کافی‌نت احسان — پرینت و چاپ، خدمات دانشجویی و ثبت‌نام، خدمات دولتی و اداری و امور مالیاتی. ثبت سفارش آنلاین با پیگیری زنده صف انجام.';
  static const String settingsContact = 'تماس با ما';
  static const String profileUpdated = 'پروفایل به‌روزرسانی شد.';

  // ── Dialogs / snackbar ──
  static const String ok = 'باشه';
  static const String yes = 'بله';
  static const String no = 'خیر';
}
