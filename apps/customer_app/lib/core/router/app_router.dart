import 'package:flutter/material.dart';

import '../../data/models/otp_challenge.dart';
import '../../data/models/restaurant.dart';
import '../../features/auth/pages/otp_page.dart';
import '../../features/auth/pages/phone_login_page.dart';
import '../../features/auth/pages/splash_page.dart';
import '../../features/cart/pages/cart_page.dart';
import '../../features/checkout/pages/checkout_page.dart';
import '../../features/home/pages/main_shell.dart';
import '../../features/home/pages/restaurant_menu_page.dart';
import '../../features/orders/pages/order_tracking_page.dart';
import '../../features/orders/pages/orders_page.dart';

abstract final class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';
  static const String otp = '/otp';
  static const String home = '/home';
  static const String restaurant = '/restaurant';
  static const String cart = '/cart';
  static const String checkout = '/checkout';
  static const String orders = '/orders';
  static const String tracking = '/tracking';
}

/// Central named-route table + global navigator/messenger keys (used by
/// the app-level cart conflict dialog and snackbars).
abstract final class AppRouter {
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();
  static final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.splash:
        return _fade(const SplashPage(), settings);
      case AppRoutes.login:
        return _fade(const PhoneLoginPage(), settings);
      case AppRoutes.otp:
        return _slide(
          OtpPage(challenge: settings.arguments! as OtpChallenge),
          settings,
        );
      case AppRoutes.home:
        return _fade(const MainShell(), settings);
      case AppRoutes.restaurant:
        return _slide(
          RestaurantMenuPage(restaurant: settings.arguments! as Restaurant),
          settings,
        );
      case AppRoutes.cart:
        return _slide(const CartPage(), settings);
      case AppRoutes.checkout:
        return _slide(const CheckoutPage(), settings);
      case AppRoutes.orders:
        return _slide(const OrdersPage(), settings);
      case AppRoutes.tracking:
        return _slide(
          OrderTrackingPage(orderId: settings.arguments! as String),
          settings,
        );
      default:
        return _fade(const SplashPage(), settings);
    }
  }

  static PageRouteBuilder<dynamic> _fade(Widget page, RouteSettings settings) {
    return PageRouteBuilder<dynamic>(
      settings: settings,
      transitionDuration: const Duration(milliseconds: 350),
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder:
          (_, Animation<double> animation, __, Widget child) =>
              FadeTransition(opacity: animation, child: child),
    );
  }

  static PageRouteBuilder<dynamic> _slide(
    Widget page,
    RouteSettings settings,
  ) {
    return PageRouteBuilder<dynamic>(
      settings: settings,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder:
          (_, Animation<double> animation, __, Widget child) {
        final CurvedAnimation curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.04),
            end: Offset.zero,
          ).animate(curved),
          child: FadeTransition(opacity: curved, child: child),
        );
      },
    );
  }
}
