import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart'; // ✅ ScreenUtil import
import 'login_page.dart';
import 'registration_page.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // ✅ ScreenUtil 초기화는 main.dart에서 이미 했다고 가정
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: SizedBox(
          width: double.infinity,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              SizedBox(height: 180.h), // ✅ 화면 비율 기반 높이

              Image.asset(
                'assets/grooming_main.png',
                height: 150.h, // ✅ 기존 200 → 170.h로 조정
                fit: BoxFit.contain,
                alignment: Alignment.bottomCenter,
                errorBuilder: (context, error, stackTrace) {
                  return Text(
                    'Cloud Image Placeholder',
                    style: TextStyle(
                      fontSize: 24.sp,
                      color: Colors.grey,
                    ), // ✅ 글자 크기도 sp 적용
                  );
                },
              ),

              SizedBox(height: 50.h), // ✅ 버튼 위 간격
              // 🚩 로그인 버튼
              SizedBox(
                width: 150.w, // ✅ 너비 w 적용
                height: 45.h, // ✅ 높이 h 적용
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5A9AFF),
                    elevation: 5.0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.r), // ✅ 반경 r 적용
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
                  child: Text(
                    "로그인",
                    style: TextStyle(
                      fontFamily: 'GyeonggiTitle',
                      fontSize: 23.sp, // ✅ 글자 크기 sp 적용
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              SizedBox(height: 30.h), // ✅ 버튼 간 간격
              // 🚩 회원가입 버튼
              SizedBox(
                width: 150.w,
                height: 45.h,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5A9AFF),
                    elevation: 5.0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.r),
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
                  child: Text(
                    "회원가입",
                    style: TextStyle(
                      fontFamily: 'GyeonggiTitle',
                      fontSize: 23.sp,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              SizedBox(height: 20.h),
            ],
          ),
        ),
      ),
    );
  }
}
