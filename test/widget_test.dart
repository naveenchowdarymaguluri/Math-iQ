import 'package:flutter_test/flutter_test.dart';
import 'package:mathiq/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const MathIQApp());
    expect(find.byType(MathIQApp), findsOneWidget);
  });
}
