import 'package:flutter/material.dart';
import 'login_page.dart';
import 'registration_page.dart';

// ---------------------------------------------
// 1. 앱 제목 및 이름 화면 (시작 화면)
// ---------------------------------------------
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: SizedBox(
          // Container 대신 SizedBox 사용
          width: double.infinity,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              const SizedBox(height: 200),
              Image.asset(
                'assets/grooming_main.png',
                height: 200,
                fit: BoxFit.contain,
                alignment: Alignment.bottomCenter,
                errorBuilder: (context, error, stackTrace) {
                  // 이미지가 없을 경우 대체 텍스트/위젯을 표시합니다.
                  return const Text(
                    'Cloud Image Placeholder',
                    style: TextStyle(fontSize: 24, color: Colors.grey),
                  );
                },
              ),

              const SizedBox(height: 80),

              // 🚩 1. 로그인 버튼 (순서 변경)
              SizedBox(
                width: 180,
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5A9AFF),
                    elevation: 5.0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LoginPage(),
                      ),
                    );
                  },
                  child: const Text(
                    "로그인",
                    style: TextStyle(
                      fontFamily: 'GyeonggiTitle',
                      fontSize: 26,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              // 2. 버튼 사이 간격
              const SizedBox(height: 40),

              // 🚩 3. 회원가입 버튼 (순서 변경)
              SizedBox(
                width: 180,
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5A9AFF),
                    elevation: 5.0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const RegistrationPage(),
                      ),
                    );
                  },
                  child: const Text(
                    "회원가입",
                    style: TextStyle(
                      fontFamily: 'GyeonggiTitle',
                      fontSize: 26,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
