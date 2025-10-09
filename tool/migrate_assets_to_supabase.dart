import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:dotenv/dotenv.dart' as dotenv;
import 'package:mime/mime.dart';
import 'package:path/path.dart' as p;
import 'package:supabase/supabase.dart';
import 'package:uuid/uuid.dart';

/// Uploads image assets from `assets/images` into the configured Supabase
/// storage bucket. After a successful run, a JSON summary is written to
/// `build/migrated_assets.json` mapping the original file names to their new
/// public URLs so they can be copied into seeds or the database.
Future<void> main(List<String> args) async {
  stdout.writeln('Loading environment from .env...');
  final dotenv.DotEnv env = dotenv.DotEnv(includePlatformEnvironment: true)
    ..load(<String>['.env']);

  final String? supabaseUrl = env['SUPABASE_URL'];
  final String? supabaseAnonKey = env['SUPABASE_ANON_KEY'];
  final String? serviceEmail = env['SUPABASE_SERVICE_EMAIL'];
  final String? servicePassword = env['SUPABASE_SERVICE_PASSWORD'];
  final String? bucket = env['SUPABASE_STORAGE_BUCKET'];

  if (supabaseUrl == null || supabaseUrl.isEmpty) {
    stderr.writeln('Missing SUPABASE_URL in .env');
    exitCode = 1;
    return;
  }
  if (supabaseAnonKey == null || supabaseAnonKey.isEmpty) {
    stderr.writeln('Missing SUPABASE_ANON_KEY in .env');
    exitCode = 1;
    return;
  }
  if (serviceEmail == null || serviceEmail.isEmpty) {
    stderr.writeln('Missing SUPABASE_SERVICE_EMAIL in .env');
    exitCode = 1;
    return;
  }
  if (servicePassword == null || servicePassword.isEmpty) {
    stderr.writeln('Missing SUPABASE_SERVICE_PASSWORD in .env');
    exitCode = 1;
    return;
  }
  if (bucket == null || bucket.isEmpty) {
    stderr.writeln('Missing SUPABASE_STORAGE_BUCKET in .env');
    exitCode = 1;
    return;
  }

  stdout.writeln('Connecting to Supabase...');
  final SupabaseClient client = SupabaseClient(supabaseUrl, supabaseAnonKey);

  stdout.writeln('Signing in service account...');
  try {
    final AuthResponse response = await client.auth.signInWithPassword(
      email: serviceEmail,
      password: servicePassword,
    );
    if (response.user == null) {
      stderr.writeln('Service account sign-in returned no user.');
      exitCode = 2;
      return;
    }
  } on AuthException catch (error) {
    stderr.writeln('Service account login failed: ${error.message}');
    exitCode = 2;
    return;
  } catch (error) {
    stderr.writeln('Unexpected auth error: $error');
    exitCode = 2;
    return;
  }

  final StorageFileApi storage = client.storage.from(bucket);

  final Directory assetDir = Directory('assets/images');
  if (!assetDir.existsSync()) {
    stderr.writeln('No assets/images directory found.');
    exitCode = 3;
    await client.auth.signOut();
    return;
  }

  final List<FileSystemEntity> entries = assetDir.listSync();
  if (entries.isEmpty) {
    stdout.writeln('No files found inside assets/images. Nothing to upload.');
    await client.auth.signOut();
    return;
  }

  final Map<String, String> uploaded = <String, String>{};
  final List<String> skipped = <String>[];

  for (final FileSystemEntity entity in entries) {
    if (entity is! File) {
      continue;
    }
    final String ext = p.extension(entity.path).toLowerCase();
    if (!<String>{'.png', '.jpg', '.jpeg', '.webp'}.contains(ext)) {
      skipped.add(p.basename(entity.path));
      continue;
    }

    final String fileName = p.basename(entity.path);
    stdout.writeln('Uploading $fileName...');
    final Uint8List rawBytes = await entity.readAsBytes();
    final String objectKey = _buildObjectKey('catalog', fileName);
    final String mimeType =
        lookupMimeType(fileName, headerBytes: rawBytes) ??
        'application/octet-stream';

    try {
      await storage.uploadBinary(
        objectKey,
        rawBytes,
        fileOptions: FileOptions(contentType: mimeType),
      );
      final String publicUrl = storage.getPublicUrl(objectKey);
      uploaded[fileName] = publicUrl;
      stdout.writeln('  → Success: $publicUrl');
    } on StorageException catch (error) {
      stderr.writeln('  → Failed to upload $fileName: ${error.message}');
    } catch (error, stackTrace) {
      stderr.writeln('  → Unexpected error for $fileName: $error');
      stderr.writeln(stackTrace);
    }
  }

  final Directory outputDir = Directory('build');
  if (!outputDir.existsSync()) {
    outputDir.createSync(recursive: true);
  }
  final File summaryFile = File(p.join(outputDir.path, 'migrated_assets.json'));
  summaryFile.writeAsStringSync(
    const JsonEncoder.withIndent('  ').convert(<String, dynamic>{
      'uploaded': uploaded,
      if (skipped.isNotEmpty) 'skipped': skipped,
    }),
  );

  stdout.writeln(
    'Wrote upload summary to ${summaryFile.path} with ${uploaded.length} entries.',
  );

  await client.auth.signOut();
}

const Uuid _uuid = Uuid();

String _buildObjectKey(String directory, String fileName) {
  final String sanitizedDirectory = _sanitizePathSegment(directory);
  final String extension = p.extension(fileName).toLowerCase();
  final int timestamp = DateTime.now().millisecondsSinceEpoch;
  return '$sanitizedDirectory/$timestamp-${_uuid.v4()}$extension';
}

String _sanitizePathSegment(String input) {
  final String trimmed = input.trim();
  if (trimmed.isEmpty) {
    return 'uploads';
  }
  return trimmed.replaceAll(RegExp(r'[^A-Za-z0-9/_-]'), '-');
}
