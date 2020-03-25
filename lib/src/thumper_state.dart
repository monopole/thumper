import 'package:meta/meta.dart';
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
@immutable
class ThumperState<E> {
  /// Make a new state.
  const ThumperState(this.speed, this.power, this.thing, [this.thumpCount = 0]);

  /// Make an initial state.
  factory ThumperState.init(E e, ThumperSpeed s) =>
      ThumperState(s, ThumperPower.reset, e);

  /// The current speed.
  final ThumperSpeed speed;

  /// Current power setting.
  final ThumperPower power;

  /// The current instance of E from the iterator.
  final E thing;

  /// How many thumps since the last reset?
  final int thumpCount;

  @override
  String toString() => '$power:$speed:$thing:$thumpCount';

  @override
  bool operator ==(dynamic other) =>
      identical(this, other) ||
      speed == other.speed &&
          power == other.power &&
          thing == other.thing &&
          thumpCount == other.thumpCount;

  @override
  int get hashCode =>
      (thing.hashCode * thumpCount * speed.hashCode) ^ (power.index + 1);

  /// Make a paused version of this.
  ThumperState<E> pause() =>
      ThumperState<E>(speed, ThumperPower.off, thing, thumpCount);

  /// Make a resumed version of this.
  ThumperState<E> resume() =>
      ThumperState<E>(speed, ThumperPower.on, thing, thumpCount);
}
