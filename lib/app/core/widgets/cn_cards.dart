import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../config/env.dart';
import '../routes/app_routes.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart' show Formatters;
import '../utils/icon_mapper.dart' show IconMapper;
import '../values/strings.dart';
import '../../data/models/category_model.dart';
import '../../data/models/misc_models.dart';
import '../../data/models/order_model.dart';
import '../../data/models/service_model.dart';
import 'common_widgets.dart';

/// ─────────────────────────────────────────────────────────────
/// کروم و کارت‌های ساختاری — پورت وفادار CSS پله:
/// .app-bar / .home-search / .cat-icon-tile / .svc-card / .order-card /
/// .hero-slider / .slider-dots
/// ─────────────────────────────────────────────────────────────

/// رنگ متن روی tone block آیکون.
Color _toneFg(Color tone) => switch (tone) {
      CnColors.emerald => const Color(0xFF065F46),
      CnColors.amber => const Color(0xFF92400E),
      CnColors.indigo => CnColors.indigo,
      CnColors.rose => const Color(0xFF9F1239),
      CnColors.slate => CnColors.slate,
      _ => CnColors.skyDeep,
    };

Color _toneBg(Color tone, bool isDark) => isDark ? tone.withOpacity(.18) : switch (tone) {
      CnColors.emerald => CnColors.emeraldSoft,
      CnColors.amber => CnColors.amberSoft,
      CnColors.indigo => CnColors.indigoSoft,
      CnColors.rose => CnColors.roseSoft,
      CnColors.slate => CnColors.slateSoft,
      _ => CnColors.skySoft,
    };

/// AppBar برند — پورت دقیق .app-bar: گرادیان 135deg sky→sky-deep،
/// لوگوی سفید 30×30 (radius 9)، t1 16/700 + t2 11.5، اکشن‌های شیشه‌ای.
class CnBrandBar extends StatelessWidget implements PreferredSizeWidget {
  const CnBrandBar({
    super.key,
    required this.title,
    this.subtitle,
    this.actions,
  });

  final String title;
  final String? subtitle;
  final List<Widget>? actions;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 10);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      foregroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleSpacing: 12,
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [CnColors.sky, CnColors.skyDeep],
          ),
        ),
      ),
      title: Row(
        children: [
          // .brand-logo → 30×30 سفید radius 9
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(9),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(.25),
                  blurRadius: 3,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: const Icon(Icons.local_cafe_rounded, size: 20, color: CnColors.sky),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontFamily: 'Peyda', fontSize: 16,
                        fontWeight: FontWeight.w700, color: Colors.white)),
                if (subtitle != null && subtitle!.isNotEmpty)
                  Text(subtitle!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontFamily: 'Peyda', fontSize: 11.5,
                          color: Colors.white.withOpacity(.85))),
              ],
            ),
          ),
        ],
      ),
      actions: actions,
    );
  }
}

/// اکشن‌های استاندارد AppBar مشتری — پورت renderAppBar() وب:
/// چپ کیف پول (موجودی) + دکمه پروفایل شیشه‌ای؛ مهمان: چپ «ورود».
List<Widget> cnCustomerBarActions() {
  final auth = Get.find<AuthService>();
  return [
    Obx(() {
      final u = auth.user.value;
      if (u == null) {
        return CnWalletChip(
          balanceText: 'ورود',
          onTap: () => Get.toNamed(Routes.auth),
        );
      }
      return CnWalletChip(
        balanceText: Formatters.tomanWithUnit(u.walletBalance),
        onTap: () => Get.offAllNamed(Routes.wallet, predicate: (r) => false),
      );
    }),
    Obx(() => CnBarIconButton(
          icon: Icons.person_rounded,
          onTap: () {
            if (auth.user.value == null) {
              Get.toNamed(Routes.auth);
            } else {
              Get.offAllNamed(Routes.profile, predicate: (r) => false);
            }
          },
        )),
  ];
}

/// دکمه آیکونی شیشه‌ای AppBar — معادل .app-bar .icon-btn (38×38، سفید 14%).
class CnBarIconButton extends StatelessWidget {
  const CnBarIconButton({super.key, required this.icon, this.onTap, this.badge});

