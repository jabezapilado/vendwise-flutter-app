import 'dart:developer' as developer;

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vendwise/backend/app_repository.dart';
import 'package:vendwise/backend/supabase_repository.dart';

/// Describes the outcome of initializing runtime services (currently Supabase).
class AppBootstrapResult {
  const AppBootstrapResult({
    required this.envFileLoaded,
    required this.supabaseConfigured,
    required this.supabaseInitialized,
    required this.tableIssues,
    required this.storageBucket,
    required this.storageError,
    this.errorMessage,
  });

  /// Whether the .env file was successfully parsed.
  final bool envFileLoaded;

  /// True when both SUPABASE_URL and SUPABASE_ANON_KEY were present.
  final bool supabaseConfigured;

  /// True if `Supabase.initialize` finished without throwing.
  final bool supabaseInitialized;

  /// Tables that failed the readiness check mapped to their error message.
  final Map<String, String> tableIssues;

  /// The configured storage bucket (if any) used for asset uploads.
  final String? storageBucket;

  /// A human readable description if the storage bucket access check failed.
  final String? storageError;

  /// A high-level error description when non-specific failures occur.
  final String? errorMessage;

  /// Convenience getter that reports whether Supabase can be used safely.
  bool get supabaseReady =>
      supabaseConfigured &&
      supabaseInitialized &&
      tableIssues.isEmpty &&
      storageError == null;

  /// Brief summary of any outstanding setup gaps, intended for logs/tests.
  String describeIssues() {
    final messages = <String>[];
    if (!envFileLoaded) {
      messages.add('Failed to load .env file.');
    }
    if (!supabaseConfigured) {
      messages.add(
        'Supabase credentials (SUPABASE_URL & SUPABASE_ANON_KEY) are missing.',
      );
    }
    if (!supabaseInitialized && supabaseConfigured) {
      messages.add(
        errorMessage ?? 'Supabase initialization failed for an unknown reason.',
      );
    }
    if (tableIssues.isNotEmpty) {
      tableIssues.forEach((table, issue) {
        messages.add('Table "$table" check failed: $issue');
      });
    }
    if (storageError != null && storageBucket != null) {
      messages.add(
        'Storage bucket "$storageBucket" check failed: $storageError',
      );
    }
    if (messages.isEmpty) {
      return 'All services ready';
    }
    return messages.join(' | ');
  }
}

bool _supabaseInitialized = false;
bool _usingSupabaseRepository = false;
String? _supabaseServiceEmail;
String? _supabaseServicePassword;
String? _supabaseStorageBucket;

/// Indicates whether the app is currently using the Supabase-backed
/// repository (i.e. Supabase was initialized successfully and all
/// readiness checks passed).
bool get supabaseRepositoryActive => _usingSupabaseRepository;

/// Email used for the shared Supabase service account when configured.
String? get supabaseServiceEmail => _supabaseServiceEmail;

/// Password used for the shared Supabase service account when configured.
String? get supabaseServicePassword => _supabaseServicePassword;

/// Name of the Supabase storage bucket configured for uploads.
String? get supabaseStorageBucket => _supabaseStorageBucket;

const List<String> _requiredTables = <String>[
  'inventory',
  'suppliers',
  'products',
  'transactions',
  'app_users',
];

/// Loads environment variables, connects to Supabase, and verifies all required
/// tables/buckets exist before handing control to the UI. When Supabase is ready
/// it swaps the application repository to [SupabaseAppRepository]; otherwise the
/// app keeps using the in-memory mock data.
Future<AppBootstrapResult> initializeBackend() async {
  final envLoaded = await _loadEnvFile();
  final supabaseUrl = dotenv.env['SUPABASE_URL']?.trim() ?? '';
  final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY']?.trim() ?? '';
  final storageBucket = dotenv.env['SUPABASE_STORAGE_BUCKET']?.trim();
  _supabaseStorageBucket = (storageBucket == null || storageBucket.isEmpty)
      ? null
      : storageBucket;
  final rawServiceEmail = dotenv.env['SUPABASE_SERVICE_EMAIL']?.trim();
  _supabaseServiceEmail = (rawServiceEmail == null || rawServiceEmail.isEmpty)
      ? null
      : rawServiceEmail;

  final rawServicePassword = dotenv.env['SUPABASE_SERVICE_PASSWORD']?.trim();
  _supabaseServicePassword =
      (rawServicePassword == null || rawServicePassword.isEmpty)
      ? null
      : rawServicePassword;

  if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
    developer.log(
      'Supabase credentials missing; continuing with mock repository.',
      name: 'AppBootstrap',
    );
    return AppBootstrapResult(
      envFileLoaded: envLoaded,
      supabaseConfigured: false,
      supabaseInitialized: false,
      tableIssues: const {},
      storageBucket: _supabaseStorageBucket,
      storageError: null,
      errorMessage:
          'Add SUPABASE_URL and SUPABASE_ANON_KEY to .env to enable Supabase.',
    );
  }

  SupabaseClient? client;
  try {
    if (!_supabaseInitialized) {
      await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
      _supabaseInitialized = true;
      developer.log('Supabase initialized successfully.', name: 'AppBootstrap');
    }
    client = Supabase.instance.client;
  } catch (error, stackTrace) {
    developer.log(
      'Supabase initialization failed: $error',
      name: 'AppBootstrap',
      error: error,
      stackTrace: stackTrace,
    );
    return AppBootstrapResult(
      envFileLoaded: envLoaded,
      supabaseConfigured: true,
      supabaseInitialized: false,
      tableIssues: const {},
      storageBucket: _supabaseStorageBucket,
      storageError: null,
      errorMessage: 'Supabase initialization failed: $error',
    );
  }

  final tableIssues = await _verifyTables(client);
  final storageError = await _verifyStorageBucket(
    client,
    _supabaseStorageBucket,
  );

  final supabaseReady = tableIssues.isEmpty && storageError == null;
  if (supabaseReady) {
    setAppRepository(SupabaseAppRepository());
    _usingSupabaseRepository = true;
  } else {
    developer.log(
      'Supabase prerequisites missing; falling back to mock data.',
      name: 'AppBootstrap',
    );
    _usingSupabaseRepository = false;
  }

  return AppBootstrapResult(
    envFileLoaded: envLoaded,
    supabaseConfigured: true,
    supabaseInitialized: true,
    tableIssues: tableIssues,
    storageBucket: _supabaseStorageBucket,
    storageError: storageError,
    errorMessage: supabaseReady
        ? null
        : 'Supabase prerequisites are incomplete.',
  );
}

Future<bool> _loadEnvFile() async {
  try {
    if (!dotenv.isInitialized) {
      await dotenv.load(fileName: '.env');
    }
    return true;
  } catch (error, stackTrace) {
    developer.log(
      'Could not load .env file: $error',
      name: 'AppBootstrap',
      error: error,
      stackTrace: stackTrace,
    );
    return false;
  }
}

Future<Map<String, String>> _verifyTables(SupabaseClient client) async {
  final issues = <String, String>{};
  for (final table in _requiredTables) {
    try {
      await client.from(table).select('id').limit(1);
    } on PostgrestException catch (error) {
      issues[table] = error.message;
    } catch (error) {
      issues[table] = error.toString();
    }
  }
  return issues;
}

Future<String?> _verifyStorageBucket(
  SupabaseClient client,
  String? storageBucket,
) async {
  if (storageBucket == null || storageBucket.isEmpty) {
    return null;
  }

  try {
    await client.storage.from(storageBucket).list();
    return null;
  } on StorageException catch (error) {
    return error.message;
  } catch (error) {
    return error.toString();
  }
}
