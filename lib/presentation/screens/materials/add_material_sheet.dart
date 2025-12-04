import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import '../../../config/service_locator.dart';
import '../../../stores/material_store.dart';
import '../../../domain/services/material_processor.dart';

class AddMaterialSheet extends StatelessWidget {
  const AddMaterialSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.onSurfaceVariant.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Title
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.upload_file,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Add Study Material',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        Text(
                          'Choose a source to upload',
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

            const Divider(height: 1),

            // Options
            _OptionTile(
              icon: Icons.picture_as_pdf,
              iconColor: Colors.red,
              title: 'PDF Document',
              subtitle: 'Upload textbooks, notes, or worksheets',
              onTap: () => _pickPdf(context),
            ),

            _OptionTile(
              icon: Icons.image,
              iconColor: Colors.blue,
              title: 'From Gallery',
              subtitle: 'Select images of study materials',
              onTap: () => _pickImage(context),
            ),

            _OptionTile(
              icon: Icons.camera_alt,
              iconColor: Colors.purple,
              title: 'Take Photo',
              subtitle: 'Capture pages with your camera',
              onTap: () => _takePhoto(context),
            ),

            const SizedBox(height: 16),

            // Cancel button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
              ),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _pickPdf(BuildContext context) async {
    final materialStore = getIt<MaterialStore>();

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null && result.files.single.path != null) {
      Navigator.pop(context);
      final file = File(result.files.single.path!);
      final title = result.files.single.name.replaceAll('.pdf', '');

      _showProcessingSnackbar(context, title);
      await materialStore.processMaterial(MaterialInput(
        title: title,
        sourceType: 'pdf',
        content: file.path,
      ));
    }
  }

  Future<void> _pickImage(BuildContext context) async {
    final materialStore = getIt<MaterialStore>();
    final picker = ImagePicker();

    final result = await picker.pickImage(source: ImageSource.gallery);

    if (result != null) {
      Navigator.pop(context);
      final title = 'Image ${DateTime.now().millisecondsSinceEpoch}';

      _showProcessingSnackbar(context, title);
      await materialStore.processMaterial(MaterialInput(
        title: title,
        sourceType: 'image',
        content: result.path,
      ));
    }
  }

  Future<void> _takePhoto(BuildContext context) async {
    final materialStore = getIt<MaterialStore>();
    final picker = ImagePicker();

    final result = await picker.pickImage(source: ImageSource.camera);

    if (result != null) {
      Navigator.pop(context);
      final title = 'Photo ${DateTime.now().millisecondsSinceEpoch}';

      _showProcessingSnackbar(context, title);
      await materialStore.processMaterial(MaterialInput(
        title: title,
        sourceType: 'image',
        content: result.path,
      ));
    }
  }

  void _showProcessingSnackbar(BuildContext context, String title) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text('Processing "$title"...'),
            ),
          ],
        ),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _OptionTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}

