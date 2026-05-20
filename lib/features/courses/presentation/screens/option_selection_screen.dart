import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nexora_academy/core/widgets/app_scaffold.dart';
import 'package:nexora_academy/features/courses/presentation/providers/subjects_provider.dart';
import 'package:nexora_academy/core/widgets/empty_state_widget.dart';
import 'package:nexora_academy/l10n/app_localizations.dart';

/// Shown after selecting a level that has option_lang partitioning.
/// Queries Supabase for distinct option_lang values and presents them as cards.
class OptionSelectionScreen extends ConsumerWidget {
  final String levelId;
  final String levelName;
  final String? streamId;

  const OptionSelectionScreen({
    super.key,
    required this.levelId,
    required this.levelName,
    this.streamId,
  });

  // Human-readable label and icon for each option_lang code
  static const _optionMeta = <String, Map<String, dynamic>>{
    'ar': {
      'icon': Icons.translate_rounded,
      'gradient': [Color(0xFF4A6CF7), Color(0xFF819DF9)],
    },
    'fr': {
      'icon': Icons.language_rounded,
      'gradient': [Color(0xFF10B981), Color(0xFF6EE7B7)],
    },
  };

  // Fallback for unknown option codes
  static Map<String, dynamic> _metaFor(String code, int index) {
    final fallbackGradients = [
      [const Color(0xFFF59E0B), const Color(0xFFFCD34D)],
      [const Color(0xFFEC4899), const Color(0xFFF9A8D4)],
      [const Color(0xFF8B5CF6), const Color(0xFFC4B5FD)],
      [const Color(0xFFEF4444), const Color(0xFFFCA5A5)],
    ];
    return _optionMeta[code] ??
        {
          'label': code.toUpperCase(),
          'sublabel': '',
          'icon': Icons.folder_open_rounded,
          'gradient': fallbackGradients[index % fallbackGradients.length],
        };
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final optionsAsync = ref.watch(optionsByLevelProvider((levelId: levelId, streamId: streamId)));
    final loc = AppLocalizations.of(context)!;

    return AppScaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Header ──
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
                    levelName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 22,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 48),
              ],
            ),
          ),

          // ── Subtitle ──
          Padding(
            padding: const EdgeInsets.only(left: 24, right: 24, bottom: 16),
            child: Text(
              loc.selectOption,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          // ── Body ──
          Expanded(
            child: optionsAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: Color(0xFF4A6CF7)),
              ),
              error: (e, _) => CustomScrollView(
                slivers: [
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: EmptyStateWidget(
                      icon: Icons.error_outline,
                      title: loc.failedToLoadSubjects,
                      actionLabel: loc.tryAgain,
                      onAction: () =>
                          ref.invalidate(
                            optionsByLevelProvider((levelId: levelId, streamId: streamId)),
                          )
                    ),
                  ),
                ],
              ),
              data: (options) {
                if (options.length <= 1) {
                  // Fallback in case route is accessed directly
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    context.pushReplacement(
                      '/level-subjects',
                      extra: {
                        'levelId': levelId,
                        'levelName': levelName,
                        'streamId': streamId,
                        'optionLang': options.isNotEmpty ? options.first : null,
                      },
                    );
                  });
                  return const Center(
                    child: CircularProgressIndicator(color: Color(0xFF4A6CF7)),
                  );
                }

                return ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
                  itemCount: options.length,
                  itemBuilder: (context, index) {
                    final code = options[index];
                    final meta = _metaFor(code, index);

                    final label = code == 'fr'
                        ? loc.optionFrench
                        : loc.optionArabic;

                    final sublabel = code == 'fr'
                        ? loc.optionFrenchDesc
                        : loc.optionArabicDesc;
                    return _OptionCard(
                      label: label,
                      sublabel: sublabel,
                      icon: meta['icon'] as IconData,
                      gradient: List<Color>.from(
                          meta['gradient'] as List),
                      index: index,
                      onTap: () {
                        context.push(
                          '/level-subjects',
                          extra: {
                            'levelId': levelId,
                            'levelName': '$levelName — $label',
                            'streamId': streamId,
                            'optionLang': code,
                          },
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════
// _OptionCard — animated option selector card
// ══════════════════════════════════════════

class _OptionCard extends StatefulWidget {
  final String label;
  final String sublabel;
  final IconData icon;
  final List<Color> gradient;
  final int index;
  final VoidCallback onTap;

  const _OptionCard({
    required this.label,
    required this.sublabel,
    required this.icon,
    required this.gradient,
    required this.index,
    required this.onTap,
  });

  @override
  State<_OptionCard> createState() => _OptionCardState();
}

class _OptionCardState extends State<_OptionCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;
  late Animation<Offset> _slide;
  bool _hovering = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));

    Future.delayed(Duration(milliseconds: widget.index * 100), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: MouseRegion(
            onEnter: (_) => setState(() => _hovering = true),
            onExit: (_) => setState(() => _hovering = false),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: _hovering
                        ? widget.gradient[0].withOpacity(0.22)
                        : Colors.black.withOpacity(0.06),
                    blurRadius: _hovering ? 18 : 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: widget.onTap,
                  splashColor: widget.gradient[0].withOpacity(0.12),
                  highlightColor: widget.gradient[0].withOpacity(0.06),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        // Icon bubble
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: widget.gradient,
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Center(
                            child: Icon(
                              widget.icon,
                              color: Colors.white,
                              size: 30,
                            ),
                          ),
                        ),
                        const SizedBox(width: 18),
                        // Text
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.label,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                              if (widget.sublabel.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  widget.sublabel,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF64748B),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        // Arrow
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: _hovering
                                ? widget.gradient[0].withOpacity(0.12)
                                : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 14,
                            color: _hovering
                                ? widget.gradient[0]
                                : const Color(0xFF94A3B8),
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
