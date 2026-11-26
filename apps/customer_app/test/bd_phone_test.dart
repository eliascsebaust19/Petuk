import 'package:flutter_test/flutter_test.dart';
import 'package:foodie_birganj/core/utils/bd_phone.dart';

void main() {
  group('BdPhone.isValid', () {
    test('accepts valid Bangladeshi operator prefixes', () {
      expect(BdPhone.isValid('01712345678'), isTrue); // GP
      expect(BdPhone.isValid('01312345678'), isTrue); // GP
      expect(BdPhone.isValid('01812345678'), isTrue); // Robi
      expect(BdPhone.isValid('01912345678'), isTrue); // Banglalink
      expect(BdPhone.isValid('01512345678'), isTrue); // Teletalk
      expect(BdPhone.isValid('01612345678'), isTrue); // Airtel
    });

    test('rejects invalid numbers', () {
      expect(BdPhone.isValid('01212345678'), isFalse); // 012 unused
      expect(BdPhone.isValid('01012345678'), isFalse); // 010 unused
      expect(BdPhone.isValid('1712345678'), isFalse); // 10 digits
      expect(BdPhone.isValid('017123456789'), isFalse); // 12 digits
      expect(BdPhone.isValid('0171234567a'), isFalse); // non-digit
      expect(BdPhone.isValid(''), isFalse);
      expect(BdPhone.isValid('+8801712345678'), isFalse); // must be local
    });
  });

  group('conversions', () {
    test('local → E.164', () {
      expect(BdPhone.toE164('01712345678'), '+8801712345678');
    });

    test('E.164 → pretty display', () {
      expect(BdPhone.pretty('+8801712345678'), '01712-345678');
    });
  });

  group('form validator', () {
    test('null for valid input', () {
      expect(BdPhone.validate('01712345678'), isNull);
    });

    test('Bangla error for empty/invalid input', () {
      expect(BdPhone.validate(null), isNotNull);
      expect(BdPhone.validate('123'), isNotNull);
      expect(BdPhone.validate('01212345678'), isNotNull);
    });
  });
}
