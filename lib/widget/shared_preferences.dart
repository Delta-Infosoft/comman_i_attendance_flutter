import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferencesService {
  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  String getString(String key) => _prefs?.getString(key) ?? '';

  Future<bool> setString(String key, String value) =>
      _prefs?.setString(key, value) ?? Future.value(false);

  // Add other methods as needed
}
