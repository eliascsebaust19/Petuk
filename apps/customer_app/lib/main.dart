import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'data/repositories/mock_auth_repository.dart';
import 'data/repositories/mock_catalog_repository.dart';
import 'data/repositories/mock_order_repository.dart';

/// Phase 1 entry point.
///
/// The mock repositories are complete, runnable implementations of the
/// SRS flows (demo OTP banner, bundled Birganj catalog, timed order
/// pipeline). When the central backend goes live, swap them here for
/// the API-backed implementations — no UI change required.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ),
  );
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  runApp(
    FoodieBirganjApp(
      authRepository: MockAuthRepository(prefs: prefs),
      catalogRepository: MockCatalogRepository(),
      orderRepository: MockOrderRepository(),
    ),
  );
}
