import 'package:shared_preferences/shared_preferences.dart';

class UserPreferences {
  static const String _userNameKey = 'user_name';
  static const String _welcomeCompletedKey = 'welcome_completed';

  // Save user name
  static Future<void> setUserName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userNameKey, name);
  }

  // Get user name
  static Future<String?> getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userNameKey);
  }

  // Set welcome completed
  static Future<void> setWelcomeCompleted(bool completed) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_welcomeCompletedKey, completed);
  }

  // Check if welcome is completed
  static Future<bool> isWelcomeCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_welcomeCompletedKey) ?? false;
  }

  // Clear all user preferences (for testing/reset)
  static Future<void> clearAllPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userNameKey);
    await prefs.remove(_welcomeCompletedKey);
  }
}