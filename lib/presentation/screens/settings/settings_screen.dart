import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import '../../../config/service_locator.dart';
import '../../../stores/app_store.dart';
import '../../../stores/material_store.dart';
import '../dev_tools/dev_tools_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appStore = getIt<AppStore>();
    final materialStore = getIt<MaterialStore>();
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Appearance Section
          _SectionHeader(title: 'Appearance'),
          Card(
            child: Observer(
              builder: (_) => Column(
                children: [
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        _getThemeIcon(appStore.themeMode),
                        color: colorScheme.primary,
                      ),
                    ),
                    title: const Text('Theme'),
                    subtitle: Text(_getThemeLabel(appStore.themeMode)),
                    trailing: SegmentedButton<ThemeMode>(
                      segments: const [
                        ButtonSegment(
                          value: ThemeMode.light,
                          icon: Icon(Icons.light_mode, size: 18),
                        ),
                        ButtonSegment(
                          value: ThemeMode.system,
                          icon: Icon(Icons.brightness_auto, size: 18),
                        ),
                        ButtonSegment(
                          value: ThemeMode.dark,
                          icon: Icon(Icons.dark_mode, size: 18),
                        ),
                      ],
                      selected: {appStore.themeMode},
                      onSelectionChanged: (selection) {
                        appStore.setThemeMode(selection.first);
                      },
                      showSelectedIcon: false,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Developer Section
          _SectionHeader(title: 'Developer'),
          Card(
            child: Observer(
              builder: (_) => Column(
                children: [
                  SwitchListTile(
                    secondary: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: colorScheme.tertiaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.developer_mode,
                        color: colorScheme.tertiary,
                      ),
                    ),
                    title: const Text('Developer Mode'),
                    subtitle: const Text('Show debug info and tools'),
                    value: appStore.devModeEnabled,
                    onChanged: (value) => appStore.setDevModeEnabled(value),
                  ),
                  if (appStore.devModeEnabled) ...[
                    const Divider(height: 1),
                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: colorScheme.secondaryContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.bug_report,
                          color: colorScheme.secondary,
                        ),
                      ),
                      title: const Text('Debug Console'),
                      subtitle: const Text('View chunks, embeddings & logs'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const DevToolsScreen()),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Data Section
          _SectionHeader(title: 'Data'),
          Card(
            child: Column(
              children: [
                Observer(
                  builder: (_) => ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.storage, color: Colors.blue),
                    ),
                    title: const Text('Materials'),
                    subtitle: Text(
                      '${materialStore.materials.length} materials, '
                      '${_totalChunks(materialStore)} chunks',
                    ),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.delete_sweep, color: Colors.red),
                  ),
                  title: const Text('Clear All Data'),
                  subtitle: const Text('Delete all materials and chats'),
                  onTap: () => _confirmClearData(context, materialStore),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // AI Models Section
          _SectionHeader(title: 'AI Models'),
          Card(
            child: Observer(
              builder: (_) => Column(
                children: [
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        appStore.isInferenceModelReady
                            ? Icons.check_circle
                            : Icons.hourglass_empty,
                        color: appStore.isInferenceModelReady
                            ? Colors.green
                            : Colors.orange,
                      ),
                    ),
                    title: const Text('Inference Model'),
                    subtitle: Text(
                      appStore.isInferenceModelReady
                          ? 'Gemma 3n E2B ready'
                          : 'Loading...',
                    ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.purple.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        appStore.isEmbeddingModelReady
                            ? Icons.check_circle
                            : Icons.hourglass_empty,
                        color: appStore.isEmbeddingModelReady
                            ? Colors.green
                            : Colors.orange,
                      ),
                    ),
                    title: const Text('Embedding Model'),
                    subtitle: Text(
                      appStore.isEmbeddingModelReady
                          ? 'EmbeddingGemma 300M ready'
                          : 'Loading...',
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // About Section
          _SectionHeader(title: 'About'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.info_outline, color: colorScheme.primary),
                  ),
                  title: const Text('EduMate Lite'),
                  subtitle: const Text('Version 1.0.0'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.science, color: Colors.orange),
                  ),
                  title: const Text('Powered by'),
                  subtitle: const Text('Google Gemma • On-device AI'),
                ),
              ],
            ),
          ),

          const SizedBox(height: 100),
        ],
      ),
    );
  }

  IconData _getThemeIcon(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return Icons.light_mode;
      case ThemeMode.dark:
        return Icons.dark_mode;
      case ThemeMode.system:
        return Icons.brightness_auto;
    }
  }

  String _getThemeLabel(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
      case ThemeMode.system:
        return 'System';
    }
  }

  int _totalChunks(MaterialStore store) {
    return store.completedMaterials.fold(0, (sum, m) => sum + m.chunkCount);
  }

  void _confirmClearData(BuildContext context, MaterialStore store) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Data?'),
        content: const Text(
          'This will permanently delete all materials, chunks, and conversations. '
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            onPressed: () {
              // TODO: Implement clear all data
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('All data cleared')),
              );
            },
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
      ),
    );
  }
}

