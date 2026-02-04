import 'package:flutter_test/flutter_test.dart';
import 'package:volcano_flutter/main.dart';
import 'package:volcano_flutter/di/service_locator.dart';

void main() {
  setUpAll(() {
    setupServiceLocator();
  });

  testWidgets('Volcano app renders', (WidgetTester tester) async {
    await tester.pumpWidget(const VolcanoApp());

    // Verify that the app renders with the title
    expect(find.text('Volcano Plot'), findsOneWidget);
  });
}
