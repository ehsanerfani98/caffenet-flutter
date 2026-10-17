import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/icon_mapper.dart';
import '../../../core/values/strings.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../data/models/service_model.dart';
import '../controllers/catalog_controller.dart';
import '../../../core/theme/app_text_styles.dart';

/// کاتالوگ کامل با جستجو (T4.5).
class CatalogView extends GetView<CatalogController> {
  const CatalogView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(Strings.services)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: TextField(
              onChanged: (v) => controller.query.value = v,
              decoration: const InputDecoration(
                hintText: Strings.search,
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => controller.load(fresh: true),
              child: Obx(() {
                final st = controller.status.value;
                if (st.isLoading) return const LoadingSkeleton(lines: 6);
                if (st.isError) {
                  return CnErrorRetry(message: st.errorMessage, onRetry: () => controller.load(fresh: true));
                }
                final list = controller.filtered;
                if (st.isEmpty || list.isEmpty) {
                  return CnEmptyState(
                    icon: Icons.search_off_outlined,
                    title: controller.query.value.isEmpty ? Strings.noServices : Strings.noServicesFound,
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: list.length,
                  itemBuilder: (c, i) => _ServiceTile(
                    service: list[i],
                    onTap: () => Get.toNamed('/service-detail', arguments: list[i]),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

/// صفحه خدمات یک دسته.
class CatalogCategoryView extends GetView<CatalogController> {
  const CatalogCategoryView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(controller.category?.title ?? Strings.services)),
      body: RefreshIndicator(
        onRefresh: () => controller.load(fresh: true),
        child: Obx(() {
          final st = controller.status.value;
          if (st.isLoading) return const LoadingSkeleton(lines: 5);
          if (st.isError) {
            return CnErrorRetry(message: st.errorMessage, onRetry: () => controller.load(fresh: true));
          }
          final list = controller.filtered;
          if (st.isEmpty || list.isEmpty) {
            return const CnEmptyState(icon: Icons.category_outlined, title: Strings.noServices);
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            itemBuilder: (c, i) => _ServiceTile(
              service: list[i],
              onTap: () => Get.toNamed('/service-detail', arguments: list[i]),
            ),
          );
        }),
      ),
    );
  }
}

/// جزئیات خدمت — قیمت پایه + فرمول + دکمه ثبت (T4.6).
class ServiceDetailView extends GetView<CatalogController> {
  const ServiceDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    final s = controller.service;
    if (s == null) {
      return const Scaffold(body: CnEmptyState(title: Strings.noServices));
    }
    return Scaffold(
      appBar: AppBar(title: Text(s.title)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: IconMapper.color(s.iconColor).withOpacity(.12),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(IconMapper.safe(s.icon),
                            color: IconMapper.color(s.iconColor), size: 28),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(s.title, style: Theme.of(context).textTheme.titleLarge),
                            const SizedBox(height: 4),
                            if (s.estimatedTime.isNotEmpty)
                              Text('${Strings.estimatedTime}: ${s.estimatedTime}',
                                  style: Theme.of(context).textTheme.bodySmall),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 26),
                  PriceRow(label: Strings.basePrice, amount: Formatters.tomanWithUnit(s.basePrice), bold: true),
                ],
              ),
            ),
          ),
          if (s.description.isNotEmpty) ...[
            SectionHeader(title: 'توضیحات'),
            Text(s.description, style: Theme.of(context).textTheme.bodyMedium),
          ],
          if (s.pricingFormulaDescription.isNotEmpty) ...[
            SectionHeader(title: Strings.pricingFormula),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: CnColors.skySoft.withOpacity(.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(s.pricingFormulaDescription,
                  style: Theme.of(context).textTheme.bodySmall),
            ),
          ],
          const SizedBox(height: 24),
          CnButton(
            label: Strings.orderThisService,
            icon: Icons.add_shopping_cart_outlined,
            onPressed: () => controller.openOrderForm(s),
          ),
        ],
      ),
    );
  }
}

/// آیتم خدمت در لیست (icon, basePrice فارسی, estimatedTime — T4.5).
class _ServiceTile extends StatelessWidget {
  const _ServiceTile({required this.service, required this.onTap});

  final ServiceModel service;
  final VoidCallback onTap;

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
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: IconMapper.color(service.iconColor).withOpacity(.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(IconMapper.safe(service.icon),
                      color: IconMapper.color(service.iconColor), size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(service.title,
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleSmall),
                      const SizedBox(height: 2),
                      if (service.estimatedTime.isNotEmpty)
                        Text('${Strings.estimatedTime}: ${service.estimatedTime}',
                            style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
                Text(Formatters.tomanWithUnit(service.basePrice),
                    style: AppTextStyles.price(context)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
