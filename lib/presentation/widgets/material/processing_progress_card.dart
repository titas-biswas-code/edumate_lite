import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import '../../../stores/material_store.dart';
import '../../../config/service_locator.dart';

/// Modern processing progress card with step indicators
class ProcessingProgressCard extends StatelessWidget {
  const ProcessingProgressCard({super.key});

  @override
  Widget build(BuildContext context) {
    final materialStore = getIt<MaterialStore>();
    final colorScheme = Theme.of(context).colorScheme;

    return Observer(
      builder: (_) {
        if (!materialStore.hasProcessingJobs) {
          return const SizedBox.shrink();
        }

        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withOpacity(0.5),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: colorScheme.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Processing Materials',
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          Text(
                            '${materialStore.processingJobsCount} ${materialStore.processingJobsCount == 1 ? 'item' : 'items'} in queue',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Jobs list
              ...materialStore.processingJobs.entries.map((entry) {
                final state = entry.value;
                return _ProcessingJobItem(
                  title: state.material.title,
                  message: state.message,
                  progress: state.progress,
                  isComplete: state.isComplete,
                  isError: state.isError,
                  errorMessage: state.errorMessage,
                );
              }),
            ],
          ),
        );
      },
    );
  }
}

class _ProcessingJobItem extends StatelessWidget {
  final String title;
  final String message;
  final double progress;
  final bool isComplete;
  final bool isError;
  final String? errorMessage;

  const _ProcessingJobItem({
    required this.title,
    required this.message,
    required this.progress,
    required this.isComplete,
    required this.isError,
    this.errorMessage,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // Determine current step based on message
    final currentStep = _getStepFromMessage(message);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title row
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              _StatusBadge(
                isComplete: isComplete,
                isError: isError,
                progress: progress,
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Step indicators
          _StepIndicators(currentStep: currentStep, isError: isError),

          const SizedBox(height: 12),

          // Current status message
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isError
                  ? Colors.red.withOpacity(0.1)
                  : colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  isError
                      ? Icons.error_outline
                      : isComplete
                          ? Icons.check_circle_outline
                          : Icons.sync,
                  size: 16,
                  color: isError
                      ? Colors.red
                      : isComplete
                          ? Colors.green
                          : colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isError ? (errorMessage ?? message) : message,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isError ? Colors.red : null,
                        ),
                  ),
                ),
              ],
            ),
          ),

          if (!isError && !isComplete) ...[
            const SizedBox(height: 12),
            // Progress bar
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 6,
                      backgroundColor: colorScheme.surfaceContainerHighest,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${(progress * 100).toInt()}%',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  int _getStepFromMessage(String message) {
    final lowerMessage = message.toLowerCase();
    if (lowerMessage.contains('extract') || lowerMessage.contains('reading')) {
      return 0;
    } else if (lowerMessage.contains('chunk')) {
      return 1;
    } else if (lowerMessage.contains('embed')) {
      return 2;
    } else if (lowerMessage.contains('complete') || lowerMessage.contains('done')) {
      return 3;
    }
    return 0;
  }
}

class _StepIndicators extends StatelessWidget {
  final int currentStep;
  final bool isError;

  const _StepIndicators({
    required this.currentStep,
    required this.isError,
  });

  static const _steps = ['Extract', 'Chunk', 'Embed', 'Done'];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: List.generate(_steps.length * 2 - 1, (index) {
        if (index.isOdd) {
          // Connector line
          final stepIndex = index ~/ 2;
          final isCompleted = stepIndex < currentStep;
          return Expanded(
            child: Container(
              height: 2,
              color: isCompleted
                  ? Colors.green
                  : colorScheme.surfaceContainerHighest,
            ),
          );
        }

        // Step dot
        final stepIndex = index ~/ 2;
        final isCompleted = stepIndex < currentStep;
        final isCurrent = stepIndex == currentStep;

        return Column(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isCompleted
                    ? Colors.green
                    : isCurrent
                        ? (isError ? Colors.red : colorScheme.primary)
                        : colorScheme.surfaceContainerHighest,
              ),
              child: Center(
                child: isCompleted
                    ? const Icon(Icons.check, size: 14, color: Colors.white)
                    : isCurrent && isError
                        ? const Icon(Icons.close, size: 14, color: Colors.white)
                        : isCurrent
                            ? SizedBox(
                                width: 12,
                                height: 12,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                '${stepIndex + 1}',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _steps[stepIndex],
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: isCurrent
                        ? colorScheme.primary
                        : colorScheme.onSurfaceVariant,
                    fontWeight: isCurrent ? FontWeight.bold : null,
                  ),
            ),
          ],
        );
      }),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final bool isComplete;
  final bool isError;
  final double progress;

  const _StatusBadge({
    required this.isComplete,
    required this.isError,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (isComplete) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.green.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, size: 14, color: Colors.green),
            const SizedBox(width: 4),
            Text(
              'Complete',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Colors.green,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
      );
    }

    if (isError) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error, size: 14, color: Colors.red),
            const SizedBox(width: 4),
            Text(
              'Failed',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Colors.red,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '${(progress * 100).toInt()}%',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }
}



