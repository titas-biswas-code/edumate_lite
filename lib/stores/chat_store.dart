import 'package:mobx/mobx.dart';
import '../domain/entities/conversation.dart';
import '../domain/entities/message.dart';
import '../domain/services/rag_engine.dart';
import '../domain/services/conversation_manager.dart';
import '../config/service_locator.dart';

part 'chat_store.g.dart';

class ChatStore = ChatStoreBase with _$ChatStore;

abstract class ChatStoreBase with Store {
  final RagEngine _ragEngine = getIt<RagEngine>();
  final ConversationManager _conversationManager = getIt<ConversationManager>();

  @observable
  Conversation? currentConversation;

  @observable
  ObservableList<Message> messages = ObservableList<Message>();

  @observable
  bool isLoading = false;

  @observable
  String? error;

  @action
  void clearError() {
    error = null;
  }

  @observable
  String currentResponse = '';

  @observable
  List<int>? selectedMaterialIds;

  @action
  Future<void> startNewConversation(String title, {int? materialId}) async {
    isLoading = true;
    error = null;

    final result = await _conversationManager.createConversation(
      title: title,
      materialId: materialId,
    );

    result.fold(
      (failure) {
        error = failure.message;
        isLoading = false;
      },
      (conversation) {
        currentConversation = conversation;
        messages.clear();
        isLoading = false;
      },
    );
  }

  @action
  Future<void> loadConversation(int conversationId) async {
    isLoading = true;
    error = null;

    final convResult = await _conversationManager.getConversation(conversationId);
    final historyResult = await _conversationManager.getContextHistory(conversationId);

    convResult.fold(
      (failure) {
        error = failure.message;
        isLoading = false;
      },
      (conversation) {
        currentConversation = conversation;
        
        historyResult.fold(
          (failure) => error = failure.message,
          (history) => messages = ObservableList.of(history),
        );
        
        isLoading = false;
      },
    );
  }

  @action
  Future<void> sendMessage(String content) async {
    if (currentConversation == null) {
      error = 'No active conversation';
      return;
    }

    isLoading = true;
    error = null;
    currentResponse = '';

    // Add user message
    final userMsgResult = await _conversationManager.addMessage(
      currentConversation!.id,
      role: 'user',
      content: content,
    );

    userMsgResult.fold(
      (failure) {
        error = failure.message;
        isLoading = false;
        return;
      },
      (userMessage) {
        messages.add(userMessage);
      },
    );

    // Get RAG response
    final ragResult = await _ragEngine.answer(
      content,
      materialIds: selectedMaterialIds,
      conversationHistory: messages.toList(),
    );

    await ragResult.fold(
      (failure) async {
        error = failure.message;
        isLoading = false;
      },
      (responseStream) async {
        final buffer = StringBuffer();
        List<int>? retrievedChunkIds;
        double? confidence;

        await for (final response in responseStream) {
          if (!response.isComplete) {
            buffer.write(response.content);
            currentResponse = buffer.toString();
          }

          if (response.retrievedChunks != null) {
            retrievedChunkIds = response.retrievedChunks!
                .map((sc) => sc.chunk.id)
                .toList();
          }
          confidence = response.confidenceScore;

          if (response.isComplete) {
            // Save assistant message
            final assistantMsgResult = await _conversationManager.addMessage(
              currentConversation!.id,
              role: 'assistant',
              content: buffer.toString(),
              retrievedChunkIds: retrievedChunkIds,
              confidenceScore: confidence,
            );

            assistantMsgResult.fold(
              (failure) => error = failure.message,
              (assistantMessage) {
                messages.add(assistantMessage);
                currentResponse = '';
              },
            );
          }
        }

        isLoading = false;
      },
    );
  }

  @action
  void clearConversation() {
    currentConversation = null;
    messages.clear();
    currentResponse = '';
    error = null;
  }

  @action
  void setSelectedMaterials(List<int>? materialIds) {
    selectedMaterialIds = materialIds;
  }
}

