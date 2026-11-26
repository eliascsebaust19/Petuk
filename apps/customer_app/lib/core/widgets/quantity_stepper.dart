import 'package:flutter/material.dart';

import '../constants/app_constants.dart';
import '../theme/app_colors.dart';
import '../utils/bn_format.dart';

/// − / quantity / + stepper. When [min] is 0 and quantity is 1, the minus
/// button becomes a delete action (removes the cart line).
class QuantityStepper extends StatelessWidget {
  const QuantityStepper({
    super.key,
    required this.quantity,
    required this.onChanged,
    this.min = 0,
    this.max = AppConstants.maxItemQuantity,
    this.compact = false,
  });

  final int quantity;
  final ValueChanged<int> onChanged;
  final int min;
  final int max;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final double side = compact ? 32 : 38;
    final bool canDecrease = quantity > min;
    final bool canIncrease = quantity < max;
    final bool deletesNext = min == 0 && quantity == 1;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          _StepperButton(
            icon: deletesNext ? Icons.delete_outline_rounded : Icons.remove,
            color: deletesNext ? AppColors.error : AppColors.primary,
            enabled: canDecrease,
            side: side,
            onTap: () => onChanged(quantity - 1),
          ),
          SizedBox(
            width: compact ? 30 : 36,
            child: Text(
              BnFormat.digits(quantity),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: compact ? 14 : 16,
                color: AppColors.slate,
              ),
            ),
          ),
          _StepperButton(
            icon: Icons.add,
            color: AppColors.primary,
            enabled: canIncrease,
            side: side,
            onTap: () => onChanged(quantity + 1),
          ),
        ],
      ),
    );
  }
}

class _StepperButton extends StatelessWidget {
  const _StepperButton({
    required this.icon,
    required this.color,
    required this.enabled,
    required this.side,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final bool enabled;
  final double side;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: side,
      height: side,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: enabled ? onTap : null,
          child: Icon(
            icon,
            size: side * 0.5,
            color: enabled ? color : AppColors.slate40,
          ),
        ),
      ),
    );
  }
}
