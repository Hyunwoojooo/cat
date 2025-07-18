import 'package:shared_preferences/shared_preferences.dart';

class UserPreferences {
  static const String _userIdKey = 'userId';
  static const String _isLoggedInKey = 'isLoggedIn';
  static const String _loginTimeKey = 'loginTime';
  static const String _loginExpiryDaysKey = 'loginExpiryDays';

  // 사용자 ID 저장
  static Future<void> saveUserId(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userIdKey, userId);
  }

  // 사용자 ID 가져오기
  static Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userIdKey);
  }

  // 로그인 상태 저장
  static Future<void> setLoggedIn(bool isLoggedIn) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isLoggedInKey, isLoggedIn);
  }

  // 로그인 상태 확인
  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isLoggedInKey) ?? false;
  }

  // 로그인 시간 저장
  static Future<void> saveLoginTime(String loginTime) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_loginTimeKey, loginTime);
  }

  // 로그인 시간 가져오기
  static Future<String?> getLoginTime() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_loginTimeKey);
  }

  // 로그인 유효기간 저장
  static Future<void> saveLoginExpiryDays(int days) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_loginExpiryDaysKey, days);
  }

  // 로그인 유효기간 가져오기
  static Future<int> getLoginExpiryDays() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_loginExpiryDaysKey) ?? 7;
  }

  // 모든 사용자 데이터 삭제 (로그아웃 시)
  static Future<void> clearUserData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userIdKey);
    await prefs.remove(_isLoggedInKey);
    await prefs.remove(_loginTimeKey);
    await prefs.remove(_loginExpiryDaysKey);
  }
}
