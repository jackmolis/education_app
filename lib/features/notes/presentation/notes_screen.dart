import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../notes_providers.dart';

class NotesScreen extends ConsumerStatefulWidget {
  final String lessonId;
  final String lessonTitle;

  const NotesScreen({
    super.key,
    required this.lessonId,
    required this.lessonTitle,
  });

  @override
  ConsumerState<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends ConsumerState<NotesScreen> {
  late TextEditingController _controller;
  Timer? _debounce;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onTextChanged(String text) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 1500), () {
      ref.read(noteControllerProvider(widget.lessonId).notifier).save(text);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final noteAsync = ref.watch(noteProvider(widget.lessonId));
    final saveState = ref.watch(noteControllerProvider(widget.lessonId));

    // Pre-fill controller once when data loads
    if (!_loaded) {
      noteAsync.whenData((content) {
        if (!_loaded && content != null) {
          _controller.text = content;
          _controller.selection = TextSelection.fromPosition(
            TextPosition(offset: content.length),
          );
        }
        _loaded = true;
      });
    }

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B),
            size: 22,
          ),
          onPressed: () {
            // Save immediately before leaving
            _debounce?.cancel();
            if (_controller.text.isNotEmpty) {
              ref
                  .read(noteControllerProvider(widget.lessonId).notifier)
                  .save(_controller.text);
            }
            context.pop();
          },
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Notes',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: isDark
                    ? const Color(0xFFF1F5F9)
                    : const Color(0xFF1E293B),
              ),
            ),
            Text(
              widget.lessonTitle,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.grey[400] : Colors.grey[500],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        actions: [
          // Save indicator
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: saveState.when(
                data: (_) => Icon(
                  Icons.cloud_done_outlined,
                  color: isDark ? Colors.grey[500] : Colors.grey[400],
                  size: 20,
                ),
                loading: () => const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                error: (_, __) => const Icon(
                  Icons.cloud_off_outlined,
                  color: Colors.red,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
      body: noteAsync.when(
        data: (_) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: TextField(
              controller: _controller,
              onChanged: _onTextChanged,
              maxLines: null,
              expands: true,
              textAlignVertical: TextAlignVertical.top,
              style: TextStyle(
                fontSize: 15,
                height: 1.7,
                color: isDark
                    ? const Color(0xFFCBD5E1)
                    : const Color(0xFF334155),
              ),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: 'Write your notes here...',
                hintStyle: TextStyle(
                  color: isDark ? Colors.grey[600] : Colors.grey[400],
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text(
            'Failed to load notes',
            style: TextStyle(color: Colors.grey[500]),
          ),
        ),
      ),
    );
  }
}
