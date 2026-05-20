import 'dart:async';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/add_lesson_provider.dart';
import '../../../courses/domain/models/lesson_model.dart';
import '../../../courses/presentation/providers/courses_provider.dart';
import '../../../courses/domain/models/subject_model.dart';
import '../../../courses/presentation/providers/subjects_provider.dart';
import 'package:nexora_academy/core/widgets/app_scaffold.dart';

class AddLessonScreen extends ConsumerStatefulWidget {
  final LessonModel? lessonToEdit;

  const AddLessonScreen({super.key, this.lessonToEdit});

  @override
  ConsumerState<AddLessonScreen> createState() => _AddLessonScreenState();
}

class _AddLessonScreenState extends ConsumerState<AddLessonScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  // Explicit TabControllers to avoid nested DefaultTabController crashes
  late TabController _mainTabController;
  late TabController _langTabController;

  // Form Controllers
  final _titleControllers = {
    'EN': TextEditingController(),
    'FR': TextEditingController(),
    'AR': TextEditingController(),
  };
  final _descControllers = {
    'EN': TextEditingController(),
    'FR': TextEditingController(),
    'AR': TextEditingController(),
  };
  
  final _contentController = TextEditingController();
  final _videoUrlController = TextEditingController();
  final _pdfUrlController = TextEditingController();
  final _orderNumberController = TextEditingController();
  final _durationController = TextEditingController();

  String? _selectedLevelId;
  String? _selectedSubjectId;

  bool _videoSourceIsUpload = false;
  bool _pdfSourceIsUpload = false;
  String? _pickedVideoName;
  Uint8List? _pickedVideoBytes;
  String? _pickedPdfName;
  Uint8List? _pickedPdfBytes;

  double? _videoUploadProgress;
  double? _pdfUploadProgress;

  @override
  void initState() {
    super.initState();
    _mainTabController = TabController(length: 4, vsync: this);
    _langTabController = TabController(length: 3, vsync: this);

    if (widget.lessonToEdit != null) {
      final lesson = widget.lessonToEdit!;
      _titleControllers['EN']!.text = lesson.titleEn ?? '';
      _titleControllers['FR']!.text = lesson.titleFr ?? '';
      _titleControllers['AR']!.text = lesson.titleAr ?? '';
      
      _descControllers['EN']!.text = lesson.descriptionEn ?? '';
      _descControllers['FR']!.text = lesson.descriptionFr ?? '';
      _descControllers['AR']!.text = lesson.descriptionAr ?? '';
      
      _contentController.text = lesson.content ?? '';
      _selectedSubjectId = lesson.subjectId;
      _videoUrlController.text = lesson.videoUrl;
      _pdfUrlController.text = lesson.pdfUrl;
      
      _orderNumberController.text = lesson.orderNumber.toString();
      _durationController.text = lesson.duration?.toString() ?? '';

      _videoSourceIsUpload = false;
      _pdfSourceIsUpload = false;
      
      // Resolve Level ID safely from the cached subjects
      Future.microtask(() {
        final subjectsVal = ref.read(subjectsProvider).valueOrNull;
        if (subjectsVal != null) {
          try {
            final matchingSubject = subjectsVal.firstWhere((s) => s.id == _selectedSubjectId);
            if (mounted) setState(() => _selectedLevelId = matchingSubject.level);
          } catch (_) {}
        }
      });
    }
  }

  @override
  void dispose() {
    _mainTabController.dispose();
    _langTabController.dispose();
    for (var c in _titleControllers.values) { c.dispose(); }
    for (var c in _descControllers.values) { c.dispose(); }
    _contentController.dispose();
    _videoUrlController.dispose();
    _pdfUrlController.dispose();
    _orderNumberController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  void _translatePlaceholders() {
    // Bonus Feature: Auto-translate placeholder
    // Mocks translation by copying English text if target is empty
    setState(() {
      final enTitle = _titleControllers['EN']!.text;
      final enDesc = _descControllers['EN']!.text;

      if (_titleControllers['FR']!.text.isEmpty) _titleControllers['FR']!.text = enTitle;
      if (_titleControllers['AR']!.text.isEmpty) _titleControllers['AR']!.text = enTitle;
      
      if (_descControllers['FR']!.text.isEmpty) _descControllers['FR']!.text = enDesc;
      if (_descControllers['AR']!.text.isEmpty) _descControllers['AR']!.text = enDesc;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Auto-populated FR/AR fields from EN (Mock)')),
    );
  }

  Future<void> _submitForm() async {
    // Since title required is per language tab, we check EN explicitly
    if (_titleControllers['EN']!.text.trim().isEmpty) {
      _mainTabController.animateTo(0);
      _langTabController.animateTo(0);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('English Title is required.')),
      );
      return;
    }

    if (_selectedSubjectId == null) {
      _mainTabController.animateTo(0);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Subject is required.')),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    await ref.read(addLessonProvider.notifier).submit(
      lessonIdToEdit: widget.lessonToEdit?.id,
      titleEn: _titleControllers['EN']!.text,
      titleFr: _titleControllers['FR']!.text,
      titleAr: _titleControllers['AR']!.text,
      descriptionEn: _descControllers['EN']!.text,
      descriptionFr: _descControllers['FR']!.text,
      descriptionAr: _descControllers['AR']!.text,
      content: _contentController.text,
      subjectId: _selectedSubjectId!,
      videoSourceIsUpload: _videoSourceIsUpload,
      videoUrl: _videoUrlController.text,
      videoBytes: _pickedVideoBytes,
      videoFileName: _pickedVideoName,
      pdfSourceIsUpload: _pdfSourceIsUpload,
      pdfUrl: _pdfUrlController.text,
      pdfBytes: _pickedPdfBytes,
      pdfFileName: _pickedPdfName,
      orderNumberText: _orderNumberController.text,
      durationText: _durationController.text,
      onVideoProgress: (p) {
        if (mounted) setState(() => _videoUploadProgress = p);
      },
      onPdfProgress: (p) {
        if (mounted) setState(() => _pdfUploadProgress = p);
      },
    );
  }

  void _listenToSubmitState() {
    ref.listen<AsyncValue<void>>(addLessonProvider, (prev, next) {
      next.whenOrNull(
        error: (err, st) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $err'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        },
        data: (_) {
          // If we transitioned from loading to data, it means success
          if (prev is AsyncLoading) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(widget.lessonToEdit != null ? 'Lesson updated!' : 'Lesson created successfully!'),
                backgroundColor: Colors.green.shade600,
              ),
            );
            Navigator.of(context).pop();
          }
        },
      );
    });
  }

  Widget _buildCard({required Widget child}) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    _listenToSubmitState();
    final submitState = ref.watch(addLessonProvider);
    final isLoading = submitState is AsyncLoading;

    return AppScaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        title: Text(widget.lessonToEdit != null ? 'Edit Lesson' : 'Add New Lesson'),
        centerTitle: true,
        bottom: TabBar(
          controller: _mainTabController,
          labelColor: Theme.of(context).colorScheme.primary,
          unselectedLabelColor: Colors.grey,
          indicatorSize: TabBarIndicatorSize.tab,
          tabs: const [
            Tab(text: 'Basic Info', icon: Icon(Icons.info_outline)),
            Tab(text: 'Content', icon: Icon(Icons.article_outlined)),
            Tab(text: 'Media', icon: Icon(Icons.perm_media_outlined)),
            Tab(text: 'Settings', icon: Icon(Icons.settings_outlined)),
          ],
        ),
      ),
      body: Form(
        key: _formKey,
        child: TabBarView(
          controller: _mainTabController,
          children: [
            _buildBasicInfoTab(),
            _buildContentTab(),
            _buildMediaTab(),
            _buildSettingsTab(isLoading),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // TABS
  // ==========================================

  Widget _buildBasicInfoTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Categorization', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                _buildLevelDropdown(),
                const SizedBox(height: 16),
                _buildSubjectDropdown(),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Localization', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.translate, size: 18),
                      label: const Text('Auto-translate'),
                      onPressed: _translatePlaceholders,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TabBar(
                  controller: _langTabController,
                  labelColor: Theme.of(context).colorScheme.primary,
                  unselectedLabelColor: Colors.grey,
                  tabs: const [
                    Tab(text: 'English'),
                    Tab(text: 'Français'),
                    Tab(text: 'العربية'),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 320,
                  child: TabBarView(
                    controller: _langTabController,
                    children: [
                      _buildLangForm('EN', 'English', false),
                      _buildLangForm('FR', 'French', false),
                      _buildLangForm('AR', 'Arabic', true),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContentTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: _buildCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Lesson Content (Overview)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextFormField(
              controller: _contentController,
              maxLines: 25,
              minLines: 15,
              decoration: InputDecoration(
                hintText: 'Write full explanation here...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMediaTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          _buildCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Video Source', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(value: false, label: Text('URL'), icon: Icon(Icons.link)),
                    ButtonSegment(value: true, label: Text('Upload'), icon: Icon(Icons.upload_file)),
                  ],
                  selected: {_videoSourceIsUpload},
                  onSelectionChanged: (Set<bool> newSelection) {
                    setState(() => _videoSourceIsUpload = newSelection.first);
                  },
                ),
                const SizedBox(height: 24),
                if (_videoSourceIsUpload) ...[
                  _buildFileUploadArea(
                    isUploading: _videoUploadProgress != null,
                    progress: _videoUploadProgress,
                    pickedName: _pickedVideoName,
                    icon: Icons.video_file,
                    onTap: () async {
                      final result = await FilePicker.platform.pickFiles(type: FileType.video, withData: true);
                      if (result == null || result.files.isEmpty) return;
                      setState(() {
                         _pickedVideoBytes = result.files.single.bytes;
                         _pickedVideoName = result.files.single.name;
                      });
                    },
                  ),
                ] else ...[
                  TextFormField(
                    controller: _videoUrlController,
                    decoration: InputDecoration(
                      labelText: 'Video URL',
                      prefixIcon: const Icon(Icons.link),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ],
                const SizedBox(height: 24),
                _buildVideoPreviewPlaceholder(),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('PDF Source', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(value: false, label: Text('URL'), icon: Icon(Icons.link)),
                    ButtonSegment(value: true, label: Text('Upload'), icon: Icon(Icons.upload_file)),
                  ],
                  selected: {_pdfSourceIsUpload},
                  onSelectionChanged: (Set<bool> newSelection) {
                    setState(() => _pdfSourceIsUpload = newSelection.first);
                  },
                ),
                const SizedBox(height: 24),
                if (_pdfSourceIsUpload) ...[
                  _buildFileUploadArea(
                    isUploading: _pdfUploadProgress != null,
                    progress: _pdfUploadProgress,
                    pickedName: _pickedPdfName,
                    icon: Icons.picture_as_pdf,
                    onTap: () async {
                      final result = await FilePicker.platform.pickFiles(
                        type: FileType.custom, allowedExtensions: ['pdf'], withData: true,
                      );
                      if (result == null || result.files.isEmpty) return;
                      setState(() {
                         _pickedPdfBytes = result.files.single.bytes;
                         _pickedPdfName = result.files.single.name;
                      });
                    },
                  ),
                ] else ...[
                  TextFormField(
                    controller: _pdfUrlController,
                    decoration: InputDecoration(
                      labelText: 'PDF URL',
                      prefixIcon: const Icon(Icons.link),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTab(bool isLoading) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Lesson Settings', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _orderNumberController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Order Number (Optional)',
                    hintText: 'Auto-generated if empty',
                    prefixIcon: const Icon(Icons.format_list_numbered),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _durationController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Duration (minutes)',
                    hintText: 'e.g. 45',
                    prefixIcon: const Icon(Icons.timer_outlined),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 56,
            child: FilledButton(
              onPressed: isLoading ? null : _submitForm,
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(
                      widget.lessonToEdit != null ? 'Update Lesson' : 'Create Lesson',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // HELPERS
  // ==========================================

  Widget _buildLangForm(String key, String langName, bool isRtl) {
    return SingleChildScrollView(
      child: Column(
        children: [
          TextFormField(
            controller: _titleControllers[key],
            textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
            decoration: InputDecoration(
              labelText: 'Title ($key)',
              prefixIcon: const Icon(Icons.title),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _descControllers[key],
            maxLines: 4,
            textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
            decoration: InputDecoration(
              labelText: 'Description ($key)',
              alignLabelWithHint: true,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLevelDropdown() {
    final levelsAsync = ref.watch(levelsProvider);
    return levelsAsync.when(
      loading: () => const LinearProgressIndicator(),
      error: (e, _) => Text('Error loading levels: $e', style: const TextStyle(color: Colors.red)),
      data: (levels) => DropdownButtonFormField<String>(
        value: _selectedLevelId,
        decoration: InputDecoration(
          labelText: 'Educational Level',
          prefixIcon: const Icon(Icons.school_outlined),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        ),
        hint: const Text('Select Level'),
        items: levels.map((l) => DropdownMenuItem(value: l.id, child: Text(l.name))).toList(),
        onChanged: (val) {
          setState(() {
            _selectedLevelId = val;
            _selectedSubjectId = null;
          });
        },
      ),
    );
  }

  Widget _buildSubjectDropdown() {
    if (_selectedLevelId == null) {
      return DropdownButtonFormField<String>(
        value: null,
        decoration: InputDecoration(
          labelText: 'Subject',
          prefixIcon: const Icon(Icons.library_books),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
          filled: true,
          fillColor: Colors.grey.shade100,
        ),
        hint: const Text('Select a level first'),
        items: const [],
        onChanged: null,
      );
    }

    final subjectsAsync = ref.watch(subjectsByLevelProvider((levelId: _selectedLevelId!, streamId: null, optionLang: null)));
    return subjectsAsync.when(
      loading: () => const LinearProgressIndicator(),
      error: (e, _) => Text('Error loading subjects: $e', style: const TextStyle(color: Colors.red)),
      data: (subjects) => DropdownButtonFormField<String>(
        value: _selectedSubjectId,
        decoration: InputDecoration(
          labelText: 'Subject',
          prefixIcon: const Icon(Icons.library_books),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        ),
        hint: Text(subjects.isEmpty ? 'No subjects in level' : 'Select Subject'),
        items: subjects.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name))).toList(),
        onChanged: subjects.isEmpty ? null : (val) => setState(() => _selectedSubjectId = val),
      ),
    );
  }

  Widget _buildFileUploadArea({
    required bool isUploading,
    required double? progress,
    required String? pickedName,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: isUploading ? null : onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          border: Border.all(color: theme.colorScheme.outlineVariant, width: 2),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(icon, size: 48, color: theme.colorScheme.primary),
            const SizedBox(height: 12),
            if (isUploading)
              Column(
                children: [
                   LinearProgressIndicator(value: progress),
                   const SizedBox(height: 8),
                   Text('Uploading... ${((progress ?? 0) * 100).toInt()}%'),
                ],
              )
            else
              Text(
                pickedName ?? 'Click to select file',
                style: TextStyle(fontWeight: pickedName != null ? FontWeight.bold : FontWeight.normal),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoPreviewPlaceholder() {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Container(
        decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(16)),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), shape: BoxShape.circle),
                child: const Icon(Icons.play_arrow, color: Colors.white, size: 48),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  _videoSourceIsUpload 
                      ? (_pickedVideoName ?? 'Video Preview') 
                      : (_videoUrlController.text.isNotEmpty ? 'External Video' : 'No Video selected'),
                  style: const TextStyle(color: Colors.white70),
                  textAlign: TextAlign.center,
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
