import 'package:flutter/material.dart';
import 'services/mypage_service.dart';
import 'services/auth_service.dart';

class MyPage extends StatefulWidget {
  const MyPage({super.key});

  @override
  State<MyPage> createState() => _MyPageState();
}

class _MyPageState extends State<MyPage> {
  late final MyPageService myPageService;
  Map<String, dynamic>? myPageData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    final authService = AuthService();
    myPageService = MyPageService(authService: authService);
    fetchData();
  }

  Future<void> fetchData() async {
    setState(() {
      isLoading = true;
    });
    final data = await myPageService.fetchMyPageData();
    setState(() {
      myPageData = data;
      isLoading = false;
    });
  }

  Future<void> handleLogout() async {
    await myPageService.authService.logout();

    if (mounted) {
      // 팝업 대신 SnackBar 사용 가능
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('로그아웃 되었습니다.')));

      // 1초 정도 기다렸다가 화면 전환
      await Future.delayed(const Duration(seconds: 1));

      // 메인 화면으로 이동, 이전 화면 모두 제거
      Navigator.of(context).pushNamedAndRemoveUntil(
        '/main', // 메인 화면 라우트 이름으로 변경
        (route) => false,
      );
    }
  }

  Future<void> handleDeleteAccount() async {
    final success = await myPageService.authService.deleteAccount();
    if (success) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('회원 탈퇴 성공')));

        await Future.delayed(const Duration(seconds: 1));

        // 회원 탈퇴 후 화면 이동
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/main', // 로그인 화면 또는 메인 화면
          (route) => false,
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('회원 탈퇴 실패')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 25), // 기존 디자인 그대로
        const Center(
          child: Text(
            "마이 페이지",
            style: TextStyle(
              fontFamily: 'Gyeonggibatang',
              fontSize: 32,
              color: Color(0xFF1A6DFF),
            ),
          ),
        ),
        const SizedBox(height: 10),

        // 🔄 마이페이지 데이터 표시
        if (isLoading)
          const Center(child: CircularProgressIndicator())
        else if (myPageData != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('사용자 이름: ${myPageData!['user_name'] ?? ''}'),
                Text('사용자 ID: ${myPageData!['user_id'] ?? ''}'),
                Text('가입일: ${myPageData!['created_at'] ?? ''}'),
                Text('시작 날짜: ${myPageData!['start_date'] ?? 0}'),
                Text('감정 점수: ${myPageData!['user_emotion_score'] ?? 0}'),
              ],
            ),
          )
        else
          const Center(child: Text('마이페이지 데이터를 불러올 수 없습니다.')),

        const SizedBox(height: 20),

        // 🔐 버튼
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              ElevatedButton(
                onPressed: handleLogout,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A6DFF),
                  minimumSize: const Size.fromHeight(50),
                ),
                child: const Text('로그아웃', style: TextStyle(fontSize: 18)),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: handleDeleteAccount,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  minimumSize: const Size.fromHeight(50),
                ),
                child: const Text('회원 탈퇴', style: TextStyle(fontSize: 18)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
