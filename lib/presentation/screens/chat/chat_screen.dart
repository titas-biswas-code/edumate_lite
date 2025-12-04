import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import '../../../config/service_locator.dart';
import '../../../stores/chat_store.dart';
import '../../../stores/material_store.dart';
import '../../widgets/chat/message_bubble.dart';
import '../../widgets/chat/input_bar.dart';

class ChatScreen extends StatefulWidget {
  final int? conversationId;
  
  const ChatScreen({super.key, this.conversationId});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final chatStore = getIt<ChatStore>();
  final materialStore = getIt<MaterialStore>();
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  Future<void> _initializeChat() async {
    if (widget.conversationId != null) {
      // Load existing conversation
      await chatStore.loadConversation(widget.conversationId!);
    } else if (chatStore.currentConversation == null) {
      // Start a new conversation
      await chatStore.startNewConversation('New Chat');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Observer(
          builder: (_) => Text(chatStore.currentConversation?.title ?? 'Chat'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showMaterialFilter,
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'new') {
                _startNewChat();
              } else if (value == 'clear') {
                chatStore.clearConversation();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'new',
                child: Text('New Conversation'),
              ),
              const PopupMenuItem(value: 'clear', child: Text('Clear Chat')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: Observer(
              builder: (_) {
                if (chatStore.messages.isEmpty &&
                    chatStore.currentResponse.isEmpty) {
                  return _buildEmptyState();
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount:
                      chatStore.messages.length +
                      (chatStore.currentResponse.isNotEmpty ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index < chatStore.messages.length) {
                      final message = chatStore.messages[index];
                      return MessageBubble(message: message);
                    } else {
                      // Show current streaming response
                      return MessageBubble.streaming(
                        content: chatStore.currentResponse,
                      );
                    }
                  },
                );
              },
            ),
          ),

          // Error display
          Observer(
            builder: (_) {
              if (chatStore.error != null) {
                return Container(
                  padding: const EdgeInsets.all(12),
                  color: Theme.of(context).colorScheme.errorContainer,
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          chatStore.error!,
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onErrorContainer,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: () {
                          // Clear error - allow user to continue
                          chatStore.clearError();
                        },
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ],
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),

          // Input bar
          Observer(
            builder: (_) => InputBar(
              controller: _controller,
              onSend: _handleSend,
              isLoading: chatStore.isLoading,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 64,
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Start a conversation',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Ask questions about your study materials',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleSend() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    _controller.clear();
    await chatStore.sendMessage(text);

    // Scroll to bottom after sending
    Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
  }

  void _showMaterialFilter() {
    showDialog(
      context: context,
      builder: (context) => Observer(
        builder: (_) => AlertDialog(
          title: const Text('Filter by Materials'),
          content: materialStore.materials.isEmpty
              ? const Text('No materials available')
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      title: const Text('All Materials'),
                      leading: Icon(
                        chatStore.selectedMaterialIds == null
                            ? Icons.radio_button_checked
                            : Icons.radio_button_unchecked,
                      ),
                      onTap: () {
                        chatStore.setSelectedMaterials(null);
                        Navigator.pop(context);
                      },
                    ),
                    ...materialStore.completedMaterials.map(
                      (material) => CheckboxListTile(
                        title: Text(material.title),
                        subtitle: material.subject != null
                            ? Text(material.subject!)
                            : null,
                        value:
                            chatStore.selectedMaterialIds?.contains(
                              material.id,
                            ) ??
                            false,
                        onChanged: (checked) {
                          final current = chatStore.selectedMaterialIds ?? [];
                          if (checked == true) {
                            chatStore.setSelectedMaterials([
                              ...current,
                              material.id,
                            ]);
                          } else {
                            chatStore.setSelectedMaterials(
                              current.where((id) => id != material.id).toList(),
                            );
                          }
                        },
                      ),
                    ),
                  ],
                ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Done'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _startNewChat() async {
    await chatStore.startNewConversation('New Chat');
  }
}
