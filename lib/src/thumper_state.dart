import 'package:meta/meta.dart';
import 'frequency.dart';
import 'power.dart';

/// ThumperState<E> is an immutable composite of E, [Frequency], [Power] and
/// the [thumpCount].
///
/// The E is some instance that came from the Iterable<E>
/// held by ThumperBloc<E>.
@immutable
class ThumperState<E> {
  /// Make a new state.
  const ThumperState(this.frequency, this.power, this.thing,
      [this.thumpCount = 0]);

  /// Make an initial state.
  factory ThumperState.init(E e, Frequency s) =>
      ThumperState(s, Power.reset, e);

  /// The current frequency.
  final Frequency frequency;

  /// Current power setting.
  final Power power;

  /// The current instance of E from the iterator.
  final E thing;

  /// How many thumps since the last reset?
  final int thumpCount;

  @override
  String toString() => '$power:$frequency:$thing:$thumpCount';

  @override
  bool operator ==(dynamic other) =>
      identical(this, other) ||
      frequency == other.frequency &&
          power == other.power &&
          thing == other.thing &&
          thumpCount == other.thumpCount;

  @override
  int get hashCode =>
      (thing.hashCode * thumpCount * frequency.hashCode) ^ (power.index + 1);

  /// Make a paused version of this.
  ThumperState<E> pause() =>
      ThumperState<E>(frequency, Power.idle, thing, thumpCount);

  /// Make a resumed version of this.
  ThumperState<E> resume() =>
      ThumperState<E>(frequency, Power.running, thing, thumpCount);
}
