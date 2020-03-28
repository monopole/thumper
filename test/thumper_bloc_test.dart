import 'dart:async';
import 'package:test/test.dart';
import 'package:thumper/data/fruit.dart';
import 'package:thumper/src/thumper_bloc.dart';
import 'package:thumper/src/thumper_event.dart';
import 'package:thumper/src/thumper_speed.dart';
import 'package:thumper/src/thumper_state.dart';

// ignore_for_file: cascade_invocations

void main() {
  ThumperBloc thumperBloc;
  ThumperSpeed currentSpeed;
  StreamController<bool> thumpStreamController;
  final firstFruit = Fruit.values[0];
  final speedRange = SpeedRange.fromPeriodsInMilliSec(const [400, 1000, 30, 800, 100]);

  ThumperState<Fruit> makeTsReset(ThumperSpeed s, Fruit f, int c) =>
      ThumperState<Fruit>(s, ThumperPower.reset, f, c);
  ThumperState<Fruit> makeTsOff(ThumperSpeed s, Fruit f, int c) =>
      ThumperState<Fruit>(s, ThumperPower.off, f, c);
  ThumperState<Fruit> makeTsOn(ThumperSpeed s, Fruit f, int c) =>
      ThumperState<Fruit>(s, ThumperPower.on, f, c);

  ThumperState<Fruit> tsAtSpeed(ThumperSpeed s) =>
      ThumperState<Fruit>(s, ThumperPower.reset, firstFruit);

  Stream<bool> makeThumperStream(ThumperSpeed s) {
    currentSpeed = s;
    thumpStreamController?.close();
    thumpStreamController = StreamController<bool>(sync: true);
    return thumpStreamController.stream;
  }

  setUp(() {
    currentSpeed = null;
    thumperBloc = ThumperBloc<Fruit>(
        List.from(Fruit.values), speedRange, makeThumperStream);
  });

  tearDown(() {
    thumpStreamController?.close();
    thumperBloc?.close();
  });

  test('init', () {
    expect(thumperBloc.initialState,
        ThumperState<Fruit>(speedRange[0], ThumperPower.reset, firstFruit));
  });

  test('close does not emit new states', () {
    expectLater(
      thumperBloc,
      emitsInOrder([
        ThumperState(speedRange[0], ThumperPower.reset, firstFruit),
        emitsDone
      ]),
    );
    thumperBloc.close();
  });

  test('acceleration', () {
    final states = [
      tsAtSpeed(speedRange[0]),
      tsAtSpeed(speedRange[1]), // 1
      tsAtSpeed(speedRange[2]), // 2
      tsAtSpeed(speedRange[3]), //3
      tsAtSpeed(speedRange[4]), // 4
      emitsDone,
    ];

    expectLater(
      thumperBloc,
      emitsInOrder(states),
    );

    thumperBloc.add(ThumperEvent.accelerated); // 1
    thumperBloc.add(ThumperEvent.accelerated); // 2
    thumperBloc.add(ThumperEvent.accelerated); // 3
    thumperBloc.add(ThumperEvent.accelerated); // 4
    thumperBloc.add(ThumperEvent.accelerated); // 5 Further acceleration does
    thumperBloc.add(ThumperEvent.accelerated); // 6 not change the state, so no
    thumperBloc.add(ThumperEvent.accelerated); // 7 new states.
    thumperBloc.close();
  });

  test('speed up and down', () {
    final states = [
      tsAtSpeed(speedRange[0]),
      tsAtSpeed(speedRange[1]),
      tsAtSpeed(speedRange[2]),
      tsAtSpeed(speedRange[1]),
      tsAtSpeed(speedRange[0]),
      emitsDone,
    ];

    expectLater(
      thumperBloc,
      emitsInOrder(states),
    );

    thumperBloc.add(ThumperEvent.accelerated); // 1
    thumperBloc.add(ThumperEvent.accelerated); // 2
    thumperBloc.add(ThumperEvent.decelerated); // 3
    thumperBloc.add(ThumperEvent.decelerated); // 4
    thumperBloc.add(ThumperEvent.decelerated); // 5 Further deceleration does
    thumperBloc.add(ThumperEvent.decelerated); // 6 not change the state, so no
    thumperBloc.add(ThumperEvent.decelerated); // 7 new states.
    thumperBloc.close();
  });

  void expectThumperRunningAtSpeed(ThumperSpeed s) {
    expect(thumpStreamController, isNotNull);
    expect(thumpStreamController.isPaused, false);
    expect(thumpStreamController.hasListener, true);
    expect(currentSpeed, s);
  }

  test('full lifecycle test', () async {
    final stateIterator = StreamIterator<ThumperState>(thumperBloc);

    // Confirm initial state.
    var ready = await stateIterator.moveNext();
    expect(ready, true);
    expect(stateIterator.current,
        equals(makeTsReset(speedRange[0], firstFruit, 0)));
    expect(thumpStreamController, isNull);

    // Turn on the thumper.
    thumperBloc.add(ThumperEvent.resumed);
    ready = await stateIterator.moveNext();
    expect(ready, true);
    expect(
        stateIterator.current, equals(makeTsOn(speedRange[0], firstFruit, 0)));

    expectThumperRunningAtSpeed(speedRange[0]);

    // Send an automatic thump, wait for an echo.
    thumpStreamController.sink.add(ThumperBloc.irrelevantBoolValue);
    ready = await stateIterator.moveNext();
    expect(ready, true);
    expect(stateIterator.current.thumpCount, 1);
    expect(stateIterator.current,
        equals(makeTsOn(speedRange[0], Fruit.apricot, 1)));

    // Send an automatic thump, wait for an echo.
    thumpStreamController.sink.add(ThumperBloc.irrelevantBoolValue);
    ready = await stateIterator.moveNext();
    expect(ready, true);
    expect(stateIterator.current.thumpCount, 2);
    expect(stateIterator.current,
        equals(makeTsOn(speedRange[0], Fruit.banana, 2)));

    // Pause the thumper.
    thumperBloc.add(ThumperEvent.paused);
    ready = await stateIterator.moveNext();
    expect(ready, true);
    expect(stateIterator.current,
        equals(makeTsOff(speedRange[0], Fruit.banana, 2)));

    expect(stateIterator.current.speed.unitInterval, 0.0);

    expect(thumpStreamController.isPaused, true);

    // Send an accelerated event - which should trigger a state
    // change (because speed change).
    thumperBloc.add(ThumperEvent.accelerated);
    ready = await stateIterator.moveNext();
    expect(ready, true);
    expect(stateIterator.current,
        equals(makeTsOff(speedRange[1], Fruit.banana, 2)));
    expect(stateIterator.current.speed.unitInterval, 0.25);

    // Send a manual thump, wait for an echo.
    thumperBloc.add(ThumperEvent.thumpedManually);
    ready = await stateIterator.moveNext();
    expect(ready, true);
    expect(stateIterator.current.thumpCount, 3);
    expect(stateIterator.current,
        equals(makeTsOff(speedRange[1], Fruit.blackberry, 3)));

    // Resume the thumper.
    thumperBloc.add(ThumperEvent.resumed);
    ready = await stateIterator.moveNext();
    expect(ready, true);
    expect(stateIterator.current,
        equals(makeTsOn(speedRange[1], Fruit.blackberry, 3)));

    expectThumperRunningAtSpeed(speedRange[1]);

    // Send an automatic thump, wait for an echo.
    thumpStreamController.sink.add(ThumperBloc.irrelevantBoolValue);
    ready = await stateIterator.moveNext();
    expect(ready, true);
    expect(stateIterator.current,
        equals(makeTsOn(speedRange[1], Fruit.cantaloupe, 4)));

    // For fun, send an automatic thump event, but bypass the thump stream
    // and send it directly to the block.
    thumperBloc.add(ThumperEvent.thumpedAutomatically);
    ready = await stateIterator.moveNext();
    expect(ready, true);
    expect(stateIterator.current,
        equals(makeTsOn(speedRange[1], Fruit.coconut, 5)));

    // Accelerate to top speed.
    thumperBloc.add(ThumperEvent.accelerated);
    ready = await stateIterator.moveNext();
    expect(ready, true);
    expect(stateIterator.current,
        equals(makeTsOn(speedRange[2], Fruit.coconut, 5)));
    expect(stateIterator.current.speed.unitInterval, 0.5);

    thumperBloc.add(ThumperEvent.accelerated);
    ready = await stateIterator.moveNext();
    expect(ready, true);
    expect(stateIterator.current,
        equals(makeTsOn(speedRange[3], Fruit.coconut, 5)));

    expect(stateIterator.current.speed.unitInterval, 0.75);

    thumperBloc.add(ThumperEvent.accelerated);
    ready = await stateIterator.moveNext();
    expect(ready, true);
    expect(stateIterator.current,
        equals(makeTsOn(speedRange[4], Fruit.coconut, 5)));
    expect(stateIterator.current.speed.unitInterval, 1.0);

    // Accelerate again while at top speed, assure that nothing crashes.
    // There's no state change, so nothing to wait for.
    thumperBloc.add(ThumperEvent.accelerated);
    expect(stateIterator.current,
        equals(makeTsOn(speedRange[4], Fruit.coconut, 5)));

    // Decelerate all the way down.
    thumperBloc.add(ThumperEvent.decelerated);
    await stateIterator.moveNext();
    thumperBloc.add(ThumperEvent.decelerated);
    await stateIterator.moveNext();
    thumperBloc.add(ThumperEvent.decelerated);
    await stateIterator.moveNext();
    thumperBloc.add(ThumperEvent.decelerated);
    await stateIterator.moveNext();
    expect(stateIterator.current,
        equals(makeTsOn(speedRange[0], Fruit.coconut, 5)));
  });
}
