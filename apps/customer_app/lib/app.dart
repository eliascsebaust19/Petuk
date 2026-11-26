import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/constants/app_constants.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'data/repositories/auth_repository.dart';
import 'data/repositories/catalog_repository.dart';
import 'data/repositories/order_repository.dart';
import 'features/auth/bloc/auth_bloc.dart';
import 'features/cart/bloc/cart_bloc.dart';
import 'features/cart/widgets/cart_conflict_listener.dart';
import 'features/orders/bloc/orders_bloc.dart';

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
  });

  final AuthRepository authRepository;
  final CatalogRepository catalogRepository;
  final OrderRepository orderRepository;

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: <RepositoryProvider<dynamic>>[
        RepositoryProvider<AuthRepository>.value(value: authRepository),
        RepositoryProvider<CatalogRepository>.value(
          value: catalogRepository,
        ),
        RepositoryProvider<OrderRepository>.value(value: orderRepository),
      ],
      child: MultiBlocProvider(
        providers: <BlocProvider<dynamic>>[
          BlocProvider<AuthBloc>(
            create: (BuildContext context) => AuthBloc(
              authRepository: context.read<AuthRepository>(),
            )..add(const AuthStarted()),
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
        child: MaterialApp(
          title: AppConstants.appName,
          debugShowCheckedModeBanner: false,
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
    );
  }
}
