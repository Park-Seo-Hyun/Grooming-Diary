import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'diary/diary_entry.dart';
import 'diary/diary_page.dart';
import 'diary/diary_detail_page.dart';
import 'graph/graph_page.dart';
import 'write_page.dart';
import 'my_page.dart';
import 'navbar.dart';
import 'services/diary_service.dart';

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
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => DiaryDetailPage(
            diaryId: entry.id,
            onDelete: () {
              setState(() {
                diaries.removeWhere((d) => d.id == entry.id);
              });
            },
            onUpdate: (updatedEntry) {
              setState(() {
                final index = diaries.indexWhere(
                  (d) => d.id == updatedEntry.id,
                );
                if (index != -1) diaries[index] = updatedEntry as DiaryEntry;
              });
            },
          ),
        ),
      );
    } else {
      if (day.isAfter(DateTime.now())) return;

      final result = await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => DiaryPage(selectedDate: day)),
      );

      if (result != null && result is Map<String, dynamic>) {
        try {
          String formattedDate = DateFormat('yyyy-MM-dd').format(day);
          String text = result['text'];
          File? imageFile = result['image'];

          final createdData = await _diaryService.createDiary({
            'diary_date': formattedDate,
            'content': text,
          }, imageFile);
          final createdEntry = DiaryEntry.fromJson(createdData);

          setState(() {
            diaryEntries[normalizedDay] = createdEntry;
          });
        } catch (e) {
          print("일기 작성 에러: $e");
          if (!mounted) return;
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('일기 저장 중 오류가 발생했습니다.')));
        }
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
            height: 60,
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
            style: const TextStyle(
              color: Color(0xFFF44FBD),
              fontFamily: 'GyeonggiTitle',
              fontSize: 16,
            ),
          ),
          actionsPadding: EdgeInsets.zero,
          actions: [
            Row(
              children: [
                // 왼쪽 버튼: 취소
                Expanded(
                  child: InkWell(
                    onTap: () {
                      Navigator.of(context).pop(); // 팝업 닫기
                    },
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(15),
                    ),
                    child: Container(
                      height: 56,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFFC9F1), // 연한 하늘색
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

                // 오른쪽 버튼: 그래프 페이지 이동
                Expanded(
                  child: InkWell(
                    onTap: () {
                      Navigator.of(context).pop(); // 팝업 닫기
                      _onItemTapped(1); // 그래프 페이지로 이동
                    },
                    borderRadius: const BorderRadius.only(
                      bottomRight: Radius.circular(15),
                    ),
                    child: Container(
                      height: 56,
                      decoration: const BoxDecoration(
                        color: Color(0xFFF79CDF), // 진한 파란색
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
                height: 80,
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
                                    style: const TextStyle(
                                      fontSize: 18,
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
                    const SizedBox(width: 30),
                    DropdownButton<int>(
                      value: selectedMonth,
                      iconEnabledColor: const Color(0xFF5A9AFF),
                      items: List.generate(12, (i) => i + 1)
                          .map(
                            (month) => DropdownMenuItem(
                              value: month,
                              child: Text(
                                "$month월",
                                style: const TextStyle(
                                  fontSize: 18,
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
                const SizedBox(width: 10),
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
      return const Icon(Icons.mood, size: 40, color: Colors.grey);
    }
    return Image.network(
      imageUrl,
      width: 40,
      height: 40,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        print("Emoji network load error: $error");
        return const Icon(Icons.mood_bad, size: 40, color: Colors.grey);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
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
            const SizedBox(height: 10),
            Stack(
              children: [
                Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 10.0),
                      child: IconButton(
                        icon: const Icon(
                          Icons.calendar_month,
                          color: Color(0xFF5675DC),
                          size: 35,
                        ),
                        onPressed: _showYearMonthPicker,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      DateFormat('yyyy').format(_focusedDay),
                      style: const TextStyle(
                        fontFamily: 'PretendardBold',
                        fontSize: 25,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF5675DC),
                      ),
                    ),
                    const Spacer(),
                    const SizedBox(width: 60),
                  ],
                ),
                Positioned(
                  right: 20,
                  top: 50,
                  child: Text(
                    '구르밍 점수: $userEmotionScore 점',
                    style: const TextStyle(
                      fontSize: 16,
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
                  icon: const Icon(
                    Icons.arrow_left,
                    size: 40,
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
                const SizedBox(width: 40),
                Text(
                  DateFormat('MM').format(_focusedDay),
                  style: const TextStyle(
                    fontFamily: 'PretendardRegular',
                    fontSize: 33,
                    color: Color(0xFF5675DC),
                  ),
                ),
                const SizedBox(width: 40),
                IconButton(
                  icon: const Icon(
                    Icons.arrow_right,
                    size: 40,
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
              style: const TextStyle(
                fontFamily: 'PretendardRegular',
                fontSize: 15,
                color: Color(0xFF5675DC),
              ),
            ),
            const SizedBox(height: 25),
            Container(
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(color: lineColor, width: 1),
                  bottom: BorderSide(color: lineColor, width: 1),
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
                                fontSize: 13,
                                color: d == 'Sun'
                                    ? Colors.redAccent
                                    : d == 'Sat'
                                    ? primaryColor
                                    : const Color(0xFF827C7C),
                              ),
                            ),
                          ),
                        ),
                        if (index != 6)
                          Container(width: 1, height: 25, color: lineColor),
                      ],
                    ),
                  );
                }),
              ),
            ),
            Column(
              children: <Widget>[
                GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
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
                              ? const Color(0xFFE2E2E2)
                              : Colors.transparent,
                          border: Border(
                            right: BorderSide(
                              color: (index + 1) % 7 == 0
                                  ? Colors.transparent
                                  : lineColor,
                              width: 1.0,
                            ),
                            bottom: BorderSide(color: lineColor, width: 1.0),
                          ),
                        ),
                        child: Stack(
                          children: [
                            Positioned(
                              left: 3,
                              top: 5,
                              child: Text(
                                '${day.day}',
                                style: TextStyle(
                                  fontFamily: 'PretendardRegular',
                                  fontSize: 11,
                                  color: isCurrentMonth
                                      ? const Color(0xFF827C7C)
                                      : Colors.grey.withOpacity(0.2),
                                  fontWeight: currentEntry != null
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                            ),
                            if (currentEntry != null)
                              Positioned(
                                right: 7,
                                bottom: 9,
                                child: _buildEmojiWidget(currentEntry.emojiUrl),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),
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
        title: SizedBox(height: 60, child: Image.asset('assets/cloud.png')),
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
