import 'dart:convert';
import 'dart:io';

import 'package:dotenv/dotenv.dart' as dotenv;
import 'package:path/path.dart' as p;
import 'package:supabase/supabase.dart';

Future<void> main(List<String> args) async {
  final bool dryRun = args.contains('--dry-run');
  final String? customPrefix = _extractPrefixArg(args);

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

  final File manifestFile = File(p.join('build', 'migrated_assets.json'));
  if (!manifestFile.existsSync()) {
    stderr.writeln(
      'Could not find build/migrated_assets.json. Run the migration script first.',
    );
    exitCode = 2;
    return;
  }

  final Map<String, dynamic> manifest =
      jsonDecode(manifestFile.readAsStringSync()) as Map<String, dynamic>;
  final Map<String, dynamic> uploaded = (manifest['uploaded'] as Map)
      .cast<String, dynamic>();
  final Set<String> allowedObjectPaths = uploaded.values
      .map((dynamic value) => _extractObjectPath(value as String, bucket))
      .where((String? path) => path != null)
      .cast<String>()
      .map(_normalizeStoragePath)
      .toSet();

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
      exitCode = 3;
      return;
    }
  } on AuthException catch (error) {
    stderr.writeln('Service account login failed: ${error.message}');
    exitCode = 3;
    return;
  } catch (error) {
    stderr.writeln('Unexpected auth error: $error');
    exitCode = 3;
    return;
  }

  final StorageFileApi storage = client.storage.from(bucket);
  final List<String> deletedPaths = <String>[];

  final String normalizedPrefix = _normalizeStoragePath(
    customPrefix ?? 'catalog',
  );

  stdout.writeln(
    'Scanning $bucket for orphaned objects under "${normalizedPrefix.isEmpty ? '(root)' : normalizedPrefix}"...',
  );
  final List<FileObject> files = await _listAll(storage, normalizedPrefix);
  for (final FileObject file in files) {
    final String objectPath = _composeObjectPath(normalizedPrefix, file.name);
    if (!allowedObjectPaths.contains(objectPath)) {
      if (dryRun) {
        stdout.writeln('  → Would remove $objectPath');
      } else {
        stdout.writeln('  → Removing $objectPath');
      }
      deletedPaths.add(objectPath);
    }
  }

  if (deletedPaths.isEmpty) {
    stdout.writeln('No orphaned objects found.');
  } else if (dryRun) {
    stdout.writeln('Dry run complete. ${deletedPaths.length} objects flagged.');
  } else {
    await storage.remove(deletedPaths);
    stdout.writeln('Deleted ${deletedPaths.length} objects.');
  }

  await client.auth.signOut();
}

Future<List<FileObject>> _listAll(StorageFileApi storage, String path) async {
  const int pageSize = 100;
  final List<FileObject> results = <FileObject>[];
  int offset = 0;

  while (true) {
    final List<FileObject> batch = await storage.list(
      path: path.isEmpty ? null : path,
      searchOptions: SearchOptions(
        limit: pageSize,
        offset: offset,
        sortBy: const SortBy(column: 'name', order: 'asc'),
      ),
    );

    if (batch.isEmpty) {
      break;
    }

    results.addAll(batch);
    if (batch.length < pageSize) {
      break;
    }
    offset += batch.length;
  }

  return results;
}

String? _extractObjectPath(String url, String bucket) {
  try {
    final Uri uri = Uri.parse(url);
    final int publicIndex = uri.pathSegments.indexOf('public');
    if (publicIndex == -1 || publicIndex + 2 >= uri.pathSegments.length) {
      return null;
    }
    final String bucketSegment = uri.pathSegments[publicIndex + 1];
    if (bucketSegment != bucket) {
      return null;
    }
    final String objectPath = uri.pathSegments
        .sublist(publicIndex + 2)
        .join('/');
    return objectPath;
  } catch (_) {
    return null;
  }
}

String _normalizeStoragePath(String path) {
  return path
      .replaceAll(RegExp(r'^/+'), '')
      .replaceAll(RegExp(r'/+$'), '')
      .replaceAll(RegExp(r'/+'), '/');
}

String _composeObjectPath(String prefix, String name) {
  final String normalizedName = _normalizeStoragePath(name);
  if (prefix.isEmpty) {
    return normalizedName;
  }
  if (normalizedName.isEmpty) {
    return prefix;
  }
  if (normalizedName == prefix || normalizedName.startsWith('$prefix/')) {
    return normalizedName;
  }
  return '$prefix/$normalizedName';
}

String? _extractPrefixArg(List<String> args) {
  for (final String arg in args) {
    if (arg.startsWith('--prefix=')) {
      final String value = arg.substring('--prefix='.length);
      return value;
    }
  }
  return null;
}
