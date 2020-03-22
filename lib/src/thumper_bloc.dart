import 'package:bloc/bloc.dart';
import 'dart:async';
import 'thumper_event.dart';
import 'thumper_state.dart';
import 'thumper_speed.dart';

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
/// over.
///
class ThumperBloc<E> extends Bloc<ThumperEvent, ThumperState<E>> {
  static const int _defaultInitialThumpCountdown = 1000;

  // TODO: change to stream bool, since the int is meaningless
  final Stream<int> Function(ThumperSpeed) _timerFactoryFunc;

  /// Holds the stuff to emit.
  final Iterable<E> _iterable;

  final SpeedRange _speedRange;

  int get numDivisions => _speedRange.numDivisions;

  Iterator<E> _iterator;
  StreamSubscription<int> _thumperSubscription;

  /// How many automatic thumps remaining before automatic thumping should stop?
  int _autoThumpsRemaining;

  /// ThumperBloc accepts
  /// - A non-empty Iterable<E>.
  /// - A _speedRange.
  /// - A stream factory that accepts a speed and returns a Stream<int>.
  ///   The factory presumably makes a stream that emits ints at the given
  ///   speed for use as a timer.
  ThumperBloc(
    Iterable<E> iterable,
    SpeedRange range,
    Stream<int> Function(ThumperSpeed) stFactoryFunc,
  )   : assert(iterable.isNotEmpty && range != null && stFactoryFunc != null),
        _iterable = iterable,
        _speedRange = range,
        _timerFactoryFunc = stFactoryFunc,
        _autoThumpsRemaining = _defaultInitialThumpCountdown;

  factory ThumperBloc.fromIterable(Iterable<E> iterable) => ThumperBloc(
      iterable,
      SpeedRange.fromInts([400, 1000, 30, 800, 100]),
      makeThumperWithSpeed);

  /// Makes a stream that can be used to control the rate of
  /// automatic thumps.
  static Stream<int> makeThumperWithSpeed(ThumperSpeed speed) =>
      Stream.periodic(speed.period, (int k) => k);

  @override
  Future<void> close() {
    _thumperSubscription?.cancel();
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

  void reactToSpeedValue(double value) {
    ThumperSpeed s = _speedRange.mapUnitIntervalToSpeed(value);
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
    _iterator = _iterable.iterator;
    // The constructor asserted a non-empty iterator, so we can call .moveNext
    // and be assured that .current will return a valid E.
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
      throw "wut?";
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
    _restartThumperIfRunning(s.speed);
    yield s;
  }

  Stream<ThumperState<E>> _mapDeceleratedToState() async* {
    if (state.speed.isSlowest) {
      return;
    }
    final s = _newStateAtSpeed(state.speed.slower);
    _restartThumperIfRunning(s.speed);
    yield s;
  }

  ThumperState<E> _newStateAtSpeed(ThumperSpeed s) =>
      ThumperState<E>(s, state.power, state.thing, state.thumpCount);

  /// If stream exists, just cancel it.  If it should be running,
  /// restart it at the given speed.
  void _restartThumperIfRunning(ThumperSpeed newSpeed) async {
    if (_thumperSubscription != null) {
      await _thumperSubscription.cancel();
      _thumperSubscription = null;
      if (state.power == ThumperPower.on) {
        _subscribeToThumper(newSpeed);
      }
    }
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
    _thumperSubscription?.cancel();
    _thumperSubscription = null;
    yield initialState;
  }
}
