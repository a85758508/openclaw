import 'package:flutter_test/flutter_test.dart';

import 'package:bedtime_story_app/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const BedtimeStoryApp());
    expect(find.text('给宝宝的睡前故事'), findsOneWidget);
  });
}
