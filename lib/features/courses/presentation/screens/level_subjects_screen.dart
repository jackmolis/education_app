import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nexora_academy/core/widgets/app_scaffold.dart';
import 'package:nexora_academy/features/courses/presentation/providers/subjects_provider.dart';
import 'package:nexora_academy/core/utils/localization_helper.dart';
import 'package:nexora_academy/core/widgets/empty_state_widget.dart';
import '../../../../core/providers/locale_provider.dart';
import 'package:nexora_academy/l10n/app_localizations.dart';
import '../../data/progress_repository.dart';

class LevelSubjectsScreen extends ConsumerStatefulWidget {
  final String levelId;
  final String levelName;
  final String? streamId;
  final String? optionLang;

  const LevelSubjectsScreen({
    super.key,
    required this.levelId,
    required this.levelName,
    this.streamId,
    this.optionLang,
  });

  @override
  ConsumerState<LevelSubjectsScreen> createState() =>
      _LevelSubjectsScreenState();
}

class _LevelSubjectsScreenState extends ConsumerState<LevelSubjectsScreen> {
  final ScrollController _scrollController = ScrollController();

  SubjectsQueryArgs get _args => (
        levelId: widget.levelId,
        streamId: widget.streamId,
        optionLang: widget.optionLang,
      );

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final current = _scrollController.offset;
    if (current >= maxScroll - 200) {
      ref.read(paginatedSubjectsByLevelProvider(_args).notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(paginatedSubjectsByLevelProvider(_args));
    final locale = ref.watch(localeProvider);
    final loc = AppLocalizations.of(context)!;

    return AppScaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Padding(
            padding:
                const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded),
                  onPressed: () => context.pop(),
                ),
                Expanded(
                  child: Text(
                    widget.levelName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 20,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 48),
              ],
            ),
          ),
          // Body
          Expanded(
            child: _buildBody(context, state, locale, loc),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    PaginatedSubjectsState state,
    dynamic locale,
    AppLocalizations loc,
  ) {
    if (state.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF4A6CF7)),
      );
    }

    if (state.error != null && state.subjects.isEmpty) {
      return CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverFillRemaining(
            hasScrollBody: false,
            child: EmptyStateWidget(
              icon: Icons.error_outline,
              title: loc.failedToLoadSubjects,
              actionLabel: loc.tryAgain,
              onAction: () =>
                  ref.read(paginatedSubjectsByLevelProvider(_args).notifier).refresh(),
            ),
          ),
        ],
      );
    }

    return RefreshIndicator(
      color: const Color(0xFF4A6CF7),
      onRefresh: () =>
          ref.read(paginatedSubjectsByLevelProvider(_args).notifier).refresh(),
      child: state.subjects.isEmpty
          ? CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              slivers: [
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: EmptyStateWidget(
                    icon: Icons.library_books_outlined,
                    title: loc.noSubjectsAvailable,
                    subtitle: loc.subjectsAppearHere,
                    actionLabel: loc.refresh,
                    onAction: () => ref
                        .read(paginatedSubjectsByLevelProvider(_args).notifier)
                        .refresh(),
                  ),
                ),
              ],
            )
          : ListView.builder(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
              itemCount:
                  state.subjects.length + (state.isLoadingMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == state.subjects.length) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(
                      child: CircularProgressIndicator(
                          color: Color(0xFF4A6CF7)),
                    ),
                  );
                }

                final subject = state.subjects[index];
                final localizedName = subject.getName(locale.languageCode);

                return _SubjectItemCard(
                  subjectId: subject.id,
                  name: localizedName,
                  levelName: widget.levelName,
                  colorIndex: index,
                  index: index,
                  onTap: () {
                    context.push(
                      '/levels/${Uri.encodeComponent(widget.levelId)}/subjects/${Uri.encodeComponent(subject.id)}/sections',
                      extra: {
                        'levelName': widget.levelName,
                        'subject': subject,
                      },
                    );
                  },
                );
              },
            ),
    );
  }
}

// ==========================================
// _SubjectItemCard — Animated subject card
// ==========================================

class _SubjectItemCard extends ConsumerStatefulWidget {
  final String subjectId;
  final String name;
  final String levelName;
  final int colorIndex;
  final int index;
  final VoidCallback onTap;

  const _SubjectItemCard({
    required this.subjectId,
    required this.name,
    required this.levelName,
    required this.colorIndex,
    required this.index,
    required this.onTap,
  });

  @override
  ConsumerState<_SubjectItemCard> createState() => _SubjectItemCardState();
}

class _SubjectItemCardState extends ConsumerState<_SubjectItemCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;
  bool _isHovering = false;

  final List<List<Color>> _gradients = [
    [const Color(0xFF4A6CF7), const Color(0xFF819DF9)],
    [const Color(0xFFF59E0B), const Color(0xFFFCD34D)],
    [const Color(0xFF10B981), const Color(0xFF6EE7B7)],
    [const Color(0xFFEC4899), const Color(0xFFF9A8D4)],
    [const Color(0xFF8B5CF6), const Color(0xFFC4B5FD)],
    [const Color(0xFFEF4444), const Color(0xFFFCA5A5)],
    [const Color(0xFF06B6D4), const Color(0xFF67E8F9)],
  ];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.0, 1.0, curve: Curves.easeOut),
      ),
    );

    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.0, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    // Cap stagger delay at 20 items to avoid excessive scheduling
    final staggerIndex = widget.index % 20;
    Future.delayed(Duration(milliseconds: staggerIndex * 60), () {
      if (mounted) _animController.forward();
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gradient = _gradients[widget.colorIndex % _gradients.length];
    final loc = AppLocalizations.of(context)!;
    final progressAsync = ref.watch(subjectProgressProvider(widget.subjectId));
    final progressPercent = progressAsync.maybeWhen(
      data: (val) => val.isNaN ? 0.0 : val,
      orElse: () => 0.0,
    );
    final progressText = '${(progressPercent * 100).toInt()}% ${loc.completeProgress}';

    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: MouseRegion(
            onEnter: (_) => setState(() => _isHovering = true),
            onExit: (_) => setState(() => _isHovering = false),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: _isHovering
                        ? gradient[0].withOpacity(0.2)
                        : Colors.black.withOpacity(0.05),
                    blurRadius: _isHovering ? 15 : 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: widget.onTap,
                  splashColor: gradient[0].withOpacity(0.1),
                  highlightColor: gradient[0].withOpacity(0.05),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        // LEFT: Square gradient icon
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: gradient,
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.menu_book_rounded,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        // CENTER: Subject details
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.name,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1E293B),
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  // LEFT: level
                                  Flexible(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF1F5F9),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        _extractBaseLevelName(widget.levelName),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF64748B),
                                        ),
                                      ),
                                    ),
                                  ),

                                  const SizedBox(width: 8),

                                  // RIGHT: progress
                                  Text(
                                    progressText,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: gradient[0],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              // Progress bar
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: progressPercent.isNaN
                                      ? 0
                                      : progressPercent,
                                  minHeight: 5,
                                  backgroundColor: const Color(0xFFF1F5F9),
                                  valueColor:
                                      AlwaysStoppedAnimation<Color>(gradient[0]),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        // RIGHT: Arrow
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 14,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Extracts the base level name from a compound path string.
/// "2ème Bac - Sciences Agronomiques" → "2ème Bac"
/// "Common Core" → "Common Core"
String _extractBaseLevelName(String fullName) {
  final separators = [' - ', ' — ', ' – '];
  for (final sep in separators) {
    final idx = fullName.indexOf(sep);
    if (idx > 0) return fullName.substring(0, idx);
  }
  return fullName;
}
