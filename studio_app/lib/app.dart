import 'package:flutter/material.dart';

import 'screens/onboarding_screen.dart';
import 'services/studio_client.dart';
import 'studio_branding.dart';

Widget buildToolkitStudioApp({
  required String port,
  required String initialView,
}) {
  return ToolkitStudioApp(
    client: StudioClient(port),
    initialView: initialView,
  );
}

class ToolkitStudioApp extends StatelessWidget {
  const ToolkitStudioApp({
    super.key,
    required this.client,
    required this.initialView,
  });

  final StudioClient client;
  final String initialView;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: studioProductName,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2563EB)),
        useMaterial3: true,
      ),
      home: OnboardingScreen(
        client: client,
        initialView: initialView,
      ),
    );
  }
}
