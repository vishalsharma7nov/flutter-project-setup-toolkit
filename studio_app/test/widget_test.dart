import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toolkit_studio_app/screens/onboarding_screen.dart';
import 'package:toolkit_studio_app/services/studio_client.dart';

void main() {
  testWidgets('OnboardingScreen shows project picker while loading', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: OnboardingScreen(
          client: StudioClient('8765'),
          initialView: '',
        ),
      ),
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
