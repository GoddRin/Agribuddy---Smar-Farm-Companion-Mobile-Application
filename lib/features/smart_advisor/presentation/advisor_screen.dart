import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';

// State management for intelligent diagnosis
final isAnalyzingProvider = StateProvider<bool>((ref) => false);
final analysisResultProvider = StateProvider<String?>((ref) => null);
final selectedImageBytesProvider = StateProvider<Uint8List?>((ref) => null);

class SmartAdvisorScreen extends ConsumerStatefulWidget {
  const SmartAdvisorScreen({super.key});

  @override
  ConsumerState<SmartAdvisorScreen> createState() => _SmartAdvisorScreenState();
}

class _SmartAdvisorScreenState extends ConsumerState<SmartAdvisorScreen> {
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(ImageSource source) async {
    Navigator.pop(context); // Close bottom sheet
    try {
      final XFile? pickedFile = await _picker.pickImage(source: source);
      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        ref.read(selectedImageBytesProvider.notifier).state = bytes;
        _processImage();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e')),
      );
    }
  }

  void _showPickerBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(LucideIcons.image),
                      title: const Text('Choose from Gallery'),
                      onTap: () => _pickImage(ImageSource.gallery),
                    ),
                    if (!kIsWeb)
                      ListTile(
                        leading: const Icon(LucideIcons.camera),
                        title: const Text('Take a Photo'),
                        onTap: () => _pickImage(ImageSource.camera),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _processImage() async {
    ref.read(isAnalyzingProvider.notifier).state = true;
    ref.read(analysisResultProvider.notifier).state = null;

    // Simulate heuristic image processing
    await Future.delayed(const Duration(seconds: 3));

    if (mounted) {
      ref.read(isAnalyzingProvider.notifier).state = false;
      ref.read(analysisResultProvider.notifier).state =
          'Diagnosis: Early Blight detected (85% confidence).\n\nRecommendation: Apply copper-based fungicide and ensure proper spacing for air circulation. Avoid overhead watering.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isAnalyzing = ref.watch(isAnalyzingProvider);
    final analysisResult = ref.watch(analysisResultProvider);
    final selectedImageBytes = ref.watch(selectedImageBytesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('AgriBuddy Advisor'),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                theme.colorScheme.primary.withValues(alpha: 0.1),
                Colors.transparent
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Analyze Plant Health',
              style: theme.textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ).animate().fade().slideY(begin: 0.2),
            const SizedBox(height: 8),
            Text(
              'Upload a photo of your crop to detect diseases or get fertilizer recommendations.',
              style: theme.textTheme.bodyLarge?.copyWith(color: Colors.grey),
            ).animate().fade(delay: 100.ms),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: isAnalyzing ? null : _showPickerBottomSheet,
              child: Container(
                height: selectedImageBytes != null ? 280 : 200,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.05),
                  border: Border.all(
                    color: selectedImageBytes != null
                        ? Colors.transparent
                        : theme.colorScheme.primary.withValues(alpha: 0.5),
                    width: 2,
                    style: BorderStyle.solid,
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: selectedImageBytes != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(22),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.memory(
                              selectedImageBytes,
                              fit: BoxFit.cover,
                            ),
                            if (!isAnalyzing)
                              Positioned(
                                bottom: 12,
                                right: 12,
                                child: CircleAvatar(
                                  backgroundColor:
                                      Colors.white.withValues(alpha: 0.9),
                                  child: Icon(LucideIcons.edit2,
                                      color: theme.colorScheme.primary,
                                      size: 20),
                                ),
                              )
                          ],
                        ),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(LucideIcons.imagePlus,
                              size: 48, color: theme.colorScheme.primary),
                          const SizedBox(height: 16),
                          Text(
                            'Tap to Upload Image',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
              ),
            ).animate().scale(delay: 200.ms),
            const SizedBox(height: 32),
            if (isAnalyzing)
              Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(color: theme.colorScheme.primary),
                    const SizedBox(height: 16),
                    const Text('Analyzing with vision model...'),
                  ],
                ),
              ).animate().fade(),
            if (analysisResult != null) ...[
              Text(
                'Intelligence Recommendation',
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: theme.cardTheme.color,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(LucideIcons.sparkles,
                        color: theme.colorScheme.secondary),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        analysisResult,
                        style: theme.textTheme.bodyLarge?.copyWith(height: 1.5),
                      ),
                    ),
                  ],
                ),
              ).animate().fade().slideY(begin: 0.2),
            ]
          ],
        ),
      ),
    );
  }
}
