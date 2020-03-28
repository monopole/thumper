import 'package:test/test.dart';
import 'package:thumper/src/spectrum.dart';

void main() {
  Spectrum s;

  setUp(() {
    s = Spectrum.fromPeriodsInMilliSec(const [400, 1000, 30, 800, 100]);
  });

  test('ctor errors', () {
    expect(
          () => Spectrum.fromPeriodsInMilliSec(const []),
      throwsA(
        isA<ArgumentError>().having(
              (error) => error.message,
          'should throw on empty arg',
          'a spectrum requires at least two unique periods',
        ),
      ),
    );
    expect(
          () => Spectrum.fromPeriodsInMilliSec(const [400, 400]),
      throwsA(
        isA<ArgumentError>().having(
              (error) => error.message,
          'removing repeated args might leave nothing',
          'a spectrum requires at least two unique periods',
        ),
      ),
    );
  });

  test('periods', () {
    expect(s[0].period, equals(const Duration(milliseconds: 1000)));
    expect(s[1].period, equals(const Duration(milliseconds: 800)));
    expect(s[2].period, equals(const Duration(milliseconds: 400)));
    expect(s[3].period, equals(const Duration(milliseconds: 100)));
    expect(s[4].period, equals(const Duration(milliseconds: 30)));
  });

  test('unitInterval', () {
    expect(s[0].unitInterval, equals(0));
    expect(s[1].unitInterval, equals(0.25));
    expect(s[2].unitInterval, equals(0.5));
    expect(s[3].unitInterval, equals(0.75));
    expect(s[4].unitInterval, equals(1.0));
  });

  test('mapUnitIntervalToFrequency', () {
    expect(s.mapUnitIntervalToFrequency(-777).name, equals('lowest'));
    expect(s.mapUnitIntervalToFrequency(0).name, equals('lowest'));
    expect(s.mapUnitIntervalToFrequency(0.100).name, equals('lowest'));
    expect(s.mapUnitIntervalToFrequency(0.120).name, equals('lowest'));

    expect(s.mapUnitIntervalToFrequency(0.124).name, equals('lowest'));
    expect(s.mapUnitIntervalToFrequency(0.125).name, equals('mid_1_of_3'));
    expect(s.mapUnitIntervalToFrequency(0.126).name, equals('mid_1_of_3'));

    expect(s.mapUnitIntervalToFrequency(0.374).name, equals('mid_1_of_3'));
    expect(s.mapUnitIntervalToFrequency(0.375).name, equals('mid_2_of_3'));
    expect(s.mapUnitIntervalToFrequency(0.376).name, equals('mid_2_of_3'));

    expect(s.mapUnitIntervalToFrequency(0.624).name, equals('mid_2_of_3'));
    expect(s.mapUnitIntervalToFrequency(0.625).name, equals('mid_3_of_3'));
    expect(s.mapUnitIntervalToFrequency(0.626).name, equals('mid_3_of_3'));

    expect(s.mapUnitIntervalToFrequency(0.874).name, equals('mid_3_of_3'));
    expect(s.mapUnitIntervalToFrequency(0.875).name, equals('highest'));
    expect(s.mapUnitIntervalToFrequency(0.876).name, equals('highest'));

    expect(s.mapUnitIntervalToFrequency(1).name, equals('highest'));
    expect(s.mapUnitIntervalToFrequency(777).name, equals('highest'));
  });
}
