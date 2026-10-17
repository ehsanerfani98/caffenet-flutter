import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';
import '../values/strings.dart';

/// ─────────────────────────────────────────────────────────────
/// کامپوننت‌های مشترک — پورت وفادار CSS پله (public/css/app.css):
/// .btn / .pill / .section-title / .chip / .info-box / .warn-box /
/// .list-row / .price-summary / .search-box / .empty-state
/// ─────────────────────────────────────────────────────────────

/// دکمه اصلی برند — معادل .btn (radius 13، 14px/700، حالت loading).
class CnButton extends StatelessWidget {
  const CnButton({
    super.key,
    required this.label,
    this.onPressed,
    this.loading = false,
    this.icon,
    this.outlined = false,
    this.danger = false,
    this.emerald = false,
    this.ghost = false,
    this.expanded = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final IconData? icon;
  final bool outlined;
  final bool danger;
  final bool emerald;
  final bool ghost;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final Color fg;
    if (ghost) {
      bg = CnColors.slateSoft;
      fg = CnColors.ink;
    } else if (outlined) {
      bg = Colors.transparent;
      fg = danger ? CnColors.rose : CnColors.sky;
    } else if (danger) {
      bg = CnColors.rose;
      fg = Colors.white;
    } else if (emerald) {
      bg = CnColors.emerald;
      fg = Colors.white;
    } else {
      bg = CnColors.sky;
      fg = Colors.white;
    }
    final child = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (loading)
          SizedBox(
            width: 17,
            height: 17,
            child: CircularProgressIndicator(strokeWidth: 2, color: fg),
          )
        else ...[
          if (icon != null) ...[Icon(icon, size: 17, color: fg), const SizedBox(width: 7)],
          Text(label),
        ],
      ],
    );

    final btn = Material(
      color: ghost || outlined ? bg : bg,
      borderRadius: BorderRadius.circular(13),
      child: InkWell(
        borderRadius: BorderRadius.circular(13),
        onTap: loading ? null : onPressed,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
          child: DefaultTextStyle(
            style: TextStyle(
              fontFamily: 'Peyda',
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: fg,
            ),
            child: child,
          ),
        ),
      ),
    );
    return expanded ? SizedBox(width: double.infinity, child: btn) : btn;
  }
}

/// دکمه کوچک — معادل .btn.sm (padding 8×12، 12px، radius 10).
class CnButtonSm extends StatelessWidget {
  const CnButtonSm({super.key, required this.label, this.onPressed, this.slate = true, this.icon});

  final String label;
  final VoidCallback? onPressed;
  final bool slate;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: slate ? CnColors.slate : CnColors.sky,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 14, color: Colors.white),
                const SizedBox(width: 5),
              ],
              Text(label,
                  style: const TextStyle(
                      fontFamily: 'Peyda', fontSize: 12, fontWeight: FontWeight.w700,
                      color: Colors.white)),
            ],
          ),
        ),
      ),
    );
  }
}

/// فیلد متنی RTL یکدست — معادل .input (border 1.5، radius 12، focus آبی).
class CnTextField extends StatelessWidget {
  const CnTextField({
    super.key,
    required this.controller,
    this.label,
    this.requiredMark = false,
    this.hint,
    this.validator,
    this.keyboardType,
    this.maxLines = 1,
    this.obscure = false,
    this.prefixIcon,
    this.suffix,
    this.enabled = true,
    this.maxLength,
    this.onChanged,
    this.errorText,
    this.inputFormatters,
    this.textAlign = TextAlign.start,
    this.textAlignVertical,
    this.fontSize = 14,
  });

