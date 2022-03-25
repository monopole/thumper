import 'package:test/test.dart';
import 'package:thumper/data/fruit.dart';
import 'package:thumper/src/power.dart';
import 'package:thumper/src/spectrum.dart';
import 'package:thumper/src/thumper_state.dart';

void main() {
  late Spectrum spectrum;
  late ThumperState<Fruit> aState;

  setUp(() {
    spectrum = Spectrum.fromPeriodsInMilliSec(const [400, 1000, 30, 800, 100]);
    aState = ThumperState<Fruit>.init(Fruit.peach, spectrum[0]);
  });

  test('init', () {
    expect(aState, ThumperState<Fruit>(spectrum[0], Power.reset, Fruit.peach));
  });

  test('toString', () {
    expect(ThumperState<Fruit>.init(Fruit.peach, spectrum[0]).toString(),
        'Power.reset:lowest:Fruit.peach:0');
  });

  test('pauseAndResume', () {
    var s = aState;
    expect(s.power, Power.reset);
    s = s.resume();
    expect(s.power, Power.running);
    s = s.resume();
    expect(s.power, Power.running);
    s = s.pause();
    expect(s.power, Power.idle);
    s = s.pause();
    expect(s.power, Power.idle);
    s = s.resume();
    expect(s.power, Power.running);
  });
}
