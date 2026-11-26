import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/models/order.dart';

/// Payment toggle (FR-C05): COD is the default (~80% of Birganj orders);
/// bKash / Nagad run as merchant Send-Money + TrxID verification in
/// Phase 1, upgrading to dynamic QR + IPN in Phase 2.
class PaymentMethodSelector extends StatelessWidget {
  const PaymentMethodSelector({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final PaymentMethod selected;
  final ValueChanged<PaymentMethod> onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        _MethodCard(
          method: PaymentMethod.cod,
          icon: Icons.payments_outlined,
          title: 'ক্যাশ অন ডেলিভারি',
          subtitle: 'খাবার হাতে পেয়ে টাকা দিন',
          color: AppColors.primary,
          badge: 'জনপ্রিয়',
          selected: selected == PaymentMethod.cod,
          onTap: () => onSelected(PaymentMethod.cod),
        ),
        const SizedBox(height: 10),
        _MethodCard(
          method: PaymentMethod.bkash,
          icon: Icons.account_balance_wallet_outlined,
          title: 'বিকাশ',
          subtitle: 'সেন্ড মানি করে ট্রানজেকশন আইডি দিন',
          color: AppColors.bkash,
          selected: selected == PaymentMethod.bkash,
          onTap: () => onSelected(PaymentMethod.bkash),
        ),
        const SizedBox(height: 10),
        _MethodCard(
          method: PaymentMethod.nagad,
          icon: Icons.account_balance_wallet_outlined,
          title: 'নগদ',
          subtitle: 'সেন্ড মানি করে ট্রানজেকশন আইডি দিন',
          color: AppColors.nagad,
          selected: selected == PaymentMethod.nagad,
          onTap: () => onSelected(PaymentMethod.nagad),
        ),
      ],
    );
  }
}

class _MethodCard extends StatelessWidget {
  const _MethodCard({
    required this.method,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.selected,
    required this.onTap,
    this.badge,
  });

  final PaymentMethod method;
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final bool selected;
  final VoidCallback onTap;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? color : AppColors.border,
              width: selected ? 1.6 : 1,
            ),
          ),
          child: Row(
            children: <Widget>[
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Text(
                          title,
                          style: text.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        if (badge != null) ...<Widget>[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.accentSoft,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              badge!,
                              style: text.labelSmall?.copyWith(
                                color: AppColors.accentDark,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(subtitle, style: text.labelSmall),
                  ],
                ),
              ),
              Icon(
                selected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_unchecked_rounded,
                color: selected ? color : AppColors.slate40,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
