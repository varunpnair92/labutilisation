import 'package:flutter_test/flutter_test.dart';
import 'package:extralabutilization/main.dart';

void main() {
  testWidgets('Lab Utilization app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const LabUtilizationApp());
    expect(find.text('Lab Utilization'), findsOneWidget);
  });
}
