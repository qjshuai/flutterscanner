import 'dart:convert';
import 'environment.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:quiver/strings.dart';

class EnvironmentRepository {
  static const _storeKey = 'com.repository.environment';

  Future<Environment> restoreEnvironment() async {
    try {
      final preference = await SharedPreferences.getInstance();
      final environmentString = preference.getString(_storeKey);
      if (isEmpty(environmentString)) {
        _clearEnvironment();
        return null;
      }
      final json = JsonDecoder().convert(environmentString) as Map<String, dynamic>;
      return Environment.fromJson(json);
    } catch (e) {
      _clearEnvironment();
      return null;
    }
  }

  void _clearEnvironment() async {
    final preference = await SharedPreferences.getInstance();
    await preference.remove(_storeKey);
  }

  Future<bool> saveEnvironment(Environment env) async {
    final json = env.toJson();
    final environmentString = JsonEncoder().convert(json);
    final preference = await SharedPreferences.getInstance();
    return preference.setString(_storeKey, environmentString);
  }
}
