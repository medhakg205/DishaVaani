// widget_test.dart — basic smoke test: splash screen renders
import 'package:flutter_test/flutter_test.dart';
import 'package:disha_vaani/app.dart';

void main() {
  testWidgets('App splash screen smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const DishaVaaniApp());
    expect(find.text('DISHAVAANI'), findsOneWidget);
  });
}