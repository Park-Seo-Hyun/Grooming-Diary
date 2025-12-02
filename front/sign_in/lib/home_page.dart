import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'diary/diary_entry.dart'; // 경로 확인 필요
import 'diary/diary_page.dart';
import 'diary/diary_detail_page.dart';
import 'graph/graph_page.dart';
import 'write_page.dart';
import 'my_page.dart';
import 'navbar.dart';
import 'services/diary_service.dart'; // 경로 확인 필요

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<DiaryEntry> diaries = [];

  DateTime _focusedDay = DateTime.now();
  int _selectedIndex = 0;

  // 날짜별 일기 데이터 관리
  final Map<DateTime, DiaryEntry> diaryEntries = {};

  // 감정 점수
  num userEmotionScore = 0;

  final DiaryService _diaryService = DiaryService();

  @override
  void initState() {
    super.initState();
    _loadMonthlyDiaries();
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
    try {
      final response = await _diaryService.getMonthlyDiaries(monthlyYear);

      if (!mounted) return;

      setState(() {
        diaryEntries.clear();

        // 감정 점수
        var rawScore = response['user_emotion_score'];
        userEmotionScore = rawScore is num ? rawScore : 0;

        // 다이어리 리스트
        final List<dynamic> diaries =
            (response['diaries'] as List<dynamic>?) ?? [];

        for (var item in diaries) {
          try {
            final entry = DiaryEntry.fromJson(item);
            DateTime dateKey = DateTime(
              entry.date.year,
              entry.date.month,
              entry.date.day,
            );
            diaryEntries[dateKey] = entry;
          } catch (e) {
            print("일기 개별 파싱 오류: $e");
          }
        }
      });
    } catch (e) {
      print('월별 일기 로드 실패 상세: $e');
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
      // 작성된 일기가 있으면 상세 페이지
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

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

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

  Widget _buildEmojiWidget(String? emojiData) {
    if (emojiData == null || emojiData.isEmpty) {
      return const Icon(
        Icons.mood, // 서버에 emoji 없을 때 기본 아이콘
        size: 40,
        color: Colors.grey,
      );
    }

    try {
      final decoded = base64Decode(emojiData);
      return Image.memory(decoded, width: 40, height: 40, fit: BoxFit.contain);
    } catch (e) {
      return const Icon(Icons.mood_bad, size: 40, color: Colors.grey);
    }
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

    // ✅ 현재 년-월 문자열 미리 생성
    final String currentYearMonth = DateFormat('yyyy-MM').format(_focusedDay);

    List<Widget> pages = [
      SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
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
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF5675DC),
                  ),
                ),
                const Spacer(),
                const SizedBox(width: 60),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.arrow_left,
                    size: 45,
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
                    fontSize: 36,
                    color: Color(0xFF5675DC),
                  ),
                ),
                const SizedBox(width: 40),
                IconButton(
                  icon: const Icon(
                    Icons.arrow_right,
                    size: 45,
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
                fontSize: 18,
                color: Color(0xFF5675DC),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(color: lineColor, width: 2),
                  bottom: BorderSide(color: lineColor, width: 2),
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
                                fontSize: 16,
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
                          Container(width: 2, height: 25, color: lineColor),
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
                              width: 2.0,
                            ),
                            bottom: BorderSide(color: lineColor, width: 2.0),
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
                                  fontSize: 16,
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
                                child: _buildEmojiWidget(currentEntry.emoji),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.only(right: 20),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      '구르밍 점수: $userEmotionScore 점',
                      style: const TextStyle(
                        fontSize: 20,
                        fontFamily: 'GyeonggiBatang',
                        color: Color(0xFF3A3939),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      GraphPage(initialYearMonth: currentYearMonth), // ✅ 수정 완료
      WritePage(),
      const MyPage(),
    ];

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.white,
        title: SizedBox(height: 60, child: Image.asset('assets/cloud.png')),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1.0),
          child: Divider(color: Color(0xFFEEEEEE), thickness: 7),
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
