import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// One label/value line of the bill breakdown (cart, checkout, tracking).
class BillRow extends StatelessWidget {
  const BillRow(
    this.label,
    this.value, {
    super.key,
    this.bold = false,
    this.valueColor,
  });

  final String label;
  final String value;
  final bool bold;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              label,
              style: bold
                  ? text.titleMedium
                  : text.bodyMedium?.copyWith(color: AppColors.slate60),
            ),
          ),
          Text(
            value,
            style: (bold ? text.titleMedium : text.bodyMedium)?.copyWith(
              color: valueColor ?? (bold ? AppColors.slate : AppColors.slate60),
              fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
