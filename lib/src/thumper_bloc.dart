import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:pedantic/pedantic.dart';
import 'thumper_event.dart';
import 'thumper_speed.dart';
import 'thumper_state.dart';

/// ThumperBloc maps ThumperEvent to ThumperState<E>.
///
/// This bloc contains and manages a timer that sends events to this (the bloc),
/// so as to emit states at a particular rate.  The bloc accepts a factory
/// function to make the timer.
///
/// Each state contains an E.  To get them, the block requires an Iterable<E>.
/// The iterable must be non-empty (at least one E), so that the initial state
/// can be defined.  The iterable is used to make an iterator, and if the
/// iterator runs out, the iterable is used to make another iterator to start
/// over again.
class ThumperBloc<E> extends Bloc<ThumperEvent, ThumperState<E>> {
  /// ThumperBloc accepts
  /// - A non-empty Iterable<E>.
  /// - A [SpeedRange].
  /// - A factory func that accepts a speed and returns a Stream<bool>.
  ///   The factory should make a stream that emits bools, presumably
  ///   at the given frequency for use as a timer.  Nothing here assures
  ///   this behavior - a test can inject a stream that emits on test
  ///   events.  The bool values aren't consulted; only their appearance on
  ///   the stream matters.
  ThumperBloc(
    Iterable<E> iterable,
    SpeedRange range,
    Stream<bool> Function(ThumperSpeed) stFactoryFunc,
  )   : assert(iterable.isNotEmpty && range != null && stFactoryFunc != null,
            'nonsensical ctor args'),
        _iterable = iterable,
        _speedRange = range,
        _timerFactoryFunc = stFactoryFunc,
        _autoThumpsRemaining = _defaultInitialThumpCountdown;

  /// Make a bloc from an iterable.
  factory ThumperBloc.fromIterable(Iterable<E> iterable) => ThumperBloc(
      iterable,
      SpeedRange.fromPeriodsInMilliSec(const [1000, 500, 250, 100, 50, 25]),
      makeThumperWithSpeed);

  static const int _defaultInitialThumpCountdown = 1000;

  /// An arbitrary boolean sent on the thumper stream.
  /// Exposed for use in tests.
  static const irrelevantBoolValue = true;

  final Stream<bool> Function(ThumperSpeed) _timerFactoryFunc;

  /// Holds the stuff to emit.
  final Iterable<E> _iterable;

  final SpeedRange _speedRange;

  /// A slider has this many divisions
  /// (one less than the number of stopping positions).
  int get numDivisions => _speedRange.numDivisions;

  Iterator<E> _iterator;
  StreamSubscription<bool> _thumperSubscription;

  /// How many automatic thumps remaining before automatic thumping should stop?
  int _autoThumpsRemaining;

  /// Makes a stream that can be used to control the rate of
  /// automatic thumps.
  static Stream<bool> makeThumperWithSpeed(ThumperSpeed speed) =>
      Stream.periodic(speed.period, (k) => irrelevantBoolValue);

  @override
  Future<void> close() {
    _cancelSubscription();
    return super.close();
  }

  void _subscribeToThumper(ThumperSpeed s) {
    _thumperSubscription = _timerFactoryFunc(s)
        .listen((x) => add(ThumperEvent.thumpedAutomatically));
  }

  @override
  ThumperState<E> get initialState {
    _iterator = _iterable.iterator;
    _thump();
    return ThumperState.init(_iterator.current, _speedRange.slowest);
  }

  /// Send an event if the slider changes.
  void reactToSpeedValue(double value) {
    final s = _speedRange.mapUnitIntervalToSpeed(value);
    if (s > state.speed) {
      add(ThumperEvent.accelerated);
    } else if (s < state.speed) {
      add(ThumperEvent.decelerated);
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
    } else if (event == ThumperEvent.accelerated) {
      yield* _mapAcceleratedToState();
    } else if (event == ThumperEvent.decelerated) {
      yield* _mapDeceleratedToState();
    } else if (event == ThumperEvent.thumpedAutomatically) {
      yield* _mapThumpedAutomaticallyToState();
    } else if (event == ThumperEvent.thumpedManually) {
      yield* _mapThumpedManuallyToState();
    } else {
      throw ArgumentError('cannot handle $event');
    }
  }

  Stream<ThumperState<E>> _mapResumedToState() async* {
    if (state.power == ThumperPower.on) {
      return;
    }
    if (_thumperSubscription == null) {
      _subscribeToThumper(state.speed);
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
    if (state.power == ThumperPower.off) {
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

  Stream<ThumperState<E>> _mapAcceleratedToState() async* {
    if (state.speed.isFastest) {
      return;
    }
    final s = _newStateAtSpeed(state.speed.faster);
    unawaited(_restartThumperIfRunning(s.speed));
    yield s;
  }

  Stream<ThumperState<E>> _mapDeceleratedToState() async* {
    if (state.speed.isSlowest) {
      return;
    }
    final s = _newStateAtSpeed(state.speed.slower);
    unawaited(_restartThumperIfRunning(s.speed));
    yield s;
  }

  ThumperState<E> _newStateAtSpeed(ThumperSpeed s) =>
      ThumperState<E>(s, state.power, state.thing, state.thumpCount);

  /// If stream exists, just cancel it.  If it should be running,
  /// restart it at the given speed.
  Future<void> _restartThumperIfRunning(ThumperSpeed newSpeed) async {
    if (_thumperSubscription != null) {
      _cancelSubscription();
      if (state.power == ThumperPower.on) {
        _subscribeToThumper(newSpeed);
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
      yield ThumperState<E>(
          state.speed, state.power, _iterator.current, state.thumpCount + 1);
      return;
    }
    _thumperSubscription?.pause();
    _autoThumpsRemaining = _defaultInitialThumpCountdown;
    yield ThumperState<E>(
        state.speed, ThumperPower.off, _iterator.current, state.thumpCount + 1);
  }

  Stream<ThumperState<E>> _mapThumpedManuallyToState() async* {
    _thump();
    if (state.power == ThumperPower.reset) {
      _autoThumpsRemaining = _defaultInitialThumpCountdown;
      yield ThumperState<E>(state.speed, ThumperPower.off, _iterator.current,
          state.thumpCount + 1);
      return;
    }
    yield ThumperState<E>(
        state.speed, state.power, _iterator.current, state.thumpCount + 1);
  }

  Stream<ThumperState<E>> _mapRewoundToState() async* {
    _cancelSubscription();
    yield initialState;
  }
}
