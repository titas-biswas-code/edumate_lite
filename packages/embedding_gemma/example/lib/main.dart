import 'package:flutter/material.dart';
import 'package:embedding_gemma/embedding_gemma.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EmbeddingGemma Example',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const EmbeddingDemo(),
    );
  }
}

class EmbeddingDemo extends StatefulWidget {
  const EmbeddingDemo({Key? key}) : super(key: key);

  @override
  State<EmbeddingDemo> createState() => _EmbeddingDemoState();
}

class _EmbeddingDemoState extends State<EmbeddingDemo> {
  EmbeddingGemma? _embedder;
  bool _isInstalling = false;
  bool _isInitializing = false;
  bool _isInstalled = false;
  bool _isInitialized = false;
  String _status = 'Not installed';
  double _installProgress = 0.0;
  final TextEditingController _textController = TextEditingController();
  List<double>? _lastEmbedding;

  @override
  void initState() {
    super.initState();
    _checkInstalled();
  }

  @override
  void dispose() {
    _embedder?.dispose();
    _textController.dispose();
    super.dispose();
  }

  Future<void> _checkInstalled() async {
    final hasModel = await EmbeddingGemma.hasActiveModel();
    setState(() {
      _isInstalled = hasModel;
      _status = hasModel ? 'Model installed' : 'Not installed';
    });
  }

  Future<void> _install() async {
    setState(() {
      _isInstalling = true;
      _status = 'Installing models...';
      _installProgress = 0.0;
    });

    try {
      print('=== STARTING INSTALLATION ===');

      final installation = await EmbeddingGemma.installModel()
          .modelFromAsset(
              'assets/models/embeddinggemma-300M_seq2048_mixed-precision.tflite')
          .tokenizerFromAsset('assets/models/sentencepiece.model')
          .withProgress((progress) {
        setState(() {
          _installProgress = progress;
          _status = 'Installing: ${(progress * 100).toInt()}%';
        });
        print('Installation progress: ${(progress * 100).toInt()}%');
      }).install();

      print('=== INSTALLATION COMPLETE ===');
      print('Model path: ${installation.modelPath}');
      print('Tokenizer path: ${installation.tokenizerPath}');

      setState(() {
        _isInstalled = true;
        _status = 'Models installed successfully!';
      });
    } catch (e, stack) {
      print('=== INSTALLATION FAILED ===');
      print('Error: $e');
      print('Stack: $stack');

      setState(() {
        _status = 'Installation error: $e';
      });
    } finally {
      setState(() {
        _isInstalling = false;
      });
    }
  }

  Future<void> _initialize() async {
    setState(() {
      _isInitializing = true;
      _status = 'Initializing...';
    });

    try {
      print('=== INITIALIZING MODEL ===');

      final embedder = await EmbeddingGemma.getActiveModel(
        backend: EmbeddingBackend.GPU,
      );

      print('=== MODEL INITIALIZED ===');

      setState(() {
        _embedder = embedder;
        _isInitialized = true;
        final backend =
            embedder.actualBackend?.toString().split('.').last ?? 'Unknown';
        _status = 'Ready ($backend backend)';
      });
    } catch (e, stack) {
      print('=== INITIALIZATION FAILED ===');
      print('Error: $e');
      print('Stack: $stack');

      setState(() {
        _status = 'Init error: $e';
      });
    } finally {
      setState(() {
        _isInitializing = false;
      });
    }
  }

  Future<void> _embedText(bool isQuery) async {
    if (_embedder == null || _textController.text.isEmpty) return;

    setState(() {
      _status = 'Generating embedding...';
    });

    try {
      print('=== EMBEDDING TEXT ===');
      print('Text: ${_textController.text}');
      print('IsQuery: $isQuery');

      final embedding = isQuery
          ? await _embedder!.embedQuery(_textController.text)
          : await _embedder!.embed(_textController.text);

      print('=== EMBEDDING GENERATED ===');
      print('Dimensions: ${embedding.length}');
      print('First 5 values: ${embedding.take(5).toList()}');

      // Verify L2 norm
      final norm = embedding.map((v) => v * v).reduce((a, b) => a + b);
      print('L2 norm squared: $norm (should be ~1.0)');

      setState(() {
        _lastEmbedding = embedding;
        _status =
            'Embedding: ${embedding.length} dims, norm²=${norm.toStringAsFixed(3)}';
      });
    } catch (e, stack) {
      print('=== EMBEDDING FAILED ===');
      print('Error: $e');
      print('Stack: $stack');

      setState(() {
        _status = 'Embedding error: $e';
      });
    }
  }

