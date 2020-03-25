import 'package:flutter_test/flutter_test.dart';
import 'package:thumper/data/fruit.dart';
import 'package:thumper/thumper.dart';

void main() {
  test('thumper_state', () {
    const thumper = Thumper<Fruit>();
    expect(thumper.toString(), startsWith('Thumper<Fruit>('));
  });

  // TODO write an actual widget test presumably
//  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
//    // Build our app and trigger a frame.
//    await tester.pumpWidget(Thumper());
//
//    // Verify that our counter starts at 0.
//    expect(find.text('0'), findsOneWidget);
//    expect(find.text('1'), findsNothing);
//
//    // Tap the '+' icon and trigger a frame.
//    await tester.tap(find.byIcon(Icons.add));
//    await tester.pump();
//
//    // Verify that our counter has incremented.
//    expect(find.text('0'), findsNothing);
//    expect(find.text('1'), findsOneWidget);
//  });
}
