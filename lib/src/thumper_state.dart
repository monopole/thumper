import 'thumper_speed.dart';

/// Power status of thumper.
enum ThumperPower { reset, off, on }

/// ThumperState<E> snapshots an iteration controller for some Iterator<E>.
///
/// It's a combination of instances of E, [ThumperSpeed], ThumperPower and the
/// iteration count.
///
/// With this controller one can either manually step through the iteration, or
/// automatically "thump" the iteration at a particular speed.  The state
/// can be used to draw the controller showing pause, play and speed buttons
/// and the current instance of E.
///
/// The term 'thumper' is from Dune by Frank Herbert.
///
class ThumperState<E> {
  factory ThumperState.init(E e, ThumperSpeed s) =>
      ThumperState(s, ThumperPower.reset, e, 0);

  final ThumperSpeed speed;
  final ThumperPower power;
  final E thing;
  final int thumpCount;

  ThumperState(ThumperSpeed s, ThumperPower p, E e, [int c = 0])
      : speed = s,
        power = p,
        thing = e,
        thumpCount = c;

  @override
  String toString() => "$power:$speed:$thing:$thumpCount";

  @override
  bool operator ==(o) =>
      identical(this, o) ||
      speed == o.speed &&
          power == o.power &&
          thing == o.thing &&
          thumpCount == o.thumpCount;

  @override
  int get hashCode =>
      (thing.hashCode * thumpCount * speed.hashCode) ^ (power.index + 1);

  ThumperState<E> pause() =>
      ThumperState<E>(speed, ThumperPower.off, thing, thumpCount);

  ThumperState<E> resume() =>
      ThumperState<E>(speed, ThumperPower.on, thing, thumpCount);
}
