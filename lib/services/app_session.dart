import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vendwise/models/app_user.dart';

/// Tracks the currently authenticated user so shared UI (like the navigation
/// drawer) can show personalized content.
class AppSession {
  AppSession._();

  static final AppSession instance = AppSession._();

  static const String _storageUserId = 'session_user_id';
  static const String _storageUsername = 'session_user_username';
  static const String _storageFullName = 'session_user_full_name';

  final ValueNotifier<AppUser?> currentUser = ValueNotifier<AppUser?>(null);

  /// Loads the cached profile, if any, so greetings look correct on cold
  /// launches. This does **not** perform authentication; it simply restores the
  /// last-known user details for display purposes.
  Future<void> hydrate() async {
    final prefs = await SharedPreferences.getInstance();
    final storedId = prefs.getString(_storageUserId);
    final storedUsername = prefs.getString(_storageUsername);
    if (storedId == null || storedUsername == null) {
      return;
    }

    final storedFullName = prefs.getString(_storageFullName);
    currentUser.value = AppUser(
      id: storedId,
      username: storedUsername,
      fullName: storedFullName,
      email: null,
      role: 'staff',
      isActive: true,
      createdAt: null,
      updatedAt: null,
    );
  }

  Future<void> setUser(AppUser user) async {
    currentUser.value = user;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageUserId, user.id);
    await prefs.setString(_storageUsername, user.username);
    if (user.fullName != null && user.fullName!.isNotEmpty) {
      await prefs.setString(_storageFullName, user.fullName!);
    } else {
      await prefs.remove(_storageFullName);
    }
  }

  Future<void> clearUser({bool removePersistedProfile = true}) async {
    currentUser.value = null;
    if (!removePersistedProfile) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageUserId);
    await prefs.remove(_storageUsername);
    await prefs.remove(_storageFullName);
  }

  String greeting() {
    final user = currentUser.value;
    if (user == null) {
      return 'Hello there!';
    }
    final name = (user.fullName ?? '').trim();
    if (name.isNotEmpty) {
      return 'Hello $name!';
    }
    return 'Hello ${user.username}!';
  }
}
