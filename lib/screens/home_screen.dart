import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'tap_cat.dart';
import 'tap_food.dart';
import 'login_screen.dart';
import 'dart:developer' as developer;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  final List<Tab> myTabs = const <Tab>[
    Tab(text: '고양이'),
    Tab(text: '밥'),
  ];

  String _loginStatus = '';

  @override
  void initState() {
    super.initState();
    developer.log('=== HomeScreen initState 호출됨 ===', name: 'CatApp');
    _updateLoginStatus();
  }

  Future<void> _updateLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final loginTimeString = prefs.getString('loginTime');
    final expiryDays = prefs.getInt('loginExpiryDays') ?? 7;

    if (loginTimeString != null) {
      final loginTime = DateTime.parse(loginTimeString);
      final expiryTime = loginTime.add(Duration(days: expiryDays));
      final now = DateTime.now();
      final remainingDays = expiryTime.difference(now).inDays;

      setState(() {
        if (remainingDays > 0) {
          _loginStatus = '로그인 유효기간: ${remainingDays}일 남음';
        } else {
          _loginStatus = '로그인 만료됨';
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: myTabs.length,
      child: Scaffold(
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TabBar(
                tabs: myTabs,
                indicatorColor: Colors.orange,
                labelColor: Colors.brown,
                unselectedLabelColor: Colors.grey,
                indicatorWeight: 4,
                indicatorSize: TabBarIndicatorSize.tab,
                labelStyle:
                    const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
                unselectedLabelStyle: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: _showSettings,
              tooltip: '설정',
            ),
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: _logout,
              tooltip: '로그아웃',
            ),
          ],
        ),
        body: const TabBarView(
          children: [
            CatListScreen(),
            FoodListScreen(),
          ],
        ),
      ),
    );
  }

  Future<void> _showSettings() async {
    final prefs = await SharedPreferences.getInstance();
    int currentExpiryDays = prefs.getInt('loginExpiryDays') ?? 7;

    final result = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('로그인 유효기간 설정'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('로그인 상태가 유지되는 기간을 설정하세요:'),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildExpiryOption(context, 1, '1일', currentExpiryDays),
                _buildExpiryOption(context, 7, '7일', currentExpiryDays),
                _buildExpiryOption(context, 30, '30일', currentExpiryDays),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(currentExpiryDays),
            child: const Text('저장'),
          ),
        ],
      ),
    );

    if (result != null) {
      await prefs.setInt('loginExpiryDays', result);
      await _updateLoginStatus();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('유효기간이 ${result}일로 설정되었습니다.')),
        );
      }
    }
  }

  Widget _buildExpiryOption(
      BuildContext context, int days, String label, int currentDays) {
    final isSelected = days == currentDays;
    return GestureDetector(
      onTap: () {
        Navigator.of(context).pop(days);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.orange : Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Future<void> _logout() async {
    // 로그아웃 확인 다이얼로그
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('로그아웃'),
        content: const Text('정말 로그아웃하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('로그아웃'),
          ),
        ],
      ),
    );

    if (shouldLogout == true) {
      // SharedPreferences에서 로그인 정보 삭제
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', false);
      await prefs.remove('loginTime');
      await prefs.remove('loginExpiryDays');

      // 로그인 화면으로 이동
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    }
  }
}
