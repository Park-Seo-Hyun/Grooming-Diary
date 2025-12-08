import 'package:flutter/material.dart';
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
          backgroundColor: Color(0xFFFFFFFF),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15.0),
          ),
          title: const Text(
            "로그인 성공",
            style: TextStyle(
              fontFamily: 'GyeonggiTitle',
              fontWeight: FontWeight.bold,
              fontSize: 25,
              color: Color(0xFF5A9AFF),
            ),
          ),
          content: const Text(
            "당신의 하루를 기록해보세요!",
            style: TextStyle(fontFamily: 'GyeonggiTitle', fontSize: 20),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text(
                "확인",
                style: TextStyle(
                  fontFamily: 'GyeonggiTitle',
                  fontSize: 18,
                  color: Color(0xFF5A9AFF),
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
              constraints: const BoxConstraints(maxWidth: 350),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.red[100],
                  borderRadius: BorderRadius.circular(15),
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
                    const Icon(
                      Icons.error_outline,
                      size: 40,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      message,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                    const SizedBox(height: 15),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(dialogContext);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        "확인",
                        style: TextStyle(color: Colors.white),
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
      /// AuthService.login(user_id, user_pwd)
      final loginResult = await _authService.login(
        userId: userId,
        userPwd: userPwd,
      );

      if (loginResult['success'] == true) {
        // 서버에서 내려온 사용자 이름
        final actualName = loginResult['user_name'] ?? userId;

        // SharedPreferences에 저장
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_name', actualName);

        print('🔍 사용자 이름 세팅: $actualName'); // 디버그용
        _showSuccessDialog(context);
      } else {
        _showLoginFailDialog(context, "아이디 또는 비밀번호가 잘못되었습니다.");
      }
    } catch (e) {
      _showLoginFailDialog(context, "로그인 중 오류가 발생했습니다: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.white,
        title: SizedBox(
          height: 60,
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
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: const Color(0xFFEEEEEE), height: 5.0),
        ),
        elevation: 0.0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 50),
            const Center(
              child: Text(
                "로그인",
                style: TextStyle(
                  fontFamily: 'Gyeonggibatang',
                  fontSize: 35,
                  color: Color(0xFF5A9AFF),
                ),
              ),
            ),
            const SizedBox(height: 100),

            // 아이디 입력
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30.0),
              child: TextField(
                controller: idController,
                decoration: const InputDecoration(
                  hintText: "아이디",
                  hintStyle: TextStyle(
                    fontFamily: 'GyeonggiTitle',
                    fontSize: 20,
                    color: Color(0xFFCFCFCF),
                  ),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(
                      color: Color(0xFFCFCFCF),
                      width: 3.0,
                    ),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(
                      color: Color(0xFF5A9AFF),
                      width: 3.0,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),

            // 비밀번호 입력
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30.0),
              child: TextField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  hintText: "비밀번호",
                  hintStyle: TextStyle(
                    fontFamily: 'GyeonggiTitle',
                    fontSize: 20,
                    color: Color(0xFFCFCFCF),
                  ),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(
                      color: Color(0xFFCFCFCF),
                      width: 3.0,
                    ),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(
                      color: Color(0xFF5A9AFF),
                      width: 3.0,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 70),

            // 로그인 버튼
            Center(
              child: SizedBox(
                height: 62,
                width: 300,
                child: ElevatedButton(
                  onPressed: _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5A9AFF),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    elevation: 5.0,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text(
                    "로그인",
                    style: TextStyle(
                      fontFamily: 'GyeonggiTitle',
                      fontSize: 32,
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
