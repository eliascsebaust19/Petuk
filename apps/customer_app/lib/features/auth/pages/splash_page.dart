import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/asset_paths.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../bloc/auth_bloc.dart';

/// Brand splash: `assets/images/logo.png` fades in smoothly, holds for
/// a beat, then routes by session state (home vs phone login).
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );
  late final Animation<double> _fade = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOut,
  );
  late final Animation<double> _scale = Tween<double>(begin: 0.92, end: 1)
      .animate(
    CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
  );

  bool _minDelayDone = false;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    _controller.forward();
    Future<void>.delayed(const Duration(milliseconds: 2000)).then((_) {
      if (!mounted) return;
      _minDelayDone = true;
      _maybeNavigate(context.read<AuthBloc>().state);
    });
  }

  void _maybeNavigate(AuthState state) {
    if (_navigated || !_minDelayDone) return;
    if (state.status == AuthStatus.unknown) return;
    _navigated = true;
    Navigator.of(context).pushReplacementNamed(
      state.status == AuthStatus.authenticated
          ? AppRoutes.home
          : AppRoutes.login,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (BuildContext context, AuthState state) =>
          _maybeNavigate(state),
      child: Scaffold(
        backgroundColor: AppColors.surface,
        body: Center(
          child: FadeTransition(
            opacity: _fade,
            child: ScaleTransition(
              scale: _scale,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Image.asset(AssetPaths.logo, width: 240),
                  const SizedBox(height: 20),
                  Text(
                    AppConstants.tagline,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: AppColors.slate60),
                  ),
                  const SizedBox(height: 48),
                  const SizedBox(
                    width: 26,
                    height: 26,
                    child: CircularProgressIndicator(strokeWidth: 2.2),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
