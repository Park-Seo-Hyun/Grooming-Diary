import 'package:flutter/material.dart';
import '../services/graph_service.dart';
import 'models/monthly_graph.dart';
import 'bar_graph.dart';
import 'doughnut_graph.dart';
import 'line_graph.dart';

class GraphPage extends StatefulWidget {
  final String initialYearMonth;

  const GraphPage({super.key, required this.initialYearMonth});

  @override
  State<GraphPage> createState() => _GraphPageState();
}

class _GraphPageState extends State<GraphPage> {
  late String currentMonth;
  MonthlyGraphData? graphData;
  bool isLoading = true;
  bool isFutureMonth = false; // ✅ 미래 달 여부

  @override
  void initState() {
    super.initState();
    currentMonth = widget.initialYearMonth;
    loadGraphData();
  }

  Future<void> loadGraphData() async {
    setState(() => isLoading = true);
    final now = DateTime.now();
    final parts = currentMonth.split('-');
    int year = int.parse(parts[0]);
    int month = int.parse(parts[1]);

    final monthDate = DateTime(year, month);

    // 미래 달이면 데이터를 요청하지 않고 안내 표시
    if (monthDate.isAfter(DateTime(now.year, now.month))) {
      setState(() {
        graphData = null;
        isLoading = false;
        isFutureMonth = true;
      });
      return;
    }

    final data = await GraphService().getMonthlyGraphData(currentMonth);
    setState(() {
      graphData = data;
      isLoading = false;
      isFutureMonth = false;
    });
  }

  void changeMonth(int delta) {
    final parts = currentMonth.split('-');
    int year = int.parse(parts[0]);
    int month = int.parse(parts[1]);

    month += delta;
    if (month < 1) {
      month = 12;
      year -= 1;
    } else if (month > 12) {
      month = 1;
      year += 1;
    }

    setState(() {
      currentMonth = "$year-${month.toString().padLeft(2, '0')}";
    });

    loadGraphData();
  }

  final Map<String, String> customRoles = {
    "햇살이": "행복",
    "구슬이": "슬픔",
    "화풍이": "화남",
    "두절이": "불안",
    "평달이": "평온",
    "평푱이": "중립",
  };

  final Map<String, String> customRoleDescriptions = {
    "햇살이": "(기쁠때 나타나요!)",
    "구슬이": "(슬플때 나타나요..)",
    "화풍이": "(화날때 나타나요!)",
    "두절이": "(조금 불안할 때 나타나요.)",
    "평달이": "(평온할 때 나타나요~)",
    "평푱이": "(그저 평범할 때 나타나요.)",
  };
  final Map<String, String> customComments = {
    "햇살이": "행복이는 행복할때 나타나요!!",
    "구슬이": "슬픈 날에는 이렇게 나타나요..",
    "화풍이": "화날때 나타나요!",
    "두절이": "조금 불안할 때 나타나요.",
    "평달이": "평온할 때 나타나요~",
    "평푱이": "그저 평범할 때 나타나요.",
  };

