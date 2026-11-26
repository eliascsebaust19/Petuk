import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/router/app_router.dart';
import '../../../core/services/location_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/bd_phone.dart';
import '../../../core/utils/bn_format.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../data/models/delivery_address.dart';
import '../../../data/models/order.dart';
import '../../../data/models/user_profile.dart';
import '../../../data/repositories/order_repository.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../cart/bloc/cart_bloc.dart';
import '../../cart/bloc/cart_state.dart';
import '../../cart/widgets/bill_summary.dart';
import '../../location/pages/map_picker_page.dart';
import '../../profile/bloc/profile_bloc.dart';
import '../bloc/checkout_bloc.dart';
import '../widgets/payment_method_selector.dart';

/// Checkout: saved-address quick picker + GPS/Map pin + landmark form (FR-C04)
/// + payment toggle (COD / bKash / Nagad) + bill, ending in live tracking.
class CheckoutPage extends StatelessWidget {
  const CheckoutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<CheckoutBloc>(
      create: (BuildContext context) => CheckoutBloc(
        orderRepository: context.read<OrderRepository>(),
        cartBloc: context.read<CartBloc>(),
      ),
      child: const _CheckoutView(),
    );
  }
}

class _CheckoutView extends StatefulWidget {
  const _CheckoutView();

  @override
  State<_CheckoutView> createState() => _CheckoutViewState();
}

