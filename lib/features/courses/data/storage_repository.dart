import 'dart:io';

import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';

class StorageRepository {
  final SupabaseClient _supabase;

  StorageRepository({SupabaseClient? supabase})
    : _supabase = supabase ?? Supabase.instance.client;

  /// Returns the public URL for a file in [bucketId] at [path].
  String getPublicUrl(String bucketId, String path) {
    return _supabase.storage.from(bucketId).getPublicUrl(path);
  }

  /// Uploads a video file to the "videos" bucket at lessons/{timestamp}.{ext}
  /// and returns its public URL.
  Future<String> uploadVideo(File file, String fileExtension) async {
    const bucketId = 'videos';
    final path = 'lessons/${DateTime.now().millisecondsSinceEpoch}.${fileExtension.replaceAll('.', '')}';
    await _supabase.storage.from(bucketId).upload(
      path,
      file,
      fileOptions: const FileOptions(upsert: false),
    );
    return getPublicUrl(bucketId, path);
  }

  /// Uploads video bytes (e.g. from web file picker) to "videos" bucket.
  Future<String> uploadVideoBytes(Uint8List bytes, String fileExtension) async {
    const bucketId = 'videos';
    final path = 'lessons/${DateTime.now().millisecondsSinceEpoch}.${fileExtension.replaceAll('.', '')}';
    await _supabase.storage.from(bucketId).uploadBinary(
      path,
      bytes,
      fileOptions: const FileOptions(upsert: false),
    );
    return getPublicUrl(bucketId, path);
  }

  /// Uploads a PDF file to the "pdf" bucket at lessons/{timestamp}.pdf
  /// and returns its public URL.
  Future<String> uploadPdf(File file) async {
    const bucketId = 'pdf';
    final path = 'lessons/${DateTime.now().millisecondsSinceEpoch}.pdf';
    await _supabase.storage.from(bucketId).upload(
      path,
      file,
      fileOptions: const FileOptions(upsert: false),
    );
    return getPublicUrl(bucketId, path);
  }

  /// Uploads PDF bytes (e.g. from web file picker) to "pdf" bucket.
  Future<String> uploadPdfBytes(Uint8List bytes) async {
    const bucketId = 'pdf';
    final path = 'lessons/${DateTime.now().millisecondsSinceEpoch}.pdf';
    await _supabase.storage.from(bucketId).uploadBinary(
      path,
      bytes,
      fileOptions: const FileOptions(upsert: false),
    );
    return getPublicUrl(bucketId, path);
  }

  /// Retrieves a signed URL for a file in Supabase Storage.
  /// If [path] is already a full HTTP/HTTPS URL, it returns it directly.
  Future<String> getSignedUrl(String bucketId, String path) async {
    if (path.isEmpty) return path;

    // Check if the path is actually a full web URL (e.g., YouTube or complete URL)
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return path;
    }

    try {
      // Ask Supabase Storage for a URL valid for 1 hour (3600 seconds)
      final signedUrl = await _supabase.storage
          .from(bucketId)
          .createSignedUrl(path, 3600);

      return signedUrl;
    } catch (e) {
      throw Exception('Failed to generate storage URL for $path: $e');
    }
  }
}
