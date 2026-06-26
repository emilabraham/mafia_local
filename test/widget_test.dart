import 'package:flutter_test/flutter_test.dart';

import 'package:mafia_local/main.dart';

void main() {
  testWidgets('App renders IntroScreen', (WidgetTester tester) async {
    await tester.pumpWidget(const MafiaApp());
    expect(find.text('Mafia Local'), findsOneWidget);
    expect(find.text('Host'), findsOneWidget);
    expect(find.text('Join'), findsOneWidget);
  });
}
