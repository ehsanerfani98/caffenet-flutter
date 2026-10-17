import 'package:url_launcher/url_launcher.dart';

/// بازکردن لینک‌های خارجی — درگاه پرداخت، تماس، صفحات قوانین (T1.5 پلن).
/// پرداخت هرگز داخل WebView اپ باز نمی‌شود (خطای 3DS/OTP بانک — §4.4 پلن).
class LauncherService {
  Future<bool> openExternal(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return false;
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }

  Future<bool> openInApp(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return false;
    try {
      return await launchUrl(uri, mode: LaunchMode.platformDefault);
    } catch (_) {
      return false;
    }
  }

  Future<bool> tel(String phone) => openExternal('tel:$phone');
}
