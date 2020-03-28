import 'package:meta/meta.dart';

/// [ThumperSpeed] is an immutable speed associated with a [SpeedRange].
@immutable
class ThumperSpeed {
  /// Make a speed with the given parent range and position in that range.
  const ThumperSpeed(this._range, this.index);

  /// [SpeedRange] parent to this [ThumperSpeed] instance.
  final SpeedRange _range;

  /// Index into [_range].
  final int index;

  /// The Thumper's period (inverse frequency).
  Duration get period => _range.period(this);

  @override
  String toString() => name;

  @override
  bool operator ==(dynamic other) => index == other.index;

  /// Speed comparator.
  bool operator >(ThumperSpeed other) => index > other.index;

  /// Speed comparator.
  bool operator <(ThumperSpeed other) => index < other.index;

  @override
  int get hashCode => index.hashCode;

  /// Speed's name, as derived from its range.
  String get name => _range.name(this);

  /// The speed one step slower than this in the common range.
  ThumperSpeed get slower => _range.slower(this);

  /// The speed one step faster than this in the common range.
  ThumperSpeed get faster => _range.faster(this);

  /// True if this is the fastest speed in its range.
  bool get isFastest => _range.isFastest(this);

  /// True if this is the slowest speed in its range.
  bool get isSlowest => _range.isSlowest(this);

  /// Value of this speed in the unitary range [0..1].
  double get unitInterval => _range.mapSpeedToUnitInterval(this);
}

/// SpeedRange is an immutable, sorted list of [ThumperSpeed] with
/// some handy mapping functions.
@immutable
class SpeedRange {
  /// Make a range with the given set of periods.
  /// TODO: allow custom speed names.
  /// TODO: assure each entry unique.
  const SpeedRange._(this._periods, this.numDivisions, this._halfDivision);

  /// Interprets the int arguments as period lengths in milliseconds.
  factory SpeedRange.fromPeriodsInMilliSec(List<int> original) {
    if (original.length < 2) {
      throw ArgumentError('making a range requires at least two elements');
    }
    // sort in decreasing order (slow speed to fast)
    final lst = List<int>.from(original)..sort((a, b) => b.compareTo(a));

    final periods = List<Duration>(lst.length);
    for (var i = 0; i < lst.length; i++) {
      periods[i] = Duration(milliseconds: lst[i]);
    }
    final nDiv = periods.length - 1;
    return SpeedRange._(
        List.unmodifiable(periods), nDiv, 0.5 * ((_unity - _zero) / nDiv));
  }

  /// A slider has this many divisions
  /// (one less than the number of stopping positions).
  final int numDivisions;
  final List<Duration> _periods;
  final double _halfDivision;

  /// Offer the speed at its index.
  ThumperSpeed operator [](int k) => ThumperSpeed(this, k);

  /// A printable name for the speed.
  String name(ThumperSpeed s) => s.index <= 0
      ? 'slowest'
      : (s.index >= numDivisions
          ? 'fastest'
          : 'mid_${s.index}_of_${numDivisions - 1}');

  /// Speed's period.
  Duration period(ThumperSpeed s) => _periods[s.index];

  /// Return a faster speed.
  ThumperSpeed faster(ThumperSpeed s) => this[s.index + 1];

  /// True if this speed is the fastest.
  bool isFastest(ThumperSpeed s) => s.index == numDivisions;

  /// Return the fastest speed.
  ThumperSpeed get fastest => this[numDivisions];

  /// Return a slower speed.
  ThumperSpeed slower(ThumperSpeed s) => this[s.index - 1];

  /// True if this speed is the slowest.
  bool isSlowest(ThumperSpeed s) => s.index == 0;

  /// Return the slowest speed.
  ThumperSpeed get slowest => this[0];

  /// Minimum of unitary range.
  static const _zero = 0;

  /// Maximum of unitary range.
  static const _unity = 1;

  /// Maps given speed to a double in the unitary range.
  double mapSpeedToUnitInterval(ThumperSpeed s) => s.index * 2 * _halfDivision;

  /// Maps a double in the unitary range to a speed in the range.
  ThumperSpeed mapUnitIntervalToSpeed(double x) => this[_speedIndex(x)];

  /// Say we want to use a slider with ticks to allow value selection.
  /// We use a slider, but don't want a continuous range of values;
  /// rather we just want a distinct value per tick.  The slider should
  /// snap to the nearest tick when released.
  ///
  /// Say we want five values. That means five ticks. A slider
  /// maps its movement to a double in the unitary range; we
  /// must map this to the index 0, 1, 2, 3, or 4.
  ///
  ///
  ///           0.0           0.25          0.5           0.75          1.0
  ///            |    0.125    |    0.375    |    0.625    |    0.875    |
  ///                   .             .             .             .
  ///  5 ticks:  |-------------|-------------|-------------|-------------|
  ///    index:  0      .      1      .      2      .      3      .      4
  ///         slowest   .    mid_1    .    mid_2    .    mid_3    .   fastest
  ///
  /// So the mapping we want is
  ///
  ///            x < 0.125 : slowest
  ///   0.125 <= x < 0.375 : faster1 ...
  ///
  /// etc., which is given by the following slightly paranoid function:
  int _speedIndex(double unitaryRange) => (unitaryRange <= _zero)
      ? 0
      : (unitaryRange >= _unity)
          ? numDivisions
          : ((unitaryRange + _halfDivision) * numDivisions).floor();
}
