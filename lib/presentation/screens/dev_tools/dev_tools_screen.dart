import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import '../../../config/service_locator.dart';
import '../../../stores/material_store.dart';
import '../../../infrastructure/database/objectbox_vector_store.dart';
import '../../../domain/entities/chunk.dart';

class DevToolsScreen extends StatefulWidget {
  const DevToolsScreen({super.key});

  @override
  State<DevToolsScreen> createState() => _DevToolsScreenState();
}

class _DevToolsScreenState extends State<DevToolsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final materialStore = getIt<MaterialStore>();
  final vectorStore = getIt<ObjectBoxVectorStore>();

  List<Chunk> _chunks = [];
  bool _isLoading = false;
  String _filterQuery = '';
  int? _selectedMaterialId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadChunks();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadChunks() async {
    setState(() => _isLoading = true);
    try {
      final allChunks = await vectorStore.getAllChunks();
      setState(() {
        _chunks = allChunks;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  List<Chunk> get filteredChunks {
    var result = _chunks;

    if (_selectedMaterialId != null) {
      result = result.where((c) => c.material.targetId == _selectedMaterialId).toList();
    }

    if (_filterQuery.isNotEmpty) {
      final query = _filterQuery.toLowerCase();
      result = result.where((c) {
        return c.content.toLowerCase().contains(query) ||
            (c.metadataJson?.toLowerCase().contains(query) ?? false);
      }).toList();
    }

    return result;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug Console'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Chunks', icon: Icon(Icons.data_array)),
            Tab(text: 'Processing', icon: Icon(Icons.analytics)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadChunks,
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildChunksTab(colorScheme),
          _buildProcessingTab(colorScheme),
        ],
      ),
    );
  }

  Widget _buildChunksTab(ColorScheme colorScheme) {
    return Column(
      children: [
        // Filters
        Container(
          padding: const EdgeInsets.all(12),
          color: colorScheme.surfaceContainerHighest,
          child: Column(
            children: [
              // Search
              TextField(
                decoration: InputDecoration(
                  hintText: 'Search chunks...',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  isDense: true,
                  filled: true,
                  fillColor: colorScheme.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (value) => setState(() => _filterQuery = value),
              ),
              const SizedBox(height: 8),
              // Material filter
              Observer(
                builder: (_) => SizedBox(
                  height: 36,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      FilterChip(
                        label: const Text('All'),
                        selected: _selectedMaterialId == null,
                        onSelected: (_) =>
                            setState(() => _selectedMaterialId = null),
                      ),
                      const SizedBox(width: 8),
                      ...materialStore.materials.map(
                        (m) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(
                              m.title.length > 15
                                  ? '${m.title.substring(0, 15)}...'
                                  : m.title,
                            ),
                            selected: _selectedMaterialId == m.id,
                            onSelected: (_) =>
                                setState(() => _selectedMaterialId = m.id),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // Stats bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Text(
                '${filteredChunks.length} chunks',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const Spacer(),
              if (_isLoading)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
        ),

        // Chunks list
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : filteredChunks.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.inbox,
                            size: 64,
                            color: colorScheme.onSurfaceVariant.withOpacity(0.5),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No chunks found',
                            style: TextStyle(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(12),
                      itemCount: filteredChunks.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final chunk = filteredChunks[index];
                        return _ChunkCard(chunk: chunk);
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildProcessingTab(ColorScheme colorScheme) {
    return Observer(
      builder: (_) {
        final jobs = materialStore.processingJobs;

        if (jobs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.hourglass_empty,
                  size: 64,
                  color: colorScheme.onSurfaceVariant.withOpacity(0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  'No active processing jobs',
                  style: TextStyle(color: colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: jobs.length,
          itemBuilder: (context, index) {
            final entry = jobs.entries.elementAt(index);
            final state = entry.value;

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          state.isComplete
                              ? Icons.check_circle
                              : state.isError
                                  ? Icons.error
                                  : Icons.sync,
                          color: state.isComplete
                              ? Colors.green
                              : state.isError
                                  ? Colors.red
                                  : Colors.blue,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            state.material.title,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _DetailRow(label: 'Status', value: state.message),
                    _DetailRow(
                      label: 'Progress',
                      value: '${(state.progress * 100).toStringAsFixed(1)}%',
                    ),
                    if (state.errorMessage != null)
                      _DetailRow(
                        label: 'Error',
                        value: state.errorMessage!,
                        isError: true,
                      ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: state.progress,
                      backgroundColor: Colors.grey.shade200,
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _ChunkCard extends StatefulWidget {
  final Chunk chunk;

  const _ChunkCard({required this.chunk});

  @override
  State<_ChunkCard> createState() => _ChunkCardState();
}

class _ChunkCardState extends State<_ChunkCard> {
  bool _expanded = false;

  Map<String, dynamic> _parseMetadata(String? json) {
    if (json == null || json.isEmpty) return {};
    try {
      return jsonDecode(json) as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final chunk = widget.chunk;
    final metadata = _parseMetadata(chunk.metadataJson);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => setState(() => _expanded = !_expanded),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'ID: ${chunk.id}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      chunk.chunkType,
                      style: TextStyle(
                        fontSize: 11,
                        color: colorScheme.onSecondaryContainer,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    size: 20,
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Preview
              Text(
                chunk.content,
                maxLines: _expanded ? null : 3,
                overflow: _expanded ? null : TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontFamily: 'monospace',
                    ),
              ),

              if (_expanded) ...[
                const Divider(height: 16),
                Text(
                  'Metadata',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    _MetadataChip(
                      label: 'Material',
                      value: '${chunk.material.targetId}',
                    ),
                    if (chunk.pageNumber != null)
                      _MetadataChip(
                        label: 'Page',
                        value: '${chunk.pageNumber}',
                      ),
                    if (chunk.sectionIndex != null)
                      _MetadataChip(
                        label: 'Section',
                        value: '${chunk.sectionIndex}',
                      ),
                    _MetadataChip(
                      label: 'Chars',
                      value: '${chunk.content.length}',
                    ),
                    if (metadata['actual_tokens'] != null)
                      _MetadataChip(
                        label: 'Tokens',
                        value: '${metadata['actual_tokens']}',
                      ),
                    if (metadata['words'] != null)
                      _MetadataChip(
                        label: 'Words',
                        value: '${metadata['words']}',
                      ),
                    _MetadataChip(
                      label: 'Has Embedding',
                      value: chunk.embedding != null ? 'Yes' : 'No',
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _MetadataChip extends StatelessWidget {
  final String label;
  final String value;

  const _MetadataChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(4),
      ),
      child: RichText(
        text: TextSpan(
          style: Theme.of(context).textTheme.bodySmall,
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isError;

  const _DetailRow({
    required this.label,
    required this.value,
    this.isError = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isError ? Colors.red : null,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

