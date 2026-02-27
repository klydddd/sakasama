import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sakasama/app.dart';

void main() {
  testWidgets('App renders without errors', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: SakasamaApp()));

    // Verify the welcome screen renders
    expect(find.text('Sakasama'), findsOneWidget);
  });
}
