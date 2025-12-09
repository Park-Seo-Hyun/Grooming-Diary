import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart'; // 🔹 ScreenUtil 적용
import 'home_page.dart';
import 'services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController idController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final AuthService _authService = AuthService();

  @override
  void dispose() {
    idController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void _showSuccessDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15.r),
          ),
          title: Text(
            "로그인 성공",
            style: TextStyle(
              fontFamily: 'GyeonggiTitle',
              fontWeight: FontWeight.bold,
              fontSize: 25.sp,
              color: const Color(0xFF5A9AFF),
            ),
          ),
          content: Text(
            "당신의 하루를 기록해보세요!",
            style: TextStyle(fontFamily: 'GyeonggiTitle', fontSize: 20.sp),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(
                "확인",
                style: TextStyle(
                  fontFamily: 'GyeonggiTitle',
                  fontSize: 18.sp,
                  color: const Color(0xFF5A9AFF),
                ),
              ),
              onPressed: () {
                Navigator.pop(dialogContext);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const HomePage()),
                );
              },
            ),
          ],
        );
      },
    );
  }

  void _showLoginFailDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Align(
            alignment: Alignment.bottomCenter,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 350.w),
              child: Container(
                padding: EdgeInsets.all(20.w),
                decoration: BoxDecoration(
                  color: Colors.red[100],
                  borderRadius: BorderRadius.circular(15.r),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.error_outline, size: 40.sp, color: Colors.red),
                    SizedBox(height: 10.h),
                    Text(
                      message,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                    SizedBox(height: 15.h),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(dialogContext);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                      ),
                      child: Text(
                        "확인",
                        style: TextStyle(color: Colors.white, fontSize: 16.sp),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _login() async {
    final String userId = idController.text.trim();
    final String userPwd = passwordController.text.trim();

    if (userId.isEmpty || userPwd.isEmpty) {
      _showLoginFailDialog(context, "아이디와 비밀번호를 입력해주세요.");
      return;
    }

    try {
      final loginResult = await _authService.login(
        userId: userId,
        userPwd: userPwd,
      );

      if (loginResult['success'] == true) {
        final actualName = loginResult['user_name'] ?? userId;
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_name', actualName);

        print('🔍 사용자 이름 세팅: $actualName');
        _showSuccessDialog(context);
      } else {
        _showLoginFailDialog(context, "아이디 또는 비밀번호가 잘못되었습니다.");
      }
    } catch (e) {
      _showLoginFailDialog(context, "로그인 중 오류가 발생했습니다: $e");
    }
  }

  Widget _buildTextField(
    TextEditingController controller,
    String hintText, {
    bool obscureText = false,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 30.w),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        style: TextStyle(fontSize: 20.sp, fontFamily: 'GyeonggiTitle'),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(
            fontFamily: 'GyeonggiTitle',
            fontSize: 20.sp,
            color: const Color(0xFFCFCFCF),
          ),
          enabledBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: Color(0xFFCFCFCF), width: 3.0),
          ),
          focusedBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: Color(0xFF5A9AFF), width: 3.0),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.white,
        title: SizedBox(
          height: 60.h,
          child: Image.asset(
            'assets/cloud.png',
            errorBuilder: (context, error, stackTrace) {
              return const Text(
                'Cloud',
                style: TextStyle(fontSize: 24, color: Colors.grey),
              );
            },
          ),
        ),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(5.h),
          child: Container(color: const Color(0xFFEEEEEE), height: 5.h),
        ),
        elevation: 0.0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: 50.h),
            Center(
              child: Text(
                "로그인",
                style: TextStyle(
                  fontFamily: 'Gyeonggibatang',
                  fontSize: 33.sp,
                  color: const Color(0xFF5A9AFF),
                ),
              ),
            ),
            SizedBox(height: 60.h),
            _buildTextField(idController, "아이디"),
            SizedBox(height: 15.h),
            _buildTextField(passwordController, "비밀번호", obscureText: true),
            SizedBox(height: 60.h),
            Center(
              child: SizedBox(
                height: 50.h,
                width: 275.w,
                child: ElevatedButton(
                  onPressed: _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5A9AFF),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    elevation: 5.0,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(
                    "로그인",
                    style: TextStyle(
                      fontFamily: 'GyeonggiTitle',
                      fontSize: 30.sp,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
