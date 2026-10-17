import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/icon_mapper.dart';
import '../../../core/values/strings.dart';
import '../../../core/widgets/cn_bottom_nav.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../data/models/category_model.dart';
import '../../../data/models/misc_models.dart';
import '../../../data/models/service_model.dart';
import '../controllers/home_controller.dart';
import '../../../core/theme/app_text_styles.dart';

/// Home — هدر برند + ظرفیت + اسلایدر + دسته‌ها + ویژه + سفارش فعال (T4.4).
class HomeView extends GetView<HomeController> {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () => controller.load(fresh: true),
        child: Obx(() {
          final st = controller.status.value;
          if (st.isLoading) return const LoadingSkeleton(lines: 6);
          if (st.isError) return CnErrorRetry(message: st.errorMessage, onRetry: () => controller.load(fresh: true));
          return _Body(c: controller);
        }),
      ),
      bottomNavigationBar: const CnBottomNav(current: 0),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.c});

  final HomeController c;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        // ── هدر + ظرفیت ──
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(c.greeting.value, style: Theme.of(context).textTheme.headlineSmall),
                  Text(Strings.appName,
                      style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            Obx(() {
              final cap = c.capacity.value;
              if (cap == null) return const SizedBox.shrink();
              return CapacityBadge(tier: cap.tier, title: cap.title.isEmpty ? 'ظرفیت عادی' : cap.title);
            }),
          ],
        ),
        const SizedBox(height: 14),

        // ── اسلایدر ──
        Obx(() {
          final items = c.sliderItems;
          if (items.isEmpty) return const SizedBox.shrink();
          return _Slider(items: items);
        }),

        // ── سفارش فعال ──
        Obx(() {
          final o = c.activeOrder.value;
          if (o == null) return const SizedBox.shrink();
          return _ActiveOrderCard(controller: c, orderId: o.id, status: o.status, title: o.serviceTitle);
        }),

        // ── دسته‌ها ──
        SectionHeader(
          title: Strings.homeCategories,
          action: TextButton(onPressed: c.openCatalog, child: const Text(Strings.seeAll)),
        ),
        Obx(() {
          final cats = c.catalog.categoriesRx;
          if (cats.isEmpty) {
            return CnEmptyState(
              icon: Icons.category_outlined,
              title: Strings.noCategories,
              compact: true,
            );
          }
          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, mainAxisSpacing: 10, crossAxisSpacing: 10, childAspectRatio: 1.55,
            ),
            itemCount: cats.length,
            itemBuilder: (cc, i) => _CategoryCard(category: cats[i], onTap: () => c.openCategory(cats[i])),
          );
        }),

        // ── ویژه ──
        SectionHeader(title: Strings.homeFeatured),
        Obx(() {
          final cats = c.catalog.categoriesRx;
          return FutureBuilder<List<ServiceModel>>(
            future: c.catalog.featured(),
            builder: (cc, snap) {
              if (!snap.hasData || snap.data!.isEmpty) {
                return const SizedBox.shrink();
              }
              return Column(
                children: snap.data!
                    .map((s) => _FeaturedCard(
                          service: s,
                          categoryTitle: cats.where((x) => x.id == s.categoryId).firstOrNull?.title,
                          onTap: () => c.openService(s),
                        ))
                    .toList(),
              );
            },
          );
        }),
      ],
    );
  }
}

/// اسلایدر با PageView + autoScroll (T4.4).
class _Slider extends StatefulWidget {
  const _Slider({required this.items});

  final List<SliderItem> items;

  @override
  State<_Slider> createState() => _SliderState();
}

class _SliderState extends State<_Slider> {
  final _pageCtrl = PageController();
  Timer? _timer;
  int _i = 0;

  @override
  void initState() {
    super.initState();
    if (widget.items.length > 1) {
      _timer = Timer.periodic(const Duration(seconds: 5), (_) {
        if (!mounted) return;
        _i = (_i + 1) % widget.items.length;
        _pageCtrl.animateToPage(_i,
            duration: const Duration(milliseconds: 400), curve: Curves.easeOut);
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 132,
      child: PageView.builder(
        controller: _pageCtrl,
        itemCount: widget.items.length,
        itemBuilder: (c, i) {
          final it = widget.items[i];
          return Container(
            margin: const EdgeInsets.only(bottom: 4),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [CnColors.sky, CnColors.skyDeep],
                begin: AlignmentDirectional.topStart,
                end: AlignmentDirectional.bottomEnd,
              ),
              borderRadius: BorderRadius.circular(18),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  it.title,
                  style: const TextStyle(
                      fontFamily: 'Peyda', fontSize: 17, fontWeight: FontWeight.w700,
                      color: Colors.white),
                ),
                if (it.subtitle.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    it.subtitle,
                    style: TextStyle(
                        fontFamily: 'Peyda', fontSize: 12.5,
                        color: Colors.white.withOpacity(.85), height: 1.6),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

/// کارت سفارش فعال — لینک tracker (T4.4).
class _ActiveOrderCard extends StatelessWidget {
  const _ActiveOrderCard({
    required this.controller,
    required this.orderId,
    required this.status,
    required this.title,
  });

  final HomeController controller;
  final String orderId;
  final String status;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 14, bottom: 4),
      decoration: BoxDecoration(
        color: CnColors.amberSoft,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: CnColors.amber.withOpacity(.35)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: controller.openActiveOrder,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                const Icon(Icons.access_time_filled, color: CnColors.amber, size: 26),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(Strings.homeActiveOrder,
                          style: Theme.of(context).textTheme.titleSmall),
                      const SizedBox(height: 2),
                      Text(title, style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
                StatusChip(status: status, compact: true),
                const SizedBox(width: 6),
                const Icon(Icons.chevron_left, color: CnColors.amber),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// کارت دسته — نگاشت iconName → Material (T4.7).
class _CategoryCard extends StatelessWidget {
  const _CategoryCard({required this.category, required this.onTap});

  final CategoryModel category;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = IconMapper.color(category.iconColor);
    return Card(
      child: Material(
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(color: color.withOpacity(.12), borderRadius: BorderRadius.circular(13)),
                  child: Icon(IconMapper.safe(category.iconName), color: color, size: 24),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(category.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// کارت خدمت ویژه.
class _FeaturedCard extends StatelessWidget {
  const _FeaturedCard({
    required this.service,
    required this.onTap,
    this.categoryTitle,
  });

  final ServiceModel service;
  final VoidCallback onTap;
  final String? categoryTitle;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Material(
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Icon(Icons.local_offer_outlined, color: CnColors.amber, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(service.title, style: Theme.of(context).textTheme.titleSmall),
                      if (categoryTitle != null)
                        Text(categoryTitle!, style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
                Text(Formatters.tomanWithUnit(service.basePrice),
                    style: AppTextStyles.price(context, color: CnColors.sky)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
