import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:waha_ops/main.dart';

void main() {
  testWidgets('App boots to the login screen when no session is cached', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const WahaOpsApp());
    await tester.pumpAndSettle();
    expect(find.text('Waha'), findsOneWidget);
  });
}
