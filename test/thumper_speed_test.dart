import 'package:test/test.dart';
import 'package:thumper/src/thumper_speed.dart';

void main() {
  SpeedRange range;

  setUp(() {
    range = SpeedRange.fromInts(const [400, 1000, 30, 800, 100]);
  });

  test('periods', () {
    expect(range[0].period, equals(const Duration(milliseconds: 1000)));
    expect(range[1].period, equals(const Duration(milliseconds: 800)));
    expect(range[2].period, equals(const Duration(milliseconds: 400)));
    expect(range[3].period, equals(const Duration(milliseconds: 100)));
    expect(range[4].period, equals(const Duration(milliseconds: 30)));
  });

  test('unitInterval', () {
    expect(range[0].unitInterval, equals(0));
    expect(range[1].unitInterval, equals(0.25));
    expect(range[2].unitInterval, equals(0.5));
    expect(range[3].unitInterval, equals(0.75));
    expect(range[4].unitInterval, equals(1.0));
  });

  test('mapUnitIntervalToSpeed', () {
    expect(range.mapUnitIntervalToSpeed(-777).name, equals('slowest'));
    expect(range.mapUnitIntervalToSpeed(0).name, equals('slowest'));
    expect(range.mapUnitIntervalToSpeed(0.100).name, equals('slowest'));
    expect(range.mapUnitIntervalToSpeed(0.120).name, equals('slowest'));

    expect(range.mapUnitIntervalToSpeed(0.124).name, equals('slowest'));
    expect(range.mapUnitIntervalToSpeed(0.125).name, equals('mid_1_of_3'));
    expect(range.mapUnitIntervalToSpeed(0.126).name, equals('mid_1_of_3'));

    expect(range.mapUnitIntervalToSpeed(0.374).name, equals('mid_1_of_3'));
    expect(range.mapUnitIntervalToSpeed(0.375).name, equals('mid_2_of_3'));
    expect(range.mapUnitIntervalToSpeed(0.376).name, equals('mid_2_of_3'));

    expect(range.mapUnitIntervalToSpeed(0.624).name, equals('mid_2_of_3'));
    expect(range.mapUnitIntervalToSpeed(0.625).name, equals('mid_3_of_3'));
    expect(range.mapUnitIntervalToSpeed(0.626).name, equals('mid_3_of_3'));

    expect(range.mapUnitIntervalToSpeed(0.874).name, equals('mid_3_of_3'));
    expect(range.mapUnitIntervalToSpeed(0.875).name, equals('fastest'));
    expect(range.mapUnitIntervalToSpeed(0.876).name, equals('fastest'));

    expect(range.mapUnitIntervalToSpeed(1).name, equals('fastest'));
    expect(range.mapUnitIntervalToSpeed(777).name, equals('fastest'));
  });
}
