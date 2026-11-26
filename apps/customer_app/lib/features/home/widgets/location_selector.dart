import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/bn_format.dart';
import '../bloc/home_bloc.dart';

/// Bottom-sheet zone picker. Zone 1 areas are selectable; Zone 2 areas
/// are visible but locked with "শীঘ্রই আসছে" (expansion roadmap).
Future<void> showLocationSelector(BuildContext context) {
  final HomeBloc homeBloc = context.read<HomeBloc>();
  final String currentZone = homeBloc.state.zone;
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (BuildContext sheetContext) {
      final TextTheme text = Theme.of(sheetContext).textTheme;
      return SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text('ডেলিভারি এলাকা', style: text.titleLarge),
              const SizedBox(height: 4),
              Text(
                'আপাতত বীরগঞ্জ পৌর এলাকায় ডেলিভারি চলছে — ফ্ল্যাট চার্জ ${BnFormat.taka(AppConstants.deliveryFee)}।',
                style: text.bodySmall,
              ),
              const SizedBox(height: 12),
              for (final String zone in AppConstants.serviceZones)
                _ZoneTile(
                  zone: zone,
                  selected: zone == currentZone,
                  onTap: () {
                    homeBloc.add(HomeZoneChanged(zone));
                    Navigator.of(sheetContext).pop();
                  },
                ),
              const Divider(height: 24),
              for (final String zone in AppConstants.upcomingZones)
                _ZoneTile(zone: zone, selected: false, upcoming: true),
            ],
          ),
        ),
      );
    },
  );
}

class _ZoneTile extends StatelessWidget {
  const _ZoneTile({
    required this.zone,
    required this.selected,
    this.onTap,
    this.upcoming = false,
  });

  final String zone;
  final bool selected;
  final VoidCallback? onTap;
  final bool upcoming;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Material(
      color: selected ? AppColors.primarySoft : Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            children: <Widget>[
              Icon(
                upcoming
                    ? Icons.lock_outline_rounded
                    : selected
                        ? Icons.check_circle_rounded
                        : Icons.circle_outlined,
                size: 20,
                color: upcoming
                    ? AppColors.slate40
                    : selected
                        ? AppColors.primary
                        : AppColors.slate40,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  zone,
                  style: text.bodyLarge?.copyWith(
                    color: upcoming ? AppColors.slate40 : AppColors.slate,
                    fontWeight:
                        selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
              if (upcoming)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.accentSoft,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'শীঘ্রই আসছে',
                    style: text.labelSmall?.copyWith(
                      color: AppColors.accentDark,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
