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
import '../controllers/home_controller.dart';

/// Home — پورت وفادار Screens.home از landing.js پله:
/// نوار جستجو → اسلایدر هیرو → گرید ۴ستونه دسته‌ها (۱۲ + مشاهده بیشتر)
/// → کاروسل خدمات پرطرفدار → کاروسل خدمات هر دسته.
/// (بلوک «سفارش جاری شما» — موقتاً غیرفعال، مطابق وب ۲۰۲۶-۱۰-۱۸.)
class HomeView extends GetView<HomeController> {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CnBrandBar(
        title: Strings.barHomeT1,
        subtitle: Strings.barHomeT2,
        actions: cnCustomerBarActions(),
      ),
      body: RefreshIndicator(
        onRefresh: () => controller.load(fresh: true),
        child: Obx(() {
          final st = controller.status.value;
          if (st.isLoading) return const LoadingSkeleton(lines: 6);
          if (st.isError) return CnErrorRetry(message: st.errorMessage, onRetry: () => controller.load(fresh: true));
          return const _Body();
        }),
      ),
      bottomNavigationBar: const CnBottomNav(current: 0),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body();

  @override
  Widget build(BuildContext context) {
    final c = Get.find<HomeController>();
    return Obx(() {
      return ListView(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 18),
        children: [
          // ── ۱) نوار جستجو (بالای هیرو) ──
          HomeSearchBar(
            label: Strings.homeSearchLabel,
            count: _activeServiceCount(c),
            onTap: () => _openSearchSheet(context, c),
          ),
          const SizedBox(height: 12),

          // ── ۲) اسلایدر هیرو (تصویر + کپشن + دات) ──
          Obx(() {
            final items = c.sliderItems.where((s) => true).toList();
            return HeroSlider(slides: items);
          }),

          // ── ۳) گرید دسته‌بندی خدمات (۴ستونه + مشاهده بیشتر) ──
          _CategoryGrid(c: c),

          // ── ۴) خدمات پرطرفدار (کاروسل) ──
          Obx(() {
            final popular = _popularServices(c);
            return Column(
              children: [
                SectionHeader(title: Strings.homeFeatured, icon: Icons.star_rounded),
                TileCarousel(
                  itemCount: popular.length,
                  itemBuilder: (cc, i) => ServiceTile(
                    service: popular[i],
                    onTap: () => c.openService(popular[i]),
                  ),
                ),
              ],
            );
          }),

          // ── ۵) خدمات هر دسته (کاروسل) ──
          Obx(() {
            final cats = c.catalog.categoriesRx;
            final services = c.catalog.servicesRx
                .where((s) => s.isActive == true)
                .toList();
            if (cats.isEmpty) return const SizedBox.shrink();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final cat in cats)
                  if (services.any((s) => s.categoryId == cat.id)) ...[
                    CategoryHead(
                      title: cat.title,
                      icon: IconMapper.safe(cat.iconName),
                      iconColor: cat.iconColor.isNotEmpty
                          ? IconMapper.color(cat.iconColor)
                          : null,
                    ),
                    TileCarousel(
                      itemCount: services.where((s) => s.categoryId == cat.id).length,
                      itemBuilder: (cc, i) {
                        final list = services.where((s) => s.categoryId == cat.id).toList();
                        return ServiceTile(
                          service: list[i],
                          onTap: () => c.openService(list[i]),
                        );
                      },
                    ),
                  ],
              ],
            );
          }),
        ],
      );
    });
  }

  static int _activeServiceCount(HomeController c) =>
      c.catalog.servicesRx.where((s) => s.isActive == true).length;

  /// خدمات پرطرفدار — منطق popularServices() وب (sync از کش):
  /// ویژه‌ها (مرتب با sortOrder)؛ در نبود ویژه، ۴ خدمت فعال اول.
  static List<ServiceModel> _popularServices(HomeController c) {
    final featured = c.catalog.servicesRx
        .where((s) => s.isActive && s.isFeatured)
        .toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    if (featured.isNotEmpty) return featured;
    return c.catalog.servicesRx.where((s) => s.isActive).take(4).toList();
  }

  /// شیت جستجوی خدمات — پورت openSearchSheet() وب:
  /// فیلد جستجو چسبان + پیشنهادها (۸ ویژه) + نتایج زنده در همان شیت.
  static void _openSearchSheet(BuildContext context, HomeController c) {
    final query = ''.obs;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (sheetCtx) {
        final isDark = Theme.of(sheetCtx).brightness == Brightness.dark;
        final line = isDark ? const Color(0xFF24324E) : CnColors.line;
        final controller = TextEditingController();
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(sheetCtx).viewInsets.bottom,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(sheetCtx).size.height * .92,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // دستگیره شیت
                Container(
                  width: 42,
                  height: 4,
                  margin: const EdgeInsets.only(top: 9),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                // sheet-head
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 11),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E2A4A) : CnColors.skySoft,
                          borderRadius: BorderRadius.circular(13),
                        ),
                        child: const Icon(Icons.search_rounded, size: 20, color: CnColors.skyDeep),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(Strings.searchSheetTitle,
                                style: TextStyle(
                                    fontFamily: 'Peyda', fontSize: 14.5,
                                    fontWeight: FontWeight.w700,
                                    color: Theme.of(sheetCtx).colorScheme.onSurface)),
                            Text(Strings.searchSheetSub,
                                style: TextStyle(
                                    fontFamily: 'Peyda', fontSize: 11,
                                    color: Theme.of(sheetCtx).colorScheme.onSurface.withOpacity(.6))),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(sheetCtx),
                        icon: const Icon(Icons.close_rounded, size: 16),
                        style: IconButton.styleFrom(
                          backgroundColor: isDark ? const Color(0xFF1A2438) : CnColors.slateSoft,
                          fixedSize: const Size(32, 32),
                          minimumSize: const Size(32, 32),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ],
                  ),
                ),
                Divider(height: 1, color: line),
                // search-sheet-field چسبان
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  child: CnSearchBox(
                    controller: controller,
                    hint: Strings.searchSheetHint,
                    autofocus: true,
                    onChanged: (v) => query.value = v.trim().toLowerCase(),
                  ),
                ),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Obx(() {
                      final q = query.value;
                      final all = c.catalog.servicesRx.where((s) => s.isActive == true).toList();
                      List<ServiceModel> items;
                      Widget header = const SizedBox.shrink();
                      if (q.isEmpty) {
                        // پیشنهاد ما — همان لیست پرطرفدار
                        items = _popularServices(c).take(8).toList();
                        header = Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Row(
                            children: [
                              const Icon(Icons.star_rounded, size: 16, color: CnColors.sky),
                              const SizedBox(width: 6),
                              Text(Strings.suggestionsTitle,
                                  style: TextStyle(
                                      fontFamily: 'Peyda', fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: Theme.of(sheetCtx).colorScheme.onSurface)),
                            ],
                          ),
                        );
                      } else {
                        items = all
                            .where((s) =>
                                ('${s.title} ${s.description}').toLowerCase().contains(q))
                            .toList();
                        if (items.isNotEmpty) {
                          header = Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Align(
                              alignment: AlignmentDirectional.centerStart,
                              child: Text(
                                '${Formatters.num(items.length)}${Strings.resultsCountSuffix}$q»',
                                style: TextStyle(
                                    fontFamily: 'Peyda', fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Theme.of(sheetCtx).colorScheme.onSurface.withOpacity(.6)),
                              ),
                            ),
                          );
                        }
                      }
                      if (items.isEmpty) {
                        return CnEmptyState(
                          title: 'خدمتی یافت نشد',
                          subtitle: 'عبارت دیگری را جستجو کنید',
                          icon: Icons.search_off_rounded,
                        );
                      }
                      return Column(
                        children: [
                          header,
                          LayoutBuilder(
                            builder: (cc, box) {
                              final w = (box.maxWidth - 10) / 2;
                              return Wrap(
                                spacing: 10,
                                runSpacing: 10,
                                children: items
                                    .map((s) => SizedBox(
                                          width: w,
                                          child: ServiceCard(
                                            service: s,
                                            onTap: () {
                                              Navigator.pop(sheetCtx);
                                              c.openService(s);
                                            },
                                          ),
                                        ))
                                    .toList(),
                              );
                            },
                          ),
                        ],
                      );
                    }),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// ── گرید دسته‌بندی‌ها (۴ستونه، ۱۲ مورد + مشاهده بیشتر) ──
