import 'dart:convert';
import 'dart:io';

/// Utility for looking up Supabase-hosted asset URLs listed in
/// `build/migrated_assets.json`. This keeps mock data and other callers in sync
/// with the migration manifest without hand-editing constants.
class RemoteAssets {
  RemoteAssets._();

  static final Map<String, String> _cache = <String, String>{};

  /// Returns the public URL for a given file name (e.g. `Classic_Milk_Tea.jpg`) if
  /// it exists in the manifest, otherwise `null`.
  static String? getUrl(String fileName) {
    return _cache[fileName];
  }

  /// Provides a read-only view of the entire uploaded asset map, or `null`
  /// when the manifest is missing or could not be parsed.
  static Map<String, String> get all =>
      Map<String, String>.unmodifiable(_cache);

  /// Replaces the cache with fresh values, making the latest manifest
  /// immediately available to existing callers.
  static void replaceAll(Map<String, String> assets) {
    _cache
      ..clear()
      ..addAll(assets);
  }

  /// Adds or updates a single asset entry.
  static void put(String fileName, String publicUrl) {
    _cache[fileName] = publicUrl;
  }

  /// Deletes a cached entry.
  static void remove(String fileName) {
    _cache.remove(fileName);
  }

  /// Clears the cache entirely.
  static void clear() {
    _cache.clear();
  }

  /// Synchronously loads the manifest from disk and updates the cache. Returns
  /// `true` on success or `false` if the manifest is missing or invalid.
  static bool loadFromFile(String manifestPath) {
    try {
      final File manifestFile = File(manifestPath);
      if (!manifestFile.existsSync()) {
        return false;
      }
      final Map<String, dynamic> manifest =
          jsonDecode(manifestFile.readAsStringSync()) as Map<String, dynamic>;
      final Map<String, dynamic> uploaded = (manifest['uploaded'] as Map)
          .cast<String, dynamic>();
      replaceAll(uploaded.map((key, value) => MapEntry(key, value.toString())));
      return true;
    } catch (_) {
      return false;
    }
  }
}
