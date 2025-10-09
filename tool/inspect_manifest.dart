import 'dart:convert';
import 'dart:io';

void main(List<String> args) {
  final bool asJson = args.contains('--json');
  final String? filterArgument = _extractValue(args, '--file=');
  final bool showCounts = args.contains('--counts');
  final String manifestPath =
      _extractValue(args, '--manifest=') ?? 'build/migrated_assets.json';

  final File manifestFile = File(manifestPath);
  if (!manifestFile.existsSync()) {
    stderr.writeln('Manifest not found at "$manifestPath".');
    stderr.writeln(
      'Generate it by running flutter pub run tool/migrate_assets_to_supabase.dart.',
    );
    exitCode = 1;
    return;
  }

  late final Map<String, dynamic> manifest;
  try {
    manifest =
        jsonDecode(manifestFile.readAsStringSync()) as Map<String, dynamic>;
  } catch (error) {
    stderr.writeln('Failed to parse manifest: $error');
    exitCode = 1;
    return;
  }

  final Map<String, dynamic>? uploadedRaw =
      manifest['uploaded'] as Map<String, dynamic>?;
  if (uploadedRaw == null || uploadedRaw.isEmpty) {
    stdout.writeln('Manifest "$manifestPath" contains no uploaded entries.');
    return;
  }

  final Map<String, String> uploaded = uploadedRaw.map(
    (key, value) => MapEntry(key, value.toString()),
  );

  if (filterArgument != null) {
    final String normalized = filterArgument.trim();
    final entries = uploaded.entries.where(
      (entry) => entry.key.toLowerCase() == normalized.toLowerCase(),
    );
    if (entries.isEmpty) {
      stdout.writeln('No entry found for "$normalized".');
      exitCode = 2;
      return;
    }
    for (final entry in entries) {
      stdout.writeln('${entry.key}\n  ${entry.value}\n');
    }
    return;
  }

  if (asJson) {
    stdout.writeln(jsonEncode(uploaded));
    return;
  }

  final int maxNameLength = uploaded.keys.fold<int>(0, (prev, key) {
    return key.length > prev ? key.length : prev;
  });

  stdout.writeln('Entries in $manifestPath');
  stdout.writeln('-' * (maxNameLength + 40));
  for (final entry in uploaded.entries) {
    stdout.writeln('${entry.key.padRight(maxNameLength)}  =>  ${entry.value}');
  }

  if (showCounts) {
    stdout.writeln('\nTotal objects: ${uploaded.length}');
  }
}

String? _extractValue(List<String> args, String prefix) {
  for (final arg in args) {
    if (arg.startsWith(prefix)) {
      return arg.substring(prefix.length);
    }
  }
  return null;
}
