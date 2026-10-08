import 'package:flutter_test/flutter_test.dart';
import 'package:rescuegrid_app/main.dart';

void main() {
  testWidgets('Landing page shows Campus Safety', (WidgetTester tester) async {
    await tester.pumpWidget(const RescueGridApp());

    expect(find.text('Campus Safety'), findsWidgets);
    expect(find.text('Get started'), findsOneWidget);
  });
}