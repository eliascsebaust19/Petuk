import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/asset_paths.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/bd_phone.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../data/repositories/auth_repository.dart';
import '../bloc/phone_login_cubit.dart';

/// Phone step of the OTP auth flow (FR-C01).
///
/// `assets/images/login_animation.gif` (the Petuk rider) is featured at
/// the top; the input pre-fills the +880 prefix and accepts exactly the
/// 11-digit Bangladeshi format.
class PhoneLoginPage extends StatelessWidget {
  const PhoneLoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<PhoneLoginCubit>(
      create: (BuildContext context) => PhoneLoginCubit(
        authRepository: context.read<AuthRepository>(),
      ),
      child: const _PhoneLoginView(),
    );
  }
}

class _PhoneLoginView extends StatefulWidget {
  const _PhoneLoginView();

  @override
  State<_PhoneLoginView> createState() => _PhoneLoginViewState();
}

class _PhoneLoginViewState extends State<_PhoneLoginView> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _phoneController = TextEditingController();

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  void _submit(BuildContext context) {
    FocusScope.of(context).unfocus();
    if (_formKey.currentState?.validate() ?? false) {
      context.read<PhoneLoginCubit>().submit(_phoneController.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: BlocConsumer<PhoneLoginCubit, PhoneLoginState>(
          listener: (BuildContext context, PhoneLoginState state) async {
            if (state.status == PhoneLoginStatus.sent &&
                state.challenge != null) {
              await Navigator.of(context).pushNamed(
                AppRoutes.otp,
                arguments: state.challenge,
              );
              if (context.mounted) {
                context.read<PhoneLoginCubit>().reset();
              }
            }
          },
          builder: (BuildContext context, PhoneLoginState state) {
            final bool submitting =
                state.status == PhoneLoginStatus.submitting;
            return LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        const SizedBox(height: 24),
                        // Login animation — prominent at the top.
                        Image.asset(
                          AssetPaths.loginAnimation,
                          height: 210,
                          fit: BoxFit.contain,
                          gaplessPlayback: true,
                        ),
                        const SizedBox(height: 8),
                        Center(
                          child: Image.asset(AssetPaths.logo, width: 150),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'লগইন করুন',
                          textAlign: TextAlign.center,
                          style: text.headlineSmall,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'আপনার ১১ ডিজিটের মোবাইল নম্বর দিন —\nআমরা ৬ ডিজিটের ওটিপি পাঠাবো।',
                          textAlign: TextAlign.center,
                          style: text.bodyMedium
                              ?.copyWith(color: AppColors.slate60),
                        ),
                        const SizedBox(height: 24),
                        Form(
                          key: _formKey,
                          child: TextFormField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            textInputAction: TextInputAction.done,
                            autofillHints: const <String>[
                              AutofillHints.telephoneNumber,
                            ],
                            maxLength: 11,
                            autovalidateMode:
                                AutovalidateMode.onUserInteraction,
                            inputFormatters: <TextInputFormatter>[
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1.2,
                            ),
                            decoration: InputDecoration(
                              counterText: '',
                              labelText: 'মোবাইল নম্বর',
                              hintText: '01XXXXXXXXX',
                              prefixIconConstraints: const BoxConstraints(),
                              prefixIcon: Padding(
                                padding:
                                    const EdgeInsets.only(left: 16),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: <Widget>[
                                    const Text(
                                      '+880',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Container(
                                      width: 1,
                                      height: 24,
                                      color: AppColors.border,
                                    ),
                                    const SizedBox(width: 12),
                                  ],
                                ),
                              ),
                            ),
                            validator: BdPhone.validate,
                            onFieldSubmitted: (_) => _submit(context),
                          ),
                        ),
                        if (state.status == PhoneLoginStatus.failure &&
                            state.error != null) ...<Widget>[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.errorSoft,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: <Widget>[
                                const Icon(
                                  Icons.error_outline_rounded,
                                  color: AppColors.error,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    state.error!,
                                    style: text.bodySmall?.copyWith(
                                      color: AppColors.error,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 20),
                        PrimaryButton(
                          label: 'ওটিপি পাঠান',
                          icon: Icons.sms_outlined,
                          loading: submitting,
                          onPressed: () => _submit(context),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'চালিয়ে গেলে আপনি আমাদের শর্তাবলি ও গোপনীয়তা নীতিতে সম্মত হচ্ছেন।',
                          textAlign: TextAlign.center,
                          style: text.labelSmall,
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
