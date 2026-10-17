import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/values/strings.dart';
import '../../../core/widgets/common_widgets.dart';
import '../controllers/tracker_controller.dart';
import '../widgets/tracker_cards.dart';

/// پیگیری عمومی با توکن/لینک اشتراکی — بدون لاگین (T7.8).
class TrackPublicView extends GetView<TrackerController> {
  const TrackPublicView({super.key});

  @override
  Widget build(BuildContext context) {
    final tokenCtrl = TextEditingController(text: controller.trackToken.value);

    return Scaffold(
      appBar: AppBar(title: const Text(Strings.trackPublicTitle)),
      body: Obx(() {
        final o = controller.order.value;
        if (controller.status.value.isLoading) {
          return const LoadingSkeleton(lines: 3);
        }
        if (o != null) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              StatusCard(o: o),
              EtaCard(o: o),
            ],
          );
        }
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.link_outlined, size: 60, color: CnColors.sky),
              const SizedBox(height: 18),
              Text(Strings.trackPublicHint,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 18),
              CnTextField(
                controller: tokenCtrl,
                hint: 'مثلاً trk_9f2a…',
              ),
              const SizedBox(height: 16),
              CnButton(
                label: Strings.trackPublicTrack,
                icon: Icons.gps_fixed,
                onPressed: () => controller.searchToken(tokenCtrl.text),
              ),
            ],
          ),
        );
      }),
    );
  }
}
