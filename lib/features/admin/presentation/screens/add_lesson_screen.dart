import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/add_lesson_provider.dart';
import '../../../courses/domain/models/lesson_model.dart';
import '../../../courses/presentation/providers/courses_provider.dart';
import '../../../courses/presentation/providers/subjects_provider.dart';
import '../../../streams/presentation/providers/streams_provider.dart';
import '../../../../core/providers/locale_provider.dart';
import 'package:nexora_academy/core/widgets/app_scaffold.dart';

// ═══════════════════════════════════════════════════════════════
// Premium accent colors
// ═══════════════════════════════════════════════════════════════
const _kAccent = Color(0xFF7C3AED);
const _kAccentDark = Color(0xFF5B21B6);
const _kBorderLight = Color(0xFFE2E8F0);

class AddLessonScreen extends ConsumerStatefulWidget {
  final LessonModel? lessonToEdit;

  const AddLessonScreen({super.key, this.lessonToEdit});

  @override
  ConsumerState<AddLessonScreen> createState() => _AddLessonScreenState();
}

class _AddLessonScreenState extends ConsumerState<AddLessonScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  late TabController _mainTabController;
  late TabController _langTabController;

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
  String? _selectedStreamId;
  String? _selectedOption;
  String? _selectedSubjectId;

  bool _videoSourceIsUpload = false;
  bool _pdfSourceIsUpload = false;
  String? _pickedVideoName;
  Uint8List? _pickedVideoBytes;
  String? _pickedPdfName;
  Uint8List? _pickedPdfBytes;

  double? _videoUploadProgress;
  double? _pdfUploadProgress;

  int _currentStep = 0;

  @override
  void initState() {
    super.initState();
    _mainTabController = TabController(length: 4, vsync: this);
    _mainTabController.addListener(() {
      if (_mainTabController.index != _currentStep) {
        setState(() => _currentStep = _mainTabController.index);
      }
    });
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
    for (var c in _titleControllers.values) {
      c.dispose();
    }
    for (var c in _descControllers.values) {
      c.dispose();
    }
    _contentController.dispose();
    _videoUrlController.dispose();
    _pdfUrlController.dispose();
    _orderNumberController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  void _translatePlaceholders() {
    setState(() {
      final enTitle = _titleControllers['EN']!.text;
      final enDesc = _descControllers['EN']!.text;

      if (_titleControllers['FR']!.text.isEmpty) _titleControllers['FR']!.text = enTitle;
      if (_titleControllers['AR']!.text.isEmpty) _titleControllers['AR']!.text = enTitle;

      if (_descControllers['FR']!.text.isEmpty) _descControllers['FR']!.text = enDesc;
      if (_descControllers['AR']!.text.isEmpty) _descControllers['AR']!.text = enDesc;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.translate_rounded, color: Colors.white, size: 18),
            SizedBox(width: 12),
            Text('Auto-populated FR/AR fields from EN'),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: _kAccent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Future<void> _submitForm() async {
    if (_titleControllers['EN']!.text.trim().isEmpty) {
      _mainTabController.animateTo(0);
      _langTabController.animateTo(0);
      _showErrorSnack('English Title is required.');
      return;
    }

    if (_selectedSubjectId == null) {
      _mainTabController.animateTo(0);
      _showErrorSnack('Subject is required.');
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

  void _showErrorSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 12),
            Expanded(child: Text(msg)),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Theme.of(context).colorScheme.error,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _listenToSubmitState() {
    ref.listen<AsyncValue<void>>(addLessonProvider, (prev, next) {
      next.whenOrNull(
        error: (err, st) {
          _showErrorSnack('Error: $err');
        },
        data: (_) {
          if (prev is AsyncLoading) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                    const SizedBox(width: 12),
                    Text(widget.lessonToEdit != null ? 'Lesson updated!' : 'Lesson created successfully!'),
                  ],
                ),
                behavior: SnackBarBehavior.floating,
                backgroundColor: Colors.green.shade600,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                margin: const EdgeInsets.all(16),
              ),
            );
            Navigator.of(context).pop();
          }
        },
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    _listenToSubmitState();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final submitState = ref.watch(addLessonProvider);
    final isLoading = submitState is AsyncLoading;

    return AppScaffold(
      backgroundColor: theme.colorScheme.surface,
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            // ═══════════════════════════════════════
            // HEADER
            // ═══════════════════════════════════════
            _buildHeader(context, theme, isDark),

            // ═══════════════════════════════════════
            // STEPPER
            // ═══════════════════════════════════════
            _buildStepper(theme, isDark),

            // ═══════════════════════════════════════
            // CONTENT
            // ═══════════════════════════════════════
            Expanded(
              child: TabBarView(
                controller: _mainTabController,
                children: [
                  _buildBasicInfoTab(theme, isDark),
                  _buildContentTab(theme, isDark),
                  _buildMediaTab(theme, isDark),
                  _buildSettingsTab(theme, isDark, isLoading),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // HEADER
  // ═══════════════════════════════════════════════════════════════

  Widget _buildHeader(BuildContext context, ThemeData theme, bool isDark) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF2D1B69), const Color(0xFF1A1145)]
              : [_kAccent, _kAccentDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: _kAccent.withOpacity(isDark ? 0.15 : 0.25),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.lessonToEdit != null ? 'Edit Lesson' : 'Add New Lesson',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.lessonToEdit != null
                      ? 'Update lesson details and media'
                      : 'Create rich content for your students',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.75),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.video_library_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // STEPPER
  // ═══════════════════════════════════════════════════════════════

  Widget _buildStepper(ThemeData theme, bool isDark) {
    final steps = [
      (icon: Icons.info_outline_rounded, label: 'Basic Info'),
      (icon: Icons.article_outlined, label: 'Content'),
      (icon: Icons.perm_media_outlined, label: 'Media'),
      (icon: Icons.tune_rounded, label: 'Settings'),
    ];

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.04) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.08) : _kBorderLight,
        ),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Row(
        children: List.generate(steps.length, (index) {
          final step = steps[index];
          final isActive = _currentStep == index;
          return Expanded(
            child: GestureDetector(
              onTap: () => _mainTabController.animateTo(index),
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOut,
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: isActive
                      ? const LinearGradient(
                          colors: [_kAccent, _kAccentDark],
                        )
                      : null,
                  boxShadow: isActive
                      ? [
                          BoxShadow(
                            color: _kAccent.withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      step.icon,
                      size: 18,
                      color: isActive
                          ? Colors.white
                          : theme.colorScheme.onSurface.withOpacity(0.5),
                    ),
                    const SizedBox(height: 4),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        step.label,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: isActive
                              ? Colors.white
                              : theme.colorScheme.onSurface.withOpacity(0.5),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // SECTION CARD
  // ═══════════════════════════════════════════════════════════════

  Widget _buildSectionCard({
    required ThemeData theme,
    required bool isDark,
    required String title,
    required IconData icon,
    Widget? trailing,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.04) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.08) : _kBorderLight,
        ),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 12,
                  offset: const Offset(0, 3),
                ),
              ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                margin: const EdgeInsets.only(right: 10),
                decoration: BoxDecoration(
                  color: _kAccent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: _kAccent),
              ),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
              if (trailing != null) trailing,
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // BASIC INFO TAB
  // ═══════════════════════════════════════════════════════════════

  Widget _buildBasicInfoTab(ThemeData theme, bool isDark) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSectionCard(
            theme: theme,
            isDark: isDark,
            title: 'Categorization',
            icon: Icons.layers_rounded,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildLevelDropdown(theme, isDark),
                if (_selectedLevelId != null) ...[
                  const SizedBox(height: 14),
                  _buildStreamSelector(theme, isDark),
                ],
                if (_selectedLevelId != null) ...[
                  const SizedBox(height: 14),
                  _buildOptionSelector(theme, isDark),
                ],
                const SizedBox(height: 14),
                _buildSubjectDropdown(theme, isDark),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildSectionCard(
            theme: theme,
            isDark: isDark,
            title: 'Localization',
            icon: Icons.translate_rounded,
            trailing: _buildAutoTranslateButton(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildLanguageTabs(theme, isDark),
                const SizedBox(height: 16),
                SizedBox(
                  height: 360,
                  child: TabBarView(
                    controller: _langTabController,
                    children: [
                      _buildLangForm(theme, isDark, 'EN', false),
                      _buildLangForm(theme, isDark, 'FR', false),
                      _buildLangForm(theme, isDark, 'AR', true),
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

  Widget _buildAutoTranslateButton() {
    return GestureDetector(
      onTap: _translatePlaceholders,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: _kAccent.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _kAccent.withOpacity(0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.auto_awesome_rounded, size: 14, color: _kAccent),
            SizedBox(width: 6),
            Text(
              'Auto-translate',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: _kAccent,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageTabs(ThemeData theme, bool isDark) {
    final tabs = [
      ('EN', 'English'),
      ('FR', 'Français'),
      ('AR', 'العربية'),
    ];
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.04) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(14),
      ),
      child: AnimatedBuilder(
        animation: _langTabController,
        builder: (context, _) {
          return Row(
            children: List.generate(tabs.length, (i) {
              final isActive = _langTabController.index == i;
              return Expanded(
                child: GestureDetector(
                  onTap: () => _langTabController.animateTo(i),
                  behavior: HitTestBehavior.opaque,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOut,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: isActive
                          ? (isDark ? const Color(0xFF1E293B) : Colors.white)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: isActive && !isDark
                          ? [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.06),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: Center(
                      child: Text(
                        tabs[i].$2,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: isActive
                              ? _kAccent
                              : theme.colorScheme.onSurface.withOpacity(0.5),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          );
        },
      ),
    );
  }

  Widget _buildLangForm(ThemeData theme, bool isDark, String key, bool isRtl) {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildPremiumTextField(
            theme: theme,
            isDark: isDark,
            controller: _titleControllers[key]!,
            label: 'Lesson Title',
            hint: isRtl ? 'أدخل عنوان الدرس' : 'Enter lesson title',
            icon: Icons.title_rounded,
            isRtl: isRtl,
          ),
          const SizedBox(height: 14),
          _buildPremiumTextField(
            theme: theme,
            isDark: isDark,
            controller: _descControllers[key]!,
            label: 'Description',
            hint: isRtl ? 'وصف موجز للدرس...' : 'Brief description of the lesson...',
            icon: Icons.notes_rounded,
            isRtl: isRtl,
            maxLines: 4,
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // CONTENT TAB
  // ═══════════════════════════════════════════════════════════════

  Widget _buildContentTab(ThemeData theme, bool isDark) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      child: _buildSectionCard(
        theme: theme,
        isDark: isDark,
        title: 'Lesson Overview',
        icon: Icons.menu_book_rounded,
        child: _buildPremiumTextField(
          theme: theme,
          isDark: isDark,
          controller: _contentController,
          label: 'Full Content',
          hint: 'Write the complete lesson explanation, key concepts, examples...',
          icon: Icons.description_rounded,
          isRtl: false,
          maxLines: 18,
          minLines: 12,
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // MEDIA TAB
  // ═══════════════════════════════════════════════════════════════

  Widget _buildMediaTab(ThemeData theme, bool isDark) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      child: Column(
        children: [
          _buildSectionCard(
            theme: theme,
            isDark: isDark,
            title: 'Video Source',
            icon: Icons.play_circle_outline_rounded,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildSourceToggle(
                  theme: theme,
                  isDark: isDark,
                  isUpload: _videoSourceIsUpload,
                  onChanged: (v) => setState(() => _videoSourceIsUpload = v),
                ),
                const SizedBox(height: 18),
                if (_videoSourceIsUpload)
                  _buildUploadZone(
                    theme: theme,
                    isDark: isDark,
                    isUploading: _videoUploadProgress != null,
                    progress: _videoUploadProgress,
                    pickedName: _pickedVideoName,
                    icon: Icons.movie_creation_rounded,
                    label: 'Tap to upload video file',
                    helper: 'MP4, WebM, MOV • Max 500MB',
                    onTap: () async {
                      final result = await FilePicker.platform.pickFiles(
                        type: FileType.video,
                        withData: true,
                      );
                      if (result == null || result.files.isEmpty) return;
                      setState(() {
                        _pickedVideoBytes = result.files.single.bytes;
                        _pickedVideoName = result.files.single.name;
                      });
                    },
                  )
                else
                  _buildPremiumTextField(
                    theme: theme,
                    isDark: isDark,
                    controller: _videoUrlController,
                    label: 'Video URL',
                    hint: 'https://youtube.com/watch?v=...',
                    icon: Icons.link_rounded,
                    isRtl: false,
                    onChanged: (_) => setState(() {}),
                  ),
                const SizedBox(height: 18),
                _buildVideoPreview(theme, isDark),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildSectionCard(
            theme: theme,
            isDark: isDark,
            title: 'PDF Resource',
            icon: Icons.picture_as_pdf_rounded,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildSourceToggle(
                  theme: theme,
                  isDark: isDark,
                  isUpload: _pdfSourceIsUpload,
                  onChanged: (v) => setState(() => _pdfSourceIsUpload = v),
                ),
                const SizedBox(height: 18),
                if (_pdfSourceIsUpload)
                  _buildUploadZone(
                    theme: theme,
                    isDark: isDark,
                    isUploading: _pdfUploadProgress != null,
                    progress: _pdfUploadProgress,
                    pickedName: _pickedPdfName,
                    icon: Icons.picture_as_pdf_rounded,
                    label: 'Tap to upload PDF document',
                    helper: 'PDF only • Max 50MB',
                    onTap: () async {
                      final result = await FilePicker.platform.pickFiles(
                        type: FileType.custom,
                        allowedExtensions: ['pdf'],
                        withData: true,
                      );
                      if (result == null || result.files.isEmpty) return;
                      setState(() {
                        _pickedPdfBytes = result.files.single.bytes;
                        _pickedPdfName = result.files.single.name;
                      });
                    },
                  )
                else
                  _buildPremiumTextField(
                    theme: theme,
                    isDark: isDark,
                    controller: _pdfUrlController,
                    label: 'PDF URL',
                    hint: 'https://example.com/lesson.pdf',
                    icon: Icons.link_rounded,
                    isRtl: false,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSourceToggle({
    required ThemeData theme,
    required bool isDark,
    required bool isUpload,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.04) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildToggleOption(
              theme: theme,
              isDark: isDark,
              icon: Icons.link_rounded,
              label: 'Use URL',
              isActive: !isUpload,
              onTap: () => onChanged(false),
            ),
          ),
          Expanded(
            child: _buildToggleOption(
              theme: theme,
              isDark: isDark,
              icon: Icons.cloud_upload_rounded,
              label: 'Upload File',
              isActive: isUpload,
              onTap: () => onChanged(true),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleOption({
    required ThemeData theme,
    required bool isDark,
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isActive
              ? (isDark ? const Color(0xFF1E293B) : Colors.white)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isActive && !isDark
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: isActive ? _kAccent : theme.colorScheme.onSurface.withOpacity(0.5),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isActive ? _kAccent : theme.colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadZone({
    required ThemeData theme,
    required bool isDark,
    required bool isUploading,
    required double? progress,
    required String? pickedName,
    required IconData icon,
    required String label,
    required String helper,
    required VoidCallback onTap,
  }) {
    final hasFile = pickedName != null;

    return GestureDetector(
      onTap: isUploading ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: hasFile
              ? _kAccent.withOpacity(0.04)
              : (isDark ? Colors.white.withOpacity(0.02) : const Color(0xFFFAFBFC)),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: hasFile
                ? _kAccent.withOpacity(0.4)
                : (isDark ? Colors.white.withOpacity(0.1) : _kBorderLight),
            width: hasFile ? 1.5 : 1.5,
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _kAccent.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 28, color: _kAccent),
            ),
            const SizedBox(height: 14),
            if (isUploading) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 6,
                  backgroundColor: _kAccent.withOpacity(0.15),
                  valueColor: const AlwaysStoppedAnimation<Color>(_kAccent),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Uploading... ${((progress ?? 0) * 100).toInt()}%',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ] else if (hasFile) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_rounded, size: 16, color: Colors.green.shade600),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      pickedName,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.onSurface.withOpacity(0.85),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Tap to change file',
                style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.onSurface.withOpacity(0.4),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ] else ...[
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface.withOpacity(0.75),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                helper,
                style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.onSurface.withOpacity(0.4),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildVideoPreview(ThemeData theme, bool isDark) {
    final hasContent = _videoSourceIsUpload
        ? _pickedVideoName != null
        : _videoUrlController.text.isNotEmpty;

    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1E1B4B), Color(0xFF0F0F23)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withOpacity(0.2)),
                ),
                child: const Icon(
                  Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 38,
                ),
              ),
              const SizedBox(height: 14),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  hasContent
                      ? (_videoSourceIsUpload
                          ? (_pickedVideoName ?? 'Video Preview')
                          : 'External Video')
                      : 'No video selected',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.85),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // SETTINGS TAB
  // ═══════════════════════════════════════════════════════════════

  Widget _buildSettingsTab(ThemeData theme, bool isDark, bool isLoading) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSectionCard(
            theme: theme,
            isDark: isDark,
            title: 'Lesson Settings',
            icon: Icons.tune_rounded,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildPremiumTextField(
                  theme: theme,
                  isDark: isDark,
                  controller: _orderNumberController,
                  label: 'Order Number',
                  hint: 'Auto-generated if empty',
                  icon: Icons.format_list_numbered_rounded,
                  isRtl: false,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 14),
                _buildPremiumTextField(
                  theme: theme,
                  isDark: isDark,
                  controller: _durationController,
                  label: 'Duration (minutes)',
                  hint: 'e.g. 45',
                  icon: Icons.timer_rounded,
                  isRtl: false,
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildSubmitButton(theme, isLoading),
        ],
      ),
    );
  }

  Widget _buildSubmitButton(ThemeData theme, bool isLoading) {
    return GestureDetector(
      onTap: isLoading ? null : _submitForm,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: isLoading
              ? LinearGradient(
                  colors: [
                    _kAccent.withOpacity(0.5),
                    _kAccentDark.withOpacity(0.5),
                  ],
                )
              : const LinearGradient(
                  colors: [_kAccent, _kAccentDark],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
          boxShadow: isLoading
              ? []
              : [
                  BoxShadow(
                    color: _kAccent.withOpacity(0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isLoading)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            else
              Icon(
                widget.lessonToEdit != null
                    ? Icons.save_rounded
                    : Icons.add_circle_outline_rounded,
                color: Colors.white,
                size: 20,
              ),
            const SizedBox(width: 12),
            Text(
              isLoading
                  ? 'Saving...'
                  : (widget.lessonToEdit != null ? 'Update Lesson' : 'Create Lesson'),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // PREMIUM TEXT FIELD
  // ═══════════════════════════════════════════════════════════════

  Widget _buildPremiumTextField({
    required ThemeData theme,
    required bool isDark,
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required bool isRtl,
    int? maxLines = 1,
    int? minLines,
    TextInputType? keyboardType,
    ValueChanged<String>? onChanged,
  }) {
    final isMulti = (maxLines ?? 1) > 1;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.04) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.08) : _kBorderLight,
        ),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        minLines: minLines,
        onChanged: onChanged,
        textDirection: isRtl ? TextDirection.rtl : null,
        textAlign: isRtl ? TextAlign.right : TextAlign.start,
        textCapitalization: isRtl ? TextCapitalization.none : TextCapitalization.sentences,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: theme.colorScheme.onSurface,
          height: isMulti ? 1.5 : null,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: theme.colorScheme.onSurface.withOpacity(0.5),
            fontWeight: FontWeight.w500,
          ),
          hintText: hint,
          hintTextDirection: isRtl ? TextDirection.rtl : null,
          hintStyle: TextStyle(
            color: theme.colorScheme.onSurface.withOpacity(0.3),
            fontWeight: FontWeight.w400,
          ),
          alignLabelWithHint: isMulti,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: _kAccent, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: theme.colorScheme.error, width: 1.5),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: theme.colorScheme.error, width: 1.5),
          ),
          filled: true,
          fillColor: Colors.transparent,
          contentPadding: EdgeInsets.symmetric(
            horizontal: 18,
            vertical: isMulti ? 16 : 16,
          ),
          prefixIcon: isRtl
              ? null
              : Container(
                  margin: const EdgeInsets.only(left: 12, right: 8),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _kAccent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: _kAccent, size: 20),
                ),
          suffixIcon: isRtl
              ? Container(
                  margin: const EdgeInsets.only(left: 8, right: 12),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _kAccent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: _kAccent, size: 20),
                )
              : null,
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // LEVEL DROPDOWN
  // ═══════════════════════════════════════════════════════════════

  Widget _buildLevelDropdown(ThemeData theme, bool isDark) {
    final levelsAsync = ref.watch(levelsProvider);
    return levelsAsync.when(
      loading: () => _dropdownLoading(isDark),
      error: (e, _) => _dropdownError('Error loading levels: $e'),
      data: (levels) => _buildPremiumDropdown<String>(
        theme: theme,
        isDark: isDark,
        value: _selectedLevelId,
        label: 'Educational Level',
        hint: 'Select level',
        icon: Icons.school_rounded,
        items: levels
            .map((l) => DropdownMenuItem(value: l.id, child: Text(l.name)))
            .toList(),
        onChanged: (val) {
          setState(() {
            _selectedLevelId = val;
            _selectedStreamId = null;
            _selectedOption = null;
            _selectedSubjectId = null;
          });
        },
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // STREAM SELECTOR
  // ═══════════════════════════════════════════════════════════════

  Widget _buildStreamSelector(ThemeData theme, bool isDark) {
    final streamsAsync = ref.watch(streamsByLevelProvider(_selectedLevelId!));
    final locale = ref.watch(localeProvider);

    return streamsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (streams) {
        if (streams.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.account_tree_rounded, size: 14, color: _kAccent),
                const SizedBox(width: 6),
                Text('Stream / Branch',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.onSurface.withOpacity(0.6))),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: streams.map((stream) {
                final isActive = _selectedStreamId == stream.id;
                final name = stream.getName(locale.languageCode);
                return GestureDetector(
                  onTap: () => setState(() {
                    _selectedStreamId = isActive ? null : stream.id;
                    _selectedOption = null;
                    _selectedSubjectId = null;
                  }),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: isActive
                          ? const LinearGradient(colors: [_kAccent, _kAccentDark])
                          : null,
                      color: isActive ? null : (isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFF8FAFC)),
                      borderRadius: BorderRadius.circular(10),
                      border: isActive ? null : Border.all(color: isDark ? Colors.white.withOpacity(0.1) : _kBorderLight),
                    ),
                    child: Text(
                      name,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isActive ? Colors.white : theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // OPTION SELECTOR
  // ═══════════════════════════════════════════════════════════════

  Widget _buildOptionSelector(ThemeData theme, bool isDark) {
    final optionsAsync = ref.watch(
      optionsByLevelProvider((levelId: _selectedLevelId!, streamId: _selectedStreamId)),
    );

    return optionsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (options) {
        if (options.isEmpty || options.length <= 1) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.translate_rounded, size: 14, color: _kAccent),
                const SizedBox(width: 6),
                Text('Language Option',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.onSurface.withOpacity(0.6))),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: options.map((opt) {
                final isActive = _selectedOption == opt;
                final label = opt == 'ar' ? 'Arabic Option' : (opt == 'fr' ? 'French Option' : opt.toUpperCase());
                return GestureDetector(
                  onTap: () => setState(() {
                    _selectedOption = isActive ? null : opt;
                    _selectedSubjectId = null;
                  }),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: isActive
                          ? const LinearGradient(colors: [_kAccent, _kAccentDark])
                          : null,
                      color: isActive ? null : (isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFF8FAFC)),
                      borderRadius: BorderRadius.circular(10),
                      border: isActive ? null : Border.all(color: isDark ? Colors.white.withOpacity(0.1) : _kBorderLight),
                    ),
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isActive ? Colors.white : theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // SUBJECT DROPDOWN
  // ═══════════════════════════════════════════════════════════════

  Widget _buildSubjectDropdown(ThemeData theme, bool isDark) {
    if (_selectedLevelId == null) {
      return _buildPremiumDropdown<String>(
        theme: theme,
        isDark: isDark,
        value: null,
        label: 'Subject',
        hint: 'Select a level first',
        icon: Icons.library_books_rounded,
        items: const [],
        onChanged: null,
        disabled: true,
      );
    }

    final subjectsAsync = ref.watch(subjectsByLevelProvider(
      (levelId: _selectedLevelId!, streamId: _selectedStreamId, optionLang: _selectedOption),
    ));
    return subjectsAsync.when(
      loading: () => _dropdownLoading(isDark),
      error: (e, _) => _dropdownError('Error loading subjects: $e'),
      data: (subjects) => _buildPremiumDropdown<String>(
        theme: theme,
        isDark: isDark,
        value: _selectedSubjectId,
        label: 'Subject',
        hint: subjects.isEmpty ? 'No subjects in this level' : 'Select subject',
        icon: Icons.library_books_rounded,
        items: subjects
            .map((s) => DropdownMenuItem(
                  value: s.id,
                  child: Text(s.nameEn.isNotEmpty ? s.nameEn : s.name),
                ))
            .toList(),
        onChanged: subjects.isEmpty ? null : (val) => setState(() => _selectedSubjectId = val),
        disabled: subjects.isEmpty,
      ),
    );
  }

  Widget _buildPremiumDropdown<T>({
    required ThemeData theme,
    required bool isDark,
    required T? value,
    required String label,
    required String hint,
    required IconData icon,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?>? onChanged,
    bool disabled = false,
  }) {
    // Defensive validation: DropdownButtonFormField asserts there is EXACTLY
    // one item whose value equals `value`. When editing a lesson, the preset
    // value (e.g. _selectedSubjectId) may not yet exist in the asynchronously
    // loaded / filtered items list, or duplicates could exist. In either case
    // fall back to null instead of crashing.
    final bool valueExistsOnce =
        value != null && items.where((item) => item.value == value).length == 1;
    final T? safeValue = valueExistsOnce ? value : null;

    return Container(
      decoration: BoxDecoration(
        color: disabled
            ? (isDark ? Colors.white.withOpacity(0.02) : const Color(0xFFF8FAFC))
            : (isDark ? Colors.white.withOpacity(0.04) : Colors.white),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.08) : _kBorderLight,
        ),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: DropdownButtonFormField<T>(
        value: safeValue,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: theme.colorScheme.onSurface.withOpacity(0.5),
            fontWeight: FontWeight.w500,
          ),
          hintText: hint,
          hintStyle: TextStyle(
            color: theme.colorScheme.onSurface.withOpacity(0.3),
            fontWeight: FontWeight.w500,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: _kAccent, width: 1.5),
          ),
          filled: true,
          fillColor: Colors.transparent,
          contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          prefixIcon: Container(
            margin: const EdgeInsets.only(left: 12, right: 8),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _kAccent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: _kAccent, size: 20),
          ),
        ),
        dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        icon: Icon(
          Icons.keyboard_arrow_down_rounded,
          color: theme.colorScheme.onSurface.withOpacity(0.5),
        ),
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: theme.colorScheme.onSurface,
          fontSize: 14,
        ),
        items: items,
        onChanged: onChanged,
      ),
    );
  }

  Widget _dropdownLoading(bool isDark) {
    return Container(
      height: 58,
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.04) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.08) : _kBorderLight,
        ),
      ),
      child: const Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2, color: _kAccent),
        ),
      ),
    );
  }

  Widget _dropdownError(String message) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.withOpacity(0.2)),
      ),
      child: Text(
        message,
        style: const TextStyle(color: Colors.red, fontSize: 13),
      ),
    );
  }
}
