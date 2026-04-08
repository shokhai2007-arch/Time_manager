import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:time_management/main.dart';

void main() {
  testWidgets('App loads and shows timer icon', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ProviderScope(child: MyApp()));

    // Verify that the title text exists.
    expect(find.text('PITCH TIMER'), findsOneWidget);
  });
}
