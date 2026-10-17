import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';
import '../values/strings.dart';

/// دکمه اصلی برند — با حالت loading (T1.6).
class CnButton extends StatelessWidget {
  const CnButton({
    super.key,
    required this.label,
    this.onPressed,
    this.loading = false,
    this.icon,
    this.outlined = false,
    this.danger = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final IconData? icon;
  final bool outlined;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final bg = danger ? CnColors.rose : (outlined ? Colors.transparent : CnColors.sky);
    final fg = outlined ? (danger ? CnColors.rose : CnColors.sky) : Colors.white;
    final child = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (loading)
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2, color: fg),
          )
        else ...[
          if (icon != null) ...[Icon(icon, size: 19, color: fg), const SizedBox(width: 8)],
          Text(label),
        ],
      ],
    );

    return SizedBox(
      height: 50,
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(13),
        child: InkWell(
          borderRadius: BorderRadius.circular(13),
          onTap: loading ? null : onPressed,
          child: Center(child: DefaultTextStyle(
            style: TextStyle(
              fontFamily: 'Peyda',
              fontSize: 15.5,
              fontWeight: FontWeight.w600,
              color: fg,
            ),
            child: child,
          )),
        ),
      ),
    );
  }
}

/// فیلد متنی RTL یکدست (T1.6).
class CnTextField extends StatelessWidget {
  const CnTextField({
    super.key,
    required this.controller,
    this.label,
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
  });

  final TextEditingController controller;
  final String? label;
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

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(label!,
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.w600)),
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
          style: const TextStyle(fontFamily: 'Peyda', fontSize: 14.5),
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

/// Scaffold با هدر یکدست (T1.6).
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
      bottomNavigationBar: bottom == null ? null : null,
    );
  }
}

/// حالت خالی با آیکون (T1.6).
class CnEmptyState extends StatelessWidget {
  const CnEmptyState({
    super.key,
    required this.title,
    this.subtitle,
    this.icon = Icons.inbox_outlined,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? subtitle;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: Theme.of(context).colorScheme.onSurface.withOpacity(.25)),
            const SizedBox(height: 14),
            Text(title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium),
            if (subtitle != null) ...[
              const SizedBox(height: 6),
              Text(subtitle!,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall),
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

/// حالت خطا با تلاش مجدد (T1.6).
class CnErrorRetry extends StatelessWidget {
  const CnErrorRetry({super.key, this.message, required this.onRetry});

  final String? message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return CnEmptyState(
      icon: Icons.cloud_off_outlined,
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

/// Badge ظرفیت 🟢🟡🟠🔴 (T4.3).
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

/// Chip وضعیت سفارش رنگ‌بندی‌شده (T1.6).
class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.status, this.compact = false});

  final String status;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      'pending_payment' => CnColors.amber,
      'submitted' => CnColors.sky,
      'processing' => CnColors.indigo,
      'ready' || 'delivered' => CnColors.emerald,
      'failed' => CnColors.rose,
      _ => CnColors.slate,
    };
    final soft = switch (status) {
      'pending_payment' => CnColors.amberSoft,
      'submitted' => CnColors.skySoft,
      'processing' => CnColors.indigoSoft,
      'ready' || 'delivered' => CnColors.emeraldSoft,
      'failed' => CnColors.roseSoft,
      _ => CnColors.slateSoft,
    };
    final label = switch (status) {
      'pending_payment' => 'در انتظار پرداخت',
      'submitted' => 'در صف انجام',
      'processing' => 'در حال انجام',
      'ready' => 'آماده تحویل',
      'delivered' => 'تحویل شده',
      'failed' => 'ناموفق',
      'cancelled' => 'لغو شده',
      'refunded' => 'بازگشت وجه',
      _ => status,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(color: soft, borderRadius: BorderRadius.circular(8)),
      child: Text(label,
          style: TextStyle(
            fontFamily: 'Peyda',
            fontSize: compact ? 11 : 12,
            fontWeight: FontWeight.w600,
            color: color,
          )),
    );
  }
}

/// ردیف قیمت با ارقام فارسی.
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
          fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
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

/// بخش با عنوان در صفحات.
class SectionHeader extends StatelessWidget {
  const SectionHeader({super.key, required this.title, this.action});

  final String title;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 18,
            decoration: BoxDecoration(
              color: CnColors.sky,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(title, style: Theme.of(context).textTheme.titleLarge)),
          if (action != null) action!,
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
