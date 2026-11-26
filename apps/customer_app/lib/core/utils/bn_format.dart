import 'package:intl/intl.dart';

/// Bangla-first formatting helpers: Bengali digits, ৳ money, countdowns
/// and human day-part times ("দুপুর ১:০৫").
abstract final class BnFormat {
  static const List<String> _bnDigits = <String>[
    '০', '১', '২', '৩', '৪', '৫', '৬', '৭', '৮', '৯', //
  ];

  static const List<String> _months = <String>[
    'জানুয়ারি', 'ফেব্রুয়ারি', 'মার্চ', 'এপ্রিল', 'মে', 'জুন', //
    'জুলাই', 'আগস্ট', 'সেপ্টেম্বর', 'অক্টোবর', 'নভেম্বর', 'ডিসেম্বর', //
  ];

  static final NumberFormat _grouped = NumberFormat('#,##0');

  /// Converts ASCII digits inside [value] to Bengali digits.
  /// `125` → `১২৫`, `1:05` → `১:০৫`.
  static String digits(Object value) {
    final String text = value.toString();
    final StringBuffer buffer = StringBuffer();
    for (final int code in text.runes) {
      if (code >= 0x30 && code <= 0x39) {
        buffer.write(_bnDigits[code - 0x30]);
      } else {
        buffer.writeCharCode(code);
      }
    }
    return buffer.toString();
  }

  /// `350` → `৳৩৫০`, `-40` → `−৳৪০`, `1200` → `৳১,২০০`.
  static String taka(num amount) {
    final String sign = amount < 0 ? '−' : '';
    return '$sign৳${digits(_grouped.format(amount.abs()))}';
  }

  /// Seconds → `ম:সে` countdown with Bengali digits. `65` → `১:০৫`.
  static String countdown(int seconds) {
    final int safe = seconds < 0 ? 0 : seconds;
    final int m = safe ~/ 60;
    final int s = safe % 60;
    return digits('$m:${s.toString().padLeft(2, '0')}');
  }

  /// `DateTime` → `দুপুর ১:০৫`.
  static String time(DateTime t) {
    final int hour12 = t.hour % 12 == 0 ? 12 : t.hour % 12;
    final String minute = t.minute.toString().padLeft(2, '0');
    return '${dayPart(t.hour)} ${digits('$hour12:$minute')}';
  }

  /// Bangla day part for an hour of day (0–23).
  static String dayPart(int hour) {
    if (hour < 5) return 'রাত';
    if (hour < 12) return 'সকাল';
    if (hour < 16) return 'দুপুর';
    if (hour < 18) return 'বিকাল';
    if (hour < 20) return 'সন্ধ্যা';
    return 'রাত';
  }

  /// `DateTime` → `২৬ নভেম্বর`.
  static String date(DateTime t) => '${digits(t.day)} ${_months[t.month - 1]}';

  /// `DateTime` → `২৬ নভেম্বর, দুপুর ১:০৫`.
  static String dateTime(DateTime t) => '${date(t)}, ${time(t)}';
}