  final TextEditingController controller;
  final String? label;
  final bool requiredMark;
  final String? hint;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final int maxLines;
  final bool obscure;
  final Widget? prefixIcon;
  final Widget? suffix;
  final bool enabled;
  final int? maxLength;
  final ValueChanged<String>? onChanged;
  final String? errorText;
  final List<TextInputFormatter>? inputFormatters;
  final TextAlign textAlign;
  final TextAlignVertical? textAlignVertical;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          // .field-label → 12.5px/600 + ستاره الزامی قرمز
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Row(
              children: [
                Text(label!,
                    style: TextStyle(
                        fontFamily: 'Peyda',
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface)),
                if (requiredMark)
                  const Text(' *',
                      style: TextStyle(
                          fontFamily: 'Peyda', fontSize: 12.5, color: CnColors.rose)),
              ],
            ),
          ),
          const SizedBox(height: 6),
        ],
        TextFormField(
          controller: controller,
          validator: validator,
          keyboardType: keyboardType,
          maxLines: maxLines,
          minLines: maxLines > 1 ? 3 : 1,
          obscureText: obscure,
          enabled: enabled,
          maxLength: maxLength,
          onChanged: onChanged,
          inputFormatters: inputFormatters,
          textAlign: textAlign,
          textAlignVertical: textAlignVertical,
          style: TextStyle(fontFamily: 'Peyda', fontSize: fontSize),
          decoration: InputDecoration(
            hintText: hint,
            errorText: errorText,
            prefixIcon: prefixIcon,
            suffixIcon: suffix,
            counterText: '',
          ),
        ),
      ],
    );
  }
}

/// Scaffold با AppBar استاندارد (صفحات داخلی غیرتب).
class CnScaffold extends StatelessWidget {
  const CnScaffold({
    super.key,
    this.title,
    this.body,
    this.actions,
    this.floatingActionButton,
    this.bottom,
    this.showBack = true,
  });

  final String? title;
  final Widget? body;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final PreferredSizeWidget? bottom;
  final bool showBack;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: title == null && !showBack
          ? null
          : AppBar(
              title: Text(title ?? ''),
              actions: actions,
              bottom: bottom,
              automaticallyImplyLeading: showBack,
            ),
      body: body,
      floatingActionButton: floatingActionButton,
    );
  }
}

/// حالت خالی — معادل .empty-state (آیکون 44 با opacity .4، عنوان 14/700).
class CnEmptyState extends StatelessWidget {
  const CnEmptyState({
    super.key,
    required this.title,
    this.subtitle,
    this.icon = Icons.folder_open_rounded,
    this.actionLabel,
    this.onAction,
    this.compact = false,
  });

  final String title;
  final String? subtitle;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(compact ? 18 : 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 44,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(.4)),
            const SizedBox(height: 10),
            Text(title,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontFamily: 'Peyda',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onSurface)),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(subtitle!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontFamily: 'Peyda', fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(.6))),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 16),
              CnButton(label: actionLabel!, onPressed: onAction),
            ],
          ],
        ),
      ),
    );
  }
}

/// حالت خطا با تلاش مجدد.
class CnErrorRetry extends StatelessWidget {
  const CnErrorRetry({super.key, this.message, required this.onRetry});

  final String? message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return CnEmptyState(
      icon: Icons.cloud_off_rounded,
      title: message ?? Strings.errNetwork,
      actionLabel: Strings.retry,
      onAction: onRetry,
    );
  }
}

/// اسکلتون لودینگ لیست.
class LoadingSkeleton extends StatelessWidget {
  const LoadingSkeleton({super.key, this.lines = 4});

  final int lines;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: lines,
      itemBuilder: (c, i) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        height: 84,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.onSurface.withOpacity(.05),
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}

/// اسپینر — معادل .spinner (حلقه 38px آبی).
class CnSpinner extends StatelessWidget {
  const CnSpinner({super.key, this.size = 38});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: const CircularProgressIndicator(
        strokeWidth: 3.5,
        valueColor: AlwaysStoppedAnimation<Color>(CnColors.sky),
        backgroundColor: CnColors.skySoft,
      ),
    );
  }
}

