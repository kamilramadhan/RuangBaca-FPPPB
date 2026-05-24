import 'package:flutter_test/flutter_test.dart';

import 'package:ruang_baca/app.dart';

void main() {
  testWidgets('Home page renders menu fitur', (WidgetTester tester) async {
    await tester.pumpWidget(const RuangBacaApp());

    expect(find.text('Smart Bookshelf'), findsOneWidget);
    expect(find.text('Reading Progress'), findsOneWidget);
    expect(find.text('Community'), findsOneWidget);
  });
}
