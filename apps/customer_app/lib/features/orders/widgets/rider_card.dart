import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/bn_format.dart';
import '../../../data/models/order.dart';

/// Rider contact card with a one-tap call button. Before assignment it
/// shows the "finding a rider" state.
class RiderCard extends StatelessWidget {
  const RiderCard({super.key, required this.rider, required this.status});

  final Rider? rider;
  final OrderStatus status;

  Future<void> _call(BuildContext context, String phone) async {
    try {
      final bool launched = await launchUrl(
        Uri.parse('tel:$phone'),
        mode: LaunchMode.externalApplication,
      );
      if (!launched && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('কল করা যায়নি। নম্বর: $phone')),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('কল করা যায়নি। নম্বর: $phone')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final Rider? assigned = rider;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: assigned == null
          ? Row(
              children: <Widget>[
                const SizedBox(
                  width: 26,
                  height: 26,
                  child: CircularProgressIndicator(strokeWidth: 2.4),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        status == OrderStatus.delivered
                            ? 'রাইডার তথ্য নেই'
                            : 'রাইডার খোঁজা হচ্ছে…',
                        style: text.titleSmall,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'কাছের অনলাইন রাইডারকে অর্ডারটি পাঠানো হচ্ছে',
                        style: text.labelSmall,
                      ),
                    ],
                  ),
                ),
              ],
            )
          : Row(
              children: <Widget>[
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.accentSoft,
                  child: Text(
                    assigned.initials,
                    style: text.titleMedium
                        ?.copyWith(color: AppColors.accentDark),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        assigned.name,
                        style: text.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        assigned.vehicle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: text.labelSmall,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: <Widget>[
                          const Icon(
                            Icons.star_rounded,
                            size: 14,
                            color: AppColors.accent,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            BnFormat.digits(
                              assigned.rating.toStringAsFixed(1),
                            ),
                            style: text.labelMedium,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Material(
                  color: AppColors.primarySoft,
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () => _call(context, assigned.phone),
                    child: const SizedBox(
                      width: 46,
                      height: 46,
                      child: Icon(
                        Icons.call_rounded,
                        color: AppColors.primaryDark,
                        size: 22,
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
