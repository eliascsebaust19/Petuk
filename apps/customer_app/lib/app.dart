import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/constants/app_constants.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'data/repositories/auth_repository.dart';
import 'data/repositories/catalog_repository.dart';
import 'data/repositories/order_repository.dart';
import 'data/repositories/profile_repository.dart';
import 'features/auth/bloc/auth_bloc.dart';
import 'features/cart/bloc/cart_bloc.dart';
import 'features/cart/widgets/cart_conflict_listener.dart';
import 'features/orders/bloc/orders_bloc.dart';
import 'features/profile/bloc/profile_bloc.dart';

/// Enables touch + mouse + trackpad drag scrolling across all platforms
/// (so horizontal category chips & banners drag smoothly in Chrome too).
class _AppScrollBehavior extends MaterialScrollBehavior {
  const _AppScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => <PointerDeviceKind>{
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
        PointerDeviceKind.stylus,
      };
}

/// Root widget: repository injection → app-wide blocs → MaterialApp.
///
/// [CartBloc] lives ABOVE the navigator so the cart badge, the sticky
/// menu bar and the global restaurant-conflict dialog all share one
/// source of truth from any route.
class FoodieBirganjApp extends StatelessWidget {
  const FoodieBirganjApp({
    super.key,
    required this.authRepository,
    required this.catalogRepository,
    required this.orderRepository,
    required this.profileRepository,
  });

  final AuthRepository authRepository;
  final CatalogRepository catalogRepository;
  final OrderRepository orderRepository;
  final ProfileRepository profileRepository;

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: <RepositoryProvider<dynamic>>[
        RepositoryProvider<AuthRepository>.value(value: authRepository),
        RepositoryProvider<CatalogRepository>.value(
          value: catalogRepository,
        ),
        RepositoryProvider<OrderRepository>.value(value: orderRepository),
        RepositoryProvider<ProfileRepository>.value(value: profileRepository),
      ],
      child: MultiBlocProvider(
        providers: <BlocProvider<dynamic>>[
          BlocProvider<AuthBloc>(
            create: (BuildContext context) => AuthBloc(
              authRepository: context.read<AuthRepository>(),
            )..add(const AuthStarted()),
          ),
          BlocProvider<ProfileBloc>(
            create: (BuildContext context) => ProfileBloc(
              profileRepository: context.read<ProfileRepository>(),
            ),
          ),
          BlocProvider<CartBloc>(
            create: (BuildContext context) => CartBloc(
              catalogRepository: context.read<CatalogRepository>(),
            ),
          ),
          BlocProvider<OrdersBloc>(
            create: (BuildContext context) => OrdersBloc(
              orderRepository: context.read<OrderRepository>(),
            )..add(const OrdersStarted()),
          ),
        ],
        child: BlocListener<AuthBloc, AuthState>(
          listenWhen: (AuthState p, AuthState c) =>
              p.status != c.status || p.session?.phone != c.session?.phone,
          listener: (BuildContext context, AuthState auth) {
            if (auth.status == AuthStatus.authenticated &&
                auth.session != null) {
              context.read<ProfileBloc>().add(ProfileLoaded(auth.session!));
            } else if (auth.status == AuthStatus.unauthenticated) {
              context.read<ProfileBloc>().add(const ProfileCleared());
            }
          },
          child: MaterialApp(
            title: AppConstants.appName,
            debugShowCheckedModeBanner: false,
            scrollBehavior: const _AppScrollBehavior(),
            theme: AppTheme.light,
            navigatorKey: AppRouter.navigatorKey,
            scaffoldMessengerKey: AppRouter.scaffoldMessengerKey,
            onGenerateRoute: AppRouter.onGenerateRoute,
            initialRoute: AppRoutes.splash,
            builder: (BuildContext context, Widget? child) =>
                CartConflictListener(
              child: child ?? const SizedBox.shrink(),
            ),
          ),
        ),
      ),
    );
  }
}
