import 'package:meta/meta.dart';
import 'frequency.dart';

/// Spectrum is an immutable, sorted list of unique periods
/// (or equivalently, instances of [Frequency]), with
/// some utility functions for moving up and down spectrum
/// and mapping to values in a unitary range (for a Slider).
@immutable
class Spectrum {
  /// Make a [Spectrum] with the given set of periods.
  const Spectrum._(this._periods, this.numDivisions, this._halfDivision);

  /// Interprets the int arguments as periods in milliseconds.
  factory Spectrum.fromPeriodsInMilliSec(List<int> original) {
    final lst = _validate(original);
    final periods = List<Duration>.generate(
        lst.length, (i) => Duration(milliseconds: lst[i]));
    final nDiv = periods.length - 1;
    return Spectrum._(
        List.unmodifiable(periods), nDiv, 0.5 * ((_unity - _zero) / nDiv));
  }

  // Remove repeats, demand at least two values, and sort result.
  static List<int> _validate(List<int> lst) {
    final exists = <int>{};
    for (var i = 0; i < lst.length; i++) {
      if (!exists.contains(lst[i])) {
        exists.add(lst[i]);
      }
    }
    if (exists.length < 2) {
      throw ArgumentError('a spectrum requires at least two unique periods');
    }
    // sort in _decreasing_ order (slow frequency to fast)
    return List<int>.from(exists)..sort((a, b) => b.compareTo(a));
  }

  /// A slider has this many divisions
  /// (one less than the number of stopping positions).
  final int numDivisions;
  final List<Duration> _periods;
  final double _halfDivision;

  /// Offer the frequency at its index.
  Frequency operator [](int k) => Frequency(this, k);

  /// A printable name for the frequency.
  String name(Frequency f) => f.index <= 0
      ? 'lowest'
      : (f.index >= numDivisions
          ? 'highest'
          : 'mid_${f.index}_of_${numDivisions - 1}');

  /// Returns the argument's period.
  Duration period(Frequency f) => _periods[f.index];

  /// Return a faster frequency.
  Frequency higher(Frequency f) => this[f.index + 1];

  /// True if this frequency is the fastest.
  bool isHighest(Frequency f) => f.index == numDivisions;

  /// Return the fastest frequency.
  Frequency get fastest => this[numDivisions];

  /// Return a slower frequency.
  Frequency lower(Frequency f) => this[f.index - 1];

  /// True if this frequency is the slowest.
  bool isLowest(Frequency f) => f.index == 0;

  /// Return the slowest frequency.
  Frequency get slowest => this[0];

  /// Minimum of unitary range.
  static const _zero = 0;

  /// Maximum of unitary range.
  static const _unity = 1;

  /// Maps given frequency to a double in the unitary range.
  double mapFrequencyToUnitInterval(Frequency f) => f.index * 2 * _halfDivision;

  /// Maps a double in the unitary range to a frequency in this spectrum.
  Frequency mapUnitIntervalToFrequency(double x) => this[_spectralIndex(x)];

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
  int _spectralIndex(double unitaryRange) => (unitaryRange <= _zero)
      ? 0
      : (unitaryRange >= _unity)
          ? numDivisions
          : ((unitaryRange + _halfDivision) * numDivisions).floor();
}
