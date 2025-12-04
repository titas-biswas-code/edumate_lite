import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import '../../../config/service_locator.dart';
import '../../../stores/app_store.dart';
import '../../../stores/material_store.dart';
import '../onboarding/onboarding_screen.dart';
import '../shell/app_shell.dart';

/// Main entry point that shows onboarding or the app shell
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final appStore = getIt<AppStore>();
  final materialStore = getIt<MaterialStore>();

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    await materialStore.loadMaterials();
  }

  @override
  Widget build(BuildContext context) {
    return Observer(
      builder: (_) {
        if (!appStore.isAppReady) {
          // Show onboarding/model loading
          return OnboardingScreen(
            onComplete: () {
              setState(() {});
            },
          );
        }

        // Main app with bottom navigation
        return const AppShell();
      },
    );
  }
}


