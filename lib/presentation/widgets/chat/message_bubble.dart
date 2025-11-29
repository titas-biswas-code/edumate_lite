import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import '../../../domain/entities/message.dart';

class MessageBubble extends StatelessWidget {
  final Message? message;
  final String? streamingContent;

  const MessageBubble({
    super.key,
    this.message,
  }) : streamingContent = null;

  const MessageBubble.streaming({
    super.key,
    required String content,
  })  : streamingContent = content,
        message = null;

  bool get isUser => message?.role == 'user';
  bool get isStreaming => streamingContent != null;

  @override
  Widget build(BuildContext context) {
    final content = streamingContent ?? message?.content ?? '';
    final alignment = isUser ? Alignment.centerRight : Alignment.centerLeft;

    return Align(
      alignment: alignment,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: Card(
          color: isUser
              ? Theme.of(context).colorScheme.primaryContainer
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!isUser && !isStreaming) ...[
                  Row(
                    children: [
                      Icon(
                        Icons.smart_toy,
                        size: 16,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'EduMate',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                      ),
                      if (message?.confidenceScore != null &&
                          message!.confidenceScore! < 0.7) ...[
                        const SizedBox(width: 8),
                        Tooltip(
                          message: 'Low confidence response',
                          child: Icon(
                            Icons.warning_amber,
                            size: 16,
                            color: Theme.of(context).colorScheme.tertiary,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
                MarkdownBody(
                  data: content,
                  styleSheet: MarkdownStyleSheet.fromTheme(
                    Theme.of(context),
                  ),
                ),
                if (isStreaming) ...[
                  const SizedBox(height: 4),
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ],
                if (!isUser && message?.timestamp != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    _formatTime(message!.timestamp),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.color
                              ?.withValues(alpha: 0.6),
                        ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

