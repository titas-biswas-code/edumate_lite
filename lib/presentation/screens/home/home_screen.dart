import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import '../../../config/service_locator.dart';
import '../../../stores/app_store.dart';
import '../../../stores/material_store.dart';
import '../../../stores/chat_store.dart';
import '../chat/chat_screen.dart';
import '../materials/materials_screen.dart';
import '../onboarding/onboarding_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final appStore = getIt<AppStore>();
  final materialStore = getIt<MaterialStore>();
  final chatStore = getIt<ChatStore>();

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

        // Main app
        return Scaffold(
          appBar: AppBar(
            title: const Text('EduMate Lite'),
            actions: [
              IconButton(
                icon: Icon(
                  appStore.themeMode == ThemeMode.dark
                      ? Icons.light_mode
                      : Icons.dark_mode,
                ),
                onPressed: () {
                  appStore.setThemeMode(
                    appStore.themeMode == ThemeMode.dark
                        ? ThemeMode.light
                        : ThemeMode.dark,
                  );
                },
              ),
            ],
          ),
          body: _buildMainContent(),
        );
      },
    );
  }

  Widget _buildMainContent() {
    return Observer(
      builder: (_) => Stack(
        children: [
          CustomScrollView(
            slivers: [
              // Hero section
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context).colorScheme.primaryContainer,
                        Theme.of(context).colorScheme.secondaryContainer,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome back!',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        materialStore.materials.isEmpty
                            ? 'Upload your first study material to get started'
                            : 'You have ${materialStore.completedMaterials.length} materials ready',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ),

              // Quick actions grid
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.1,
                  ),
                  delegate: SliverChildListDelegate([
                    _QuickActionCard(
                      icon: Icons.upload_file,
                      title: 'Add Material',
                      subtitle: 'Upload PDF or image',
                      gradient: LinearGradient(
                        colors: [Colors.blue.shade400, Colors.blue.shade600],
                      ),
                      onTap: () => _navigateToMaterials(),
                    ),
                    _QuickActionCard(
                      icon: Icons.library_books,
                      title: 'My Library',
                      subtitle: '${materialStore.materials.length} materials',
                      gradient: LinearGradient(
                        colors: [Colors.purple.shade400, Colors.purple.shade600],
                      ),
                      onTap: () => _navigateToMaterials(),
                    ),
                    _QuickActionCard(
                      icon: Icons.quiz,
                      title: 'Practice Quiz',
                      subtitle: 'Test knowledge',
                      gradient: LinearGradient(
                        colors: [Colors.orange.shade400, Colors.orange.shade600],
                      ),
                      onTap: () => _showQuizDialog(),
                    ),
                    _QuickActionCard(
                      icon: Icons.history_edu,
                      title: 'Recent Chats',
                      subtitle: 'Continue learning',
                      gradient: LinearGradient(
                        colors: [Colors.teal.shade400, Colors.teal.shade600],
                      ),
                      onTap: () => _navigateToChat(),
                    ),
                  ]),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 80)),
            ],
          ),

          // Floating chat button
          Positioned(
            right: 16,
            bottom: 16,
            child: FloatingActionButton.extended(
              onPressed: () => _navigateToChat(),
              icon: const Icon(Icons.chat),
              label: const Text('Ask Question'),
              heroTag: 'chat_fab',
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToChat() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ChatScreen()),
    );
  }

  void _navigateToMaterials() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const MaterialsScreen()),
    );
  }

  void _showQuizDialog() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Quiz feature coming soon!')),
    );
  }
}


class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Gradient gradient;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(gradient: gradient),
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40, color: Colors.white),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}


