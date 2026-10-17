import 'package:flutter/material.dart';

/// نگاشت iconName/icon بک‌اند (نام‌های رشته‌ای) به آیکون Material.
/// هر نام ناشناخته → آیکون fallback (ریسک «تغییر شکل fields» §9 پلن).
class IconMapper {
  IconMapper._();

  static const Map<String, IconData> _map = {
    // دسته‌ها / خدمات رایج
    'printer': Icons.print_outlined,
    'print': Icons.print_outlined,
    'document': Icons.description_outlined,
    'documents': Icons.description_outlined,
    'file': Icons.insert_drive_file_outlined,
    'files': Icons.folder_open_outlined,
    'student': Icons.school_outlined,
    'university': Icons.school_outlined,
    'education': Icons.menu_book_outlined,
    'registration': Icons.how_to_reg_outlined,
    'government': Icons.account_balance_outlined,
    'office': Icons.business_center_outlined,
    'tax': Icons.receipt_long_outlined,
    'loan': Icons.request_quote_outlined,
    'bank': Icons.account_balance_wallet_outlined,
    'id-card': Icons.badge_outlined,
    'idcard': Icons.badge_outlined,
    'card': Icons.credit_card_outlined,
    'scan': Icons.document_scanner_outlined,
    'copy': Icons.content_copy_outlined,
    'type': Icons.keyboard_outlined,
    'translate': Icons.translate_outlined,
    'photo': Icons.photo_outlined,
    'image': Icons.image_outlined,
    'design': Icons.design_services_outlined,
    'poster': Icons.article_outlined,
    'email': Icons.mail_outline_outlined,
    'phone': Icons.phone_outlined,
    'map': Icons.map_outlined,
    'location': Icons.place_outlined,
    'time': Icons.schedule_outlined,
    'clock': Icons.schedule_outlined,
    'star': Icons.star_outline,
    'heart': Icons.favorite_outline,
    'home': Icons.home_outlined,
    'cart': Icons.shopping_cart_outlined,
    'wallet': Icons.account_balance_wallet_outlined,
    'support': Icons.support_agent_outlined,
    'chat': Icons.chat_bubble_outline,
    'shield': Icons.shield_outlined,
    'check': Icons.check_circle_outline,
    'bolt': Icons.bolt_outlined,
    'gift': Icons.card_giftcard_outlined,
    'tag': Icons.sell_outlined,
    'list': Icons.list_alt_outlined,
    'grid': Icons.grid_view_outlined,
    'coffee': Icons.local_cafe_outlined,
    'cafe': Icons.local_cafe_outlined,
  };

  static IconData? byName(String? name) {
    if (name == null || name.isEmpty) return null;
    final key = name.trim().toLowerCase().replaceAll('_', '-');
    return _map[key];
  }

  /// آیکون با fallback امن.
  static IconData safe(String? name, {IconData fallback = Icons.category_outlined}) =>
      byName(name) ?? fallback;

  /// رنگ hex بک‌اند (#RRGGBB یا رشته خالی) → Color با fallback.
  static Color color(String? hex, {Color fallback = const Color(0xFF1559DE)}) {
    if (hex == null || hex.isEmpty) return fallback;
    var v = hex.trim().replaceFirst('#', '');
    if (v.length == 6) v = 'FF$v';
    final n = int.tryParse(v, radix: 16);
    return n == null ? fallback : Color(n);
  }
}
