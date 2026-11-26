import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/router/app_router.dart';
import '../../../core/services/location_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/bd_phone.dart';
import '../../../core/utils/bn_format.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../data/models/delivery_address.dart';
import '../../../data/models/order.dart';
import '../../../data/models/user_profile.dart';
import '../../../data/sources/mock_catalog_data.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../cart/bloc/cart_bloc.dart';
import '../../cart/bloc/cart_event.dart';
import '../../home/bloc/shell_cubit.dart';
import '../../location/pages/restaurants_map_page.dart';
import '../../orders/bloc/orders_bloc.dart';
import '../bloc/profile_bloc.dart';
import '../widgets/address_editor_sheet.dart';

/// Full customer profile management: personal info, avatar, saved GPS/landmark
/// addresses, preferences, order summary, support & logout.
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  static const List<String> _avatars = <String>[
    '😋',
    '🍛',
    '🛵',
    '👨‍🎓',
    '🧕',
    '🧑',
  ];

  Future<void> _editProfile(BuildContext context, UserProfile profile) async {
    final TextEditingController nameCtrl =
        TextEditingController(text: profile.name);
    final TextEditingController emailCtrl =
        TextEditingController(text: profile.email);
    String avatar = profile.avatarEmoji;
    String defaultZone =
        AppConstants.serviceZones.contains(profile.defaultZone)
            ? profile.defaultZone
            : AppConstants.defaultZone;

    final bool? saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext sheetContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            final double bottomInset = MediaQuery.of(context).viewInsets.bottom;
            return Padding(
              padding: EdgeInsets.only(bottom: bottomInset),
              child: SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
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
                      const SizedBox(height: 14),
                      Text(
                        'প্রোফাইল সম্পাদনা',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'অবতার বেছে নিন',
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 10,
                        children: _avatars.map((String emoji) {
                          final bool selected = avatar == emoji;
                          return InkWell(
                            borderRadius: BorderRadius.circular(24),
                            onTap: () => setModalState(() => avatar = emoji),
                            child: Container(
                              width: 46,
                              height: 46,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: selected
                                    ? AppColors.primarySoft
                                    : AppColors.background,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: selected
                                      ? AppColors.primary
                                      : AppColors.border,
                                  width: selected ? 2 : 1,
                                ),
                              ),
                              child: Text(
                                emoji,
                                style: const TextStyle(fontSize: 22),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: nameCtrl,
                        decoration: const InputDecoration(
                          labelText: 'পুরো নাম',
                          hintText: 'যেমন: রফিকুল ইসলাম',
                          prefixIcon: Icon(Icons.person_outline_rounded),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'ইমেইল (ঐচ্ছিক)',
                          hintText: 'name@example.com',
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: defaultZone,
                        decoration: const InputDecoration(
                          labelText: 'পছন্দের ডেলিভারি জোন',
                          prefixIcon: Icon(Icons.location_city_rounded),
                        ),
                        items: AppConstants.serviceZones
                            .map(
                              (String z) => DropdownMenuItem<String>(
                                value: z,
                                child: Text(z),
                              ),
                            )
                            .toList(),
                        onChanged: (String? value) {
                          if (value != null) {
                            setModalState(() => defaultZone = value);
                          }
                        },
                      ),
                      const SizedBox(height: 18),
                      PrimaryButton(
                        label: 'পরিবর্তন সেভ করুন',
                        icon: Icons.check_rounded,
                        onPressed: () => Navigator.of(sheetContext).pop(true),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    if (saved == true && context.mounted) {
      context.read<ProfileBloc>().add(
            ProfileInfoUpdated(
              name: nameCtrl.text,
              email: emailCtrl.text,
              avatarEmoji: avatar,
              defaultZone: defaultZone,
              smsNotifications: profile.smsNotifications,
            ),
          );
      context.read<AuthBloc>().add(const AuthSessionRefreshed());
    }
    nameCtrl.dispose();
    emailCtrl.dispose();
  }

  Future<void> _addOrEditAddress(
    BuildContext context,
    UserProfile profile, {
    DeliveryAddress? existing,
  }) async {
    final DeliveryAddress? result = await showAddressEditorSheet(
      context,
      initial: existing,
      defaultPhone: profile.phone,
      defaultRecipientName: profile.name,
    );
    if (result != null && context.mounted) {
      context.read<ProfileBloc>().add(ProfileAddressSaved(result));
    }
  }

  Future<void> _callSupport(BuildContext context) async {
    try {
      await launchUrl(
        Uri.parse('tel:${AppConstants.supportPhone}'),
        mode: LaunchMode.externalApplication,
      );
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('কল করা যায়নি।')),
        );
      }
    }
  }

  Future<void> _confirmSignOut(BuildContext context) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text('লগআউট করবেন?'),
        content: const Text(
          'লগআউট করলে বর্তমান কার্ট খালি হয়ে যাবে। আপনার সংরক্ষিত ঠিকানা নিরাপদ থাকবে।',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('না'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              minimumSize: const Size(100, 42),
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('লগআউট'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      context.read<CartBloc>().add(const CartClearRequested());
      context.read<ProfileBloc>().add(const ProfileCleared());
      context.read<AuthBloc>().add(const AuthSignedOut());
      Navigator.of(context).pushNamedAndRemoveUntil(
        AppRoutes.login,
        (Route<dynamic> route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('আমার প্রোফাইল')),
      body: BlocConsumer<ProfileBloc, ProfileState>(
        listenWhen: (ProfileState p, ProfileState c) =>
            p.message != c.message && c.message != null,
        listener: (BuildContext context, ProfileState state) {
          if (state.message != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message!)),
            );
          }
        },
        builder: (BuildContext context, ProfileState profileState) {
          final AuthState auth = context.watch<AuthBloc>().state;
          final UserProfile? profile = profileState.profile;
          if (profile == null) {
            if (auth.session != null &&
                profileState.status == ProfileStatus.initial) {
              context.read<ProfileBloc>().add(ProfileLoaded(auth.session!));
            }
            return const Center(child: CircularProgressIndicator());
          }

          final List<Order> orders = context.watch<OrdersBloc>().state.orders;
          final int deliveredCount = orders
              .where((Order o) => o.status == OrderStatus.delivered)
              .length;

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
            children: <Widget>[
              _ProfileHeroCard(
                profile: profile,
                onEdit: () => _editProfile(context, profile),
              ),
              const SizedBox(height: 14),
              Row(
                children: <Widget>[
                  Expanded(
                    child: _StatCard(
                      icon: Icons.receipt_long_rounded,
                      color: AppColors.primary,
                      value: BnFormat.digits(orders.length),
                      label: 'মোট অর্ডার',
                      onTap: () => context.read<ShellCubit>().setIndex(1),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _StatCard(
                      icon: Icons.check_circle_outline_rounded,
                      color: AppColors.success,
                      value: BnFormat.digits(deliveredCount),
                      label: 'সম্পন্ন',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _StatCard(
                      icon: Icons.location_on_outlined,
                      color: AppColors.accentWarm,
                      value: BnFormat.digits(profile.savedAddresses.length),
                      label: 'ঠিকানা',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text('সংরক্ষিত ঠিকানা', style: text.titleMedium),
                  ),
                  TextButton.icon(
                    onPressed: () => _addOrEditAddress(context, profile),
                    icon: const Icon(Icons.add_location_alt_outlined, size: 18),
                    label: const Text('নতুন যোগ করুন'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (profile.savedAddresses.isEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Text(
                    'এখনো কোনো ঠিকানা সংরক্ষিত নেই। GPS বা ম্যাপ পিনসহ ঠিকানা যোগ করুন।',
                  ),
                )
              else
                for (final DeliveryAddress address in profile.savedAddresses)
                  _AddressCard(
                    address: address,
                    onSetDefault: () {
                      if (address.id != null) {
                        context.read<ProfileBloc>().add(
                              ProfileDefaultAddressSelected(address.id!),
                            );
                      }
                    },
                    onEdit: () =>
                        _addOrEditAddress(context, profile, existing: address),
                    onDelete: () {
                      if (address.id != null) {
                        context
                            .read<ProfileBloc>()
                            .add(ProfileAddressDeleted(address.id!));
                      }
                    },
                    onOpenMap: address.hasCoordinates
                        ? () => LocationService.openInGoogleMaps(
                              address.latitude!,
                              address.longitude!,
                              label: '${address.label}: ${address.landmark}',
                            )
                        : null,
                  ),
              const SizedBox(height: 18),
              Text('সেটিংস ও সহায়তা', style: text.titleMedium),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: <Widget>[
                    SwitchListTile.adaptive(
                      activeThumbColor: AppColors.primary,
                      secondary: const Icon(
                        Icons.sms_outlined,
                        color: AppColors.primary,
                      ),
                      title: const Text('অর্ডার এসএমএস আপডেট'),
                      subtitle: const Text(
                        'রাইডার ও ডেলিভারি স্ট্যাটাস নোটিফিকেশন',
                      ),
                      value: profile.smsNotifications,
                      onChanged: (bool val) {
                        context.read<ProfileBloc>().add(
                              ProfileInfoUpdated(
                                name: profile.name,
                                email: profile.email,
                                avatarEmoji: profile.avatarEmoji,
                                defaultZone: profile.defaultZone,
                                smsNotifications: val,
                              ),
                            );
                      },
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(
                        Icons.map_outlined,
                        color: AppColors.primary,
                      ),
                      title: const Text('বীরগঞ্জ রেস্তোরাঁ ও কভারেজ ম্যাপ'),
                      subtitle: const Text(
                        'সব পার্টনার রেস্তোরাঁ ও আপনার GPS অবস্থান দেখুন',
                      ),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => RestaurantsMapPage(
                            restaurants: MockCatalogData.restaurants,
                            userLatitude: profile.defaultAddress?.latitude,
                            userLongitude: profile.defaultAddress?.longitude,
                          ),
                        ),
                      ),
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(
                        Icons.support_agent_rounded,
                        color: AppColors.accentWarm,
                      ),
                      title: const Text('হেল্পলাইন সাপোর্ট'),
                      subtitle: Text(BdPhone.pretty(AppConstants.supportPhone)),
                      trailing: const Icon(Icons.call_outlined),
                      onTap: () => _callSupport(context),
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(
                        Icons.logout_rounded,
                        color: AppColors.error,
                      ),
                      title: const Text(
                        'লগআউট',
                        style: TextStyle(
                          color: AppColors.error,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      onTap: () => _confirmSignOut(context),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ProfileHeroCard extends StatelessWidget {
  const _ProfileHeroCard({required this.profile, required this.onEdit});

  final UserProfile profile;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: <Color>[
            AppColors.primaryDeep,
            AppColors.primary,
            AppColors.secondary,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: AppColors.tealGlow,
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 62,
            height: 62,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.5),
                width: 2,
              ),
            ),
            child: Text(
              profile.avatarEmoji,
              style: const TextStyle(fontSize: 30),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  profile.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.titleLarge?.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 2),
                Text(
                  BdPhone.pretty(profile.phone),
                  style: text.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
                if (profile.email.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 2),
                  Text(
                    profile.email,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: text.labelSmall?.copyWith(
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                ],
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'ডিফল্ট জোন: ${profile.defaultZone}',
                    style: text.labelSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'সম্পাদনা',
            onPressed: onEdit,
            style: IconButton.styleFrom(
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.edit_outlined, size: 20),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
    this.onTap,
  });

  final IconData icon;
  final Color color;
  final String value;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: <Widget>[
              Icon(icon, color: color, size: 22),
              const SizedBox(height: 4),
              Text(
                value,
                style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              Text(label, style: text.labelSmall),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddressCard extends StatelessWidget {
  const _AddressCard({
    required this.address,
    required this.onSetDefault,
    required this.onEdit,
    required this.onDelete,
    this.onOpenMap,
  });

  final DeliveryAddress address;
  final VoidCallback onSetDefault;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback? onOpenMap;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: address.isDefault ? AppColors.primary : AppColors.border,
          width: address.isDefault ? 1.4 : 1,
        ),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: address.isDefault
                      ? AppColors.primarySoft
                      : AppColors.background,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  address.label,
                  style: text.labelSmall?.copyWith(
                    color: address.isDefault
                        ? AppColors.primaryDeep
                        : AppColors.slate60,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (address.isDefault) ...<Widget>[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.accentSoft,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'ডিফল্ট',
                    style: text.labelSmall?.copyWith(
                      color: AppColors.accentDark,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
              if (address.hasCoordinates) ...<Widget>[
                const SizedBox(width: 6),
                const Icon(
                  Icons.gps_fixed_rounded,
                  size: 14,
                  color: AppColors.primary,
                ),
              ],
              const Spacer(),
              IconButton(
                tooltip: 'সম্পাদনা',
                visualDensity: VisualDensity.compact,
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined, size: 18),
              ),
              IconButton(
                tooltip: 'মুছুন',
                visualDensity: VisualDensity.compact,
                onPressed: onDelete,
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  size: 18,
                  color: AppColors.error,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(address.recipientName, style: text.titleSmall),
          const SizedBox(height: 2),
          Text(address.oneLine, style: text.bodySmall),
          const SizedBox(height: 8),
          Row(
            children: <Widget>[
              if (!address.isDefault)
                TextButton(
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(0, 32),
                  ),
                  onPressed: onSetDefault,
                  child: const Text('ডিফল্ট করুন'),
                ),
              const Spacer(),
              if (onOpenMap != null)
                TextButton.icon(
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: const Size(0, 32),
                  ),
                  onPressed: onOpenMap,
                  icon: const Icon(Icons.map_outlined, size: 16),
                  label: const Text('Google Maps'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
