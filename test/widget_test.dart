import 'package:flutter_test/flutter_test.dart';

import 'package:koreader_remote_turner/app.dart';

void main() {
  testWidgets('App loads', (WidgetTester tester) async {
    await tester.pumpWidget(App(onThemeChanged: (_) {}));
    await tester.pump();
  });
}