  Future<void> _testBatch() async {
    if (_embedder == null) return;

    setState(() {
      _status = 'Testing batch embeddings...';
    });

    try {
      print('=== BATCH EMBEDDING TEST ===');

      final texts = [
        'First document for testing',
        'Second document with different content',
        'Third document to complete the batch',
      ];

      print('Batch size: ${texts.length}');
      print('Calling embedBatch...');

      final embeddings = await _embedder!.embedBatch(texts);

      print('=== BATCH RESULT RECEIVED ===');
      print('Result type: ${embeddings.runtimeType}');
      print('Number of embeddings: ${embeddings.length}');

      for (int i = 0; i < embeddings.length; i++) {
        print('Embedding $i:');
        print('  Type: ${embeddings[i].runtimeType}');
        print('  Length: ${embeddings[i].length}');

        // Access first value to trigger any lazy cast issues
        final firstValue = embeddings[i][0];
        print('  First value: $firstValue (type: ${firstValue.runtimeType})');

        // Access a few more to be sure
        final values = embeddings[i].take(3).toList();
        print('  First 3 values: $values');
      }

      setState(() {
        _status =
            'Batch test passed! Generated ${embeddings.length} embeddings';
      });

      print('✅ BATCH TEST PASSED!');
    } catch (e, stack) {
      print('=== BATCH TEST FAILED ===');
      print('Error: $e');
      print('Error type: ${e.runtimeType}');
      print('Stack trace: $stack');

      setState(() {
        _status = 'Batch error: $e';
      });
    }
  }

  Future<void> _testTokenCount() async {
    if (_embedder == null) return;

    setState(() {
      _status = 'Testing token counting...';
    });

    try {
      print('=== TOKEN COUNTING TEST ===');

      final testCases = [
        'Hello world',
        'The quick brown fox jumps over the lazy dog',
        'Lorem ipsum dolor sit amet, consectetur adipiscing elit. ' * 10,
      ];

      for (final text in testCases) {
        final count = await _embedder!.countTokens(text);
        final countWithoutPrompt =
            await _embedder!.countTokens(text, withPrompt: false);

        final preview = text.length > 50 ? '${text.substring(0, 50)}...' : text;
        print('Text: "$preview"');
        print('  Chars: ${text.length}');
        print('  Tokens (with prompt): $count');
        print('  Tokens (without prompt): $countWithoutPrompt');
        print('  Prompt overhead: ${count - countWithoutPrompt} tokens');
      }

      // Test long text
      final longText = 'word ' * 500;
      final longCount = await _embedder!.countTokens(longText);
      print('Long text (500 words): $longCount tokens');

      setState(() {
        _status = 'Token counting works! Long text: $longCount tokens';
      });

      print('✅ TOKEN COUNTING TEST PASSED!');
    } catch (e, stack) {
      print('❌ TOKEN COUNTING FAILED: $e');
      print('Stack: $stack');
      setState(() {
        _status = 'Token count error: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('EmbeddingGemma Test'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Status
              Card(
                color: _status.contains('error') || _status.contains('Error')
                    ? Colors.red.shade50
                    : null,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Text(_status),
                ),
              ),
              const SizedBox(height: 16),

              // Install progress
              if (_isInstalling) ...[
                LinearProgressIndicator(value: _installProgress),
                const SizedBox(height: 8),
                Text('Progress: ${(_installProgress * 100).toInt()}%'),
                const SizedBox(height: 16),
              ],

              // Install button
              if (!_isInstalled)
                ElevatedButton(
                  onPressed: _isInstalling ? null : _install,
                  child: const Text('Install Models'),
                ),

              // Initialize button
              if (_isInstalled && !_isInitialized)
                ElevatedButton(
                  onPressed: _isInitializing ? null : _initialize,
                  child: const Text('Initialize Model'),
                ),

              // Text input and embedding buttons
              if (_isInitialized) ...[
                const SizedBox(height: 16),
                TextField(
                  controller: _textController,
                  decoration: const InputDecoration(
                    labelText: 'Enter text',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _embedText(false),
                        child: const Text('Embed (Doc)'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _embedText(true),
                        child: const Text('Embed (Query)'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _testBatch,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                        ),
                        child: const Text('Test Batch'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _testTokenCount,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple,
                        ),
                        child: const Text('Test Tokens'),
                      ),
                    ),
                  ],
                ),
              ],

              // Embedding preview
              if (_lastEmbedding != null) ...[
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Embedding (first 10 values):',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _lastEmbedding!
                              .take(10)
                              .map((v) => v.toStringAsFixed(6))
                              .join('\n'),
                          style: const TextStyle(
                              fontFamily: 'monospace', fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
