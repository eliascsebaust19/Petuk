/// Central registry of bundled asset paths.
///
/// Keep every `Image.asset` reference pointing here so renames stay safe.
abstract final class AssetPaths {
  /// Petuk brand wordmark — Splash, Login and header branding.
  static const String logo = 'assets/images/logo.png';

  /// Animated Petuk rider — shown prominently on the phone login screen.
  static const String loginAnimation = 'assets/images/login_animation.gif';
}
