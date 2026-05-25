import 'package:flutter_test/flutter_test.dart';
import 'package:murabbi_mobile/domain/value_objects/hex_color.dart';

void main() {
  group('HexColor', () {
    test('accepts a canonical #RRGGBB value', () {
      expect(HexColor('#3A6B8C').value, '#3A6B8C');
    });

    test('accepts lowercase hex digits', () {
      expect(HexColor('#a1b2c3').value, '#a1b2c3');
    });

    test('throws on missing leading #', () {
      expect(() => HexColor('3A6B8C'), throwsArgumentError);
    });

    test('throws on short form (#RGB)', () {
      expect(() => HexColor('#3A6'), throwsArgumentError);
    });

    test('throws on alpha form (#RRGGBBAA)', () {
      expect(() => HexColor('#3A6B8CFF'), throwsArgumentError);
    });

    test('throws on non-hex characters', () {
      expect(() => HexColor('#XY1234'), throwsArgumentError);
    });

    test('throws on free-form name (CSS keyword)', () {
      expect(() => HexColor('red'), throwsArgumentError);
    });

    test('throws on empty string', () {
      expect(() => HexColor(''), throwsArgumentError);
    });

    test('throws on whitespace-only string', () {
      expect(() => HexColor('   '), throwsArgumentError);
    });

    test('two instances with the same value are equal', () {
      expect(HexColor('#3A6B8C'), equals(HexColor('#3A6B8C')));
    });

    test('comparison is case-sensitive (preserve user-entered casing)', () {
      // We do not normalise to uppercase: round-tripping should not flip
      // the hex digits the design system uses (cf. Category seed values).
      expect(HexColor('#a1b2c3'), isNot(equals(HexColor('#A1B2C3'))));
    });

    test('toString returns the value', () {
      expect(HexColor('#3A6B8C').toString(), '#3A6B8C');
    });
  });
}