  final IconData icon;
  final VoidCallback? onTap;
  final int? badge;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(end: 8),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Material(
            color: Colors.white.withOpacity(.14),
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: onTap,
              child: SizedBox(
                width: 38,
                height: 38,
                child: Icon(icon, size: 19, color: Colors.white),
              ),
            ),
          ),
          Positioned(
            top: -4,
            end: -4,
            child: badge == null || badge == 0
                ? const SizedBox.shrink()
                : Container(
                    constraints: const BoxConstraints(minWidth: 17),
                    height: 17,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: CnColors.rose,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Center(
                      child: Text(Formatters.num(badge!),
                          style: const TextStyle(
                              fontFamily: 'Peyda', fontSize: 10,
                              fontWeight: FontWeight.w700, color: Colors.white)),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

/// چپ کیف پول AppBar — معادل .chip-wallet (سفید 16%، radius 20، 12px/600).
class CnWalletChip extends StatelessWidget {
  const CnWalletChip({super.key, required this.balanceText, this.onTap});

  final String balanceText;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(end: 8),
      child: Material(
        color: Colors.white.withOpacity(.16),
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.account_balance_wallet_rounded,
                    size: 15, color: Colors.white),
                const SizedBox(width: 5),
                Text(balanceText,
                    style: const TextStyle(
                        fontFamily: 'Peyda', fontSize: 12,
                        fontWeight: FontWeight.w600, color: Colors.white)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// نوار جستجوی صفحه اصلی — پورت دقیق .home-search:
/// radius 20، سایه آبی، آیکون‌باکس 40 گرادیان sky→#3B82F6، شمارنده خدمت.
class HomeSearchBar extends StatelessWidget {
  const HomeSearchBar({super.key, required this.label, this.count, this.onTap});

  final String label;
  final int? count;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: isDark ? const Color(0xFF141E33) : CnColors.card,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark ? const Color(0xFF24324E) : CnColors.line,
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: CnColors.sky.withOpacity(.30),
                blurRadius: 30,
                offset: const Offset(0, 14),
                spreadRadius: -14,
              ),
              BoxShadow(
                color: CnColors.dark.withOpacity(.04),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // .hs-icon → 40×40 گرادیان
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [CnColors.sky, Color(0xFF3B82F6)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: CnColors.sky.withOpacity(.65),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                      spreadRadius: -8,
                    ),
                  ],
                ),
                child: const Icon(Icons.search_rounded, size: 19, color: Colors.white),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Text(label,
                    style: TextStyle(
                        fontFamily: 'Peyda', fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(.6))),
              ),
              if (count != null && count! > 0)
                // .hs-count → sky-soft pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: CnColors.skySoft,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${Formatters.num(count!)}${Strings.servicesUnitSuffix}',
                    style: const TextStyle(
                        fontFamily: 'Peyda', fontSize: 10.5,
                        fontWeight: FontWeight.w700, color: CnColors.skyDeep),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// کاشی آیکونی — پورت دقیق .cat-icon-tile/.cat-icon-box:
/// کادر سفید radius 18 (20 در عرض ≥400)، آیکون 58%، برچسب 10.5/600.
class CatIconTile extends StatelessWidget {
  const CatIconTile({
    super.key,
    required this.title,
    required this.onTap,
    this.icon,
    this.iconColor,
    this.width,
  });

  final String title;
  final VoidCallback onTap;
  final IconData? icon;
  final Color? iconColor;
  final double? width;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = iconColor ?? CnColors.skyDeep;
    final tile = Column(
      children: [
        AspectRatio(
          aspectRatio: 1,
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF141E33) : CnColors.card,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isDark ? const Color(0xFF24324E) : CnColors.line,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF182230).withOpacity(.07),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            padding: const EdgeInsets.all(18),
            child: Icon(icon ?? Icons.widgets_outlined, size: 30, color: color),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 30,
          child: Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Peyda',
              fontSize: 10.5,
              height: 1.55,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
      ],
    );

    if (width != null) {
      return SizedBox(
        width: width,
        child: Material(
          color: Colors.transparent,
          child: InkWell(onTap: onTap, child: tile),
        ),
      );
    }
    return Material(
      color: Colors.transparent,
      child: InkWell(onTap: onTap, child: tile),
    );
  }
}

/// کارت خدمت — پورت دقیق .svc-card (گرید ۲ ستونه):
/// آیکون‌باکس 42×42 sky-soft، عنوان 13/700، توضیح 11 دوسطری،
/// ردیف پایین: زمان تقریبی + قیمت sky-deep.
class ServiceCard extends StatelessWidget {
  const ServiceCard({super.key, required this.service, required this.onTap});

  final ServiceModel service;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconColor = service.iconColor.isNotEmpty ? IconMapper.color(service.iconColor) : null;
    return Material(
      color: isDark ? const Color(0xFF141E33) : CnColors.card,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? const Color(0xFF24324E) : CnColors.line,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: isDark ? (iconColor ?? CnColors.sky).withOpacity(.18) : CnColors.skySoft,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(IconMapper.safe(service.icon),
                    size: 21, color: isDark ? (iconColor ?? CnColors.skySoft) : (iconColor ?? CnColors.skyDeep)),
              ),
              const SizedBox(height: 8),
              Text(service.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontFamily: 'Peyda', fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.onSurface)),
              const SizedBox(height: 4),
              SizedBox(
                height: 32,
                child: Text(service.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontFamily: 'Peyda', fontSize: 11, height: 1.4,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(.6))),
              ),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(service.estimatedTime,
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontFamily: 'Peyda', fontSize: 11,
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(.6))),
                  ),
                  Text(
                    service.basePrice > 0
                        ? Formatters.toman(service.basePrice)
                        : 'محاسبه در سفارش',
                    style: const TextStyle(
                        fontFamily: 'Peyda', fontSize: 11,
                        fontWeight: FontWeight.w700, color: CnColors.skyDeep),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// کارت سفارش — پورت دقیق .order-card:
/// سر: شماره فارسی 12.5/700 + pill وضعیت؛ عنوان خدمت 12.5 ink-soft؛
/// پا: قیمت 12/700 sky-deep + تاریخ/پیگیری.
class OrderCard extends StatelessWidget {
  const OrderCard({
    super.key,
    required this.orderNumber,
    required this.status,
    required this.serviceTitle,
    required this.priceText,
    this.trailing,
    this.trailingColor,
    this.onTap,
  });

  final String orderNumber;
  final String status;
  final String serviceTitle;
  final String priceText;
  final String? trailing;
  final Color? trailingColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: isDark ? const Color(0xFF141E33) : CnColors.card,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? const Color(0xFF24324E) : CnColors.line,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // .oc-head
              Row(
                children: [
                  Text(Formatters.digits(orderNumber),
                      style: TextStyle(
                          fontFamily: 'Peyda', fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).colorScheme.onSurface)),
                  const Spacer(),
                  StatusChip(status: status, compact: true),
                ],
              ),
              const SizedBox(height: 7),
              // .oc-title
              Text(serviceTitle,
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontFamily: 'Peyda', fontSize: 12.5,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(.6))),
              const SizedBox(height: 9),
              // .oc-foot
              Row(
                children: [
                  Text(priceText,
                      style: const TextStyle(
                          fontFamily: 'Peyda', fontSize: 12,
                          fontWeight: FontWeight.w700, color: CnColors.skyDeep)),
                  const Spacer(),
                  if (trailing != null)
                    Text(trailing!,
                        style: TextStyle(
                            fontFamily: 'Peyda', fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: trailingColor ?? CnColors.sky)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// اسلایدر هیرو — پورت دقیق .hero-slider:
/// تصویر 190px با کپشن گرادیانی پایین، دات‌ها زیر اسلایدر
/// (6px خاکستری؛ فعال 18px آبی)، اتوپلی ۵ ثانیه، سوایپ لمسی.
class HeroSlider extends StatefulWidget {
  const HeroSlider({super.key, required this.slides});

  final List<SliderItem> slides;

  @override
  State<HeroSlider> createState() => _HeroSliderState();
}

class _HeroSliderState extends State<HeroSlider> {
  final _pageCtrl = PageController();
  Timer? _timer;
  int _i = 0;

  bool get _hasImages => widget.slides.any((s) => s.imageUrl.trim().isNotEmpty);

  @override
  void initState() {
    super.initState();
    if (widget.slides.length > 1) {
      _timer = Timer.periodic(const Duration(seconds: 5), (_) {
        if (!mounted) return;
        _i = (_i + 1) % widget.slides.length;
        _pageCtrl.animateToPage(_i,
            duration: const Duration(milliseconds: 450), curve: Curves.ease);
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageCtrl.dispose();
    super.dispose();
  }

  /// آدرس مطلق تصویر — پشتیبانی از URL کامل و مسیر نسبی.
  static String _resolveUrl(String raw) {
    final url = raw.trim();
    if (url.isEmpty) return url;
    if (url.startsWith('http://') || url.startsWith('https://')) return url;
    return url.startsWith('/') ? '${Env.baseUrl}$url' : '${Env.baseUrl}/$url';
  }

  @override
  Widget build(BuildContext context) {
    // فال‌بک وب (ui.js imageSlider): گرادیان خوش‌آمد وقتی اسلایدی نیست.
    if (widget.slides.isEmpty || (!_hasImages)) {
      return _WelcomeFallback(
        title: Strings.appName,
        subtitle: Strings.barHomeT2,
      );
    }
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: SizedBox(
            height: 190,
            child: PageView.builder(
              controller: _pageCtrl,
              itemCount: widget.slides.length,
              onPageChanged: (i) => setState(() => _i = i),
              itemBuilder: (c, i) {
                final s = widget.slides[i];
                final hasText = s.title.isNotEmpty || s.subtitle.isNotEmpty;
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      _resolveUrl(s.imageUrl),
                      fit: BoxFit.fill,
                      errorBuilder: (_, __, ___) => Container(color: const Color(0xFFEEF2F7)),
                      loadingBuilder: (c, child, progress) =>
                          progress == null ? child : Container(color: const Color(0xFFEEF2F7)),
                    ),
                    if (hasText)
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: Container(
                          padding: const EdgeInsets.fromLTRB(14, 40, 14, 12),
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [Color(0xD9020817), Colors.transparent],
                            ),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (s.title.isNotEmpty)
                                Text(s.title,
                                    style: const TextStyle(
                                        fontFamily: 'Peyda', fontSize: 15,
                                        fontWeight: FontWeight.w700, color: Colors.white)),
                              if (s.subtitle.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(s.subtitle,
                                    style: TextStyle(
                                        fontFamily: 'Peyda', fontSize: 11.5,
                                        color: Colors.white.withOpacity(.9))),
                              ],
                            ],
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ),
        // .slider-dots → دات 6px؛ فعال 18×6 آبی
        Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 2),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < widget.slides.length; i++)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 2.5),
                  width: i == _i ? 18 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: i == _i ? CnColors.sky : const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// فال‌بک اسلایدر — پورت نسخه خالی ui.js (گرادیان برند + خوش‌آمد).
class _WelcomeFallback extends StatelessWidget {
  const _WelcomeFallback({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 170,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [CnColors.sky, CnColors.skyDeep],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontFamily: 'Peyda', fontSize: 16,
                  fontWeight: FontWeight.w700, color: Colors.white)),
          const SizedBox(height: 4),
          Text(subtitle,
              style: TextStyle(
                  fontFamily: 'Peyda', fontSize: 12,
                  color: Colors.white.withOpacity(.9))),
        ],
      ),
    );
  }
}

/// کاشی خدمت داخل کاروسل‌ها — همان .cat-icon-tile باserviceName خدمت.
class ServiceTile extends StatelessWidget {
  const ServiceTile({super.key, required this.service, required this.onTap, this.width});

  final ServiceModel service;
  final VoidCallback onTap;
  final double? width;

  @override
  Widget build(BuildContext context) {
    return CatIconTile(
      title: service.title,
      icon: IconMapper.safe(service.icon),
      iconColor: service.iconColor.isNotEmpty
          ? IconMapper.color(service.iconColor)
          : null,
      width: width,
      onTap: onTap,
    );
  }
}

/// کارت دسته برای گرید ۴ستونه (سازگاری با کد قبلی).
class CategoryTileCard extends StatelessWidget {
  const CategoryTileCard({super.key, required this.category, required this.onTap});

  final CategoryModel category;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return CatIconTile(
      title: category.title,
      icon: IconMapper.safe(category.iconName),
      iconColor: category.iconColor != null && category.iconColor!.isNotEmpty
          ? IconMapper.color(category.iconColor)
          : null,
      onTap: onTap,
    );
  }
}