class _CheckoutViewState extends State<_CheckoutView> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _areaController;
  late final TextEditingController _landmarkController;
  late final TextEditingController _noteController;
  final TextEditingController _trxController = TextEditingController();

  String _zone = AppConstants.defaultZone;
  String _phone = '';
  double? _latitude;
  double? _longitude;
  bool _locating = false;
  bool _saveToProfile = true;
  String? _selectedAddressId;

  @override
  void initState() {
    super.initState();
    final AuthState auth = context.read<AuthBloc>().state;
    final UserProfile? profile = context.read<ProfileBloc>().state.profile;
    final DeliveryAddress? saved = profile?.defaultAddress;

    _phone = auth.session?.phone ?? profile?.phone ?? '';
    _nameController = TextEditingController(
      text: saved?.recipientName.isNotEmpty == true
          ? saved!.recipientName
          : (profile?.name.isNotEmpty == true
              ? profile!.name
              : (auth.session?.name ?? '')),
    );
    _areaController = TextEditingController(text: saved?.area ?? '');
    _landmarkController = TextEditingController(text: saved?.landmark ?? '');
    _noteController = TextEditingController(text: saved?.note ?? '');

    if (saved != null) {
      _selectedAddressId = saved.id;
      if (AppConstants.serviceZones.contains(saved.zone)) {
        _zone = saved.zone;
      }
      _latitude = saved.latitude;
      _longitude = saved.longitude;
    } else if (profile != null &&
        AppConstants.serviceZones.contains(profile.defaultZone)) {
      _zone = profile.defaultZone;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _areaController.dispose();
    _landmarkController.dispose();
    _noteController.dispose();
    _trxController.dispose();
    super.dispose();
  }

  void _applySavedAddress(DeliveryAddress address) {
    setState(() {
      _selectedAddressId = address.id;
      if (address.recipientName.isNotEmpty) {
        _nameController.text = address.recipientName;
      }
      if (AppConstants.serviceZones.contains(address.zone)) {
        _zone = address.zone;
      }
      _areaController.text = address.area;
      _landmarkController.text = address.landmark;
      _noteController.text = address.note;
      _latitude = address.latitude;
      _longitude = address.longitude;
    });
  }

  Future<void> _detectGps() async {
    setState(() => _locating = true);
    try {
      final GpsFix fix = await LocationService.fetchCurrentGps();
      if (!mounted) return;
      setState(() {
        _latitude = fix.latitude;
        _longitude = fix.longitude;
        _zone = fix.zone;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('GPS অবস্থান সেট হয়েছে • ${fix.zone}')),
      );
    } on LocationFailure catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  Future<void> _openMapPicker() async {
    final PickedLocation? picked = await Navigator.of(context).push<PickedLocation>(
      MaterialPageRoute<PickedLocation>(
        builder: (_) => MapPickerPage(
          initialLatitude: _latitude,
          initialLongitude: _longitude,
          initialZone: _zone,
        ),
      ),
    );
    if (picked != null && mounted) {
      setState(() {
        _latitude = picked.latitude;
        _longitude = picked.longitude;
        _zone = picked.zone;
      });
    }
  }

  void _placeOrder(BuildContext context) {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_saveToProfile && context.read<ProfileBloc>().state.profile != null) {
      context.read<ProfileBloc>().add(
            ProfileAddressSaved(
              DeliveryAddress(
                id: _selectedAddressId,
                recipientName: _nameController.text.trim(),
                phone: _phone,
                zone: _zone,
                area: _areaController.text.trim(),
                landmark: _landmarkController.text.trim(),
                note: _noteController.text.trim(),
                latitude: _latitude,
                longitude: _longitude,
                isDefault: true,
              ),
            ),
          );
    }
    context.read<CheckoutBloc>().add(
          CheckoutPlaceOrderRequested(
            recipientName: _nameController.text,
            phone: _phone,
            zone: _zone,
            area: _areaController.text,
            landmark: _landmarkController.text,
            note: _noteController.text,
            latitude: _latitude,
            longitude: _longitude,
            trxId: _trxController.text,
          ),
        );
  }

  String? _required(String? value, String message) {
    if ((value ?? '').trim().isEmpty) return message;
    return null;
  }

  Future<void> _pickZone() async {
    final String? zone = await showModalBottomSheet<String>(
      context: context,
      builder: (BuildContext sheetContext) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                'এলাকা / জোন বাছাই করুন',
                style: Theme.of(sheetContext).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              for (final String zone in AppConstants.serviceZones)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    zone == _zone
                        ? Icons.check_circle_rounded
                        : Icons.circle_outlined,
                    color: zone == _zone
                        ? AppColors.primary
                        : AppColors.slate40,
                    size: 20,
                  ),
                  title: Text(zone),
                  onTap: () => Navigator.of(sheetContext).pop(zone),
                ),
            ],
          ),
        ),
      ),
    );
    if (zone != null && mounted) {
      setState(() => _zone = zone);
    }
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final List<DeliveryAddress> savedAddresses =
        context.watch<ProfileBloc>().state.profile?.savedAddresses ??
            const <DeliveryAddress>[];

    return Scaffold(
      appBar: AppBar(title: const Text('চেকআউট')),
      body: BlocConsumer<CheckoutBloc, CheckoutState>(
        listener: (BuildContext context, CheckoutState state) {
          if (state.status == CheckoutStatus.success &&
              state.orderId != null) {
            Navigator.of(context).pushNamedAndRemoveUntil(
              AppRoutes.tracking,
              ModalRoute.withName(AppRoutes.home),
              arguments: state.orderId,
            );
          } else if (state.status == CheckoutStatus.failure &&
              state.error != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.error!)),
            );
          }
        },
        builder: (BuildContext context, CheckoutState checkout) {
          return BlocBuilder<CartBloc, CartState>(
            builder: (BuildContext context, CartState cart) {
              if (cart.isEmpty &&
                  checkout.status != CheckoutStatus.success) {
                return EmptyState(
                  emoji: '🛒',
                  title: 'কার্ট খালি',
                  message: 'অর্ডার করতে আগে খাবার যোগ করুন।',
                  actionLabel: 'ফিরে যান',
                  onAction: () => Navigator.of(context).pop(),
                );
              }
              return Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  children: <Widget>[
                    Text('ডেলিভারি ঠিকানা', style: text.titleMedium),
                    const SizedBox(height: 4),
                    Text(
                      'বীরগঞ্জে বাড়ির নম্বর নেই — তাই ল্যান্ডমার্ক ও ম্যাপ পিন দেওয়া সুবিধাজনক।',
                      style: text.bodySmall,
                    ),
                    if (savedAddresses.isNotEmpty) ...<Widget>[
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 40,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: savedAddresses.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 8),
                          itemBuilder: (BuildContext context, int index) {
                            final DeliveryAddress addr = savedAddresses[index];
                            final bool selected =
                                _selectedAddressId == addr.id;
                            return ChoiceChip(
                              avatar: Icon(
                                addr.hasCoordinates
                                    ? Icons.gps_fixed_rounded
                                    : Icons.bookmark_outline_rounded,
                                size: 15,
                                color: selected
                                    ? AppColors.primaryDeep
                                    : AppColors.slate60,
                              ),
                              label: Text('${addr.label} • ${addr.zone}'),
                              selected: selected,
                              selectedColor: AppColors.primarySoft,
                              onSelected: (_) => _applySavedAddress(addr),
                            );
                          },
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primaryTint,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.primarySoft),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          Row(
                            children: <Widget>[
                              const Icon(
                                Icons.map_rounded,
                                size: 18,
                                color: AppColors.primaryDark,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _latitude != null && _longitude != null
                                      ? 'GPS পিন: ${_latitude!.toStringAsFixed(4)}, ${_longitude!.toStringAsFixed(4)}'
                                      : 'দ্রুত ডেলিভারির জন্য GPS বা ম্যাপ পিন দিন',
                                  style: text.bodySmall?.copyWith(
                                    color: AppColors.primaryDeep,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              if (_latitude != null && _longitude != null)
                                TextButton(
                                  style: TextButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                    minimumSize: const Size(0, 28),
                                  ),
                                  onPressed: () =>
                                      LocationService.openInGoogleMaps(
                                    _latitude!,
                                    _longitude!,
                                    label: _landmarkController.text.isEmpty
                                        ? _zone
                                        : _landmarkController.text,
                                  ),
                                  child: const Text('Google Maps'),
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: <Widget>[
                              Expanded(
                                child: OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    minimumSize: const Size(0, 40),
                                    backgroundColor: AppColors.surface,
                                  ),
                                  onPressed: _locating ? null : _detectGps,
                                  icon: _locating
                                      ? const SizedBox(
                                          width: 14,
                                          height: 14,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Icon(
                                          Icons.my_location_rounded,
                                          size: 16,
                                        ),
                                  label: const Text('আমার GPS'),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    minimumSize: const Size(0, 40),
                                  ),
                                  onPressed: _openMapPicker,
                                  icon: const Icon(
                                    Icons.pin_drop_outlined,
                                    size: 16,
                                  ),
                                  label: const Text('ম্যাপে পিন করুন'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _nameController,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'আপনার নাম',
                        hintText: 'যেমন: রফিকুল ইসলাম',
                      ),
                      validator: (String? value) =>
                          _required(value, 'নাম লিখুন'),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      initialValue: BdPhone.pretty(_phone),
                      readOnly: true,
                      decoration: const InputDecoration(
                        labelText: 'মোবাইল (লগইন করা)',
                        prefixIcon: Icon(
                          Icons.phone_android_rounded,
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: _pickZone,
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'এলাকা / জোন',
                        ),
                        child: Row(
                          children: <Widget>[
                            Expanded(
                              child: Text(
                                _zone,
                                style: text.bodyLarge,
                              ),
                            ),
                            const Icon(
                              Icons.keyboard_arrow_down_rounded,
                              color: AppColors.slate60,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _areaController,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'রাস্তা / পাড়া / গ্রাম',
                        hintText: 'যেমন: কলেজ রোড, ২য় গলি',
                      ),
                      validator: (String? value) =>
                          _required(value, 'রাস্তা/পাড়ার নাম লিখুন'),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _landmarkController,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'ল্যান্ডমার্ক (আবশ্যক)',
                        hintText:
                            'যেমন: সোনালী ব্যাংকের পেছনে / পাইলট স্কুলের পাশে',
                        prefixIcon: Icon(
                          Icons.flag_rounded,
                          color: AppColors.primary,
                          size: 20,
                        ),
                      ),
                      validator: (String? value) => _required(
                        value,
                        'ল্যান্ডমার্ক ছাড়া রাইডার খুঁজে পাবে না',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _noteController,
                      maxLines: 2,
                      maxLength: 150,
                      decoration: const InputDecoration(
                        counterText: '',
                        labelText: 'অতিরিক্ত নির্দেশনা (ঐচ্ছিক)',
                        hintText: 'যেমন: বাসায় কেউ না থাকলে ফোন দিন',
                      ),
                    ),
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      activeColor: AppColors.primary,
                      controlAffinity: ListTileControlAffinity.leading,
                      title: Text(
                        'ঠিকানাটি প্রোফাইলে সেভ রাখুন',
                        style: text.bodySmall?.copyWith(
                          color: AppColors.slate,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      value: _saveToProfile,
                      onChanged: (bool? v) =>
                          setState(() => _saveToProfile = v ?? true),
                    ),
                    const SizedBox(height: 14),
                    Text('পেমেন্ট মাধ্যম', style: text.titleMedium),
                    const SizedBox(height: 12),
                    PaymentMethodSelector(
                      selected: checkout.paymentMethod,
                      onSelected: (PaymentMethod method) => context
                          .read<CheckoutBloc>()
                          .add(CheckoutPaymentMethodChanged(method)),
                    ),
                    if (checkout.paymentMethod.isWallet) ...<Widget>[
                      const SizedBox(height: 12),
                      _WalletInstructions(
                        method: checkout.paymentMethod,
                        amount: cart.grandTotal,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _trxController,
                        textCapitalization:
                            TextCapitalization.characters,
                        textInputAction: TextInputAction.done,
                        decoration: const InputDecoration(
                          labelText: 'ট্রানজেকশন আইডি (TrxID)',
                          hintText: 'যেমন: 9HK2A7X5P1',
                        ),
                        validator: (String? value) {
                          final String trx = (value ?? '').trim();
                          if (trx.length < 6) {
                            return 'সেন্ড মানির এসএমএসে পাওয়া TrxID দিন';
                          }
                          return null;
                        },
                      ),
                    ],
                    const SizedBox(height: 24),
                    Text('বিল', style: text.titleMedium),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: BillSummary(
                        subtotal: cart.subtotal,
                        deliveryFee: cart.deliveryFee,
                        discount: cart.discount,
                        grandTotal: cart.grandTotal,
                        couponCode: cart.coupon?.code,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'অর্ডার নিশ্চিত করতে আমাদের অপারেশন টিম ফোন দিতে পারে।',
                      style: text.labelSmall,
                    ),
                    const SizedBox(height: 16),
                    PrimaryButton(
                      label:
                          'অর্ডার নিশ্চিত করুন • ${BnFormat.taka(cart.grandTotal)}',
                      icon: Icons.check_circle_outline_rounded,
                      loading:
                          checkout.status == CheckoutStatus.submitting,
                      onPressed: () => _placeOrder(context),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

/// Phase-1 wallet flow: Send Money to the merchant number, then submit
/// the TrxID (verified manually by ops; Phase 2 automates via IPN).
class _WalletInstructions extends StatelessWidget {
  const _WalletInstructions({required this.method, required this.amount});

  final PaymentMethod method;
  final int amount;

  String get _number => method == PaymentMethod.bkash
      ? AppConstants.bkashMerchantNumber
      : AppConstants.nagadMerchantNumber;

  String get _ussd => method == PaymentMethod.bkash ? '*247#' : '*167#';

  Color get _color =>
      method == PaymentMethod.bkash ? AppColors.bkash : AppColors.nagad;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _color.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(Icons.qr_code_2_rounded, color: _color, size: 22),
              const SizedBox(width: 8),
              Text(
                '${method.labelBn} — সেন্ড মানি করুন',
                style: text.titleSmall?.copyWith(
                  color: _color,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '১. ${method.labelBn} অ্যাপ খুলুন বা $_ussd ডায়াল করুন\n'
            '২. "Send Money" বেছে নিন\n'
            '৩. নিচের নম্বরে ${BnFormat.taka(amount)} পাঠান\n'
            '৪. ফিরতি এসএমএসের TrxID নিচের ঘরে লিখুন',
            style: text.bodySmall?.copyWith(height: 1.7),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    _number,
                    style: text.titleMedium?.copyWith(
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'নম্বর কপি করুন',
                  visualDensity: VisualDensity.compact,
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: _number));
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('নম্বর কপি হয়েছে'),
                          duration: Duration(seconds: 1),
                        ),
                      );
                    }
                  },
                  icon: Icon(Icons.copy_rounded, size: 18, color: _color),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
