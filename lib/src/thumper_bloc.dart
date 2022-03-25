import 'dart:async';
import 'package:bloc/bloc.dart';
import 'frequency.dart';
import 'power.dart';
import 'spectrum.dart';
import 'thumper_event.dart';
import 'thumper_state.dart';
import 'package:logging/logging.dart';

/// ThumperBloc maps ThumperEvent to ThumperState<E>.
///
/// The events are things like paused, resumed, increased, decreased -
/// things one might do to a thumper.  The state is the thumper frequency,
/// the thumpCount, the power setting (reset, idle or running), and some
/// value of E from an iterable, e.g. a list of fruits, or some arbitrarily
/// complex state machine.
///
/// This bloc contains and manages a timer that sends events to this (the bloc),
/// so as to emit states at a particular frequency.  The bloc's constructor
/// accepts a factory function to make the timer.
///
/// Each state contains an E.  To get them, the Bloc requires an Iterable<E>.
/// The iterable must be non-empty (at least one E), so that the initial state
/// can be defined.  The iterable is used to make an iterator, and if the
/// iterator runs out, the iterable is used to make another iterator to start
/// over again.
class ThumperBloc<E> extends Bloc<ThumperEvent, ThumperState<E>> {
  /// ThumperBloc accepts
  /// - A non-empty Iterable<E> to reset _iterator.
  /// - A non-empty _iterator derived from the iterable.
  /// - A [Spectrum] of allowed thumper frequency values.
  /// - A factory func that accepts a frequency and returns a Stream<bool>.
  ///   Said stream should emit booleans (of irrelevant value) at the given
  ///   frequency. The stream is used by the bloc to control thumping frequency.
  ///   A test can inject a stream that emits on test events.
  ///   The boolean values aren't consulted; only their appearance on
  ///   the stream matters.
  /// - A limit to automatic thumping.  Hitting it automatically pauses.
  ThumperBloc(
    this._iterable,
    this._iterator,
    this._spectrum,
    this._timerFactoryFunc,
    this.autoThumpLimit,
    this._log,
  )   : assert(_iterable.isNotEmpty, 'iterable cannot be empty'),
        assert(
            _iterator.current != null, ' iterator must have a current value'),
        assert(autoThumpLimit > 0, 'autoThumpLimit must be > 0'),
        _autoThumpsRemaining = autoThumpLimit,
        super(ThumperState.init(
          _iterator.current,
          Frequency(_spectrum, 0),
        )) {
    on<ThumperEventResumed>(_onResumed);
    on<ThumperEventPaused>(_onPaused);
    on<ThumperEventDecreased>(_onDecreased);
    on<ThumperEventIncreased>(_onIncreased);
    on<ThumperEventThumpedAutomatically>(_onThumpedAutomatically);
    on<ThumperEventThumpedManually>(_onThumpedManually);
    on<ThumperEventRewound>(_onRewound);
  }

  /// Make a [ThumperBloc]] from an iterable and a reasonable default spectrum.
  factory ThumperBloc.fromIterable(Iterable<E> iterable) {
    ("DEBUG Making the thumper from iterable\n");
    return ThumperBloc.fromArgs(
        iterable,
        Spectrum.fromPeriodsInMilliSec(const [1000, 500, 250, 100, 50, 25]),
        makeTimerWithFrequency,
        10000,
        Logger("thumperBloc"));
  }

  /// Set the iterator correctly.
  factory ThumperBloc.fromArgs(Iterable<E> iterable, Spectrum sp,
      Stream<bool> Function(Frequency) sf, int autoThumpLimit, Logger logger) {
    final itr = iterable.iterator;
    assert(itr.moveNext());
    return ThumperBloc(iterable, itr, sp, sf, autoThumpLimit, logger);
  }

  /// Automatically pause automatic iteration when this limit hit.
  final int autoThumpLimit;

  /// An arbitrary boolean sent on the thumper stream.
  /// It doesn't matter if this is true or false.
  static const _arbitraryBoolean = true;

  final Stream<bool> Function(Frequency) _timerFactoryFunc;

  /// Holds the stuff to emit.
  final Iterable<E> _iterable;

  final Spectrum _spectrum;

  final Logger _log;

  /// The number of divisions that a slider widget would need to represent
  /// the set of frequencies available.
  int get numDivisions => _spectrum.numDivisions;

  Iterator<E> _iterator;
  StreamSubscription<bool>? _timerSubscription;

  /// How many automatic thumps remaining before hitting [autoThumpLimit]?
  int _autoThumpsRemaining;

  /// Makes a stream that can be used to control the rate of
  /// automatic thumps.
  static Stream<bool> makeTimerWithFrequency(Frequency f) =>
      Stream.periodic(f.period, (k) => _arbitraryBoolean);

  @override
  Future<void> close() {
    _assureTimerSubscriptionCancelled();
    return super.close();
  }

  void _listenToNewTimer(Frequency f) {
    _log.fine(
        "_listenToNewTimer creating an automatic thumper at frequency $f");
    // On creation, this subscription is NOT paused.
    _timerSubscription = _timerFactoryFunc(f)
        .listen((x) => add(ThumperEventThumpedAutomatically()));
  }

  ThumperState<E> get initialState {
    _iterator = _iterable.iterator;
    _thump();
    return ThumperState.init(_iterator.current, _spectrum.slowest);
  }

  // Iterate one step.  If done, restart.
  void _thump() {
    _log.fine("_thump");

    if (_iterator.moveNext()) {
      _log.fine("_thump incrementing iterator");
      return;
    }
    // The constructor asserted a non-empty iterator, so we can call .moveNext
    // and be assured that .current will return a valid E.
    _iterator = _iterable.iterator;
    _log.fine("_thump restarting iterator");
    // ignore: cascade_invocations
    _iterator.moveNext();
  }

