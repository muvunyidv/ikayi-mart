import 'package:flutter_test/flutter_test.dart';

import 'package:ikayi_mart/main.dart';

void main() {
  testWidgets('IKAYI MART storefront loads', (tester) async {
    await tester.pumpWidget(const IkayiMartApp());
    await tester.pump();

    expect(find.textContaining('IKAYI MART'), findsWidgets);
  });
}
