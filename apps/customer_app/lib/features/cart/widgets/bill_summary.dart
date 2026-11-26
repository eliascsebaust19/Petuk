import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/bn_format.dart';
import '../../../core/widgets/bill_row.dart';

/// The transparent bill breakdown (SRS: "কোনো লুকানো ফি নেই"):
/// subtotal + flat ৳30 delivery − coupon discount = grand total.
class BillSummary extends StatelessWidget {
  const BillSummary({
    super.key,
    required this.subtotal,
    required this.deliveryFee,
    required this.discount,
    required this.grandTotal,
    this.couponCode,
  });

  final int subtotal;
  final int deliveryFee;
  final int discount;
  final int grandTotal;
  final String? couponCode;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        BillRow('সাবটোটাল', BnFormat.taka(subtotal)),
        BillRow('ডেলিভারি চার্জ (ফ্ল্যাট)', BnFormat.taka(deliveryFee)),
        if (discount > 0)
          BillRow(
            couponCode == null ? 'ডিসকাউন্ট' : 'ডিসকাউন্ট ($couponCode)',
            BnFormat.taka(-discount),
            valueColor: AppColors.success,
          ),
        const Divider(height: 20),
        BillRow(
          'মোট',
          BnFormat.taka(grandTotal),
          bold: true,
          valueColor: AppColors.primaryDark,
        ),
      ],
    );
  }
}
