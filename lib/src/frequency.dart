import 'package:meta/meta.dart';
import 'spectrum.dart';

/// [Frequency] is an immutable position within some immutable [Spectrum].
@immutable
class Frequency {
  /// Make a frequency with the given parent spectrum
  /// and position in that spectrum.
  const Frequency(this._spectrum, this.index);

  /// [Spectrum] parent to this [Frequency] instance.
  final Spectrum _spectrum;

  /// Index into [_spectrum].
  final int index;

  @override
  String toString() => name;

  @override
  bool operator ==(dynamic other) => index == other.index;

  /// Frequency comparator.  This works because of the sort in [Spectrum].
  bool operator >(Frequency other) => index > other.index;

  /// Frequency comparator.  This works because of the sort in [Spectrum].
  bool operator <(Frequency other) => index < other.index;

  @override
  int get hashCode => index.hashCode;

  /// Period is inverse frequency.
  Duration get period => _spectrum.period(this);

  /// Frequency's name, as derived from its spectrum.
  String get name => _spectrum.name(this);

  /// The frequency one step slower than this in the parent spectrum.
  Frequency get lower => _spectrum.lower(this);

  /// The frequency one step faster than this in the parent spectrum.
  Frequency get higher => _spectrum.higher(this);

  /// True if this is the highest frequency in its spectrum.
  bool get isHighest => _spectrum.isHighest(this);

  /// True if this is the lowest frequency in its spectrum.
  bool get isLowest => _spectrum.isLowest(this);

  /// Value of this frequency in the unitary spectrum [0..1].
  double get unitInterval => _spectrum.mapFrequencyToUnitInterval(this);
}

