/// Helpers for Bangladeshi mobile numbers (SRS FR-C01).
///
/// Local format: 11 digits starting `01`, second digit 3–9
/// (013 GP, 014 Banglalink, 015 Teletalk, 016 Airtel, 017 GP,
/// 018 Robi, 019 Banglalink). E.164 format: `+8801XXXXXXXXX`.
abstract final class BdPhone {
  static final RegExp _localPattern = RegExp(r'^01[3-9]\d{8}$');

  /// Whether [input] is a valid 11-digit Bangladeshi mobile number.
  static bool isValid(String input) => _localPattern.hasMatch(input.trim());

  /// `01712345678` → `+8801712345678`.
  static String toE164(String local) {
    final String digits = local.trim();
    assert(isValid(digits), 'Call only with a validated local number.');
    return '+880${digits.substring(1)}';
  }

  /// `+8801712345678` → `01712-345678` (for display).
  static String pretty(String e164) {
    final String local =
        e164.startsWith('+880') ? '0${e164.substring(4)}' : e164;
    if (local.length != 11) return e164;
    return '${local.substring(0, 5)}-${local.substring(5)}';
  }

  /// Form validator with Bangla error messages. Returns `null` when valid.
  static String? validate(String? value) {
    final String input = (value ?? '').trim();
    if (input.isEmpty) return 'মোবাইল নম্বর দিন';
    if (input.length != 11 || !input.startsWith('01')) {
      return '১১ ডিজিটের নম্বর দিন (যেমন: 017XXXXXXXX)';
    }
    if (!_localPattern.hasMatch(input)) {
      return 'সঠিক বাংলাদেশি নম্বর দিন (013–019 দিয়ে শুরু)';
    }
    return null;
  }
}
