import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:developer' as developer;
import 'utils/user_preferences.dart';

void main() {
  // 로그 레벨 설정
  developer.log('=== 앱 시작 ===', name: 'CatApp');
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '고양이 일기',
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: AppBarTheme(color: Colors.white),
      ),
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isLoading = true;
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    developer.log('=== 로그인 상태 확인 시작 ===', name: 'CatApp');
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    developer.log('현재 로그인 상태: $isLoggedIn', name: 'CatApp');

    if (isLoggedIn) {
      // 로그인 시간과 유효기간 확인
      final loginTimeString = prefs.getString('loginTime');
      final expiryDays = prefs.getInt('loginExpiryDays') ?? 7;
      developer.log('로그인 시간: $loginTimeString, 유효기간: $expiryDays일',
          name: 'CatApp');

      if (loginTimeString != null) {
        final loginTime = DateTime.parse(loginTimeString);
        final expiryTime = loginTime.add(Duration(days: expiryDays));
        final now = DateTime.now();

        // 유효기간이 지났으면 로그인 상태 해제
        if (now.isAfter(expiryTime)) {
          developer.log('로그인 유효기간 만료', name: 'CatApp');
          await prefs.setBool('isLoggedIn', false);
          await prefs.remove('loginTime');
          await prefs.remove('loginExpiryDays');

          setState(() {
            _isLoggedIn = false;
            _isLoading = false;
          });
          return;
        }
      }
    }

    setState(() {
      _isLoggedIn = isLoggedIn;
      _isLoading = false;
    });
    developer.log('최종 로그인 상태: $_isLoggedIn', name: 'CatApp');
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return _isLoggedIn ? const HomeScreen() : const LoginScreen();
  }
}
