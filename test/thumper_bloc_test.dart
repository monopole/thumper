import 'dart:async';
import 'package:test/test.dart';
import 'package:thumper/data/fruit.dart';
import 'package:thumper/src/frequency.dart';
import 'package:thumper/src/power.dart';
import 'package:thumper/src/spectrum.dart';
import 'package:thumper/src/thumper_bloc.dart';
import 'package:thumper/src/thumper_event.dart';
import 'package:thumper/src/thumper_state.dart';

// ignore_for_file: cascade_invocations

// It doesn't matter if this is true or false.
const arbitraryBoolean = true;

void main() {
  ThumperBloc thumperBloc;
  Frequency currentFrequency;
  StreamController<bool> thumpStreamController;
  final firstFruit = Fruit.values[0];
  final spectrum =
      Spectrum.fromPeriodsInMilliSec(const [400, 1000, 30, 800, 100]);

  ThumperState<Fruit> makeTsReset(Frequency s, Fruit f, int c) =>
      ThumperState<Fruit>(s, Power.reset, f, c);
  ThumperState<Fruit> makeTsOff(Frequency s, Fruit f, int c) =>
      ThumperState<Fruit>(s, Power.idle, f, c);
  ThumperState<Fruit> makeTsOn(Frequency s, Fruit f, int c) =>
      ThumperState<Fruit>(s, Power.running, f, c);

  ThumperState<Fruit> tsAtFrequency(Frequency s) =>
      ThumperState<Fruit>(s, Power.reset, firstFruit);

  Stream<bool> makeThumperStream(Frequency f) {
    currentFrequency = f;
    thumpStreamController?.close();
    thumpStreamController = StreamController<bool>(sync: true);
    return thumpStreamController.stream;
  }

  setUp(() {
    currentFrequency = null;
    thumperBloc = ThumperBloc<Fruit>(
        List.from(Fruit.values), spectrum, makeThumperStream, 100);
  });

  tearDown(() {
    thumpStreamController?.close();
    thumperBloc?.close();
  });

  test('init', () {
    expect(thumperBloc.initialState,
        ThumperState<Fruit>(spectrum[0], Power.reset, firstFruit));
  });

  test('close does not emit new states', () {
    expectLater(
      thumperBloc,
      emitsInOrder(
          [ThumperState(spectrum[0], Power.reset, firstFruit), emitsDone]),
    );
    thumperBloc.close();
  });

  test('acceleration', () {
    final states = [
      tsAtFrequency(spectrum[0]),
      tsAtFrequency(spectrum[1]), // 1
      tsAtFrequency(spectrum[2]), // 2
      tsAtFrequency(spectrum[3]), // 3
      tsAtFrequency(spectrum[4]), // 4
      emitsDone,
    ];

    expectLater(
      thumperBloc,
      emitsInOrder(states),
    );

    thumperBloc.add(ThumperEvent.increased); // 1
    thumperBloc.add(ThumperEvent.increased); // 2
    thumperBloc.add(ThumperEvent.increased); // 3
    thumperBloc.add(ThumperEvent.increased); // 4
    thumperBloc.add(ThumperEvent.increased); // 5 Further increases don't
    thumperBloc.add(ThumperEvent.increased); // 6 change the state, so no
    thumperBloc.add(ThumperEvent.increased); // 7 new states.
    thumperBloc.close();
  });

  test('moveUpAndDownTheSpectrum', () {
    final states = [
      tsAtFrequency(spectrum[0]),
      tsAtFrequency(spectrum[1]),
      tsAtFrequency(spectrum[2]),
      tsAtFrequency(spectrum[1]),
      tsAtFrequency(spectrum[0]),
      emitsDone,
    ];

    expectLater(
      thumperBloc,
      emitsInOrder(states),
    );

    thumperBloc.add(ThumperEvent.increased); // 1
    thumperBloc.add(ThumperEvent.increased); // 2
    thumperBloc.add(ThumperEvent.decreased); // 3
    thumperBloc.add(ThumperEvent.decreased); // 4
    thumperBloc.add(ThumperEvent.decreased); // 5 Further decreases don't
    thumperBloc.add(ThumperEvent.decreased); // 6 change the state, so no
    thumperBloc.add(ThumperEvent.decreased); // 7 new states.
    thumperBloc.close();
  });

  void expectThumperRunningAtFrequency(Frequency f) {
    expect(thumpStreamController, isNotNull);
    expect(thumpStreamController.isPaused, false);
    expect(thumpStreamController.hasListener, true);
    expect(currentFrequency, f);
  }

  test('full lifecycle test', () async {
    final stateIterator = StreamIterator<ThumperState>(thumperBloc);

    // Confirm initial state.
    var ready = await stateIterator.moveNext();
    expect(ready, true);
    expect(
        stateIterator.current, equals(makeTsReset(spectrum[0], firstFruit, 0)));
    expect(thumpStreamController, isNull);

    // Turn on the thumper.
    thumperBloc.add(ThumperEvent.resumed);
    ready = await stateIterator.moveNext();
    expect(ready, true);
    expect(stateIterator.current, equals(makeTsOn(spectrum[0], firstFruit, 0)));

    expectThumperRunningAtFrequency(spectrum[0]);

    // Send an automatic thump, wait for an echo.
    thumpStreamController.sink.add(arbitraryBoolean);
    ready = await stateIterator.moveNext();
    expect(ready, true);
    expect(stateIterator.current.thumpCount, 1);
    expect(
        stateIterator.current, equals(makeTsOn(spectrum[0], Fruit.apricot, 1)));

    // Send an automatic thump, wait for an echo.
    thumpStreamController.sink.add(arbitraryBoolean);
    ready = await stateIterator.moveNext();
    expect(ready, true);
    expect(stateIterator.current.thumpCount, 2);
    expect(
        stateIterator.current, equals(makeTsOn(spectrum[0], Fruit.banana, 2)));

    // Pause the thumper.
    thumperBloc.add(ThumperEvent.paused);
    ready = await stateIterator.moveNext();
    expect(ready, true);
    expect(
        stateIterator.current, equals(makeTsOff(spectrum[0], Fruit.banana, 2)));

    expect(stateIterator.current.frequency.unitInterval, 0.0);

    expect(thumpStreamController.isPaused, true);

    // Send [ThumperEvent.increased] - which should trigger a state
    // change (because of frequency change).
    thumperBloc.add(ThumperEvent.increased);
    ready = await stateIterator.moveNext();
    expect(ready, true);
    expect(
        stateIterator.current, equals(makeTsOff(spectrum[1], Fruit.banana, 2)));
    expect(stateIterator.current.frequency.unitInterval, 0.25);

    // Send a manual thump, wait for an echo.
    thumperBloc.add(ThumperEvent.thumpedManually);
    ready = await stateIterator.moveNext();
    expect(ready, true);
    expect(stateIterator.current.thumpCount, 3);
    expect(stateIterator.current,
        equals(makeTsOff(spectrum[1], Fruit.blackberry, 3)));

    // Resume the thumper.
    thumperBloc.add(ThumperEvent.resumed);
    ready = await stateIterator.moveNext();
    expect(ready, true);
    expect(stateIterator.current,
        equals(makeTsOn(spectrum[1], Fruit.blackberry, 3)));

    expectThumperRunningAtFrequency(spectrum[1]);

    // Send an automatic thump, wait for an echo.
    thumpStreamController.sink.add(arbitraryBoolean);
    ready = await stateIterator.moveNext();
    expect(ready, true);
    expect(stateIterator.current,
        equals(makeTsOn(spectrum[1], Fruit.cantaloupe, 4)));

    // For fun, send an automatic thump event, but bypass the thump stream
    // and send it directly to the block.
    thumperBloc.add(ThumperEvent.thumpedAutomatically);
    ready = await stateIterator.moveNext();
    expect(ready, true);
    expect(
        stateIterator.current, equals(makeTsOn(spectrum[1], Fruit.coconut, 5)));

    // Increase to highest frequency.
    thumperBloc.add(ThumperEvent.increased);
    ready = await stateIterator.moveNext();
    expect(ready, true);
    expect(
        stateIterator.current, equals(makeTsOn(spectrum[2], Fruit.coconut, 5)));
    expect(stateIterator.current.frequency.unitInterval, 0.5);

    thumperBloc.add(ThumperEvent.increased);
    ready = await stateIterator.moveNext();
    expect(ready, true);
    expect(
        stateIterator.current, equals(makeTsOn(spectrum[3], Fruit.coconut, 5)));

    expect(stateIterator.current.frequency.unitInterval, 0.75);

    thumperBloc.add(ThumperEvent.increased);
    ready = await stateIterator.moveNext();
    expect(ready, true);
    expect(
        stateIterator.current, equals(makeTsOn(spectrum[4], Fruit.coconut, 5)));
    expect(stateIterator.current.frequency.unitInterval, 1.0);

    // Accelerate again while at top frequency, assure that nothing crashes.
    // There's no state change, so nothing to wait for.
    thumperBloc.add(ThumperEvent.increased);
    expect(
        stateIterator.current, equals(makeTsOn(spectrum[4], Fruit.coconut, 5)));

    // Drop all the way down.
    thumperBloc.add(ThumperEvent.decreased);
    await stateIterator.moveNext();
    thumperBloc.add(ThumperEvent.decreased);
    await stateIterator.moveNext();
    thumperBloc.add(ThumperEvent.decreased);
    await stateIterator.moveNext();
    thumperBloc.add(ThumperEvent.decreased);
    await stateIterator.moveNext();
    expect(
        stateIterator.current, equals(makeTsOn(spectrum[0], Fruit.coconut, 5)));
  });
}
