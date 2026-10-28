import 'package:flutter_test/flutter_test.dart';
import 'package:nutrix_app/main.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  testWidgets('NutriX app starts', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: NutriXApp()),
    );
    // The app should start without errors
    expect(find.byType(NutriXApp), findsOneWidget);
  });
}
