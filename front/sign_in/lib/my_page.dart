import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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
    setState(() => isLoading = true);
    try {
      // 서버 지연 대비 timeout 5초
      final data = await myPageService.fetchMyPageData().timeout(
        const Duration(seconds: 5),
      );
      setState(() {
        myPageData = data;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        myPageData = null;
        isLoading = false;
      });
      // 실패 시 안내 메시지
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('서버 연결 실패. 잠시 후 다시 시도해주세요.')));
    }
  }

  bool _isLoggingOut = false;

  Future<void> handleLogout() async {
    if (_isLoggingOut) return;
    _isLoggingOut = true;

    // 팝업 띄우기
    final dialogFuture = showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: SizedBox(
          width: 160.w,
          height: 200.h,
          child: Padding(
            padding: EdgeInsets.all(12.w),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (myPageData != null)
                  Image.asset('assets/cloud.png', width: 60.w, height: 60.h),
                SizedBox(height: 10.h),
                Text(
                  "로그아웃..",
                  style: TextStyle(
                    fontSize: 25.sp,
                    fontFamily: 'GyeonggiTitle',
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF5A9AFF),
                  ),
                ),
                SizedBox(height: 15.h),
                CircularProgressIndicator(
                  color: Color(0xFF4E93FF),
                  strokeWidth: 5.w,
                ),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      await Future.wait([
        Future.delayed(const Duration(seconds: 3)),
        myPageService.authService.logout().timeout(const Duration(seconds: 5)),
      ]);
    } catch (e) {
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop(); // 팝업 닫기
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('로그아웃 실패. 다시 시도해주세요.')));
        _isLoggingOut = false;
        return;
      }
    }

    if (mounted) {
      // 1️⃣ 팝업 먼저 닫기
      await Navigator.of(context, rootNavigator: true).maybePop();

      // 2️⃣ 안전하게 화면 이동
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const MyApp()),
          (route) => false,
        );
      });
    }

    await dialogFuture;
    _isLoggingOut = false;
  }

  bool _isDeletingAccount = false;

  Future<void> handleDeleteAccount() async {
    if (_isDeletingAccount) return; // 중복 실행 방지
    _isDeletingAccount = true;

    // 팝업 띄우기
    final dialogFuture = showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: SizedBox(
          width: 180.w,
          height: 220.h,
          child: Padding(
            padding: EdgeInsets.all(12.w),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset('assets/cloud.png', width: 60.w, height: 60.h),
                SizedBox(height: 10.h),
                Text(
                  "그동안 감사했습니다.",
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'GyeonggiTitle',
                    color: Color(0xFF297BFB),
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 5.h),
                Text(
                  "추억을 기록하고 싶은 날 다시 찾아주세요!",
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontFamily: 'GyeonggiTitle',
                    color: Color(0xFF1F74F8),
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 10.h),
                CircularProgressIndicator(
                  color: Color(0xFF4E93FF),
                  strokeWidth: 5.w,
                ),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      // 최소 3초 로딩 + 서버 요청 동시 진행
      await Future.wait([
        Future.delayed(const Duration(seconds: 3)),
        myPageService.authService.deleteAccount().timeout(
          const Duration(seconds: 5),
        ),
      ]);
    } catch (e) {
      if (mounted) {
        // 팝업 닫기
        Navigator.of(context, rootNavigator: true).pop();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('계정 삭제 실패. 다시 시도해주세요.')));
        _isDeletingAccount = false;
        return;
      }
    }

    if (mounted) {
      // 팝업 먼저 닫기
      await Navigator.of(context, rootNavigator: true).maybePop();

      // 앱 초기화 화면 이동
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const MyApp()),
          (route) => false,
        );
      });
    }

    await dialogFuture; // Dialog Future 완료까지 기다림
    _isDeletingAccount = false;
  }

  Future<void> _showDeleteAccountDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext ctx) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15.r),
        ),
        insetPadding: EdgeInsets.symmetric(horizontal: 30.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: 30.h),
            Text(
              '정말 계정을 지우실 건가요?',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Pretendard',
                fontSize: 24.sp,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F74F8),
              ),
            ),
            SizedBox(height: 5.h),
            Text(
              '모든 일기가 삭제되며, 복구할 수 없습니다.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Pretendard',
                fontSize: 13.sp,
                color: Color(0xFF1F74F8),
              ),
            ),
            SizedBox(height: 30.h),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () {
                      Navigator.of(context).pop(); // 다이얼로그만 닫기
                      handleDeleteAccount(); // 계정 삭제 진행
                    },
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(15.r),
                    ),
                    child: Container(
                      height: 56.h,
                      decoration: BoxDecoration(
                        color: Color(0xFF99BEF7),
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(15.r),
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '계정 지우기',
                        style: TextStyle(
                          color: Colors.white,
                          fontFamily: 'Pretendard',
                          fontSize: 18.sp,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: InkWell(
                    onTap: () {
                      Navigator.of(context).pop(); // 다이얼로그만 닫기
                      // 여기서 handleLogout 같은 거 호출하면 안 됨
                    },
                    borderRadius: BorderRadius.only(
                      bottomRight: Radius.circular(15.r),
                    ),
                    child: Container(
                      height: 56.h,
                      decoration: BoxDecoration(
                        color: Color(0xFF5A9AFF),
                        borderRadius: BorderRadius.only(
                          bottomRight: Radius.circular(15.r),
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '취소',
                        style: TextStyle(
                          color: Colors.white,
                          fontFamily: 'Pretendard',
                          fontSize: 18.sp,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
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
          SizedBox(height: 25.h),
          Center(
            child: Text(
              "마이 페이지",
              style: TextStyle(
                fontFamily: 'GyeonggiBatang',
                fontSize: 32.sp,
                color: Color(0xFF1A6DFF),
              ),
            ),
          ),
          SizedBox(height: 20.h),

          if (isLoading)
            Center(child: CircularProgressIndicator())
          else if (myPageData == null)
            Center(child: Text("마이페이지 데이터를 불러올 수 없습니다."))
          else ...[
            // 📦 1번 박스
            Container(
              margin: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: Color(0xFFF7FAFF),
                borderRadius: BorderRadius.circular(12.r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 5.r,
                    offset: Offset(0, 2.h),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                                    style: TextStyle(
                                      fontSize: 18.sp,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'GyeonggiTitle',
                                      color: Color(0xFF000000),
                                    ),
                                  ),
                                  TextSpan(
                                    text: "님",
                                    style: TextStyle(
                                      fontSize: 18.sp,
                                      fontFamily: 'GyeonggiTitle',
                                      color: Color(0xFF000000),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(width: 10.w),
                            Text(
                              "@${myPageData!['user_id'] ?? ''}",
                              style: TextStyle(
                                fontSize: 14.sp,
                                fontFamily: 'Pretendard',
                                color: Color(0xFF8B8585),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 10.h),
                        RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: "함께 한 지 : ",
                                style: TextStyle(
                                  fontSize: 16.sp,
                                  fontFamily: 'GyeonggiTitle',
                                  color: Color(0xFF626262),
                                ),
                              ),
                              TextSpan(
                                text: "${myPageData!['start_date'] ?? ''}일",
                                style: TextStyle(
                                  fontSize: 16.sp,
                                  fontFamily: 'GyeonggiTitle',
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF626262),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 5.h),
                        RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: "가입날짜 : ",
                                style: TextStyle(
                                  fontSize: 16.sp,
                                  fontFamily: 'GyeonggiTitle',
                                  color: Color(0xFF626262),
                                ),
                              ),
                              TextSpan(
                                text: formattedDate,
                                style: TextStyle(
                                  fontSize: 16.sp,
                                  fontFamily: 'GyeonggiTitle',
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF626262),
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

            // 📦 2번 박스
            Container(
              margin: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: Color(0xFFF7FAFF),
                borderRadius: BorderRadius.circular(12.r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 5.r,
                    offset: Offset(0, 2.h),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "나의 구르밍 점수",
                    style: TextStyle(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'GyeonggiTitle',
                    ),
                  ),
                  SizedBox(height: 20.h),
                  Center(
                    child: RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: "${myPageData!['user_emotion_score'] ?? 0} ",
                            style: TextStyle(
                              fontSize: 40.sp,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A6DFF),
                              fontFamily: 'GyeonggiTitle',
                            ),
                          ),
                          TextSpan(
                            text: "/ 100점",
                            style: TextStyle(
                              fontSize: 18.sp,
                              color: Color(0xFF1A6DFF),
                              fontFamily: 'GyeonggiTitle',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 14.h),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text:
                                  " 감정 점수는 최근 30일간 사용자가 작성한 일기 내용을 기반으로, 텍스트 분석을 통해 감정 경향을 수치화한 지표",
                              style: TextStyle(
                                fontFamily: 'Pretendard',
                                fontWeight: FontWeight.bold,
                                fontSize: 14.sp,
                                color: Color(0xFF626262),
                              ),
                            ),
                            TextSpan(
                              text:
                                  "입니다. 이 점수는 사용자가 자신의 감정 변화 흐름을 간단히 확인하고, 일상 속에서 느꼈던 감정 패턴을 되돌아보는 데 도움을 드리기 위해 제공됩니다.",
                              style: TextStyle(
                                fontSize: 14.sp,
                                fontFamily: 'Pretendard',
                                color: Color(0xFF626262),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 10.h),
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text:
                                  " 다만, 감정 점수는 AI 자연어 처리 기술을 활용하여 일기 텍스트에 나타난 표현을 분석한 결과일 뿐이며,",
                              style: TextStyle(
                                fontSize: 14.sp,
                                fontFamily: 'Pretendard',
                                color: Color(0xFF626262),
                              ),
                            ),
                            TextSpan(
                              text:
                                  " 정신건강의학과 전문 평가나 심리검사, 임상 진단 기준 등을 기반으로 산출된 값이 아닙니다. ",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14.sp,
                                fontFamily: 'Pretendard',
                                color: Color(0xFF626262),
                              ),
                            ),
                            TextSpan(
                              text:
                                  "즉, 감정 점수는 참고용이며 정확한 임상 판단 지표가 아닙니다.\n따라서 이 점수는 사용자의 실제 정신건강 상태를 판단하거나 의료적 결론을 내리기 위한 도구로 사용될 수 없으며,",
                              style: TextStyle(
                                fontSize: 14.sp,
                                color: Color(0xFF626262),
                                fontFamily: 'Pretendard',
                              ),
                            ),
                            TextSpan(
                              text: " 치료, 상담, 진단 등 의료 행위로 간주되지 않습니다.",
                              style: TextStyle(
                                fontSize: 14.sp,
                                fontFamily: 'Pretendard',
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF626262),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 10.h),
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: " 또한 감정은 개인의 환경, 상태, 상황 변화에 크게 달라질 수 있으며, ",
                              style: TextStyle(
                                fontFamily: 'Pretendard',
                                fontSize: 14.sp,
                                color: Color(0xFF626262),
                              ),
                            ),
                            TextSpan(
                              text:
                                  "일기 내용만으로는 사용자의 감정/심리 상태를 완전히 해석할 수 없다는 점을 유의해 주세요.",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Pretendard',
                                fontSize: 14.sp,
                                color: Color(0xFF626262),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        "만약 최근 감정 변화로 인해 어려움을 느끼거나 일상생활에 지장이 생긴다면, 전문 상담 센터, 정신건강복지센터 또는 의료 전문가와의 상담을 권장드립니다.",
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: Color(0xFF626262),
                          fontFamily: 'Pretendard',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // 📦 3번 박스 (로그아웃)
            GestureDetector(
              onTap: handleLogout,
              child: Container(
                margin: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: Color(0xFFF7FAFF),
                  borderRadius: BorderRadius.circular(12.r),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 5.r,
                      offset: Offset(0, 2.h),
                    ),
                  ],
                ),
                child: Text(
                  "로그아웃",
                  style: TextStyle(
                    fontFamily: 'GyeonggiTitle',
                    fontSize: 20.sp,
                    color: Color(0xFFFF6262),
                  ),
                ),
              ),
            ),

            // 📦 4번 박스 (회원 탈퇴)
            Container(
              margin: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: Color(0xFFF7FAFF),
                borderRadius: BorderRadius.circular(12.r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 5.r,
                    offset: Offset(0, 2.h),
                  ),
                ],
              ),
              child: InkWell(
                onTap: _showDeleteAccountDialog,
                child: Text(
                  "회원 탈퇴",
                  style: TextStyle(
                    fontFamily: 'GyeonggiTitle',
                    fontSize: 20.sp,
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
