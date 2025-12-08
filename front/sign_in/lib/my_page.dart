import 'package:flutter/material.dart';
import 'package:sign_in/main.dart';
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
    // 팝업 띄우기
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: SizedBox(
            width: 160,
            height: 200,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (myPageData != null)
                    Image.asset('assets/cloud.png', width: 60, height: 60),
                  const SizedBox(height: 10),
                  const Text(
                    "로그아웃..",
                    style: TextStyle(
                      fontSize: 25,
                      fontFamily: 'GyeonggiTitle',
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF5A9AFF),
                    ),
                  ),
                  const SizedBox(height: 15),
                  const CircularProgressIndicator(
                    color: Color(0xFF4E93FF),
                    strokeWidth: 5,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    // 2초 동안 팝업 유지
    await Future.delayed(const Duration(seconds: 2));

    // 실제 로그아웃
    await myPageService.authService.logout();

    // 🔥 팝업 닫기
    if (mounted) Navigator.of(context).pop();

    // 🔥 팝업 닫힌 후 다음 프레임에 화면 이동 실행
    //
    //   WidgetsBinding.instance.addPostFrameCallback
    //
    // 이걸 쓰면 팝업 닫히는 애니메이션이 완전히 끝난 다음에
    // 화면 이동이 실행되어 절대 팝업이 남지 않는다!
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const MyApp()),
        (route) => false,
      );
    });
  }

  Future<void> handleDeleteAccount() async {
    // 로딩 팝업 띄우기
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: SizedBox(
            width: 180,
            height: 220,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset('assets/cloud.png', width: 60, height: 60),
                  const SizedBox(height: 10),
                  const Text(
                    "그동안 감사했습니다.",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'GyeonggiTitle',
                      color: Color(0xFF297BFB),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    "추억을 기록하고 싶은 날 다시 찾아주세요!",
                    style: TextStyle(
                      fontSize: 14,
                      fontFamily: 'GyeonggiTitle',
                      color: Color(0xFF1F74F8),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  const CircularProgressIndicator(
                    color: Color(0xFF4E93FF),
                    strokeWidth: 5,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    // 2초 후 화면 즉시 이동
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    Navigator.of(context).pop(); // 로딩 팝업 닫기

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const MyApp()),
      (route) => false,
    );

    // API는 뒤에서 처리
    myPageService.authService.deleteAccount();
  }

  Future<void> _showDeleteAccountDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext ctx) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          insetPadding: const EdgeInsets.symmetric(horizontal: 30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 30),

              const Text(
                '정말 계정을 지우실 건가요?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Pretendard',
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F74F8),
                ),
              ),

              const SizedBox(height: 5),

              const Text(
                '모든 일기가 삭제되며, 복구할 수 없습니다.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Pretendard',
                  fontSize: 13,
                  color: Color(0xFF1F74F8),
                ),
              ),

              const SizedBox(height: 30),

              Row(
                children: [
                  // ---------------------------
                  // (왼쪽) 계정 지우기 버튼 — 연한 색
                  // ---------------------------
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        Navigator.of(context).pop(); // 다이얼로그 닫기
                        handleDeleteAccount(); // 실제 탈퇴 + 로딩창
                      },
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(15),
                      ),
                      child: Container(
                        height: 56,
                        decoration: const BoxDecoration(
                          color: Color(0xFF99BEF7), // 연한 파랑
                          borderRadius: BorderRadius.only(
                            bottomLeft: Radius.circular(15),
                          ),
                        ),
                        alignment: Alignment.center,
                        child: const Text(
                          '계정 지우기',
                          style: TextStyle(
                            color: Colors.white,
                            fontFamily: 'Pretendard',
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // ---------------------------
                  // (오른쪽) 취소 버튼 — 진한 색
                  // ---------------------------
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        Navigator.of(context).pop(); // 닫기만
                      },
                      borderRadius: const BorderRadius.only(
                        bottomRight: Radius.circular(15),
                      ),
                      child: Container(
                        height: 56,
                        decoration: const BoxDecoration(
                          color: Color(0xFF5A9AFF), // 진한 파랑
                          borderRadius: BorderRadius.only(
                            bottomRight: Radius.circular(15),
                          ),
                        ),
                        alignment: Alignment.center,
                        child: const Text(
                          '취소',
                          style: TextStyle(
                            color: Colors.white,
                            fontFamily: 'Pretendard',
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final rawDate = myPageData?['created_at'];
    final createdAtString = rawDate is String ? rawDate : '';
    final formattedDate = createdAtString.replaceAll('-', '.');

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 25),
          const Center(
            child: Text(
              "마이 페이지",
              style: TextStyle(
                fontFamily: 'GyeonggiBatang',
                fontSize: 32,
                color: Color(0xFF1A6DFF),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // ==========================
          //  로딩 & 데이터 처리
          // ==========================
          if (isLoading)
            const Center(child: CircularProgressIndicator())
          else if (myPageData == null)
            const Center(child: Text("마이페이지 데이터를 불러올 수 없습니다."))
          else ...[
            // ==========================
            // 📦 1번 박스 : 사용자 정보
            // ==========================
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF7FAFF),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 이름 + 아이디
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            RichText(
                              text: TextSpan(
                                children: [
                                  TextSpan(
                                    text: myPageData!['user_name'] ?? '',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'GyeonggiTitle',
                                      color: Color(0xFF000000),
                                    ),
                                  ),
                                  const TextSpan(
                                    text: "님",
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontFamily: 'GyeonggiTitle',
                                      color: Color(0xFF000000),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(width: 10),

                            Text(
                              "@${myPageData!['user_id'] ?? ''}",
                              style: const TextStyle(
                                fontSize: 14,
                                fontFamily: 'Pretendard',
                                color: Color(0xFF8B8585),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 10),

                        // ⭐ 함께한지 (라벨만 bold)
                        RichText(
                          text: TextSpan(
                            children: [
                              const TextSpan(
                                text: "함께 한 지 : ",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontFamily: 'GyeonggiTitle',
                                  color: Color(0xFF626262),
                                ),
                              ),
                              TextSpan(
                                text: "${myPageData!['start_date'] ?? ''}일",
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontFamily: 'GyeonggiTitle',
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF626262),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 5),

                        // ⭐ 가입날짜 (라벨만 bold)
                        RichText(
                          text: TextSpan(
                            children: [
                              const TextSpan(
                                text: "가입날짜 : ",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontFamily: 'GyeonggiTitle',
                                  color: Color(0xFF626262),
                                ),
                              ),
                              TextSpan(
                                text: formattedDate,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontFamily: 'GyeonggiTitle',
                                  color: Color(0xFF626262),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ==========================
            // 📦 2번 박스 : 구르밍 점수
            // ==========================
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF7FAFF),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 제목
                  const Text(
                    "나의 구르밍 점수",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'GyeonggiTitle',
                    ),
                  ),

                  const SizedBox(height: 20),

                  // 감정점수 / 100
                  Center(
                    child: RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: "${myPageData!['user_emotion_score'] ?? 0} ",
                            style: const TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A6DFF),
                              fontFamily: 'GyeonggiTitle',
                            ),
                          ),
                          TextSpan(
                            text: "/ 100점",
                            style: const TextStyle(
                              fontSize: 18,
                              color: Color(0xFF1A6DFF),
                              fontFamily: 'GyeonggiTitle',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // 사용자 글쓰기 공간처럼 보이는 박스
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 🔹 문단 1
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text:
                                  " 감정 점수는 최근 30일간 사용자가 작성한 일기 내용을 기반으로, 텍스트 분석을 통해 감정 경향을 수치화한 지표",
                              style: TextStyle(
                                fontFamily: 'Pretendard',
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: Color(0xFF626262),
                              ),
                            ),
                            TextSpan(
                              text:
                                  "입니다. 이 점수는 사용자가 자신의 감정 변화 흐름을 간단히 확인하고, 일상 속에서 느꼈던 감정 패턴을 되돌아보는 데 도움을 드리기 위해 제공됩니다.",
                              style: TextStyle(
                                fontSize: 14,
                                fontFamily: 'Pretendard',
                                color: Color(0xFF626262),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 10),

                      // 🔹 문단 2
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text:
                                  " 다만, 감정 점수는 AI 자연어 처리 기술을 활용하여 일기 텍스트에 나타난 표현을 분석한 결과일 뿐이며,",
                              style: TextStyle(
                                fontSize: 14,
                                fontFamily: 'Pretendard',
                                color: Color(0xFF626262),
                              ),
                            ),
                            TextSpan(
                              text:
                                  " 정신건강의학과 전문 평가나 심리검사, 임상 진단 기준 등을 기반으로 산출된 값이 아닙니다. ",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                fontFamily: 'Pretendard',
                                color: Color(0xFF626262),
                              ),
                            ),
                            TextSpan(
                              text:
                                  "즉, 감정 점수는 참고용이며 정확한 임상 판단 지표가 아닙니다.\n따라서 이 점수는 사용자의 실제 정신건강 상태를 판단하거나 의료적 결론을 내리기 위한 도구로 사용될 수 없으며,",
                              style: TextStyle(
                                fontSize: 14,
                                color: Color(0xFF626262),
                                fontFamily: 'Pretendard',
                              ),
                            ),
                            TextSpan(
                              text: " 치료, 상담, 진단 등 의료 행위로 간주되지 않습니다.",
                              style: TextStyle(
                                fontSize: 14,
                                fontFamily: 'Pretendard',
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF626262),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 10),

                      // 🔹 문단 4
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: " 또한 감정은 개인의 환경, 상태, 상황 변화에 크게 달라질 수 있으며, ",
                              style: TextStyle(
                                fontFamily: 'Pretendard',
                                fontSize: 14,
                                color: Color(0xFF626262),
                              ),
                            ),
                            TextSpan(
                              text:
                                  "일기 내용만으로는 사용자의 감정/심리 상태를 완전히 해석할 수 없다는 점을 유의해 주세요.",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Pretendard',
                                fontSize: 14,
                                color: Color(0xFF626262),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // 🔹 문단 5 (일반체)
                      Text(
                        "만약 최근 감정 변화로 인해 어려움을 느끼거나 일상생활에 지장이 생긴다면, 전문 상담 센터, 정신건강복지센터 또는 의료 전문가와의 상담을 권장드립니다.",
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF626262),
                          fontFamily: 'Pretendard',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ==========================
            // 📦 3번 박스 : 로그아웃
            // ==========================
            GestureDetector(
              onTap: handleLogout, // 🔹 여기가 핵심
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7FAFF),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                // 글자도 가운데 정렬
                child: Text(
                  "로그아웃",
                  style: TextStyle(
                    fontFamily: 'GyeonggiTitle',
                    fontSize: 20,
                    color: Color(0xFFFF6262),
                  ),
                ),
              ),
            ),

            // ==========================
            // 📦 4번 박스 : 회원 탈퇴
            // ==========================
            // 1️⃣ 회원탈퇴 버튼 눌렀을 때
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF7FAFF),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: InkWell(
                onTap: () {
                  _showDeleteAccountDialog(); // 2️⃣ 확인 팝업 호출
                },
                child: const Text(
                  "회원 탈퇴",
                  style: TextStyle(
                    fontFamily: 'GyeonggiTitle',
                    fontSize: 20,
                    color: Color(0xFF626262),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
