import 'dart:async';
import 'package:test/test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:thumper/data/fruit.dart';
import 'package:thumper/src/frequency.dart';
import 'package:thumper/src/power.dart';
import 'package:thumper/src/spectrum.dart';
import 'package:thumper/src/thumper_bloc.dart';
import 'package:thumper/src/thumper_event.dart';
import 'package:thumper/src/thumper_state.dart';
import 'package:logging/logging.dart';

// ignore_for_file: cascade_invocations

// It doesn't matter if this is true or false.
const arbitraryBoolean = true;

void main() {
  Frequency? currentFrequency;

  final firstFruit = Fruit.values[0];
  final spectrum =
      Spectrum.fromPeriodsInMilliSec(const [400, 1000, 30, 800, 100]);
  final logger = Logger("thumperTest");
  Logger.root.level = Level.INFO;
  Logger.root.onRecord.listen((record) {
    //print('${record.level.name}: ${record.time}: ${record.message}');
    print(record.message);
  });

  ThumperState<Fruit> makeTsReset(Frequency s, Fruit f, int c) =>
      ThumperState<Fruit>(s, Power.reset, f, c);
  ThumperState<Fruit> makeTsIdle(Frequency s, Fruit f, int c) =>
      ThumperState<Fruit>(s, Power.idle, f, c);
  ThumperState<Fruit> makeTsRunning(Frequency s, Fruit f, int c) =>
      ThumperState<Fruit>(s, Power.running, f, c);

  ThumperState<Fruit> tsAtFrequency(Frequency s) =>
      ThumperState<Fruit>(s, Power.reset, firstFruit);

  // Used to send thumps to the ThumperBloc.
  StreamController<bool> timerController = StreamController<bool>(sync: true);

  // Function send into the ThumperBloc for testing purposes, keeping
  // the controller exposed here.
  Stream<bool> makeMockTimerStream(Frequency f) {
    currentFrequency = f;
    timerController.close();
    timerController = StreamController<bool>(sync: true);
    return timerController.stream;
  }

  ThumperBloc<Fruit> makeBlock() => ThumperBloc<Fruit>.fromArgs(
      List<Fruit>.from(Fruit.values),
      spectrum,
      makeMockTimerStream,
      100,
      logger);

  test('iterable', () {
    final itr = List<Fruit>.from(Fruit.values).iterator;
    expect(itr.moveNext(), isTrue);
    expect(itr.current, Fruit.apple);
  });

  test('initialState', () {
    final bloc = makeBlock();
    expect(
        bloc.state, ThumperState<Fruit>(spectrum[0], Power.reset, firstFruit));
  });

  blocTest<ThumperBloc<Fruit>, ThumperState<Fruit>>(
    'nothing added yields nothing',
    build: () => makeBlock(),
    expect: () => <ThumperState<Fruit>>[],
  );

  blocTest<ThumperBloc<Fruit>, ThumperState<Fruit>>(
    'acceleration only',
    build: () => makeBlock(),
    act: (bloc) {
      bloc.add(ThumperEventIncreased()); // 0->1
      bloc.add(ThumperEventIncreased()); // 1->2
      bloc.add(ThumperEventIncreased()); // 2->3
      bloc.add(ThumperEventIncreased()); // 3->4
      bloc.add(ThumperEventIncreased()); // 5 Further increases don't
      bloc.add(ThumperEventIncreased()); // 6 change the state, so no
      bloc.add(ThumperEventIncreased()); // 7 new states.
    },
    expect: () => [
      tsAtFrequency(spectrum[1]), // 1
      tsAtFrequency(spectrum[2]), // 2
      tsAtFrequency(spectrum[3]), // 3
      tsAtFrequency(spectrum[4]), // 4
    ],
  );

  blocTest<ThumperBloc<Fruit>, ThumperState<Fruit>>(
    'move up and down',
    build: () => makeBlock(),
    act: (bloc) {
      bloc.add(ThumperEventIncreased()); // 0->1
      bloc.add(ThumperEventIncreased()); // 1->2
      bloc.add(ThumperEventDecreased()); // 2->3
      bloc.add(ThumperEventDecreased()); // 3->4
      bloc.add(ThumperEventDecreased()); // 5 Further decreases don't
      bloc.add(ThumperEventDecreased()); // 6 change the state, so no
      bloc.add(ThumperEventDecreased()); // 7 new states.
    },
    expect: () => [
      // Starts at 0.
      tsAtFrequency(spectrum[1]), // 1
      tsAtFrequency(spectrum[2]), // 2
      tsAtFrequency(spectrum[1]), // 3
      tsAtFrequency(spectrum[0]), // 4
    ],
  );

  blocTest<ThumperBloc<Fruit>, ThumperState<Fruit>>(
    'manual thumping',
    build: () => makeBlock(),
    act: (bloc) {
      bloc.add(ThumperEventIncreased()); // 0->1
      bloc.add(ThumperEventIncreased()); // 1->2

      // Turn on the thumper.
      bloc.add(ThumperEventResumed());

      // Send two thumps.
      bloc.add(ThumperEventThumpedManually());
      bloc.add(ThumperEventThumpedManually());
      bloc.add(ThumperEventDecreased()); // 2->1
      bloc.add(ThumperEventDecreased()); // 1->0
      bloc.add(ThumperEventDecreased()); // no-op
      bloc.add(ThumperEventDecreased()); // no-op
      bloc.add(ThumperEventThumpedManually()); // sure, why not.
    },
    expect: () => [
      // Starts at 0.
      tsAtFrequency(spectrum[1]), // 1
      tsAtFrequency(spectrum[2]), // 2
      makeTsRunning(spectrum[2], firstFruit, 0),
      makeTsRunning(spectrum[2], Fruit.apricot, 1), // First thump
      makeTsRunning(spectrum[2], Fruit.banana, 2), // Second thump
      makeTsRunning(spectrum[1], Fruit.banana, 2), // decrease
      makeTsRunning(spectrum[0], Fruit.banana, 2), // decrease
      makeTsRunning(spectrum[0], Fruit.blackberry, 3), // First thump
    ],
  );

  blocTest<ThumperBloc<Fruit>, ThumperState<Fruit>>(
    'manual thump without turning on thumper',
    build: () => makeBlock(),
    act: (bloc) {
      bloc.add(ThumperEventIncreased()); // 0->1
      bloc.add(ThumperEventThumpedManually());
      bloc.add(ThumperEventThumpedManually());
    },
    expect: () => [
      // Starts at 0.
      makeTsReset(spectrum[1], firstFruit, 0),
      makeTsIdle(spectrum[1], Fruit.apricot, 1), // First thump
      makeTsIdle(spectrum[1], Fruit.banana, 2), // Second thump
    ],
  );

  blocTest<ThumperBloc<Fruit>, ThumperState<Fruit>>(
    'manual thumping, then turn on thumper NOT WORKING',
    build: () => makeBlock(),
    act: (bloc) {
      bloc.add(ThumperEventThumpedManually());
      bloc.add(ThumperEventThumpedManually());
      bloc.add(ThumperEventResumed());
      bloc.add(ThumperEventPaused());
    },
    expect: () => [
      // Starts at 0.
      makeTsIdle(spectrum[0], Fruit.apricot, 1), // First thump
      makeTsIdle(spectrum[0], Fruit.banana, 2), // Second thump
      makeTsRunning(spectrum[0], Fruit.banana, 2), // resumed
      makeTsIdle(spectrum[0], Fruit.banana, 2), // paused
    ],
  );

  void expectThumperRunningAtFrequency(Frequency f) {
    expect(timerController, isNotNull);
    expect(timerController.isPaused, false);
    expect(timerController.hasListener, true);
    expect(currentFrequency, f);
  }

  test('full lifecycle test', () async {
    Logger.root.level = Level.INFO; // change to FINE to see logging.
    final bloc = makeBlock();

    logger.fine(bloc.state);
    logger.fine("*** Starting long test.");
    expect(
        bloc.state, ThumperState<Fruit>(spectrum[0], Power.reset, firstFruit));

    logger.fine("*** Turn on the thumper");
    bloc.add(ThumperEventResumed());
    await Future<void>.delayed(Duration.zero);
    expectThumperRunningAtFrequency(spectrum[0]);

    logger.fine("*** Send a thump from the internal thumper.");
    timerController.sink.add(arbitraryBoolean);
    await Future<void>.delayed(Duration.zero);
    expect(bloc.state.thumpCount, 1);
    expect(bloc.state, equals(makeTsRunning(spectrum[0], Fruit.apricot, 1)));

    logger.fine("*** Send another thump via the internal thumper.");
    timerController.sink.add(arbitraryBoolean);
    await Future<void>.delayed(Duration.zero);
    expect(bloc.state.thumpCount, 2);
    expect(bloc.state, equals(makeTsRunning(spectrum[0], Fruit.banana, 2)));

    logger.fine("*** Pause the thumper.");
    bloc.add(ThumperEventPaused());
    await Future<void>.delayed(Duration.zero);
    expect(bloc.state, equals(makeTsIdle(spectrum[0], Fruit.banana, 2)));
    expect(bloc.state.frequency.unitInterval, 0.0);

    logger.fine("*** Accelerate the thumper.");
    bloc.add(ThumperEventIncreased());
    await Future<void>.delayed(Duration.zero);
    expect(bloc.state, equals(makeTsIdle(spectrum[1], Fruit.banana, 2)));
    expect(bloc.state.frequency.unitInterval, 0.25);

    logger.fine("*** Send a manual thump, wait for an echo.");
    bloc.add(ThumperEventThumpedManually());
    await Future<void>.delayed(Duration.zero);
    expect(bloc.state, equals(makeTsIdle(spectrum[1], Fruit.blackberry, 3)));

    logger.fine("*** Automatic thump, nothing should happen, because paused");
    timerController.sink.add(arbitraryBoolean);
    await Future<void>.delayed(Duration.zero);
    expect(bloc.state, equals(makeTsIdle(spectrum[1], Fruit.blackberry, 3)));

    logger.fine("*** Unpause.");
    bloc.add(ThumperEventResumed());
    await Future<void>.delayed(Duration.zero);
    expect(bloc.state, equals(makeTsRunning(spectrum[1], Fruit.blackberry, 3)));
    expectThumperRunningAtFrequency(spectrum[1]);

    logger.fine("*** Automatic thump works now");
    timerController.sink.add(arbitraryBoolean);
    await Future<void>.delayed(Duration.zero);
    expect(bloc.state, equals(makeTsRunning(spectrum[1], Fruit.cantaloupe, 4)));

    logger.fine("*** For fun, send an automatic thump event, but bypass timer");
    // i.e. do what the timer does (this test doesn't use a real timer).
    bloc.add(ThumperEventThumpedAutomatically());
    await Future<void>.delayed(Duration.zero);
    expect(bloc.state, equals(makeTsRunning(spectrum[1], Fruit.coconut, 5)));

    logger.fine("*** Increase");
    bloc.add(ThumperEventIncreased());
    await Future<void>.delayed(Duration.zero);
    expect(bloc.state, equals(makeTsRunning(spectrum[2], Fruit.coconut, 5)));
    expect(bloc.state.frequency.unitInterval, 0.5);

    logger.fine("*** Increase");
    bloc.add(ThumperEventIncreased());
    await Future<void>.delayed(Duration.zero);
    expect(bloc.state, equals(makeTsRunning(spectrum[3], Fruit.coconut, 5)));
    expect(bloc.state.frequency.unitInterval, 0.75);

    logger.fine("*** Increase");
    bloc.add(ThumperEventIncreased());
    await Future<void>.delayed(Duration.zero);
    expect(bloc.state, equals(makeTsRunning(spectrum[4], Fruit.coconut, 5)));
    expect(bloc.state.frequency.unitInterval, 1.0);

    logger.fine("*** Increase, but already at top");
    bloc.add(ThumperEventIncreased());
    await Future<void>.delayed(Duration.zero);
    expect(bloc.state, equals(makeTsRunning(spectrum[4], Fruit.coconut, 5)));
    expect(bloc.state.frequency.unitInterval, 1.0);
    expectThumperRunningAtFrequency(spectrum[4]);

    logger.fine("*** Drop all the way down.");
    bloc.add(ThumperEventDecreased());
    await Future<void>.delayed(Duration.zero);
    bloc.add(ThumperEventDecreased());
    await Future<void>.delayed(Duration.zero);
    bloc.add(ThumperEventDecreased());
    await Future<void>.delayed(Duration.zero);
    bloc.add(ThumperEventDecreased());
    await Future<void>.delayed(Duration.zero);
    bloc.add(ThumperEventDecreased());
    await Future<void>.delayed(Duration.zero);
    expect(bloc.state, equals(makeTsRunning(spectrum[0], Fruit.coconut, 5)));
    expect(bloc.state.frequency.unitInterval, 0.0);
    expectThumperRunningAtFrequency(spectrum[0]);

    logger.fine("*** Rewound");
    bloc.add(ThumperEventRewound());
    await Future<void>.delayed(Duration.zero);
    expect(bloc.state, equals(makeTsReset(spectrum[0], Fruit.apple, 0)));

    logger.fine("*** END");
    await bloc.close();
  });
}
