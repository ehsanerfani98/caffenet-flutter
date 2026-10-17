import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/icon_mapper.dart';
import '../../../core/values/strings.dart';
import '../../../core/widgets/cn_bottom_nav.dart';
import '../../../core/widgets/cn_cards.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../data/models/service_model.dart';
import '../controllers/catalog_controller.dart';

/// کاتالوگ — پورت دقیق Screens.catalog از landing.js:
/// جستجو + ردیف چیپ دسته‌ها + گرید ۲ستونه کارت خدمت.
class CatalogView extends GetView<CatalogController> {
  const CatalogView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CnBrandBar(
        title: Strings.barCatalogT1,
        subtitle: Strings.barCatalogT2,
        actions: cnCustomerBarActions(),
      ),
      body: RefreshIndicator(
        onRefresh: () => controller.load(fresh: true),
        child: Obx(() {
          final st = controller.status.value;
          if (st.isLoading) return const LoadingSkeleton(lines: 6);
          if (st.isError) {
            return CnErrorRetry(
                message: st.errorMessage, onRetry: () => controller.load(fresh: true));
          }
          return Column(
            children: [
              // ── جستجو ──
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
                child: TextField(
                  onChanged: (v) => controller.query.value = v,
                  style: const TextStyle(fontFamily: 'Peyda', fontSize: 13.5),
                  decoration: InputDecoration(
                    hintText: 'جستجو در خدمات…',
                    isDense: true,
                    prefixIcon:
                        const Icon(Icons.search_rounded, size: 17, color: CnColors.inkSoft),
                  ),
                ),
              ),
              // ── چیپ دسته‌ها ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: SizedBox(
                  height: 38,
                  child: Obx(() {
                    final cats = controller.categories;
                    return ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      itemCount: cats.length + 1,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (_, i) {
                        final isAll = i == 0;
                        final catId = isAll ? 'all' : cats[i - 1].id;
                        return CnChip(
                          label: isAll ? Strings.ordersAll : cats[i - 1].title,
                          active: controller.selectedCat.value == catId,
                          onTap: () => controller.selectedCat.value = catId,
                        );
                      },
                    );
                  }),
                ),
              ),
              const SizedBox(height: 12),
              // ── لیست خدمات ──
              Expanded(
                child: Obx(() {
                  final list = controller.filtered;
                  if (st.isEmpty || list.isEmpty) {
                    return CnEmptyState(
                      icon: Icons.search_off_rounded,
                      title: controller.query.value.isEmpty || controller.selectedCat.value != 'all'
                          ? Strings.noServices
                          : Strings.noServicesFound,
                      subtitle: controller.query.value.isNotEmpty
                          ? 'عبارت دیگری را جستجو کنید'
                          : null,
                    );
                  }
                  return LayoutBuilder(builder: (cc, box) {
                    const gap = 10.0;
                    final w = (box.maxWidth - 28 - gap) / 2;
                    return SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(14, 2, 14, 18),
                      child: Wrap(
                        spacing: gap,
                        runSpacing: gap,
                        children: list
                            .map((s) => SizedBox(
                                  width: w,
                                  child: ServiceCard(
                                    service: s,
                                    onTap: () => Get.toNamed('/service-detail', arguments: s),
                                  ),
                                ))
                            .toList(),
                      ),
                    );
                  });
                }),
              ),
            ],
          );
        }),
      ),
      bottomNavigationBar: const CnBottomNav(current: 1),
    );
  }
}

/// صفحه خدمات یک دسته — همان زبان بصری با هدر برند و گرید ۲ستونه.
class CatalogCategoryView extends GetView<CatalogController> {
  const CatalogCategoryView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CnBrandBar(
        title: controller.category?.title ?? Strings.barCatalogT1,
        subtitle: Strings.barCatalogT2,
      ),
      body: RefreshIndicator(
        onRefresh: () => controller.load(fresh: true),
        child: Obx(() {
          final st = controller.status.value;
          if (st.isLoading) return const LoadingSkeleton(lines: 5);
          if (st.isError) {
            return CnErrorRetry(
                message: st.errorMessage, onRetry: () => controller.load(fresh: true));
          }
          final list = controller.filtered;
          if (st.isEmpty || list.isEmpty) {
            return const CnEmptyState(icon: Icons.category_outlined, title: Strings.noServices);
          }
          return LayoutBuilder(builder: (cc, box) {
            const gap = 10.0;
            final w = (box.maxWidth - 28 - gap) / 2;
            return SingleChildScrollView(
              padding: const EdgeInsets.all(14),
              child: Wrap(
                spacing: gap,
                runSpacing: gap,
                children: list
                    .map((s) => SizedBox(
                          width: w,
                          child: ServiceCard(
                            service: s,
                            onTap: () => Get.toNamed('/service-detail', arguments: s),
                          ),
                        ))
                    .toList(),
              ),
            );
          });
        }),
      ),
    );
  }
}

/// جزئیات خدمت — svc-icon بزرگ + قیمت پایه + فرمول + دکمه ثبت.
class ServiceDetailView extends GetView<CatalogController> {
  const ServiceDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    final s = controller.service;
    if (s == null) {
      return const Scaffold(body: CnEmptyState(title: Strings.noServices));
    }
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconColor = s.iconColor.isNotEmpty ? IconMapper.color(s.iconColor) : null;
    return Scaffold(
      appBar: AppBar(title: Text(s.title)),
      body: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF141E33) : CnColors.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? const Color(0xFF24324E) : CnColors.line,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: isDark
                            ? (iconColor ?? CnColors.sky).withOpacity(.18)
                            : CnColors.skySoft,
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: Icon(IconMapper.safe(s.icon),
                          size: 21,
                          color: isDark
                              ? (iconColor ?? CnColors.skySoft)
                              : (iconColor ?? CnColors.skyDeep)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(s.title,
                          style: TextStyle(
                              fontFamily: 'Peyda', fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Theme.of(context).colorScheme.onSurface)),
                    ),
                  ],
                ),
                if (s.description.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(s.description,
                      style: TextStyle(
                          fontFamily: 'Peyda', fontSize: 11.5, height: 1.8,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(.6))),
                ],
              ],
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF141E33) : CnColors.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? const Color(0xFF24324E) : CnColors.line,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _metaRow(context, Strings.basePrice,
                    s.basePrice > 0 ? Formatters.toman(s.basePrice) : 'محاسبه در سفارش'),
                if (s.estimatedTime.isNotEmpty)
                  _metaRow(context, Strings.estimatedTime, s.estimatedTime),
              ],
            ),
          ),
          const SizedBox(height: 14),
          CnButton(
            label: Strings.orderThisService,
            icon: Icons.shopping_cart_outlined,
            onPressed: () => controller.openOrderForm(s),
          ),
        ],
      ),
    );
  }

  static Widget _metaRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  fontFamily: 'Peyda', fontSize: 12.5,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(.6))),
          Text(value,
              style: const TextStyle(
                  fontFamily: 'Peyda', fontSize: 12.5,
                  fontWeight: FontWeight.w700, color: CnColors.skyDeep)),
        ],
      ),
    );
  }
}