/// کاروسل افقی با پیک ۴.۵ کاشی — پورت .cat-icon-carousel
/// (۴ کاشی کامل + نیمه پنجم؛ فاصله 9px؛ اسکرول‌اسنپ).
class TileCarousel extends StatelessWidget {
  const TileCarousel({super.key, required this.itemCount, required this.itemBuilder});

  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      // width = (container − 4×9) / 4.5 — مطابق CSS پله
      final tileW = (constraints.maxWidth - 4 * 9) / 4.5;
      // ارتفاع = مربع + فاصله ۸ + برچسب ۲خطی ۳۰px
      return SizedBox(
        height: tileW + 40,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 2),
          itemCount: itemCount,
          separatorBuilder: (_, __) => const SizedBox(width: 9),
          itemBuilder: (context, i) => SizedBox(
            width: tileW,
            child: itemBuilder(context, i),
          ),
        ),
      );
    });
  }
}

/// ردیف tone آیکون‌دار برای داشبوردها — .stat-card .s-icon.
class ToneIconBox extends StatelessWidget {
  const ToneIconBox({super.key, required this.icon, this.tone = CnColors.sky, this.size = 38});

  final IconData icon;
  final Color tone;
  final double size;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: _toneBg(tone, isDark),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, size: size * 0.47,
          color: isDark ? tone : _toneFg(tone)),
    );
  }
}
