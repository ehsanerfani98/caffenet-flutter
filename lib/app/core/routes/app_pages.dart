import 'package:get/get.dart';

import '../../modules/auth/bindings/auth_binding.dart';
import '../../modules/auth/views/auth_view.dart';
import '../../modules/catalog/bindings/catalog_binding.dart';
import '../../modules/catalog/views/catalog_views.dart';
import '../../modules/checkout/bindings/checkout_binding.dart';
import '../../modules/checkout/views/checkout_view.dart';
import '../../modules/home/bindings/home_binding.dart';
import '../../modules/home/views/home_view.dart';
import '../../modules/onboarding/bindings/onboarding_binding.dart';
import '../../modules/onboarding/views/onboarding_view.dart';
import '../../modules/orders/bindings/orders_binding.dart';
import '../../modules/orders/views/order_detail_view.dart';
import '../../modules/orders/views/orders_view.dart';
import '../../modules/order_form/bindings/order_form_binding.dart';
import '../../modules/order_form/views/order_form_view.dart';
import '../../modules/payment_pending/bindings/payment_pending_binding.dart';
import '../../modules/payment_pending/views/payment_pending_view.dart';
import '../../modules/profile/bindings/profile_binding.dart';
import '../../modules/profile/views/profile_view.dart';
import '../../modules/settings/bindings/settings_binding.dart';
import '../../modules/settings/views/settings_view.dart';
import '../../modules/splash/bindings/splash_binding.dart';
import '../../modules/splash/views/splash_view.dart';
import '../../modules/tracker/bindings/tracker_binding.dart';
import '../../modules/tracker/views/track_public_view.dart';
import '../../modules/tracker/views/tracker_view.dart';
import '../../modules/wallet/bindings/wallet_binding.dart';
import '../../modules/wallet/views/wallet_view.dart';
import 'app_routes.dart';
import 'middlewares.dart';

/// جدول صفحات — GetPage همه با transition و binding ماژول.
class AppPages {
  AppPages._();

  static const Duration _t = Duration(milliseconds: 260);

  static final List<GetPage> pages = [
    GetPage(
      name: Routes.splash,
      page: () => const SplashView(),
      binding: SplashBinding(),
      transition: Transition.fadeIn,
      transitionDuration: _t,
    ),
    GetPage(
      name: Routes.onboarding,
      page: () => const OnboardingView(),
      binding: OnboardingBinding(),
      transition: Transition.fadeIn,
      transitionDuration: _t,
    ),
    GetPage(
      name: Routes.auth,
      page: () => const AuthView(),
      binding: AuthBinding(),
      middlewares: const [GuestMiddleware()],
      transition: Transition.fadeIn,
      transitionDuration: _t,
    ),
    GetPage(
      name: Routes.home,
      page: () => const HomeView(),
      binding: HomeBinding(),
      middlewares: const [AuthMiddleware()],
      transition: Transition.fadeIn,
      transitionDuration: _t,
    ),
    GetPage(
      name: Routes.catalog,
      page: () => const CatalogView(),
      binding: CatalogBinding(),
      middlewares: const [AuthMiddleware()],
      transition: Transition.rightToLeft,
      transitionDuration: _t,
    ),
    GetPage(
      name: Routes.catalogCategory,
      page: () => const CatalogCategoryView(),
      binding: CatalogBinding(),
      middlewares: const [AuthMiddleware()],
      transition: Transition.rightToLeft,
      transitionDuration: _t,
    ),
    GetPage(
      name: Routes.serviceDetail,
      page: () => const ServiceDetailView(),
      binding: CatalogBinding(),
      middlewares: const [AuthMiddleware()],
      transition: Transition.rightToLeft,
      transitionDuration: _t,
    ),
    GetPage(
      name: Routes.orderForm,
      page: () => const OrderFormView(),
      binding: OrderFormBinding(),
      middlewares: const [AuthMiddleware()],
      transition: Transition.rightToLeft,
      transitionDuration: _t,
    ),
    GetPage(
      name: Routes.checkout,
      page: () => const CheckoutView(),
      binding: CheckoutBinding(),
      middlewares: const [AuthMiddleware()],
      transition: Transition.rightToLeft,
      transitionDuration: _t,
    ),
    GetPage(
      name: Routes.paymentPending,
      page: () => const PaymentPendingView(),
      binding: PaymentPendingBinding(),
      middlewares: const [AuthMiddleware()],
      transition: Transition.fadeIn,
      transitionDuration: _t,
    ),
    GetPage(
      name: Routes.orders,
      page: () => const OrdersView(),
      binding: OrdersBinding(),
      middlewares: const [AuthMiddleware()],
      transition: Transition.fadeIn,
      transitionDuration: _t,
    ),
    GetPage(
      name: Routes.orderDetail,
      page: () => const OrderDetailView(),
      binding: OrdersBinding(),
      middlewares: const [AuthMiddleware()],
      transition: Transition.rightToLeft,
      transitionDuration: _t,
    ),
    GetPage(
      name: Routes.tracker,
      page: () => const TrackerView(),
      binding: TrackerBinding(),
      middlewares: const [AuthMiddleware()],
      transition: Transition.rightToLeft,
      transitionDuration: _t,
    ),
    GetPage(
      name: Routes.trackPublic,
      page: () => const TrackPublicView(),
      binding: TrackerBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: _t,
    ),
    GetPage(
      name: Routes.wallet,
      page: () => const WalletView(),
      binding: WalletBinding(),
      middlewares: const [AuthMiddleware()],
      transition: Transition.fadeIn,
      transitionDuration: _t,
    ),
    GetPage(
      name: Routes.profile,
      page: () => const ProfileView(),
      binding: ProfileBinding(),
      middlewares: const [AuthMiddleware()],
      transition: Transition.fadeIn,
      transitionDuration: _t,
    ),
    GetPage(
      name: Routes.settings,
      page: () => const SettingsView(),
      binding: SettingsBinding(),
      middlewares: const [AuthMiddleware()],
      transition: Transition.rightToLeft,
      transitionDuration: _t,
    ),
  ];
}
