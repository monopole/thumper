import 'package:test/test.dart';
import 'package:thumper/data/fruit.dart';
import 'package:thumper/src/thumper_speed.dart';
import 'package:thumper/src/thumper_state.dart';

void main() {
  SpeedRange range;
  ThumperState aState;

  setUp(() {
    range = SpeedRange.fromInts(const [400, 1000, 30, 800, 100]);
    aState = ThumperState<Fruit>.init(Fruit.peach, range[0]);
  });

  test('init', () {
    expect(
        aState, ThumperState<Fruit>(range[0], ThumperPower.reset, Fruit.peach));
  });

  test('toString', () {
    expect(ThumperState<Fruit>.init(Fruit.peach, range[0]).toString(),
        'ThumperPower.reset:slowest:Fruit.peach:0');
  });

  test('pauseAndResume', () {
    var s = aState;
    expect(s.power, ThumperPower.reset);
    s = s.resume();
    expect(s.power, ThumperPower.on);
    s = s.resume();
    expect(s.power, ThumperPower.on);
    s = s.pause();
    expect(s.power, ThumperPower.off);
    s = s.pause();
    expect(s.power, ThumperPower.off);
    s = s.resume();
    expect(s.power, ThumperPower.on);
  });
}
