import 'package:flutter_test/flutter_test.dart';
import 'package:kuberadmsdn/main.dart';

void main() {
  testWidgets('DMS app loads login screen', (WidgetTester tester) async {
    // Build the app
    await tester.pumpWidget(const DMSApp());

    // Verify login screen text appears
    expect(find.text('DMS System'), findsOneWidget);

    // Verify login button exists
    expect(find.text('LOGIN'), findsOneWidget);
  });
}