import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../courses/domain/models/subject_model.dart';
import '../../../courses/presentation/providers/subjects_provider.dart';
import '../../../streams/presentation/providers/streams_provider.dart';
import '../../../../core/providers/locale_provider.dart';

const _kAccent = Color(0xFF7C3AED);
const _kAccentDark = Color(0xFF5B21B6);
const _kBorderLight = Color(0xFFE2E8F0);

/// Reusable academic-hierarchy selector:
///   Level → Stream (if any) → Language Option (if >1) → Subject
///
/// It does NOT contain any filtering logic of its own — it drives the exact
/// same Riverpod providers used by Add Lesson (`levelsProvider`,
/// `streamsByLevelProvider`, `optionsByLevelProvider`, `subjectsByLevelProvider`),
/// so subject filtering stays in one place.
///
/// Emits the chosen [SubjectModel] (and the resolved level id) via [onSubjectSelected].
class SubjectCategorySelector extends ConsumerStatefulWidget {
  final void Function(SubjectModel subject, String levelId) onSubjectSelected;

  /// Optional initial selection (used when editing).
  final String? initialLevelId;
  final String? initialStreamId;
  final String? initialOptionLang;
  final String? initialSubjectId;

  const SubjectCategorySelector({
    super.key,
    required this.onSubjectSelected,
    this.initialLevelId,
    this.initialStreamId,
    this.initialOptionLang,
    this.initialSubjectId,
  });

  @override
  ConsumerState<SubjectCategorySelector> createState() =>
      _SubjectCategorySelectorState();
}

class _SubjectCategorySelectorState
    extends ConsumerState<SubjectCategorySelector> {
  String? _selectedLevelId;
  String? _selectedStreamId;
  String? _selectedOption;
  String? _selectedSubjectId;

  @override
  void initState() {
    super.initState();
    _selectedLevelId = widget.initialLevelId;
    _selectedStreamId = widget.initialStreamId;
    _selectedOption = widget.initialOptionLang;
    _selectedSubjectId = widget.initialSubjectId;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Column(
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
    );
  }

  // ── Level ──
  Widget _buildLevelDropdown(ThemeData theme, bool isDark) {
    final levelsAsync = ref.watch(levelsProvider);
    return levelsAsync.when(
      loading: () => _loadingBox(isDark),
      error: (e, _) => _errorBox('Error loading levels: $e'),
      data: (levels) => _dropdown<String>(
        theme: theme,
        isDark: isDark,
        value: _selectedLevelId,
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

  // ── Stream ──
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
            _miniLabel(theme, Icons.account_tree_rounded, 'Stream / Branch'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: streams.map((stream) {
                final isActive = _selectedStreamId == stream.id;
                return _pill(
                  theme: theme,
                  isDark: isDark,
                  label: stream.getName(locale.languageCode),
                  isActive: isActive,
                  onTap: () => setState(() {
                    _selectedStreamId = isActive ? null : stream.id;
                    _selectedOption = null;
                    _selectedSubjectId = null;
                  }),
                );
              }).toList(),
            ),
          ],
        );
      },
    );
  }

  // ── Option ──
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
            _miniLabel(theme, Icons.translate_rounded, 'Language Option'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: options.map((opt) {
                final isActive = _selectedOption == opt;
                final label = opt == 'ar'
                    ? 'Arabic Option'
                    : (opt == 'fr' ? 'French Option' : opt.toUpperCase());
                return _pill(
                  theme: theme,
                  isDark: isDark,
                  label: label,
                  isActive: isActive,
                  onTap: () => setState(() {
                    _selectedOption = isActive ? null : opt;
                    _selectedSubjectId = null;
                  }),
                );
              }).toList(),
            ),
          ],
        );
      },
    );
  }

  // ── Subject ──
  Widget _buildSubjectDropdown(ThemeData theme, bool isDark) {
    if (_selectedLevelId == null) {
      return _dropdown<String>(
        theme: theme,
        isDark: isDark,
        value: null,
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
    final localeCode = ref.watch(localeProvider).languageCode;

    return subjectsAsync.when(
      loading: () => _loadingBox(isDark),
      error: (e, _) => _errorBox('Error loading subjects: $e'),
      data: (subjects) => _dropdown<String>(
        theme: theme,
        isDark: isDark,
        value: _selectedSubjectId,
        hint: subjects.isEmpty ? 'No subjects in this level' : 'Select subject',
        icon: Icons.library_books_rounded,
        items: subjects
            .map((s) => DropdownMenuItem(
                  value: s.id,
                  child: Text(s.getName(localeCode)),
                ))
            .toList(),
        onChanged: subjects.isEmpty
            ? null
            : (val) {
                setState(() => _selectedSubjectId = val);
                if (val == null) return;
                final match = subjects.where((s) => s.id == val);
                if (match.isNotEmpty) {
                  widget.onSubjectSelected(match.first, _selectedLevelId!);
                }
              },
        disabled: subjects.isEmpty,
      ),
    );
  }

  // ── Shared building blocks (visual only — no filtering here) ──

  Widget _dropdown<T>({
    required ThemeData theme,
    required bool isDark,
    required T? value,
    required String hint,
    required IconData icon,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?>? onChanged,
    bool disabled = false,
  }) {
    final bool valueExistsOnce =
        value != null && items.where((i) => i.value == value).length == 1;
    final T? safeValue = valueExistsOnce ? value : null;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: isDark ? Colors.white.withValues(alpha: 0.08) : _kBorderLight),
      ),
      child: DropdownButtonFormField<T>(
        value: safeValue,
        isExpanded: true,
        decoration: InputDecoration(
          hintText: hint,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: _kAccent, width: 1.5)),
          filled: true,
          fillColor: Colors.transparent,
          contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          prefixIcon: Container(
            margin: const EdgeInsets.only(left: 12, right: 8),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _kAccent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: _kAccent, size: 20),
          ),
        ),
        dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        items: items,
        onChanged: onChanged,
      ),
    );
  }

  Widget _miniLabel(ThemeData theme, IconData icon, String text) => Row(
        children: [
          Icon(icon, size: 14, color: _kAccent),
          const SizedBox(width: 6),
          Text(text,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6))),
        ],
      );

  Widget _pill({
    required ThemeData theme,
    required bool isDark,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          gradient: isActive
              ? const LinearGradient(colors: [_kAccent, _kAccentDark])
              : null,
          color: isActive
              ? null
              : (isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFF8FAFC)),
          borderRadius: BorderRadius.circular(10),
          border: isActive
              ? null
              : Border.all(color: isDark ? Colors.white.withValues(alpha: 0.1) : _kBorderLight),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: isActive ? Colors.white : theme.colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
      ),
    );
  }

  Widget _loadingBox(bool isDark) => Container(
        height: 58,
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: isDark ? Colors.white.withValues(alpha: 0.08) : _kBorderLight),
        ),
        child: const Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2, color: _kAccent),
          ),
        ),
      );

  Widget _errorBox(String message) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
        ),
        child: Text(message, style: const TextStyle(color: Colors.red, fontSize: 13)),
      );
}
