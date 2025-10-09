import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as p;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:vendwise/backend/bootstrap.dart';

/// Helper that wraps Supabase Storage interactions for uploading assets.
class SupabaseStorageService {
  SupabaseStorageService(this._client, this._bucket);

  final SupabaseClient _client;
  final String _bucket;
  static const Uuid _uuid = Uuid();

  /// Uploads the provided file picker selection into the configured bucket and
  /// returns a public URL pointing to the uploaded asset.
  Future<String> uploadPlatformFile(
    PlatformFile file, {
    String directory = 'products',
  }) async {
    if (file.bytes == null) {
      throw StateError(
        'File bytes were not provided by the picker. Enable withData: true when calling FilePicker.',
      );
    }
    final Uint8List data = file.bytes!;

    final String fileName = file.name;
    final String extension = p.extension(fileName).toLowerCase();
    final String sanitizedDir = _sanitizePathSegment(directory);
    final String objectKey =
        '$sanitizedDir/${DateTime.now().millisecondsSinceEpoch}-${_uuid.v4()}$extension';
    final String mimeType =
        lookupMimeType(fileName, headerBytes: data) ??
        'application/octet-stream';

    await _client.storage
        .from(_bucket)
        .uploadBinary(
          objectKey,
          data,
          fileOptions: FileOptions(contentType: mimeType, upsert: true),
        );

    return _client.storage.from(_bucket).getPublicUrl(objectKey);
  }

  String _sanitizePathSegment(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) {
      return 'uploads';
    }
    return trimmed.replaceAll(RegExp(r'[^A-Za-z0-9/_-]'), '-');
  }
}

/// Returns a configured storage service when Supabase is active and a bucket
/// name is available; otherwise null.
SupabaseStorageService? getSupabaseStorageService() {
  if (!supabaseRepositoryActive) {
    return null;
  }
  final bucket = supabaseStorageBucket;
  if (bucket == null || bucket.isEmpty) {
    return null;
  }
  return SupabaseStorageService(Supabase.instance.client, bucket);
}
