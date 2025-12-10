import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'diary/diary_entry.dart';
import 'diary/diary_page.dart';
import 'diary/diary_detail_page.dart';
import 'graph/graph_page.dart';
import 'write_page.dart';
import 'my_page.dart';
import 'navbar.dart';
import 'services/diary_service.dart';
import 'package:cached_network_image/cached_network_image.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<DiaryEntry> diaries = [];
  DateTime _focusedDay = DateTime.now();
  int _selectedIndex = 0;

  final Map<DateTime, DiaryEntry> diaryEntries = {};
  num userEmotionScore = 0;
  final DiaryService _diaryService = DiaryService();

  String userName = '사용자'; // 실제로 로그인 시 가져온 이름을 여기에 저장

  @override
  void initState() {
    super.initState();
    _loadUserName();
    _loadMonthlyDiaries();
  }

  Future<void> _loadUserName() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? savedName = prefs.getString('user_name');
    if (savedName != null) {
      setState(() {
        userName = savedName;
        print("🔍 로컬에서 불러온 사용자 이름: $userName");
      });
    }
  }

  DateTime get _firstDayOfMonth =>
      DateTime(_focusedDay.year, _focusedDay.month, 1);
  DateTime get _lastDayOfMonth =>
      DateTime(_focusedDay.year, _focusedDay.month + 1, 0);

  DateTime get _firstDisplayDay {
    int weekday = _firstDayOfMonth.weekday % 7;
    return _firstDayOfMonth.subtract(Duration(days: weekday));
  }

  DateTime get _lastDisplayDay {
    int weekday = _lastDayOfMonth.weekday % 7;
    return _lastDayOfMonth.add(Duration(days: 6 - weekday));
  }

  Future<void> _loadMonthlyDiaries() async {
    String monthlyYear = DateFormat('yyyy-MM').format(_focusedDay);
    print("🔍 월별 일기 요청: $monthlyYear");

    try {
      final response = await _diaryService.getMonthlyDiaries(monthlyYear);

      if (!mounted) return;

      print("서버 응답: $response");

      setState(() {
        diaryEntries.clear();
        userEmotionScore = response['user_emotion_score'] is num
            ? response['user_emotion_score']
            : 0;

        print("🔍 사용자 이름 세팅: $userName, 감정 점수: $userEmotionScore");

        if (userEmotionScore < 55) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _showLowScorePopup();
          });
        }

        final List<dynamic> diariesList =
            (response['diaries'] as List<dynamic>?) ?? [];

        for (var item in diariesList) {
          try {
            final diaryEntry = DiaryEntry.fromJson(item); // URL 사용
            DateTime dateKey = DateTime(
              diaryEntry.date.year,
              diaryEntry.date.month,
              diaryEntry.date.day,
            );
            diaryEntries[dateKey] = diaryEntry;
          } catch (e) {
            print("❌ 일기 개별 파싱 오류: $e");
          }
        }
      });
    } catch (e) {
      print("❌ 월별 일기 로드 실패 상세: $e");
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('데이터 로드 중 오류: $e')));
    }
  }

  Future<void> _onDayTapped(DateTime day) async {
    DateTime normalizedDay = DateTime(day.year, day.month, day.day);
    final entry = diaryEntries[normalizedDay];

    if (entry != null) {
      // 기존 일기 상세 페이지로 이동
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => DiaryDetailPage(
            diaryId: entry.id,
            onDelete: () async {
              await _loadMonthlyDiaries(); // 삭제 즉시 반영
            },
            onUpdate: (updatedEntry) async {
              await _loadMonthlyDiaries(); // 수정 즉시 반영
            },
            // 기존 일기를 열 때는 isNewWrite를 전달할 필요가 없습니다. (기본값 false 사용)
          ),
        ),
      );

      // 🔥🔥🔥 상세 페이지에서 pop(true) 받은 경우 즉시 갱신
      if (result == true) {
        await _loadMonthlyDiaries();
      }
    } else {
      // 새 일기 작성
      final result = await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => DiaryPage(selectedDate: day)),
      );

      // 🔥 [수정] 새 일기 저장 후 즉시 갱신!
      // DiaryPage에서 pushReplacement -> DiaryDetailPage로 이동한 후,
      // DiaryDetailPage에서 뒤로가기 시 `true`를 반환하도록 로직을 변경했으므로,
      // 여기서 `result == true`를 확인하면 됩니다.
      if (result == true) {
        await _loadMonthlyDiaries();
      }
    }
  }

  Future<void> _showLowScorePopup() async {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: SizedBox(
            height: 60.h,
            child: Image.asset(
              'assets/cloud.png',
              color: Color(0xFFF44FBD),
              colorBlendMode: BlendMode.srcIn,
            ),
          ),
          content: Text(
            '오늘도 $userName님의 추엇을 남기러 와주어서 고마워요.\n\n'
            '요즘 마음이 많이 지쳐있으신 거 같아요.\n'
            '이러한 감정 점수는 잘못된 것이 아닌 그만큼 마음이 지쳐있다는 작은 신호일 뿐이에요.\n\n'
            '혹시 계속 힘든 감정이 이어진다면,\n전문가와 잠시 이야기 나누는 것도 도움이 될 수 있어요.\n\n'
            '누군가에게 기대는 건 약함이 아니라, 지친 마음을 돌보는 아주 자연스러운 선택이에요.\n\n'
            '당신의 마음이 조금이라도 더 편해지길 바랄게요.',
            style: TextStyle(
              color: Color(0xFFF44FBD),
              fontFamily: 'GyeonggiTitle',
              fontSize: 16.sp,
            ),
          ),
          actionsPadding: EdgeInsets.zero,
          actions: [
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () {
                      Navigator.of(context).pop();
                    },
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(15),
                    ),
                    child: Container(
                      height: 56.h,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFFC9F1),
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(15),
                        ),
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        '닫기',
                        style: TextStyle(
                          color: Colors.white,
                          fontFamily: 'Pretendard',
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: InkWell(
                    onTap: () {
                      Navigator.of(context).pop();
                      _onItemTapped(1);
                    },
                    borderRadius: const BorderRadius.only(
                      bottomRight: Radius.circular(15),
                    ),
                    child: Container(
                      height: 56.h,
                      decoration: const BoxDecoration(
                        color: Color(0xFFF79CDF),
                        borderRadius: BorderRadius.only(
                          bottomRight: Radius.circular(15),
                        ),
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        '그래프 보러 가기',
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
        );
      },
    );
  }

  void _onItemTapped(int index) => setState(() => _selectedIndex = index);

  void _showYearMonthPicker() async {
    int selectedYear = _focusedDay.year;
    int selectedMonth = _focusedDay.month;

    final result = await showDialog<Map<String, int>>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              title: const Center(
                child: Text(
                  '년 / 월 선택',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Pretendard',
                    color: Color(0xFF5675DC),
                  ),
                ),
              ),
              content: SizedBox(
                height: 80.h,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    DropdownButton<int>(
                      value: selectedYear,
                      iconEnabledColor: const Color(0xFF5675DC),
                      items:
                          List.generate(50, (i) => DateTime.now().year - 25 + i)
                              .map(
                                (year) => DropdownMenuItem(
                                  value: year,
                                  child: Text(
                                    "$year년",
                                    style: TextStyle(
                                      fontSize: 18.sp,
                                      fontFamily: 'GyeonggiTitle',
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                      onChanged: (year) {
                        if (year != null)
                          setDialogState(() => selectedYear = year);
                      },
                    ),
                    SizedBox(width: 30.w),
                    DropdownButton<int>(
                      value: selectedMonth,
                      iconEnabledColor: const Color(0xFF5A9AFF),
                      items: List.generate(12, (i) => i + 1)
                          .map(
                            (month) => DropdownMenuItem(
                              value: month,
                              child: Text(
                                "$month월",
                                style: TextStyle(
                                  fontSize: 18.sp,
                                  fontFamily: 'GyeonggiTitle',
                                ),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (month) {
                        if (month != null)
                          setDialogState(() => selectedMonth = month);
                      },
                    ),
                  ],
                ),
              ),
              actionsAlignment: MainAxisAlignment.center,
              actions: [
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF5A9AFF),
                  ),
                  child: const Text(
                    '취소',
                    style: TextStyle(fontSize: 18, color: Color(0xFF5675DC)),
                  ),
                ),
                SizedBox(width: 10.w),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, {
                    'year': selectedYear,
                    'month': selectedMonth,
                  }),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5675DC),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('확인', style: TextStyle(fontSize: 18)),
                ),
              ],
            );
          },
        );
      },
    );

    if (result != null) {
      setState(() {
        _focusedDay = DateTime(result['year']!, result['month']!, 1);
        _loadMonthlyDiaries();
      });
    }
  }

  Widget _buildEmojiWidget(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return Icon(Icons.mood, size: 40.sp, color: Colors.grey);
    }

    // 서버 URL이 상대 경로일 경우를 대비해 처리 필요
    String fullUrl = imageUrl.startsWith('http')
        ? imageUrl
        : "${_diaryService.baseUrl}$imageUrl";

    return CachedNetworkImage(
      imageUrl: fullUrl,
      width: 40.w,
      height: 40.h,
      fit: BoxFit.contain,
      placeholder: (context, url) => SizedBox(
        width: 20.w,
        height: 20.h,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
      errorWidget: (context, url, error) {
        print("❌ Emoji load error: $error, URL: $url");
        return Image.network(
          fullUrl, // 안전하게 fallback
          width: 40.w,
          height: 40.h,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) =>
              Icon(Icons.mood_bad, size: 40.sp, color: Colors.grey),
        );
      },
      // 캐시 강제 설정
      memCacheHeight: 100,
      memCacheWidth: 100,
    );
  }

  @override
  Widget build(BuildContext context) {
    ScreenUtil.init(context, designSize: const Size(390, 844));

    const primaryColor = Color(0xFF5A9AFF);
    const lineColor = Color(0xFFCFCFCF);

    List<DateTime> days = [];
    for (
      DateTime day = _firstDisplayDay;
      !day.isAfter(_lastDisplayDay);
      day = day.add(const Duration(days: 1))
    ) {
      days.add(day);
    }

    final String currentYearMonth = DateFormat('yyyy-MM').format(_focusedDay);

    List<Widget> pages = [
      SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(height: 10.h),
            Stack(
              children: [
                Row(
                  children: [
                    Padding(
                      padding: EdgeInsets.only(left: 10.w),
                      child: IconButton(
                        icon: Icon(
                          Icons.calendar_month,
                          color: Color(0xFF5675DC),
                          size: 35.sp,
                        ),
                        onPressed: _showYearMonthPicker,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      DateFormat('yyyy').format(_focusedDay),
                      style: TextStyle(
                        fontFamily: 'PretendardBold',
                        fontSize: 25.sp,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF5675DC),
                      ),
                    ),
                    const Spacer(),
                    SizedBox(width: 60.w),
                  ],
                ),
                Positioned(
                  right: 20.w,
                  top: 50.h,
                  child: Text(
                    '구르밍 점수: $userEmotionScore 점',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontFamily: 'GyeonggiBatang',
                      color: Color(0xFF3A3939),
                    ),
                  ),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: Icon(
                    Icons.arrow_left,
                    size: 40.sp,
                    color: Color(0xFF5675DC),
                  ),
                  onPressed: () => setState(() {
                    _focusedDay = DateTime(
                      _focusedDay.year,
                      _focusedDay.month - 1,
                    );
                    _loadMonthlyDiaries();
                  }),
                ),
                SizedBox(width: 40.w),
                Text(
                  DateFormat('MM').format(_focusedDay),
                  style: TextStyle(
                    fontFamily: 'PretendardRegular',
                    fontSize: 33.sp,
                    color: Color(0xFF5675DC),
                  ),
                ),
                SizedBox(width: 40.w),
                IconButton(
                  icon: Icon(
                    Icons.arrow_right,
                    size: 40.sp,
                    color: Color(0xFF5675DC),
                  ),
                  onPressed: () => setState(() {
                    _focusedDay = DateTime(
                      _focusedDay.year,
                      _focusedDay.month + 1,
                    );
                    _loadMonthlyDiaries();
                  }),
                ),
              ],
            ),
            Text(
              DateFormat('MMMM').format(_focusedDay),
              style: TextStyle(
                fontFamily: 'PretendardRegular',
                fontSize: 15.sp,
                color: Color(0xFF5675DC),
              ),
            ),
            SizedBox(height: 25.h),
            Container(
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: lineColor, width: 1.w),
                  bottom: BorderSide(color: lineColor, width: 1.w),
                ),
              ),
              child: Row(
                children: List.generate(7, (index) {
                  final daysOfWeek = [
                    'Sun',
                    'Mon',
                    'Tue',
                    'Wed',
                    'Thu',
                    'Fri',
                    'Sat',
                  ];
                  final d = daysOfWeek[index];
                  return Expanded(
                    child: Row(
                      children: [
                        Expanded(
                          child: Center(
                            child: Text(
                              d,
                              style: TextStyle(
                                fontFamily: 'PretendardBold',
                                fontSize: 13.sp,
                                color: d == 'Sun'
                                    ? Colors.redAccent
                                    : d == 'Sat'
                                    ? primaryColor
                                    : Color(0xFF827C7C),
                              ),
                            ),
                          ),
                        ),
                        if (index != 6)
                          Container(width: 1.w, height: 25.h, color: lineColor),
                      ],
                    ),
                  );
                }),
              ),
            ),
            Column(
              children: <Widget>[
                GridView.builder(
                  physics: NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    childAspectRatio: 0.75,
                  ),
                  itemCount: days.length,
                  itemBuilder: (context, index) {
                    final day = days[index];
                    bool isCurrentMonth = day.month == _focusedDay.month;
                    bool isFutureDay = day.isAfter(DateTime.now());
                    DateTime normalizedDay = DateTime(
                      day.year,
                      day.month,
                      day.day,
                    );
                    final currentEntry = diaryEntries[normalizedDay];

                    return GestureDetector(
                      onTap: () {
                        if (!isFutureDay) _onDayTapped(day);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: isFutureDay
                              ? Color(0xFFE2E2E2)
                              : Colors.transparent,
                          border: Border(
                            right: BorderSide(
                              color: (index + 1) % 7 == 0
                                  ? Colors.transparent
                                  : lineColor,
                              width: 1.w,
                            ),
                            bottom: BorderSide(color: lineColor, width: 1.w),
                          ),
                        ),
                        child: Stack(
                          children: [
                            Positioned(
                              left: 3.w,
                              top: 5.h,
                              child: Text(
                                '${day.day}',
                                style: TextStyle(
                                  fontFamily: 'PretendardRegular',
                                  fontSize: 11.sp,
                                  color: isCurrentMonth
                                      ? Color(0xFF827C7C)
                                      : Colors.grey.withOpacity(0.2),
                                  fontWeight: currentEntry != null
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                            ),
                            if (currentEntry != null)
                              Positioned(
                                right: 7.w,
                                bottom: 9.h,
                                child: _buildEmojiWidget(currentEntry.emojiUrl),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                SizedBox(height: 20.h),
              ],
            ),
          ],
        ),
      ),
      GraphPage(initialYearMonth: currentYearMonth),
      WritePage(),
      const MyPage(),
    ];

    return Scaffold(
      appBar: AppBar(
        scrolledUnderElevation: 0,
        centerTitle: true,
        backgroundColor: Colors.white,
        leading: Container(),
        title: SizedBox(height: 60.h, child: Image.asset('assets/cloud.png')),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(5.0),
          child: Divider(color: Color(0xFFEEEEEE), thickness: 5),
        ),
        elevation: 0.0,
      ),
      body: IndexedStack(index: _selectedIndex, children: pages),
      bottomNavigationBar: CustomBottomNavBar(
        selectedIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}
