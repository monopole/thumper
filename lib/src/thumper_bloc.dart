import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:pedantic/pedantic.dart';
import 'frequency.dart';
import 'power.dart';
import 'spectrum.dart';
import 'thumper_event.dart';
import 'thumper_state.dart';

/// ThumperBloc maps ThumperEvent to ThumperState<E>.
///
/// This bloc contains and manages a timer that sends events to this (the bloc),
/// so as to emit states at a particular frequency.  The bloc's constructor
/// accepts a factory function to make the timer.
///
/// Each state contains an E.  To get them, the block requires an Iterable<E>.
///
/// The iterable must be non-empty (at least one E), so that the initial state
/// can be defined.  The iterable is used to make an iterator, and if the
/// iterator runs out, the iterable is used to make another iterator to start
/// over again.
class ThumperBloc<E> extends Bloc<ThumperEvent, ThumperState<E>> {
  /// ThumperBloc accepts
  /// - A non-empty Iterable<E>.
  /// - A [Spectrum] of allowed thumper frequency values.
  /// - A factory func that accepts a frequency and returns a Stream<bool>.
  ///   Said stream should emit booleans (of irrelevant value) at the given
  ///   frequency. The stream is used by the bloc to control thumping frequency.
  ///   A test can inject a stream that emits on test events.
  ///   The boolean values aren't consulted; only their appearance on
  ///   the stream matters.
  ThumperBloc(
    this._iterable,
    this._spectrum,
    this._timerFactoryFunc,
  )   : assert(_iterable.isNotEmpty, 'iterable cannot be empty'),
        assert(_spectrum != null, 'must specify spectrum'),
        assert(_timerFactoryFunc != null, 'must specify a timer factory'),
        _autoThumpsRemaining = _defaultInitialThumpCountdown;

  /// Make a [ThumperBloc]] from an iterable and a reasonable default spectrum.
  factory ThumperBloc.fromIterable(Iterable<E> iterable) => ThumperBloc(
      iterable,
      Spectrum.fromPeriodsInMilliSec(const [1000, 500, 250, 100, 50, 25]),
      makeThumperWithFrequency);

  static const int _defaultInitialThumpCountdown = 1000;

  /// An arbitrary boolean sent on the thumper stream.
  /// It doesn't matter if this is true or false.
  static const _arbitraryBoolean = true;

  final Stream<bool> Function(Frequency) _timerFactoryFunc;

  /// Holds the stuff to emit.
  final Iterable<E> _iterable;

  final Spectrum _spectrum;

  /// The number of divisions that a slider widget would need to represent
  /// the set of frequencies available.
  int get numDivisions => _spectrum.numDivisions;

  Iterator<E> _iterator;
  StreamSubscription<bool> _thumperSubscription;

  /// How many automatic thumps remaining before automatic thumping should stop?
  int _autoThumpsRemaining;

  /// Makes a stream that can be used to control the rate of
  /// automatic thumps.
  static Stream<bool> makeThumperWithFrequency(Frequency f) =>
      Stream.periodic(f.period, (k) => _arbitraryBoolean);

  @override
  Future<void> close() {
    _cancelSubscription();
    return super.close();
  }

  void _subscribeToThumper(Frequency s) {
    _thumperSubscription = _timerFactoryFunc(s)
        .listen((x) => add(ThumperEvent.thumpedAutomatically));
  }

  @override
  ThumperState<E> get initialState {
    _iterator = _iterable.iterator;
    _thump();
    return ThumperState.init(_iterator.current, _spectrum.slowest);
  }

  /// Use this to tell the thumper that the frequency should change.
  void reactToFrequencyValue(double value) {
    final s = _spectrum.mapUnitIntervalToFrequency(value);
    if (s > state.frequency) {
      add(ThumperEvent.increased);
    } else if (s < state.frequency) {
      add(ThumperEvent.decreased);
    }
  }

  // Iterate one step.  If done, restart.
  void _thump() {
    if (_iterator.moveNext()) {
      return;
    }
    // The constructor asserted a non-empty iterator, so we can call .moveNext
    // and be assured that .current will return a valid E.
    _iterator = _iterable.iterator;
    // ignore: cascade_invocations
    _iterator.moveNext();
  }

