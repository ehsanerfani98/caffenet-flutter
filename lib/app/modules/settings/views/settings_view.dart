import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/config/env.dart';
import '../../../core/services/launcher_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/values/strings.dart';
import '../../../core/widgets/common_widgets.dart';
import '../controllers/settings_controller.dart';

/// Settings — تم + لینک‌ها + درباره (T8.2).
class SettingsView extends GetView<SettingsController> {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(Strings.settingsTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── تم ──
          SectionHeader(title: Strings.settingsTheme),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Obx(() => Row(
                    children: [
                      Expanded(
                        child: _themeOption(context, 'system', Strings.themeSystem,
                            Icons.brightness_auto_outlined),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _themeOption(context, 'light', Strings.themeLight,
                            Icons.light_mode_outlined),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _themeOption(context, 'dark', Strings.themeDark,
                            Icons.dark_mode_outlined),
                      ),
                    ],
                  )),
            ),
          ),
          const SizedBox(height: 18),

          // ── لینک‌ها ──
          SectionHeader(title: Strings.settingsLinks),
          _tile(context, Icons.gavel_outlined, Strings.settingsTerms,
              () => _open('${Env.appUrl}/terms')),
          _tile(context, Icons.privacy_tip_outlined, Strings.settingsPrivacy,
              () => _open('${Env.appUrl}/privacy')),
          _tile(context, Icons.support_agent_outlined, Strings.settingsContact,
              () => _open('${Env.appUrl}/contact')),

          const SizedBox(height: 18),
          SectionHeader(title: Strings.settingsAbout),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: CnColors.skySoft,
                          borderRadius: BorderRadius.circular(13),
                        ),
                        child: const Icon(Icons.local_cafe_rounded,
                            color: CnColors.sky, size: 26),
                      ),
                      const SizedBox(width: 12),
                      const Text(Strings.appName,
                          style: TextStyle(
                              fontFamily: 'Peyda', fontSize: 16,
                              fontWeight: FontWeight.w700)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(Strings.settingsAboutBody,
                      style: TextStyle(height: 1.8, fontSize: 13)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _themeOption(BuildContext c, String value, String label, IconData icon) {
    final selected = controller.themeMode.value == value;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => controller.setTheme(value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? CnColors.skySoft : null,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: selected ? CnColors.sky : Theme.of(c).dividerColor),
        ),
        child: Column(
          children: [
            Icon(icon, size: 22,
                color: selected ? CnColors.sky : CnColors.inkSoft),
            const SizedBox(height: 4),
            Text(label,
                style: TextStyle(
                    fontFamily: 'Peyda', fontSize: 11.5,
                    color: selected ? CnColors.sky : CnColors.inkSoft)),
          ],
        ),
      ),
    );
  }

  Widget _tile(BuildContext c, IconData icon, String title, VoidCallback onTap) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: CnColors.sky),
        title: Text(title, style: c.textTheme.titleSmall),
        trailing: const Icon(Icons.chevron_left),
      ),
    );
  }

  void _open(String url) => Get.find<LauncherService>().openExternal(url);
}
