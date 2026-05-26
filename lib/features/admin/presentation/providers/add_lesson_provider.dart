import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/admin_providers.dart';
import '../../../courses/presentation/providers/courses_provider.dart';
import '../../../courses/presentation/providers/storage_provider.dart';

final addLessonProvider = StateNotifierProvider.autoDispose<AddLessonNotifier, AsyncValue<void>>((ref) {
  return AddLessonNotifier(ref);
});

class AddLessonNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;

  AddLessonNotifier(this._ref) : super(const AsyncValue.data(null));

  Future<void> submit({
    required String? lessonIdToEdit,
    required String titleEn,
    required String titleFr,
    required String titleAr,
    required String descriptionEn,
    required String descriptionFr,
    required String descriptionAr,
    required String content,
    required String subjectId,
    required bool videoSourceIsUpload,
    required String videoUrl,
    required Uint8List? videoBytes,
    required String? videoFileName,
    required bool pdfSourceIsUpload,
    required String pdfUrl,
    required Uint8List? pdfBytes,
    required String? pdfFileName,
    required String orderNumberText,
    required String durationText,
    required Function(double) onVideoProgress,
    required Function(double) onPdfProgress,
  }) async {
    state = const AsyncValue.loading();

    try {
      final adminRepo = _ref.read(adminRepositoryProvider);
      final storageRepo = _ref.read(storageRepositoryProvider);

      // Resolve Video URL
      String? finalVideoUrl;
      if (videoSourceIsUpload && videoBytes != null) {
        onVideoProgress(0.1);
        final ext = videoFileName?.split('.').last ?? 'mp4';
        finalVideoUrl = await storageRepo.uploadVideoBytes(videoBytes, ext);
        onVideoProgress(1.0);
      } else {
        finalVideoUrl = videoUrl.trim().isEmpty ? null : videoUrl.trim();
      }

      // Resolve PDF URL
      String? finalPdfUrl;
      if (pdfSourceIsUpload && pdfBytes != null) {
        onPdfProgress(0.1);
        finalPdfUrl = await storageRepo.uploadPdfBytes(pdfBytes);
        onPdfProgress(1.0);
      } else {
        finalPdfUrl = pdfUrl.trim().isEmpty ? null : pdfUrl.trim();
      }

      if (finalVideoUrl == null || finalVideoUrl.isEmpty) {
        throw Exception('Video is required: pick a file or enter a URL');
      }
      if (finalPdfUrl == null || finalPdfUrl.isEmpty) {
        throw Exception('PDF is required: pick a file or enter a URL');
      }

      int? duration = int.tryParse(durationText.trim());
      
      final Map<String, dynamic> lessonData = {
        'title': titleEn.trim().isNotEmpty ? titleEn.trim() : (titleFr.trim().isNotEmpty ? titleFr.trim() : titleAr.trim()),
        'title_en': titleEn.trim(),
        'title_fr': titleFr.trim(),
        'title_ar': titleAr.trim(),
        'description': descriptionEn.trim().isNotEmpty ? descriptionEn.trim() : (descriptionFr.trim().isNotEmpty ? descriptionFr.trim() : descriptionAr.trim()),
        'description_en': descriptionEn.trim(),
        'description_fr': descriptionFr.trim(),
        'description_ar': descriptionAr.trim(),
        'content': content.trim(),
        'subject_id': subjectId,
        'video_url': finalVideoUrl,
        'pdf_url': finalPdfUrl,
        if (duration != null) 'duration': duration,
      };

      if (lessonIdToEdit != null) {
        if (orderNumberText.trim().isNotEmpty) {
           lessonData['order_number'] = int.tryParse(orderNumberText.trim()) ?? 0;
        }
        await adminRepo.updateLesson(lessonIdToEdit, lessonData);
      } else {
        int orderNumber;
        if (orderNumberText.trim().isNotEmpty) {
          orderNumber = int.tryParse(orderNumberText.trim()) ?? await adminRepo.getNextOrderNumber(subjectId);
        } else {
          orderNumber = await adminRepo.getNextOrderNumber(subjectId);
        }
        lessonData['order_number'] = orderNumber;
        await adminRepo.addLesson(lessonData);
      }

      // Invalidate caches
      _ref.read(coursesRepositoryProvider).invalidateLessonsCache(subjectId);
      _ref.invalidate(lessonsProvider(subjectId));
      _ref.invalidate(allLessonsProvider);

      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}