  void showEmotionPopup() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          titlePadding: const EdgeInsets.only(
            left: 16,
            right: 8,
            top: 16,
            bottom: 0,
          ),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "감정 소개",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: const Icon(Icons.close, size: 24),
              ),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: graphData == null
                ? const Center(child: Text("데이터가 없습니다."))
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: graphData!.emotionState.length,
                    itemBuilder: (context, index) {
                      final emotion = graphData!.emotionState[index];
                      final imageUrl =
                          GraphService.baseUrl + emotion.emotionEmoji;

                      return Column(
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 이미지
                              Image.network(
                                imageUrl,
                                height: 100,
                                width: 100,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    const Icon(
                                      Icons.sentiment_neutral,
                                      size: 24,
                                    ),
                              ),
                              const SizedBox(width: 12),
                              // 감정 텍스트 3줄
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // 이름: 볼드체
                                    Text(
                                      "이름: ${emotion.emotionLabel}",
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    // 역할: 볼드체 / 설명: 일반체
                                    Text.rich(
                                      TextSpan(
                                        children: [
                                          const TextSpan(
                                            text: "역할: ",
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                          ),
                                          TextSpan(
                                            text:
                                                customRoles[emotion
                                                    .emotionLabel] ??
                                                "",
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                          ),
                                          const TextSpan(text: " "),
                                          TextSpan(
                                            text:
                                                customRoleDescriptions[emotion
                                                    .emotionLabel] ??
                                                "",
                                            style: const TextStyle(
                                              fontWeight: FontWeight.normal,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    // 주석
                                    Text(
                                      customComments[emotion.emotionLabel] ??
                                          "",
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.normal,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const Divider(),
                        ],
                      );
                    },
                  ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: 25),
                child: Column(
                  children: [
                    Stack(
                      children: [
                        Center(
                          child: Text(
                            "감정 그래프",
                            style: TextStyle(
                              fontFamily: 'GyeonggiBatang',
                              fontSize: 32,
                              color: Color(0xFF1A6DFF),
                            ),
                          ),
                        ),
                        Positioned(
                          right: 20, // 오른쪽에서 20px
                          top: 0, // 위에서 0px
                          child: IconButton(
                            icon: Icon(Icons.menu, size: 30),
                            onPressed: showEmotionPopup,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 15),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_left, size: 30),
                          onPressed: () => changeMonth(-1),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          currentMonth,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.arrow_right, size: 30),
                          onPressed: () => changeMonth(1),
                        ),
                        const SizedBox(width: 8),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // 🔴 미래 달이면 안내 텍스트 표시
                    if (isFutureMonth)
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 20),
                        padding: const EdgeInsets.all(16),

                        child: const Center(
                          child: Text(
                            "구르밍은 아직 감정을 기다리고있어요!",
                            style: TextStyle(
                              fontSize: 16,
                              color: Color(0xFF1A6DFF),
                              fontFamily: 'GyeonggiBatang',
                            ),
                          ),
                        ),
                      )
                    else if (graphData == null)
                      const Center(child: Text("데이터 로드 실패"))
                    else
                      Column(
                        children: [
                          // 월 총 일기 횟수
                          Container(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 8,
                            ),
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
                            width: double.infinity,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "이번 달 일기 총 기록",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF585858),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Center(
                                  child: Text(
                                    "${graphData!.diaryCnt}회",
                                    style: const TextStyle(
                                      fontSize: 30,
                                      fontFamily: 'GyeonggiTitle',
                                      color: Color(0xFF1A6DFF),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  "이번 달에는 어떤 감정이 많았을까요? 행복한 날이 많아지기를 바랍니다!",
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFF585858),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // 막대그래프
                          Container(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 8,
                            ),
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
                            width: double.infinity,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "내 감정 순위",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontFamily: 'Pretendard',
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF585858),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  "이번 달에는 어떤 감정이 많았을까요? 행복한 날이 많아지기를 바랍니다!",
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontFamily: 'Pretendard',
                                    color: Color(0xFF585858),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                BarGraphWidget(
                                  emotionState: graphData!.emotionState,
                                ),
                              ],
                            ),
                          ),

                          // 도넛형 원형그래프
                          Container(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 8,
                            ),
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
                            width: double.infinity,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "내 감정 비율",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontFamily: 'Pretendard',
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF585858),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  "이번 달 나의 감정 비율을 알아봐요. 부디 행복으로 가득차기를!",
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontFamily: 'Pretendard',
                                    color: Color(0xFF585858),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                DoughnutGraphWidgetFL(
                                  emotionState: graphData!.emotionState,
                                ),
                              ],
                            ),
                          ),

                          // 꺾은선그래프
                          Container(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 8,
                            ),
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
                            width: double.infinity,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "내 감정 추이",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontFamily: 'Pretendard',
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF585858),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  "이번 달 나의 감정의 변화를 한 눈에 확인해보세요. 일기를 통해 쌓인 감정의 흐름을 살펴보며 나를 좀 더 이해하는 시간을 가져보아요!",
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontFamily: 'Pretendard',
                                    color: Color(0xFF585858),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                MultiEmotionLineGraph(
                                  dailyEmotionScores:
                                      graphData!.dailyEmotionScores,
                                ),
                                const Text(
                                  "AI 자연어 처리 기술을 활용하여 일기 텍스트에 나타난 표현을 분석한 결과일 뿐이며, 정신건강의학과 전문 평가나 심리검사, 일상 진단 기준 등을 기반으로 산출된 값이 아닙니다.",
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontFamily: 'Pretendard',
                                    color: Color(0xFFFF0000),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 50),
                        ],
                      ),
                  ],
                ),
              ),
      ),
    );
  }
}
