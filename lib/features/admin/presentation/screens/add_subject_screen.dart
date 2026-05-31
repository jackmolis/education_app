import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../../data/admin_providers.dart';
import '../../../courses/presentation/providers/courses_provider.dart';
import '../../../courses/presentation/providers/subjects_provider.dart';
import '../../../streams/presentation/providers/streams_provider.dart';
import '../../../../core/providers/locale_provider.dart';
import 'package:nexora_academy/core/widgets/app_scaffold.dart';

const _kAccent = Color(0xFF7C3AED);
const _kAccentDark = Color(0xFF5B21B6);
const _kBorderLight = Color(0xFFE2E8F0);

class AddSubjectScreen extends ConsumerStatefulWidget {
  const AddSubjectScreen({super.key});

  @override
  ConsumerState<AddSubjectScreen> createState() => _AddSubjectScreenState();
}

class _AddSubjectScreenState extends ConsumerState<AddSubjectScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameEnController = TextEditingController();
  final _nameFrController = TextEditingController();
  final _nameArController = TextEditingController();
  final _descriptionController = TextEditingController();
  String? _pickedImageName;
  Uint8List? _pickedImageBytes;
  bool _isSubmitting = false;
  String? _selectedLevelId;
  String? _selectedStreamId;
  String? _selectedOption;

  @override
  void dispose() {
    _nameEnController.dispose();
    _nameFrController.dispose();
    _nameArController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedLevelId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select a level before saving.'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final repo = ref.read(adminRepositoryProvider);

      String imageUrl = '';
      if (_pickedImageBytes != null) {
        final ext = _pickedImageName?.split('.').last ?? 'jpg';
        imageUrl = await repo.uploadSubjectImageBytes(
          _pickedImageBytes!,
          ext,
        );
      }

      final subjectData = {
        'name_en': _nameEnController.text.trim(),
        'name_fr': _nameFrController.text.trim(),
        'name_ar': _nameArController.text.trim(),
        'description': _descriptionController.text.trim(),
        'image_url': imageUrl,
        'level_id': _selectedLevelId!,
        if (_selectedStreamId != null) 'stream_id': _selectedStreamId,
        if (_selectedOption != null) 'option_lang': _selectedOption,
      };

      debugPrint('Inserting subject with level_id: $_selectedLevelId');
      await repo.addSubjectWithDetails(subjectData);

      ref.read(coursesRepositoryProvider).clearSubjectsCache();
      ref.invalidate(subjectsProvider);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 12),
              Expanded(child: Text('Subject added successfully!')),
            ],
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          backgroundColor: Colors.green.shade600,
          margin: const EdgeInsets.only(bottom: 24, left: 24, right: 24),
        ),
      );

      _nameEnController.clear();
      _nameFrController.clear();
      _nameArController.clear();
      _descriptionController.clear();
      setState(() {
        _pickedImageName = null;
        _pickedImageBytes = null;
        _selectedLevelId = null;
        _selectedStreamId = null;
        _selectedOption = null;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text('Failed to add subject: $e')),
              ],
            ),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            backgroundColor: Theme.of(context).colorScheme.error,
            margin: const EdgeInsets.only(bottom: 24, left: 24, right: 24),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AppScaffold(
      backgroundColor: theme.colorScheme.surface,
      body: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        slivers: [
          // ═══════════════════════════════════════
          // HEADER
          // ═══════════════════════════════════════
          SliverToBoxAdapter(
            child: _buildHeader(context, theme, isDark),
          ),

          // ═══════════════════════════════════════
          // FORM BODY
          // ═══════════════════════════════════════
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── Level Selection ──
                    _buildSectionLabel(theme, 'Level Assignment', Icons.school_rounded),
                    const SizedBox(height: 12),
                    _buildLevelDropdown(context, theme, isDark),

                    // ── Stream Selection (if level has streams) ──
                    if (_selectedLevelId != null) ...[
                      const SizedBox(height: 14),
                      _buildStreamSelector(theme, isDark),
                    ],

                    // ── Option Selection (if level/stream has options) ──
                    if (_selectedLevelId != null) ...[
                      const SizedBox(height: 14),
                      _buildOptionSelector(theme, isDark),
                    ],

                    const SizedBox(height: 28),

                    // ── Subject Names ──
                    _buildSectionLabel(theme, 'Subject Names', Icons.translate_rounded),
                    const SizedBox(height: 12),
                    _buildTextField(
                      controller: _nameEnController,
                      label: 'English Name',
                      hint: 'e.g. Mathematics',
                      icon: Icons.language_rounded,
                      theme: theme,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 14),
                    _buildTextField(
                      controller: _nameFrController,
                      label: 'French Name',
                      hint: 'e.g. Mathématiques',
                      icon: Icons.language_rounded,
                      theme: theme,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 14),
                    _buildTextField(
                      controller: _nameArController,
                      label: 'Arabic Name',
                      hint: 'e.g. رياضيات',
                      icon: Icons.language_rounded,
                      theme: theme,
                      isDark: isDark,
                      textDirection: TextDirection.rtl,
                    ),

                    const SizedBox(height: 28),

                    // ── Description ──
                    _buildSectionLabel(theme, 'Description', Icons.description_rounded),
                    const SizedBox(height: 12),
                    _buildDescriptionField(theme, isDark),

                    const SizedBox(height: 28),

                    // ── Image Upload ──
                    _buildSectionLabel(theme, 'Cover Image', Icons.image_rounded),
                    const SizedBox(height: 12),
                    _buildImageUpload(context, theme, isDark),

                    const SizedBox(height: 36),

                    // ── Submit Button ──
                    _buildSubmitButton(theme),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // HEADER
  // ═══════════════════════════════════════════════════════════════

  Widget _buildHeader(BuildContext context, ThemeData theme, bool isDark) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF2D1B69), const Color(0xFF1A1145)]
              : [const Color(0xFF7C3AED), const Color(0xFF5B21B6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7C3AED).withOpacity(isDark ? 0.15 : 0.25),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          // Back button
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
          // Title
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Add New Subject',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Create a new subject for your platform',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.75),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          // Icon
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.library_add_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // SECTION LABEL
  // ═══════════════════════════════════════════════════════════════

  Widget _buildSectionLabel(ThemeData theme, String label, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: const Color(0xFF7C3AED),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.onSurface.withOpacity(0.7),
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // LEVEL DROPDOWN
  // ═══════════════════════════════════════════════════════════════

  Widget _buildLevelDropdown(BuildContext context, ThemeData theme, bool isDark) {
    final levelsAsync = ref.watch(levelsProvider);

    return levelsAsync.when(
      loading: () => Container(
        height: 58,
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.04) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFE2E8F0),
          ),
        ),
        child: const Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ),
      error: (e, st) {
        debugPrint('Error loading levels: $e');
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.red.withOpacity(0.2)),
          ),
          child: Text(
            'Failed to load levels: $e',
            style: const TextStyle(color: Colors.red, fontSize: 13),
          ),
        );
      },
      data: (levels) {
        debugPrint('Levels loaded for Add Subject: ${levels.length}');
        return Container(
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(0.04) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFE2E8F0),
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
          child: DropdownButtonFormField<String>(
            key: const ValueKey('add_subject_level_dropdown'),
            value: _selectedLevelId,
            decoration: InputDecoration(
              hintText: 'Select a level',
              hintStyle: TextStyle(
                color: theme.colorScheme.onSurface.withOpacity(0.4),
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
                borderSide: const BorderSide(color: Color(0xFF7C3AED), width: 1.5),
              ),
              filled: true,
              fillColor: Colors.transparent,
              contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              prefixIcon: Container(
                margin: const EdgeInsets.only(left: 12, right: 8),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF7C3AED).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.school_rounded, color: Color(0xFF7C3AED), size: 20),
              ),
            ),
            dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            items: levels.map<DropdownMenuItem<String>>((level) {
              return DropdownMenuItem<String>(
                value: level.id,
                child: Text(
                  level.name.isNotEmpty ? level.name : 'Unnamed Level',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              );
            }).toList(),
            onChanged: (value) {
              debugPrint('Level selected: $value');
              setState(() {
                _selectedLevelId = value;
                _selectedStreamId = null;
                _selectedOption = null;
              });
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please select a level';
              }
              return null;
            },
          ),
        );
      },
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
            _buildSectionLabel(theme, 'Stream / Branch', Icons.account_tree_rounded),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: streams.map((stream) {
                final isActive = _selectedStreamId == stream.id;
                final name = stream.getName(locale.languageCode);
                return GestureDetector(
                  onTap: () => setState(() {
                    _selectedStreamId = isActive ? null : stream.id;
                    _selectedOption = null;
                  }),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      gradient: isActive
                          ? const LinearGradient(colors: [_kAccent, _kAccentDark])
                          : null,
                      color: isActive ? null : (isDark ? Colors.white.withOpacity(0.06) : Colors.white),
                      borderRadius: BorderRadius.circular(12),
                      border: isActive ? null : Border.all(color: isDark ? Colors.white.withOpacity(0.1) : _kBorderLight),
                      boxShadow: isActive
                          ? [BoxShadow(color: _kAccent.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 3))]
                          : (isDark ? [] : [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6, offset: const Offset(0, 2))]),
                    ),
                    child: Text(
                      name,
                      style: TextStyle(
                        fontSize: 13,
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
            _buildSectionLabel(theme, 'Language Option', Icons.translate_rounded),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: options.map((opt) {
                final isActive = _selectedOption == opt;
                final label = opt == 'ar' ? 'Arabic Option' : (opt == 'fr' ? 'French Option' : opt.toUpperCase());
                return GestureDetector(
                  onTap: () => setState(() => _selectedOption = isActive ? null : opt),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      gradient: isActive
                          ? const LinearGradient(colors: [_kAccent, _kAccentDark])
                          : null,
                      color: isActive ? null : (isDark ? Colors.white.withOpacity(0.06) : Colors.white),
                      borderRadius: BorderRadius.circular(12),
                      border: isActive ? null : Border.all(color: isDark ? Colors.white.withOpacity(0.1) : _kBorderLight),
                      boxShadow: isActive
                          ? [BoxShadow(color: _kAccent.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 3))]
                          : (isDark ? [] : [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6, offset: const Offset(0, 2))]),
                    ),
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 13,
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
  // TEXT FIELD
  // ═══════════════════════════════════════════════════════════════

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required ThemeData theme,
    required bool isDark,
    TextDirection? textDirection,
  }) {
    final isRtl = textDirection == TextDirection.rtl;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.04) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFE2E8F0),
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
        textDirection: textDirection,
        textAlign: isRtl ? TextAlign.right : TextAlign.start,
        textCapitalization: isRtl ? TextCapitalization.none : TextCapitalization.words,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: theme.colorScheme.onSurface,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: theme.colorScheme.onSurface.withOpacity(0.5),
            fontWeight: FontWeight.w500,
          ),
          hintText: hint,
          hintTextDirection: textDirection,
          hintStyle: TextStyle(
            color: theme.colorScheme.onSurface.withOpacity(0.3),
            fontWeight: FontWeight.w400,
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
            borderSide: const BorderSide(color: Color(0xFF7C3AED), width: 1.5),
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
          contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          prefixIcon: isRtl
              ? null
              : Container(
                  margin: const EdgeInsets.only(left: 12, right: 8),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF7C3AED).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: const Color(0xFF7C3AED), size: 20),
                ),
          suffixIcon: isRtl
              ? Container(
                  margin: const EdgeInsets.only(left: 8, right: 12),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF7C3AED).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: const Color(0xFF7C3AED), size: 20),
                )
              : null,
        ),
        validator: (value) => value == null || value.trim().isEmpty ? 'Required' : null,
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // DESCRIPTION FIELD
  // ═══════════════════════════════════════════════════════════════

  Widget _buildDescriptionField(ThemeData theme, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.04) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFE2E8F0),
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
        controller: _descriptionController,
        maxLines: 4,
        style: TextStyle(
          fontWeight: FontWeight.w500,
          color: theme.colorScheme.onSurface,
          height: 1.5,
        ),
        decoration: InputDecoration(
          labelText: 'Description',
          labelStyle: TextStyle(
            color: theme.colorScheme.onSurface.withOpacity(0.5),
            fontWeight: FontWeight.w500,
          ),
          hintText: 'Describe what students will learn in this subject...',
          hintStyle: TextStyle(
            color: theme.colorScheme.onSurface.withOpacity(0.3),
            fontWeight: FontWeight.w400,
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
            borderSide: const BorderSide(color: Color(0xFF7C3AED), width: 1.5),
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
          contentPadding: const EdgeInsets.all(18),
          alignLabelWithHint: true,
        ),
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return 'Please enter a description';
          }
          return null;
        },
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // IMAGE UPLOAD
  // ═══════════════════════════════════════════════════════════════

  Widget _buildImageUpload(BuildContext context, ThemeData theme, bool isDark) {
    return GestureDetector(
      onTap: _isSubmitting
          ? null
          : () async {
              final result = await FilePicker.platform.pickFiles(
                type: FileType.image,
                withData: true,
              );
              if (result == null || result.files.isEmpty) return;
              final file = result.files.single;
              if (file.bytes == null) return;
              setState(() {
                _pickedImageName = file.name;
                _pickedImageBytes = file.bytes;
              });
            },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.04) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: _pickedImageBytes != null
                ? const Color(0xFF7C3AED).withOpacity(0.4)
                : isDark
                    ? Colors.white.withOpacity(0.08)
                    : const Color(0xFFE2E8F0),
            width: _pickedImageBytes != null ? 1.5 : 1,
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
        child: _pickedImageBytes != null
            ? _buildImagePreview(theme, isDark)
            : _buildUploadPlaceholder(theme),
      ),
    );
  }

  Widget _buildUploadPlaceholder(ThemeData theme) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF7C3AED).withOpacity(0.08),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.cloud_upload_rounded,
            color: Color(0xFF7C3AED),
            size: 32,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Tap to upload cover image',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'PNG, JPG, or WebP • Max 5MB',
          style: TextStyle(
            fontSize: 12,
            color: theme.colorScheme.onSurface.withOpacity(0.4),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildImagePreview(ThemeData theme, bool isDark) {
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Image.memory(
            _pickedImageBytes!,
            height: 140,
            width: double.infinity,
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_rounded,
              size: 16,
              color: Colors.green.shade600,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                _pickedImageName ?? 'Image selected',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: () {
                setState(() {
                  _pickedImageBytes = null;
                  _pickedImageName = null;
                });
              },
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.close_rounded, size: 16, color: Colors.red),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // SUBMIT BUTTON
  // ═══════════════════════════════════════════════════════════════

  Widget _buildSubmitButton(ThemeData theme) {
    return GestureDetector(
      onTap: _isSubmitting ? null : _submit,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: _isSubmitting
              ? LinearGradient(
                  colors: [
                    const Color(0xFF7C3AED).withOpacity(0.5),
                    const Color(0xFF5B21B6).withOpacity(0.5),
                  ],
                )
              : const LinearGradient(
                  colors: [Color(0xFF7C3AED), Color(0xFF5B21B6)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
          boxShadow: _isSubmitting
              ? []
              : [
                  BoxShadow(
                    color: const Color(0xFF7C3AED).withOpacity(0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_isSubmitting)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            else
              const Icon(Icons.add_circle_outline_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Text(
              _isSubmitting ? 'Saving Subject...' : 'Save Subject',
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
}
