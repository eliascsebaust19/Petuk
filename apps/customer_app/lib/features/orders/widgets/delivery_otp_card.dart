import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/bn_format.dart';

/// The 4-digit handover code. The rider must collect it at the door —
/// matching code = confirmed delivery (SRS Rider App / DFD 4.0).
class DeliveryOtpCard extends StatelessWidget {
  const DeliveryOtpCard({
    super.key,
    required this.otp,
    required this.delivered,
  });

  final String otp;
  final bool delivered;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.slate,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(
                delivered
                    ? Icons.verified_rounded
                    : Icons.shield_outlined,
                color: delivered ? AppColors.success : AppColors.accent,
                size: 22,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  delivered
                      ? 'ডেলিভারি সম্পন্ন হয়েছে'
                      : 'রাইডারকে এই কোডটি বলুন',
                  style: text.titleSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'কোড কপি করুন',
                visualDensity: VisualDensity.compact,
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: otp));
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('কোড কপি হয়েছে'),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  }
                },
                icon: const Icon(
                  Icons.copy_rounded,
                  size: 18,
                  color: AppColors.accent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              for (int i = 0; i < otp.length; i++)
                Container(
                  width: 46,
                  height: 54,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Text(
                    BnFormat.digits(otp[i]),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            delivered
                ? 'কোড মিলে যাওয়ায় ডেলিভারি নিশ্চিত করা হয়েছে। ধন্যবাদ!'
                : 'খাবার বুঝে নেওয়ার সময় এই ৪ ডিজিটের কোডটি রাইডারকে দিন। কোড মিললেই ডেলিভারি নিশ্চিত হবে।',
            textAlign: TextAlign.center,
            style: text.labelSmall?.copyWith(
              color: Colors.white.withValues(alpha: 0.7),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
