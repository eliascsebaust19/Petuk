#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# One-time platform scaffold for the Foodie Birganj customer app.
#
# The repo ships the complete Dart code, assets and platform overlays.
# This script generates the android/ and ios/ runner projects with the
# Flutter tool (they are machine-generated, so they are not committed),
# applies the Petuk overlays, and fetches packages.
#
# Requirements: Flutter (latest stable) on PATH.
# Usage:        ./tool/bootstrap.sh
# ---------------------------------------------------------------------------
set -euo pipefail
cd "$(dirname "$0")/.."

if ! command -v flutter >/dev/null 2>&1; then
  echo "ERROR: Flutter SDK not found on PATH. Install from https://docs.flutter.dev/get-started/install" >&2
  exit 1
fi

echo "==> Generating android/ and ios/ runner projects (existing files are kept)…"
flutter create . --project-name foodie_birganj --org com.petuk --platforms android,ios

echo "==> Applying platform overlays (app name, INTERNET permission, tel queries)…"
cp platform_overlays/android/AndroidManifest.xml android/app/src/main/AndroidManifest.xml
cp platform_overlays/ios/Info.plist ios/Runner/Info.plist

# flutter create may drop in the default counter-app widget test;
# this project ships real tests in test/ instead.
rm -f test/widget_test.dart

echo "==> Fetching packages…"
flutter pub get

echo ""
echo "Done ✅"
echo "  Run app:   flutter run"
echo "  Run tests: flutter test"
echo "  Analyze:   flutter analyze"