  void _onResumed(ThumperEventResumed event, Emitter<ThumperState<E>> emit) {
    _log.fine("_onResumed thumper");
    if (state.power == Power.running) {
      _log.fine("resuming already running");
      emit(state);
      return;
    }
    if (_timerSubscription == null) {
      _log.fine("_onResumed starting subscription");
      _listenToNewTimer(state.frequency);
    } else {
      if (_timerSubscription!.isPaused) {
        _log.fine("_onResumed from a paused subscription");
        _timerSubscription!.resume();
      } else {
        _log.fine("_onResumed timer already running, why try to resume?");
      }
    }
    emit(state.resume());
  }

  void _onPaused(ThumperEventPaused event, Emitter<ThumperState<E>> emit) {
    _log.fine("_onPaused, entering");
    if (state.power == Power.idle) {
      _log.fine("_onPaused, already paused");
      emit(state);
      return;
    }
    if (_timerSubscription == null) {
      _log.fine("_onPaused, time subscription is nil, nothing to pause");
    } else {
      _assureTimerSubscriptionCancelled();
    }
    emit(state.pause());
  }

  void _onIncreased(
      ThumperEventIncreased event, Emitter<ThumperState<E>> emit) {
    _log.fine("_onIncreased, entering");
    if (state.frequency.isHighest) {
      _log.fine("_onIncreased, but already at top");
      emit(state);
      return;
    }
    final s = _newStateAtFrequency(state.frequency.higher);
    _log.fine("_onIncreased from ${state.frequency} to freq ${s.frequency}");
    // unawaited(_restartTimerIfRunning(s.frequency));
    _restartTimerIfRunning(s.frequency).ignore();
    emit(s);
  }

  void _onDecreased(
      ThumperEventDecreased event, Emitter<ThumperState<E>> emit) {
    _log.fine("_onDecreased, entering");
    if (state.frequency.isLowest) {
      _log.fine("_onDecreased, but already at bottom");
      emit(state);
      return;
    }
    final s = _newStateAtFrequency(state.frequency.lower);
    _log.fine("_onDecreased from ${state.frequency} to freq ${s.frequency}");
    // unawaited(_restartTimerIfRunning(s.frequency));
    _restartTimerIfRunning(s.frequency).ignore();
    emit(s);
  }

  ThumperState<E> _newStateAtFrequency(Frequency f) =>
      ThumperState<E>(f, state.power, state.thing, state.thumpCount);

  /// If stream exists, just cancel it.  If it should be running,
  /// restart it at the given frequency.
  Future<void> _restartTimerIfRunning(Frequency f) async {
    _log.fine("_restartTimerIfRunning entered");
    if (_timerSubscription == null) {
      _log.fine("_restartTimerIfRunning no timer, doing nothing");
      return;
    }
    _assureTimerSubscriptionCancelled();
    if (state.power != Power.running) {
      _log.fine(
          "_restartTimerIfRunning state.power=$state.power, doing nothing");
      return;
    }
    _log.fine("_restartTimerIfRunning starting a new timer");
    _listenToNewTimer(f);
  }

  void _onThumpedAutomatically(
      ThumperEventThumpedAutomatically event, Emitter<ThumperState<E>> emit) {
    _log.fine("_onThumpedAutomatically");
    _thump();
    if (_autoThumpsRemaining > 1) {
      _autoThumpsRemaining--;
      emit(ThumperState<E>(state.frequency, state.power, _iterator.current,
          state.thumpCount + 1));
      return;
    }
    _log.fine("_onThumpedAutomatically - but ran out of thumps, so pausing");
    _assureTimerSubscriptionCancelled();
    _autoThumpsRemaining = autoThumpLimit;
    emit(ThumperState<E>(
        state.frequency, Power.idle, _iterator.current, state.thumpCount + 1));
  }

  void _onThumpedManually(
      ThumperEventThumpedManually event, Emitter<ThumperState<E>> emit) {
    _log.fine("_onThumpedManually");
    _thump();
    var p = state.power;
    if (p == Power.reset) {
      _log.fine(
          "_onThumpedManually from a reset, so going to idle, and restoring thumps remaining");
      _autoThumpsRemaining = autoThumpLimit;
      p = Power.idle;
    } else {
      _log.fine("_onThumpedManually no change in power");
    }
    emit(ThumperState<E>(
        state.frequency, p, _iterator.current, state.thumpCount + 1));
  }

  void _onRewound(ThumperEventRewound event, Emitter<ThumperState<E>> emit) {
    _log.fine("_onRewound enter");
    _assureTimerSubscriptionCancelled();
    emit(initialState);
  }

  void _assureTimerSubscriptionCancelled() {
    _log.fine("_cancelTimerSubscription enter");
    if (_timerSubscription == null) {
      _log.fine("_cancelTimerSubscription - nothing to cancel");
      return;
    }
    final cancelMe = _timerSubscription; // put in temp var to cancel.
    _log.fine("_cancelTimerSubscription cancelling!");
    unawaited(cancelMe!.cancel());
    // Set this to null to signal it needs recreation.
    _timerSubscription = null;
  }

  /// Use this to tell the thumper that the frequency should change.
  void reactToFrequencyValue(double value) {
    final s = _spectrum.mapUnitIntervalToFrequency(value);
    if (s > state.frequency) {
      add(ThumperEventIncreased());
    } else if (s < state.frequency) {
      add(ThumperEventDecreased());
    }
  }
}
