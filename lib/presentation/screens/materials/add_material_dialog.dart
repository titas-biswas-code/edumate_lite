import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import '../../../config/service_locator.dart';
import '../../../stores/material_store.dart';
import '../../../domain/services/material_processor.dart';

class AddMaterialDialog extends StatefulWidget {
  const AddMaterialDialog({super.key});

  @override
  State<AddMaterialDialog> createState() => _AddMaterialDialogState();
}

class _AddMaterialDialogState extends State<AddMaterialDialog> {
  final materialStore = getIt<MaterialStore>();
  final _titleController = TextEditingController();
  String? _selectedSubject;
  int? _selectedGrade;

  final List<String> _subjects = [
    'math',
    'science',
    'history',
    'english',
    'other',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Observer(
          builder: (_) {
            if (materialStore.isLoading) {
              return _buildProcessingView();
            }

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Add Study Material',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 24),

                // Source selection
                const Text('Choose source:'),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _SourceButton(
                      icon: Icons.picture_as_pdf,
                      label: 'PDF',
                      onTap: _pickPDF,
                    ),
                    _SourceButton(
                      icon: Icons.image,
                      label: 'Image',
                      onTap: _pickImage,
                    ),
                    _SourceButton(
                      icon: Icons.camera_alt,
                      label: 'Camera',
                      onTap: _captureCamera,
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildProcessingView() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Observer(
          builder: (_) {
            final progress = materialStore.currentProgress;
            return Column(
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(
                  progress?.stage ?? 'Processing...',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                if (progress?.message != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    progress!.message!,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
                if (progress?.progress != null) ...[
                  const SizedBox(height: 16),
                  LinearProgressIndicator(value: progress!.progress),
                  const SizedBox(height: 8),
                  Text('${(progress.progress * 100).toInt()}%'),
                ],
              ],
            );
          },
        ),
      ],
    );
  }

  Future<void> _pickPDF() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null && result.files.single.path != null) {
      await _showMetadataDialog(
        filePath: result.files.single.path!,
        sourceType: 'pdf',
        suggestedTitle: result.files.single.name.replaceAll('.pdf', ''),
      );
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      await _showMetadataDialog(
        filePath: image.path,
        sourceType: 'image',
        suggestedTitle: 'Image ${DateTime.now().toString().substring(0, 10)}',
      );
    }
  }

  Future<void> _captureCamera() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.camera);

    if (image != null) {
      // Read bytes from captured image
      final bytes = await image.readAsBytes();

      await _showMetadataDialog(
        filePath: image.path,
        sourceType: 'camera',
        suggestedTitle: 'Camera ${DateTime.now().toString().substring(0, 10)}',
        imageBytes: bytes,
      );
    }
  }

  Future<void> _showMetadataDialog({
    required String filePath,
    required String sourceType,
    required String suggestedTitle,
    dynamic imageBytes,
  }) async {
    _titleController.text = suggestedTitle;

    final proceed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Material Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _selectedSubject,
              decoration: const InputDecoration(
                labelText: 'Subject (Optional)',
                border: OutlineInputBorder(),
              ),
              items: _subjects
                  .map(
                    (s) => DropdownMenuItem(
                      value: s,
                      child: Text(s.toUpperCase()),
                    ),
                  )
                  .toList(),
              onChanged: (value) => setState(() => _selectedSubject = value),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              initialValue: _selectedGrade,
              decoration: const InputDecoration(
                labelText: 'Grade (Optional)',
                border: OutlineInputBorder(),
              ),
              items: List.generate(6, (i) => i + 5)
                  .map(
                    (g) => DropdownMenuItem(value: g, child: Text('Grade $g')),
                  )
                  .toList(),
              onChanged: (value) => setState(() => _selectedGrade = value),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Process'),
          ),
        ],
      ),
    );

    if (proceed == true) {
      final input = MaterialInput(
        title: _titleController.text,
        sourceType: sourceType,
        content:
            imageBytes ?? filePath, // Use bytes for camera, path for others
        subject: _selectedSubject,
        gradeLevel: _selectedGrade,
      );

      // Close the main dialog
      if (mounted) Navigator.pop(context);

      // Start processing in background (non-blocking)
      materialStore.processMaterial(input);

      // Show immediate feedback
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Processing started in background...'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }
}

class _SourceButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _SourceButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 80,
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40),
            const SizedBox(height: 8),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}
