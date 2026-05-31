import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../discussion/data/discussion_repository.dart';
import '../../../discussion/discussion_providers.dart';
import '../../../authentication/data/supabase_auth_repository.dart';
import 'package:nexora_academy/l10n/app_localizations.dart';

class LessonTabsSection extends ConsumerStatefulWidget {
  final String lessonId;
  final String? description;
  final bool hasPdf;
  final VoidCallback? onOpenPdf;

  const LessonTabsSection({
    super.key,
    required this.lessonId,
    this.description,
    this.hasPdf = false,
    this.onOpenPdf,
  });

  @override
  ConsumerState<LessonTabsSection> createState() => _LessonTabsSectionState();
}

class _LessonTabsSectionState extends ConsumerState<LessonTabsSection>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: TabBar(
            controller: _tabController,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            labelColor: const Color(0xFF4A6CF7),
            unselectedLabelColor:
                isDark ? Colors.grey[500] : Colors.grey[600],
            labelStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
            unselectedLabelStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            indicatorColor: const Color(0xFF4A6CF7),
            indicatorWeight: 3,
            dividerColor: Colors.transparent,
            padding: EdgeInsets.zero,
            labelPadding: const EdgeInsets.only(right: 24),
            tabs: [
              Tab(text: AppLocalizations.of(context)!.overview),
              Tab(text: AppLocalizations.of(context)!.resources),
              Tab(text: AppLocalizations.of(context)!.discussion),
            ],
          ),
        ),
        SizedBox(
          height: 320,
          child: TabBarView(
            controller: _tabController,
            children: [
              _OverviewTab(
                description: widget.description,
                isDark: isDark,
              ),
              _ResourcesTab(
                hasPdf: widget.hasPdf,
                onOpenPdf: widget.onOpenPdf,
                isDark: isDark,
              ),
              _DiscussionTab(
                lessonId: widget.lessonId,
                isDark: isDark,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Overview Tab ──────────────────────────────────────────────────

class _OverviewTab extends StatelessWidget {
  final String? description;
  final bool isDark;

  const _OverviewTab({
    this.description,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final text = description?.isNotEmpty == true
        ? description!
        : AppLocalizations.of(context)!.noContentAvailable;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: SelectableText(
        text,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: isDark ? Colors.grey[300] : Colors.grey[700],
          height: 1.7,
        ),
      ),
    );
  }
}

// ── Resources Tab ─────────────────────────────────────────────────

class _ResourcesTab extends StatelessWidget {
  final bool hasPdf;
  final VoidCallback? onOpenPdf;
  final bool isDark;

  const _ResourcesTab({
    required this.hasPdf,
    this.onOpenPdf,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    if (!hasPdf) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.folder_open_rounded,
              size: 40,
              color: isDark ? Colors.grey[600] : Colors.grey[400],
            ),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context)!.noResourcesAvailable,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.grey[500] : Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: InkWell(
        onTap: onOpenPdf,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF97316).withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFFF97316).withValues(alpha: 0.15),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF97316).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.picture_as_pdf_rounded,
                  color: Color(0xFFF97316),
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.lessonPdf,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? const Color(0xFFF1F5F9)
                            : const Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      AppLocalizations.of(context)!.viewOrDownload,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.grey[400] : Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.open_in_new_rounded,
                color: isDark ? Colors.grey[500] : Colors.grey[400],
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Discussion Tab ────────────────────────────────────────────────

class _DiscussionTab extends ConsumerStatefulWidget {
  final String lessonId;
  final bool isDark;

  const _DiscussionTab({required this.lessonId, required this.isDark});

  @override
  ConsumerState<_DiscussionTab> createState() => _DiscussionTabState();
}

class _DiscussionTabState extends ConsumerState<_DiscussionTab> {
  final TextEditingController _commentController = TextEditingController();
  bool _isSending = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _sendComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    final authRepo = ref.read(authRepositoryProvider);
    final user = authRepo.currentUser;
    if (user == null) return;

    setState(() => _isSending = true);

    try {
      final repo = ref.read(discussionRepositoryProvider);
      debugPrint('[Discussion] Sending comment for lessonId: ${widget.lessonId}');
      await repo.addComment(
        userId: user.id,
        lessonId: widget.lessonId,
        content: text,
        userEmail: user.email,
      );
      _commentController.clear();

    } catch (e) {
      debugPrint('[Discussion] Failed to send comment: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final commentsAsync =
        ref.watch(commentsStreamProvider(widget.lessonId));

    return Column(
      children: [
        // Comments list
        Expanded(
          child: commentsAsync.when(
            data: (comments) {
              if (comments.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.chat_bubble_outline_rounded,
                        size: 36,
                        color: widget.isDark
                            ? Colors.grey[600]
                            : Colors.grey[400],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        AppLocalizations.of(context)!.beFirstToComment,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: widget.isDark
                              ? Colors.grey[500]
                              : Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                itemCount: comments.length,
                itemBuilder: (context, index) {
                  final comment = comments[index];
                  return _CommentBubble(
                    comment: comment,
                    isDark: widget.isDark,
                  );
                },
              );
            },
            loading: () =>
                const Center(child: CircularProgressIndicator()),
            error: (_, __) => Center(
              child: Text(
                'Failed to load comments',
                style: TextStyle(color: Colors.grey[500]),
              ),
            ),
          ),
        ),

        // Input bar
        Container(
          padding: const EdgeInsets.fromLTRB(20, 8, 12, 8),
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                color: widget.isDark
                    ? const Color(0xFF334155)
                    : const Color(0xFFE2E8F0),
              ),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _commentController,
                  style: TextStyle(
                    fontSize: 14,
                    color: widget.isDark
                        ? const Color(0xFFCBD5E1)
                        : const Color(0xFF334155),
                  ),
                  decoration: InputDecoration(
                    hintText: AppLocalizations.of(context)!.writeComment,
                    hintStyle: TextStyle(
                      color: widget.isDark
                          ? Colors.grey[600]
                          : Colors.grey[400],
                      fontSize: 14,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding:
                        const EdgeInsets.symmetric(vertical: 10),
                  ),
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _sendComment(),
                ),
              ),
              const SizedBox(width: 8),
              _isSending
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child:
                          CircularProgressIndicator(strokeWidth: 2),
                    )
                  : IconButton(
                      onPressed: _sendComment,
                      icon: const Icon(
                        Icons.send_rounded,
                        color: Color(0xFF4A6CF7),
                        size: 22,
                      ),
                    ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CommentBubble extends StatelessWidget {
  final CommentModel comment;
  final bool isDark;

  const _CommentBubble({
    required this.comment,
    required this.isDark,
  });

  String get _displayName {
    final email = comment.userEmail;
    if (email == null || email.isEmpty) return 'User';
    return email.contains('@') ? email.split('@').first : email;
  }

  String get _timeAgo {
    final diff = DateTime.now().difference(comment.createdAt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${comment.createdAt.day}/${comment.createdAt.month}';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor:
                const Color(0xFF4A6CF7).withValues(alpha: 0.15),
            child: Text(
              _displayName[0].toUpperCase(),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xFF4A6CF7),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      _displayName,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? const Color(0xFFF1F5F9)
                            : const Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _timeAgo,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  comment.content,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark
                        ? const Color(0xFFCBD5E1)
                        : const Color(0xFF475569),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
