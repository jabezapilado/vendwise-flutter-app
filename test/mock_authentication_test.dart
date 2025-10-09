import 'package:flutter_test/flutter_test.dart';
import 'package:vendwise/backend/app_repository.dart';

void main() {
  group('MockAppRepository authentication', () {
    late MockAppRepository repository;

    setUp(() {
      repository = MockAppRepository();
    });

    test('allows sign-in using username', () async {
      final user = await repository.authenticate('admin', 'admin123');
      expect(user, isNotNull);
      expect(user!.username, 'admin');
    });

    test('allows sign-in using email (case-insensitive)', () async {
      final lower = await repository.authenticate(
        'admin@vendwise.com',
        'admin123',
      );
      final upper = await repository.authenticate(
        'ADMIN@VENDWISE.COM',
        'admin123',
      );

      expect(lower, isNotNull);
      expect(upper, isNotNull);
    });

    test('rejects invalid credentials', () async {
      final wrongPassword = await repository.authenticate('admin', 'nope');
      final unknownUser = await repository.authenticate('unknown', 'admin123');

      expect(wrongPassword, isNull);
      expect(unknownUser, isNull);
    });
  });
}
