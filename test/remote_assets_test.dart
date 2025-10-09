import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:vendwise/constants/remote_assets.dart';

void main() {
  group('RemoteAssets', () {
    late Directory tempDir;
    late String manifestPath;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('remote_assets_test');
      manifestPath = p.join(tempDir.path, 'manifest.json');
      RemoteAssets.clear();
    });

    tearDown(() async {
      RemoteAssets.clear();
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('loadFromFile returns false when manifest is missing', () {
      final loaded = RemoteAssets.loadFromFile(manifestPath);

      expect(loaded, isFalse);
      expect(RemoteAssets.getUrl('nonexistent.png'), isNull);
      expect(RemoteAssets.all, isEmpty);
    });

    test('loadFromFile populates cache from manifest contents', () async {
      final manifest = <String, dynamic>{
        'uploaded': <String, String>{
          'sample.png': 'https://example.com/sample.png',
          'other.jpg': 'https://example.com/other.jpg',
        },
      };
      await File(manifestPath).writeAsString(jsonEncode(manifest));

      final loaded = RemoteAssets.loadFromFile(manifestPath);

      expect(loaded, isTrue);
      expect(
        RemoteAssets.getUrl('sample.png'),
        equals('https://example.com/sample.png'),
      );
      expect(RemoteAssets.all.length, equals(2));
    });

    test('cache mutation helpers update entries as expected', () {
      RemoteAssets.replaceAll(<String, String>{
        'a.png': 'https://example.com/a.png',
      });
      RemoteAssets.put('b.jpg', 'https://example.com/b.jpg');
      RemoteAssets.remove('a.png');

      expect(RemoteAssets.getUrl('a.png'), isNull);
      expect(RemoteAssets.getUrl('b.jpg'), equals('https://example.com/b.jpg'));
      expect(RemoteAssets.all.keys, containsAll(<String>['b.jpg']));
      RemoteAssets.clear();
      expect(RemoteAssets.all, isEmpty);
    });
  });
}
