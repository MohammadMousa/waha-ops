import 'package:flutter/material.dart';
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

  testWidgets('PIN field hides digits until the eye icon is tapped', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const WahaOpsApp());
    await tester.pumpAndSettle();
    bool obscured() => tester.widget<EditableText>(find.byType(EditableText).last).obscureText;
    expect(obscured(), isTrue);
    await tester.tap(find.byIcon(Icons.visibility));
    await tester.pump();
    expect(obscured(), isFalse);
    await tester.tap(find.byIcon(Icons.visibility_off));
    await tester.pump();
    expect(obscured(), isTrue);
  });
}