/// Badge ظرفیت 🟢🟡🟠🔴 (حلقه رنگی + عنوان).
class CapacityBadge extends StatelessWidget {
  const CapacityBadge({
    super.key,
    required this.tier,
    required this.title,
    this.compact = false,
  });

  final String tier;
  final String title;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final color = switch (tier) {
      'yellow' => const Color(0xFFF59E0B),
      'orange' => const Color(0xFFD97706),
      'red' => CnColors.rose,
      _ => CnColors.emerald,
    };
    return Container(
      padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 10, vertical: compact ? 4 : 6),
      decoration: BoxDecoration(
        color: color.withOpacity(.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(title,
              style: TextStyle(
                fontFamily: 'Peyda',
                fontSize: compact ? 11.5 : 12.5,
                fontWeight: FontWeight.w600,
                color: color,
              )),
        ],
      ),
    );
  }
}

/// Pill وضعیت سفارش — پورت دقیق .pill از app.css:
/// radius 20، padding 4×10، 11px/700، رنگ‌های soft هر وضعیت.
class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.status, this.compact = false});

  final String status;
  final bool compact;

  static const Map<String, ({String label, Color bg, Color fg})> _map = {
    'pending_payment': (label: 'در انتظار پرداخت', bg: CnColors.amberSoft, fg: Color(0xFF92400E)),
    'submitted': (label: Strings.statusSubmitted, bg: CnColors.skySoft, fg: CnColors.skyDeep),
    'processing': (label: 'در حال انجام', bg: CnColors.indigoSoft, fg: CnColors.indigo),
    'ready': (label: Strings.statusReady, bg: CnColors.emeraldSoft, fg: Color(0xFF065F46)),
    'delivered': (label: Strings.statusDelivered, bg: CnColors.slateSoft, fg: CnColors.slate),
    'failed': (label: 'ناموفق', bg: CnColors.roseSoft, fg: Color(0xFF9F1239)),
    'cancelled': (label: 'لغو شده', bg: Color(0xFFF3F4F6), fg: Color(0xFF6B7280)),
    'refunded': (label: Strings.statusRefunded, bg: CnColors.roseSoft, fg: Color(0xFF9F1239)),
  };

  /// برچسب وضعیت — نسخه کوتاه برای فضاهای باریک.
  static String shortLabel(String status) {
    if (status == 'ready') return 'آماده تحویل';
    return _map[status]?.label ?? status;
  }

  @override
  Widget build(BuildContext context) {
    final meta = _map[status] ?? _map['pending_payment']!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: meta.bg, borderRadius: BorderRadius.circular(20)),
      child: Text(meta.label,
          style: TextStyle(
            fontFamily: 'Peyda',
            fontSize: compact ? 10.5 : 11,
            fontWeight: FontWeight.w700,
            color: meta.fg,
          )),
    );
  }
}

/// Chip فیلتر — پورت دقیق .chip (radius 22، border 1.5، حالت فعال sky-soft).
class CnChip extends StatelessWidget {
  const CnChip({
    super.key,
    required this.label,
    required this.active,
    required this.onTap,
    this.icon,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final line = isDark ? const Color(0xFF24324E) : CnColors.line;
    return Material(
      color: active ? CnColors.skySoft : (isDark ? const Color(0xFF141E33) : CnColors.card),
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: active ? CnColors.sky : line, width: 1.5),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 15,
                    color: active ? CnColors.skyDeep : CnColors.inkSoft),
                const SizedBox(width: 5),
              ],
              Text(label,
                  style: TextStyle(
                    fontFamily: 'Peyda',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: active ? CnColors.skyDeep : CnColors.inkSoft,
                  )),
            ],
          ),
        ),
      ),
    );
  }
}

/// ردیف چیپ‌های افقی اسکرول‌شو — معادل .chip-row.
class CnChipRow extends StatelessWidget {
  const CnChipRow({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 2),
        itemCount: children.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) => children[i],
      ),
    );
  }
}