class _CategoryGrid extends StatefulWidget {
  const _CategoryGrid({required this.c});

  final HomeController c;

  @override
  State<_CategoryGrid> createState() => _CategoryGridState();
}

class _CategoryGridState extends State<_CategoryGrid> {
  bool _expanded = false;
  static const int _rowLimit = 12; // ۳ ردیف × ۴ کاشی

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final cats = widget.c.catalog.categoriesRx;
      if (cats.isEmpty) {
        return Column(
          children: [
            SectionHeader(title: Strings.homeCategories, icon: Icons.grid_view_rounded),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF141E33)
                    : CnColors.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xFF24324E)
                      : CnColors.line,
                ),
              ),
              child: Center(
                child: Text(Strings.noCategoriesShort,
                    style: TextStyle(
                        fontFamily: 'Peyda', fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(.6))),
              ),
            ),
          ],
        );
      }
      final visible = _expanded ? cats : cats.take(_rowLimit).toList();
      return Column(
        children: [
          SectionHeader(title: Strings.homeCategories, icon: Icons.grid_view_rounded),
          LayoutBuilder(builder: (cc, box) {
            final w = (box.maxWidth - 3 * 9) / 4;
            return Wrap(
              spacing: 9,
              runSpacing: 18,
              children: visible
                  .map((cat) => SizedBox(
                        width: w,
                        child: CatIconTile(
                          title: cat.title,
                          icon: IconMapper.safe(cat.iconName),
                          iconColor:
                              cat.iconColor != null && cat.iconColor!.isNotEmpty
                                  ? IconMapper.color(cat.iconColor)
                                  : null,
                          onTap: () => widget.c.openCategory(cat),
                        ),
                      ))
                  .toList(),
            );
          }),
          if (!_expanded && cats.length > _rowLimit)
            // .cat-more-btn
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: TextButton.icon(
                onPressed: () => setState(() => _expanded = true),
                icon: const Icon(Icons.keyboard_arrow_down_rounded,
                    size: 15, color: CnColors.sky),
                label: const Text(Strings.seeMore,
                    style: TextStyle(
                        fontFamily: 'Peyda', fontSize: 12.5,
                        fontWeight: FontWeight.w700, color: CnColors.skyDeep)),
                style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 4)),
              ),
            ),
        ],
      );
    });
  }
}
