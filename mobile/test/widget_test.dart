import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hishabai_mobile/screens/login_screen.dart';
import 'package:hishabai_mobile/theme/app_theme.dart';

void main() {
  testWidgets('login presents Google sign-in and privacy copy', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: LoginScreen(onContinue: () => tapped = true),
      ),
    );

    expect(find.text('hishabAI'), findsOneWidget);
    expect(find.text('Continue with Google'), findsOneWidget);
    expect(find.textContaining('stay private'), findsOneWidget);

    await tester.tap(find.text('Continue with Google'));
    expect(tapped, isTrue);
  });
}
