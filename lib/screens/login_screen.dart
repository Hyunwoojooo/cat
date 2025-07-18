import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import 'home_screen.dart';
import '../utils/user_preferences.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _dio = Dio();

  bool _isLoading = false;
  bool _isError = false;
  String _errorMessage = '';

  // API 설정
  static const String _loginEndpoint = 'http://catlove.o-r.kr:4000/api/user/id';
//
  @override
  void initState() {
    super.initState();
    _setupDio();
  }

  void _setupDio() {
    _dio.options.validateStatus =
        (status) => status != null && status >= 200 && status < 500;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    print('Login button pressed');
    setState(() {
      _isLoading = true;
      _isError = false;
      _errorMessage = '';
    });
    print('isLoading: $_isLoading');
    try {
      print('try');
      print("loginEndpoint: $_loginEndpoint");
      // 요청 헤더 설정
      _dio.options.headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      final response = await _dio.post(
        '$_loginEndpoint',
        data: {
          'id': _emailController.text,
          'password': _passwordController.text,
        },
      );

      print('Response1234: ${response.data}');
      print('Response1234: ${response.statusCode}');
      if (response.statusCode == 200) {
        print('Response: ${response.data}');
        print("성고오오옹");
        await _handleSuccessfulLogin(response);
      } else {
        _handleLoginError(response);
      }
    } catch (e) {
      _handleException(e);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleSuccessfulLogin(Response response) async {
    final now = DateTime.now();

    // 서버에서 받은 id 저장
    final userId = response.data['id'];
    if (userId != null) {
      await UserPreferences.saveUserId(userId);
      print('사용자 ID 저장됨: $userId');
    }

    // 로그인 시간과 유효기간(7일) 저장
    await UserPreferences.setLoggedIn(true);
    await UserPreferences.saveLoginTime(now.toIso8601String());
    await UserPreferences.saveLoginExpiryDays(7); // 7일 유효기간

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    }
  }

  void _handleLoginError(Response response) {
    setState(() {
      _isError = true;
      _errorMessage = response.data['message'] ?? '로그인에 실패했습니다.';
    });
  }

  // 저장된 사용자 ID를 가져오는 함수
  static Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('userId');
  }

  void _handleException(dynamic error) {
    setState(() {
      _isError = true;
      if (error is DioException) {
        switch (error.type) {
          case DioExceptionType.connectionTimeout:
            _errorMessage = '서버 연결 시간이 초과되었습니다.';
            break;
          case DioExceptionType.connectionError:
            _errorMessage = '서버에 연결할 수 없습니다. 서버가 실행 중인지 확인해주세요.';
            break;
          case DioExceptionType.receiveTimeout:
            _errorMessage = '서버 응답 시간이 초과되었습니다.';
            break;
          default:
            _errorMessage = '서버 연결에 실패했습니다.';
        }
      } else {
        _errorMessage = '알 수 없는 오류가 발생했습니다.';
      }
    });
    print('Login error: $error');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildTitle(),
                const SizedBox(height: 48),
                _buildEmailField(),
                const SizedBox(height: 16),
                _buildPasswordField(),
                if (_isError) _buildErrorMessage(),
                const SizedBox(height: 24),
                _buildLoginButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTitle() {
    return const Text(
      '고양이 일기',
      style: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.bold,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildEmailField() {
    return TextFormField(
      controller: _emailController,
      decoration: const InputDecoration(
        labelText: '이메일',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.email),
      ),
      keyboardType: TextInputType.emailAddress,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return '이메일을 입력해주세요';
        }
        return null;
      },
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      controller: _passwordController,
      decoration: const InputDecoration(
        labelText: '비밀번호',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.lock),
      ),
      obscureText: true,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return '비밀번호를 입력해주세요';
        }
        return null;
      },
    );
  }

  Widget _buildErrorMessage() {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Text(
        _errorMessage,
        style: const TextStyle(
          color: Colors.red,
          fontSize: 14,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildLoginButton() {
    return ElevatedButton(
      onPressed: _isLoading ? null : _login,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: _isLoading
          ? const CircularProgressIndicator()
          : const Text(
              '로그인',
              style: TextStyle(fontSize: 18),
            ),
    );
  }
}