/// عنوان بخش — پورت دقیق .section-title (14.5px/700 + آیکون 18px آبی).
class SectionHeader extends StatelessWidget {
  const SectionHeader({super.key, required this.title, this.icon, this.action});

  final String title;
  final IconData? icon;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 18, bottom: 10),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18, color: CnColors.sky),
            const SizedBox(width: 6),
          ],
          Expanded(
            child: Text(title,
                style: TextStyle(
                    fontFamily: 'Peyda',
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onSurface)),
          ),
          if (action != null) action!,
        ],
      ),
    );
  }
}

/// عنوان دسته — معادل .cat-head (12.5px/700 + آیکون 17px).
class CategoryHead extends StatelessWidget {
  const CategoryHead({super.key, required this.title, this.icon, this.iconColor});

  final String title;
  final IconData? icon;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 8),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 17, color: iconColor ?? CnColors.sky),
            const SizedBox(width: 6),
          ],
          Expanded(
            child: Text(title,
                style: TextStyle(
                    fontFamily: 'Peyda',
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onSurface)),
          ),
        ],
      ),
    );
  }
}

/// جعبه اطلاعات — معادل .info-box (sky-soft، radius 13، 12px sky-deep).
class CnInfoBox extends StatelessWidget {
  const CnInfoBox({super.key, required this.text, this.child});

  final String text;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2A4A) : CnColors.skySoft,
        borderRadius: BorderRadius.circular(13),
      ),
      child: child ??
          Text(text,
              style: const TextStyle(
                  fontFamily: 'Peyda', fontSize: 12,
                  height: 1.9, color: CnColors.skyDeep)),
    );
  }
}

/// جعبه هشدار — معادل .warn-box (amber-soft، radius 13، 12px #92400E).
class CnWarnBox extends StatelessWidget {
  const CnWarnBox({super.key, required this.text, this.child});

  final String text;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF3A2E14) : CnColors.amberSoft,
        borderRadius: BorderRadius.circular(13),
      ),
      child: child ??
          Text(text,
              style: TextStyle(
                  fontFamily: 'Peyda', fontSize: 12,
                  height: 1.9,
                  color: isDark ? CnColors.amberSoft : const Color(0xFF92400E))),
    );
  }
}

/// ردیف لیست — پورت دقیق .list-row (آیکون tone 38×38 + عنوان 13/700 + زیرنویس 11).
class CnListRow extends StatelessWidget {
  const CnListRow({
    super.key,
    required this.title,
    this.subtitle,
    required this.icon,
    this.tone = CnColors.sky,
    this.trailing,
    this.onTap,
  });

  final String title;
  final String? subtitle;
  final IconData icon;
  final Color tone;
  final Widget? trailing;
  final VoidCallback? onTap;

  /// رنگ متن tone block بر اساس رنگ زمینه (soft palettes).
  static Color toneFg(Color tone) => switch (tone) {
        CnColors.emerald => const Color(0xFF065F46),
        CnColors.amber => const Color(0xFF92400E),
        CnColors.indigo => CnColors.indigo,
        CnColors.rose => const Color(0xFF9F1239),
        CnColors.slate => CnColors.slate,
        _ => CnColors.skyDeep,
      };

  static Color toneBg(Color tone) => switch (tone) {
        CnColors.emerald => CnColors.emeraldSoft,
        CnColors.amber => CnColors.amberSoft,
        CnColors.indigo => CnColors.indigoSoft,
        CnColors.rose => CnColors.roseSoft,
        CnColors.slate => CnColors.slateSoft,
        _ => CnColors.skySoft,
      };

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 2),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: isDark ? tone.withOpacity(.18) : toneBg(tone),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 18,
                  color: isDark ? tone : toneFg(tone)),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          fontFamily: 'Peyda', fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).colorScheme.onSurface)),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(subtitle!,
                        style: TextStyle(
                            fontFamily: 'Peyda', fontSize: 11,
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(.6))),
                  ],
                ],
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }
}

