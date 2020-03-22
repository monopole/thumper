/// [ThumperSpeed] is an immutable speed associated with a [SpeedRange].
class ThumperSpeed {
  final int index;
  final SpeedRange _range;

  const ThumperSpeed(int i, SpeedRange r)
      : index = i,
        _range = r;

  Duration get period => _range.duration(this);

  @override
  String toString() => name;

  @override
  bool operator ==(o) => index == o.index;

  bool operator >(o) => index > o.index;

  bool operator <(o) => index < o.index;

  @override
  int get hashCode => index.hashCode;

  String get name => _range.name(this);

  /// Return a speed slower than this.
  ThumperSpeed get slower => _range.slower(this);

  /// Return a speed faster than this.
  ThumperSpeed get faster => _range.faster(this);

  bool get isFastest => _range.isFastest(this);
  bool get isSlowest => _range.isSlowest(this);

  /// Value of this speed in the unitary range [0..1].
  double get unitInterval => _range.mapSpeedToUnitInterval(this);
}

/// SpeedRange is an immutable, sorted list of [ThumperSpeed] with
/// some handy mapping functions.
class SpeedRange {
  final List<Duration> _periods;
  final int numDivisions;
  final double _halfDivision;

  ThumperSpeed operator [](int k) => ThumperSpeed(k, this);

  /// TODO: allow custom speed names.  Make sure everything is unique.
  const SpeedRange(List<Duration> p, int nd, double hd)
      : _periods = p,
        numDivisions = nd,
        _halfDivision = hd;

  /// Interprets the ints as lengths, in milliseconds, of periods.
  factory SpeedRange.fromInts(List<int> original) {
    if (original.length < 2) {
      throw "making a range requires at least two elements";
    }
    final lst = List<int>.from(original);
    lst.sort((a, b) => b.compareTo(a)); // decreasing

    final periods = List<Duration>(lst.length);
    for (int i = 0; i < lst.length; i++) {
      periods[i] = Duration(milliseconds: lst[i]);
    }
    final int nDiv = periods.length - 1;
    return SpeedRange(
        List.unmodifiable(periods), nDiv, 0.5 * ((unity - zero) / nDiv));
  }

  String name(ThumperSpeed s) => s.index <= 0
      ? "slowest"
      : (s.index >= numDivisions
          ? "fastest"
          : "mid_${s.index}_of_${numDivisions - 1}");

  Duration duration(ThumperSpeed s) => _periods[s.index];

  ThumperSpeed faster(ThumperSpeed s) => this[s.index + 1];
  bool isFastest(ThumperSpeed s) => s.index == numDivisions;
  ThumperSpeed get fastest => this[numDivisions];

  ThumperSpeed slower(ThumperSpeed s) => this[s.index - 1];
  bool isSlowest(ThumperSpeed s) => s.index == 0;
  ThumperSpeed get slowest => this[0];

  /// Minimum of unitary range.
  static final zero = 0;

  /// Maximum of unitary range.
  static final unity = 1;

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
  int _speedIndex(double unitaryRange) => (unitaryRange <= zero)
      ? 0
      : (unitaryRange >= unity)
          ? numDivisions
          : ((unitaryRange + _halfDivision) * numDivisions).floor();
}
