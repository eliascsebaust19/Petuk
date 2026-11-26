import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/bn_format.dart';
import '../../../data/models/order.dart';

/// The 4-step visual pipeline (FR-C06):
/// অর্ডার গৃহীত → রান্না হচ্ছে → পথে আছে → ডেলিভারি সম্পন্ন.
///
/// Completed steps are teal, the in-flight step is amber, upcoming steps
/// are grey; reached-step timestamps render under each label.
class OrderStatusStepper extends StatelessWidget {
  const OrderStatusStepper({
    super.key,
    required this.status,
    required this.statusTimes,
  });

  final OrderStatus status;
  final Map<OrderStatus, DateTime> statusTimes;

  static const List<IconData> _icons = <IconData>[
    Icons.receipt_long_rounded,
    Icons.soup_kitchen_rounded,
    Icons.delivery_dining_rounded,
    Icons.check_circle_rounded,
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        for (int i = 0; i < OrderStatus.values.length; i++)
          Expanded(
            child: _Step(
              icon: _icons[i],
              label: OrderStatus.values[i].labelBn,
              time: statusTimes[OrderStatus.values[i]],
              completed: i < status.step ||
                  status == OrderStatus.delivered,
              active: i == status.step &&
                  status != OrderStatus.delivered,
              lineLeftDone: i <= status.step,
              lineRightDone: i < status.step,
              isFirst: i == 0,
              isLast: i == OrderStatus.values.length - 1,
            ),
          ),
      ],
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({
    required this.icon,
    required this.label,
    required this.time,
    required this.completed,
    required this.active,
    required this.lineLeftDone,
    required this.lineRightDone,
    required this.isFirst,
    required this.isLast,
  });

  final IconData icon;
  final String label;
  final DateTime? time;
  final bool completed;
  final bool active;
  final bool lineLeftDone;
  final bool lineRightDone;
  final bool isFirst;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final Color circleColor = completed
        ? AppColors.primary
        : active
            ? AppColors.accent
            : AppColors.surface;
    final Color lineDone = AppColors.primary;
    const Color lineTodo = AppColors.border;

    return Column(
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: Container(
                height: 3,
                color: isFirst
                    ? Colors.transparent
                    : lineLeftDone
                        ? lineDone
                        : lineTodo,
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: circleColor,
                border: Border.all(
                  color: completed || active
                      ? circleColor
                      : AppColors.border,
                  width: 2,
                ),
              ),
              child: Icon(
                icon,
                size: 17,
                color: completed || active
                    ? Colors.white
                    : AppColors.slate40,
              ),
            ),
            Expanded(
              child: Container(
                height: 3,
                color: isLast
                    ? Colors.transparent
                    : lineRightDone
                        ? lineDone
                        : lineTodo,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            style: TextStyle(
              fontSize: 11,
              height: 1.25,
              fontWeight: FontWeight.w600,
              color: completed || active
                  ? AppColors.slate
                  : AppColors.slate40,
            ),
          ),
        ),
        if (time != null)
          Text(
            BnFormat.time(time!),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.slate40,
            ),
          ),
      ],
    );
  }
}