/// خلاصه قیمت — پورت دقیق .price-summary (slate-soft، ردیف total با خط‌چین).
class PriceSummary extends StatelessWidget {
  const PriceSummary({super.key, required this.rows, required this.totalLabel, required this.totalValue});

  final List<({String label, String value})> rows;
  final String totalLabel;
  final String totalValue;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final softColor = isDark ? const Color(0xFF1A2438) : CnColors.slateSoft;
    final softText = isDark ? const Color(0xFF94A3B8) : CnColors.inkSoft;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: softColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          for (final r in rows)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(r.label,
                      style: TextStyle(fontFamily: 'Peyda', fontSize: 12.5, color: softText)),
                  Text(r.value,
                      style: TextStyle(fontFamily: 'Peyda', fontSize: 12.5, color: softText)),
                ],
              ),
            ),
          Container(
            margin: const EdgeInsets.only(top: 6),
            padding: const EdgeInsets.only(top: 9),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(totalLabel,
                    style: TextStyle(
                        fontFamily: 'Peyda', fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: Theme.of(context).colorScheme.onSurface)),
                Text(totalValue,
                    style: TextStyle(
                        fontFamily: 'Peyda', fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: isDark ? CnColors.skySoft : CnColors.skyDeep)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// باکس جستجو — پورت دقیق .search-box (آیکون 17px داخل، padding-start 38).
class CnSearchBox extends StatelessWidget {
  const CnSearchBox({
    super.key,
    required this.controller,
    required this.hint,
    this.onChanged,
    this.autofocus = false,
  });

  final TextEditingController controller;
  final String hint;
  final ValueChanged<String>? onChanged;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      autofocus: autofocus,
      style: const TextStyle(fontFamily: 'Peyda', fontSize: 13.5),
      decoration: InputDecoration(
        hintText: hint,
        isDense: true,
        prefixIcon: const Icon(Icons.search_rounded, size: 17, color: CnColors.inkSoft),
      ),
    );
  }
}

/// ردیف قیمت با ارقام فارسی (کارتی — checkout / order detail).
class PriceRow extends StatelessWidget {
  const PriceRow({
    super.key,
    required this.label,
    required this.amount,
    this.bold = false,
    this.color,
    this.suffix,
  });

  final String label;
  final String amount;
  final bool bold;
  final Color? color;
  final String? suffix;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodyMedium!.copyWith(
          fontWeight: bold ? FontWeight.w800 : FontWeight.w400,
          color: color,
        );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label, style: style)),
          Text('$amount${suffix ?? ''}', style: style),
        ],
      ),
    );
  }
}

/// سگمنت انتخاب فوریت (T5.2) — ضرایب از settings (فقط نمایش).
class SegmentedUrgency extends StatelessWidget {
  const SegmentedUrgency({
    super.key,
    required this.value,
    required this.onChanged,
    this.urgentMultiplier = 1,
    this.immediateMultiplier = 1,
  });

  final String value;
  final ValueChanged<String> onChanged;
  final double urgentMultiplier;
  final double immediateMultiplier;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<String>(
      showSelectedIcon: false,
      segments: [
        ButtonSegment(
          value: 'normal',
          label: Column(children: [
            const Text(Strings.urgencyNormal),
            Text('×1', style: Theme.of(context).textTheme.bodySmall),
          ]),
        ),
        ButtonSegment(
          value: 'urgent',
          label: Column(children: [
            const Text(Strings.urgencyUrgent),
            Text('×${_fmt(urgentMultiplier)}', style: Theme.of(context).textTheme.bodySmall),
          ]),
        ),
        ButtonSegment(
          value: 'immediate',
          label: Column(children: [
            const Text(Strings.urgencyImmediate),
            Text('×${_fmt(immediateMultiplier)}', style: Theme.of(context).textTheme.bodySmall),
          ]),
        ),
      ],
      selected: {value},
      onSelectionChanged: (s) => onChanged(s.first),
    );
  }

  static String _fmt(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(1);
}

