import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import '../../../stores/material_store.dart';
import '../../../config/service_locator.dart';

/// Widget to display all ongoing material processing jobs
class ProcessingJobsList extends StatelessWidget {
  const ProcessingJobsList({super.key});

  @override
  Widget build(BuildContext context) {
    final materialStore = getIt<MaterialStore>();

    return Observer(
      builder: (_) {
        if (!materialStore.hasProcessingJobs) {
          return const SizedBox.shrink();
        }

        return Card(
          margin: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.sync, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Processing (${materialStore.processingJobsCount})',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: materialStore.processingJobs.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final entry = materialStore.processingJobs.entries.elementAt(index);
                  final state = entry.value;

                  return Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                state.material.title,
                                style: Theme.of(context).textTheme.bodyLarge,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (state.isComplete)
                              const Icon(Icons.check_circle, color: Colors.green, size: 20)
                            else if (state.isError)
                              const Icon(Icons.error, color: Colors.red, size: 20)
                            else
                              SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  value: state.progress,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          state.message,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: state.isError ? Colors.red : null,
                              ),
                        ),
                        if (!state.isError) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: LinearProgressIndicator(
                                  value: state.progress,
                                  backgroundColor: Colors.grey.shade200,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${(state.progress * 100).toInt()}%',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ],
                        if (state.isError && state.errorMessage != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            state.errorMessage!,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.red,
                                ),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

