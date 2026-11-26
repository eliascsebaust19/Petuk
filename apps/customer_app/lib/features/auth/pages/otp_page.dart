import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/asset_paths.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/bd_phone.dart';
import '../../../core/utils/bn_format.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../data/models/otp_challenge.dart';
import '../../../data/repositories/auth_repository.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/otp_bloc.dart';
import '../widgets/otp_input.dart';

/// OTP verification step: 6-box input, 60-second resend countdown,
/// 3-wrong-attempts lockout (QA-01) and a demo-code banner while the
/// mock SMS gateway is active.
class OtpPage extends StatelessWidget {
  const OtpPage({super.key, required this.challenge});

  final OtpChallenge challenge;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<OtpBloc>(
      create: (BuildContext context) => OtpBloc(
        authRepository: context.read<AuthRepository>(),
        challenge: challenge,
      )..add(const OtpStarted()),
      child: _OtpView(challenge: challenge),
    );
  }
}

class _OtpView extends StatelessWidget {
  const _OtpView({required this.challenge});

  final OtpChallenge challenge;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: const Text('ওটিপি যাচাই'),
      ),
      body: SafeArea(
        child: BlocConsumer<OtpBloc, OtpState>(
          listener: (BuildContext context, OtpState state) {
            if (state.status == OtpStatus.success) {
              context.read<AuthBloc>().add(const AuthSessionRefreshed());
              Navigator.of(context).pushNamedAndRemoveUntil(
                AppRoutes.home,
                (Route<dynamic> route) => false,
              );
            }
          },
          builder: (BuildContext context, OtpState state) {
            final bool inputEnabled = !state.isLocked &&
                !state.isBusy &&
                state.status != OtpStatus.success;
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Image.asset(
                    AssetPaths.loginAnimation,
                    height: 140,
                    fit: BoxFit.contain,
                    gaplessPlayback: true,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'ওটিপি দিন',
                    textAlign: TextAlign.center,
                    style: text.headlineSmall,
                  ),
                  const SizedBox(height: 6),
                  Text.rich(
                    TextSpan(
                      children: <InlineSpan>[
                        TextSpan(
                          text: '${BdPhone.pretty(challenge.phone)} ',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.slate,
                          ),
                        ),
                        const TextSpan(
                          text: 'নম্বরে পাঠানো ৬ ডিজিটের কোডটি দিন',
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                    style: text.bodyMedium
                        ?.copyWith(color: AppColors.slate60),
                  ),
                  const SizedBox(height: 24),
                  OtpInput(
                    length: AppConstants.otpLength,
                    code: state.code,
                    enabled: inputEnabled,
                    hasError:
                        state.status == OtpStatus.failure || state.isLocked,
                    onChanged: (String code) =>
                        context.read<OtpBloc>().add(OtpCodeChanged(code)),
                  ),
                  if (state.error != null) ...<Widget>[
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
                  if (state.devCode != null) ...<Widget>[
                    const SizedBox(height: 12),
                    InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () async {
                        await Clipboard.setData(
                          ClipboardData(text: state.devCode!),
                        );
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('ডেমো কোড কপি হয়েছে'),
                              duration: Duration(seconds: 1),
                            ),
                          );
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.accentSoft,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: <Widget>[
                            const Icon(
                              Icons.science_outlined,
                              color: AppColors.accentDark,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'ডেমো মোড — এসএমএস গেটওয়ে চালু হলে কোডটি এসএমএসে যাবে। আপাতত কোড: ${state.devCode} (ট্যাপ করে কপি করুন)',
                                style: text.bodySmall?.copyWith(
                                  color: AppColors.accentDark,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  PrimaryButton(
                    label: 'যাচাই করুন',
                    loading: state.status == OtpStatus.verifying,
                    onPressed: inputEnabled &&
                            state.code.length == AppConstants.otpLength
                        ? () => context
                            .read<OtpBloc>()
                            .add(const OtpVerifyRequested())
                        : null,
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: state.isLocked
                        ? Text(
                            'আবার চেষ্টা করা যাবে ${BnFormat.countdown(state.lockSeconds)} পরে',
                            style: text.bodyMedium?.copyWith(
                              color: AppColors.error,
                              fontWeight: FontWeight.w600,
                            ),
                          )
                        : state.resendSeconds > 0
                            ? Text(
                                'আবার পাঠান ${BnFormat.countdown(state.resendSeconds)}',
                                style: text.bodyMedium?.copyWith(
                                  color: AppColors.slate60,
                                ),
                              )
                            : TextButton.icon(
                                onPressed: state.canResend
                                    ? () => context
                                        .read<OtpBloc>()
                                        .add(const OtpResendRequested())
                                    : null,
                                icon: const Icon(Icons.refresh_rounded),
                                label: const Text('আবার ওটিপি পাঠান'),
                              ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('নম্বর বদলান'),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
