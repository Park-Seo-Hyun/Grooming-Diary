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

    final displayText = "$year년 $month월";

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

  final Map<String, String> roleName = {
    "happy": "행복",
    "sad": "슬픔",
    "angry": "화남",
    "fear": "불안",
    "tender": "평온",
    "neutral": "중립",
  };

  final Map<String, String> roleDesc = {
    "happy": "(기쁨, 즐거움, 만족)",
    "sad": "(우울, 슬픔, 낙담)",
    "angry": "(화남, 짜증, 분개)",
    "fear": "(걱정, 근심, 두려움)",
    "tender": "(평온, 안정, 편안)",
    "neutral": "(even)",
  };

  final Map<String, String> charName = {
    "happy": "햇살이",
    "sad": "구슬이",
    "angry": "화풍이",
    "fear": "두절이",
    "tender": "평달이",
    "neutral": "평푱이",
  };

  /// 👉 여기! 너가 직접 적어서 보여줄 텍스트
  final Map<String, String> customComment = {
    "happy":
        "행복을 담당하는 감정 캐릭터로\n 따뜻한 햇빛처럼 마음을 밝히는 행복의 수호자입니다. 햇살이는 여러분의 긍정적인 감정을 찾아 반짝이며 기쁨의 메시지를 전해줍니다. \"오늘도 너의 마음에 따뜻한 햇살이 비치길 바라!\"",
    "sad":
        "슬픔을 담당하는 감정 캐릭터로\n 구슬이는 마움속에 먹구름이 드리워질 때 찾아오는 슬픔의 작은 수호자입니다. 구슬이는 말없이 곁에 머물며 이렇게 이야기합니다. \"울어도 괜찮아. 네가 느끼는 감정은 모두 소중해.\"",
    "angry":
        "분노를 담당하는 감정 캐릭터로\n 억눌린 분노를 이해하고 안전하게 표현할 수 있도록 도와주는 감정의 수호자입니다. 화풍이는 감정을 억누르지 않아도 괜찮다고 말없이 곁에서 함께합니다. \"화를 느끼는 건 잘못이 아니야. 네 감정에는 언제나 이유가 있어.\"",
    "fear":
        "두려움을 담당하는 감정 캐릭터로\n 마음속에 피어오르는 걱정과 두려움을 품에 안는 감정 수호자입니다. 두절이는 작은 몸을 덜덜 떨며 곁에 조용히 머물러 이렇게 말합니다. \"무서워도 괜찮아. 네가 느끼는 걱정과 두려움도 다 소중한 감정이야.\"",
    "tender":
        "평온을 담당하는 감정 캐릭터로\n 평달이는 고요한 밤하늘에 떠 있는 밤하늘에 초승달처럼, 마음속 불안을 부드럽게 감싸주며 평온함을 지켜주는 존재입니다. 평달이는 조용히 곁에서 속삭입니다. \"괜찮아, 지금 이 순간만큼은 천천히 쉬워도 돼.\"",
    "neutral":
        "중립을 담당하는 감정 캐릭터로\n 오늘의 기쁨을 명확히 한 단어로 나타낼 수 없는 감정의 수호자입니다. \"이런날도 있고 저런날도 있는거야~~\"",
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

          title: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ⭐ 가운데 제목 + 오른쪽 X 버튼
              Stack(
                alignment: Alignment.center,
                children: [
                  const Align(
                    alignment: Alignment.center,
                    child: Text(
                      "감정 소개",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'GyeonggiBatang',
                        color: Color(0xFF585858),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 0,
                    child: GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: const Icon(Icons.close),
                    ),
                  ),
                ],
              ),

              // ⭐ 아래에 얇은 구분선
              const Padding(
                padding: EdgeInsets.only(top: 8.0),
                child: Divider(
                  thickness: 1,
                  height: 1,
                  color: Color(0xFFDDDDDD),
                ),
              ),
            ],
          ),

          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: graphData!.emotionState.length,
              itemBuilder: (context, index) {
                final emotion = graphData!.emotionState[index];

                // 🔥 핵심: label 키 정리
                final rawLabel = emotion.emotionLabel;
                final label = emotion.emotionLabel.trim().toLowerCase();

                final imageUrl = GraphService.baseUrl + emotion.emotionEmoji;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Image.network(
                          imageUrl,
                          width: 70,
                          height: 70,
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(width: 12),

                        // ⭐ 여기 padding으로 텍스트를 조금 아래로 내림
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(
                              top: 8,
                            ), // ← 숫자 조절하면 높이 조절 가능!
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // 👉 이름
                                RichText(
                                  text: TextSpan(
                                    children: [
                                      const TextSpan(
                                        text: "이름 : ",
                                        style: TextStyle(
                                          fontFamily: 'Pretendard',
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black,
                                        ),
                                      ),
                                      TextSpan(
                                        text: charName[label] ?? label,
                                        style: const TextStyle(
                                          fontFamily: 'Pretendard',
                                          fontSize: 15,
                                          fontWeight: FontWeight.normal,
                                          color: Colors.black,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 4),

                                // 👉 역할
                                RichText(
                                  text: TextSpan(
                                    children: [
                                      const TextSpan(
                                        text: " 역할 : ",

                                        style: TextStyle(
                                          fontSize: 12,
                                          fontFamily: 'Pretendard',
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black,
                                        ),
                                      ),
                                      TextSpan(
                                        text:
                                            "${roleName[label] ?? ""} ${roleDesc[label] ?? ""}",
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontFamily: 'Pretendard',
                                          fontWeight: FontWeight.normal,
                                          color: Colors.black,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // 긴 설명 텍스트 — 사진 밑에 나오기!
                    Text(
                      customComment[label] ?? "",
                      style: const TextStyle(
                        fontSize: 10,
                        color: Color(0xFF555555),
                        fontFamily: 'Pretendard',
                      ),
                    ),

                    const SizedBox(height: 16),
                    // 🔥 Divider를 Dialog padding 밖까지 확장
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
                        Builder(
                          builder: (context) {
                            final parts = currentMonth.split('-');
                            int year = int.parse(parts[0]);
                            int month = int.parse(parts[1]);
                            final displayText = "$year년 $month월";

                            return Text(
                              displayText,
                              style: const TextStyle(
                                fontSize: 20,

                                fontFamily: 'GyeonggiBatang',
                                color: Color(0xFF626262),
                              ),
                            );
                          },
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
