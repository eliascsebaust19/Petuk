import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/bd_phone.dart';
import '../../../core/utils/bn_format.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../data/models/order.dart';
import '../../../data/repositories/order_repository.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../cart/bloc/cart_bloc.dart';
import '../../cart/bloc/cart_state.dart';
import '../../cart/widgets/bill_summary.dart';
import '../bloc/checkout_bloc.dart';
import '../widgets/payment_method_selector.dart';

/// Checkout: landmark-first address form (FR-C04) + payment toggle
/// (COD / bKash / Nagad) + bill, ending in live order tracking.
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
  final TextEditingController _areaController = TextEditingController();
  final TextEditingController _landmarkController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  final TextEditingController _trxController = TextEditingController();

  String _zone = AppConstants.defaultZone;
  String _phone = '';

  @override
  void initState() {
    super.initState();
    final AuthState auth = context.read<AuthBloc>().state;
    _phone = auth.session?.phone ?? '';
    _nameController =
        TextEditingController(text: auth.session?.name ?? '');
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

  void _placeOrder(BuildContext context) {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    context.read<CheckoutBloc>().add(
          CheckoutPlaceOrderRequested(
            recipientName: _nameController.text,
            phone: _phone,
            zone: _zone,
            area: _areaController.text,
            landmark: _landmarkController.text,
            note: _noteController.text,
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
                      'বীরগঞ্জে বাড়ির নম্বর নেই — তাই ল্যান্ডমার্ক দেওয়া আবশ্যক।',
                      style: text.bodySmall,
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
                    const SizedBox(height: 24),
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