  @override
  Stream<ThumperState<E>> mapEventToState(ThumperEvent event) async* {
    if (event == ThumperEvent.rewound) {
      yield* _mapRewoundToState();
    } else if (event == ThumperEvent.paused) {
      yield* _mapPausedToState();
    } else if (event == ThumperEvent.resumed) {
      yield* _mapResumedToState();
    } else if (event == ThumperEvent.increased) {
      yield* _mapIncreasedToState();
    } else if (event == ThumperEvent.decreased) {
      yield* _mapDecreasedToState();
    } else if (event == ThumperEvent.thumpedAutomatically) {
      yield* _mapThumpedAutomaticallyToState();
    } else if (event == ThumperEvent.thumpedManually) {
      yield* _mapThumpedManuallyToState();
    } else {
      throw ArgumentError('cannot handle $event');
    }
  }

  Stream<ThumperState<E>> _mapResumedToState() async* {
    if (state.power == Power.running) {
      return;
    }
    if (_thumperSubscription == null) {
      _subscribeToThumper(state.frequency);
    } else {
      if (_thumperSubscription.isPaused) {
        _thumperSubscription.resume();
      } else {
        // complain that it's already running?
      }
    }
    yield state.resume();
  }

  Stream<ThumperState<E>> _mapPausedToState() async* {
    if (state.power == Power.idle) {
      return;
    }
    if (_thumperSubscription != null) {
      if (_thumperSubscription.isPaused) {
        // complain that it's already paused?
      } else {
        _thumperSubscription.pause();
      }
    }
    yield state.pause();
  }

  Stream<ThumperState<E>> _mapIncreasedToState() async* {
    if (state.frequency.isHighest) {
      return;
    }
    final s = _newStateAtFrequency(state.frequency.higher);
    unawaited(_restartThumperIfRunning(s.frequency));
    yield s;
  }

  Stream<ThumperState<E>> _mapDecreasedToState() async* {
    if (state.frequency.isLowest) {
      return;
    }
    final s = _newStateAtFrequency(state.frequency.lower);
    unawaited(_restartThumperIfRunning(s.frequency));
    yield s;
  }

  ThumperState<E> _newStateAtFrequency(Frequency f) =>
      ThumperState<E>(f, state.power, state.thing, state.thumpCount);

  /// If stream exists, just cancel it.  If it should be running,
  /// restart it at the given frequency.
  Future<void> _restartThumperIfRunning(Frequency newFrequency) async {
    if (_thumperSubscription != null) {
      _cancelSubscription();
      if (state.power == Power.running) {
        _subscribeToThumper(newFrequency);
      }
    }
  }

  void _cancelSubscription() {
    if (_thumperSubscription == null) {
      return;
    }
    final cancelMe = _thumperSubscription;
    unawaited(cancelMe.cancel());
    // Set this to null to signal it needs recreation.
    _thumperSubscription = null;
  }

  Stream<ThumperState<E>> _mapThumpedAutomaticallyToState() async* {
    _thump();
    if (_autoThumpsRemaining > 1) {
      _autoThumpsRemaining--;
      yield ThumperState<E>(state.frequency, state.power, _iterator.current,
          state.thumpCount + 1);
      return;
    }
    _thumperSubscription?.pause();
    _autoThumpsRemaining = _defaultInitialThumpCountdown;
    yield ThumperState<E>(
        state.frequency, Power.idle, _iterator.current, state.thumpCount + 1);
  }

  Stream<ThumperState<E>> _mapThumpedManuallyToState() async* {
    _thump();
    if (state.power == Power.reset) {
      _autoThumpsRemaining = _defaultInitialThumpCountdown;
      yield ThumperState<E>(
          state.frequency, Power.idle, _iterator.current, state.thumpCount + 1);
      return;
    }
    yield ThumperState<E>(
        state.frequency, state.power, _iterator.current, state.thumpCount + 1);
  }

  Stream<ThumperState<E>> _mapRewoundToState() async* {
    _cancelSubscription();
    yield initialState;
  }
}
