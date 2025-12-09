import 'package:flutter/material.dart';
import '../services/graph_service.dart';
import 'models/monthly_graph.dart';
import 'bar_graph.dart';
import 'doughnut_graph.dart';
import 'line_graph.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

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
    "neutral": "(무심, 안정)",
  };

  final Map<String, String> charName = {
    "happy": "햇살이",
    "sad": "구슬이",
    "angry": "화풍이",
    "fear": "두절이",
    "tender": "평달이",
    "neutral": "평푱이",
  };

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
        "중립 감정 평평이는 기쁨도 슬픔도 아닌, 그 사이 어딘가의 감정을 지켜주는 수호자예요. 분명히 말로 표현하긴 어렵지만, 그런 미묘한 하루를 가장 잘 이해하는 존재죠. \“이런 날도 있고 저런 날도 있는 거야~\”라며 언제나 당신의 하루를 부드럽게 감싸줘요.",
  };

  void showEmotionPopup() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
          title: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  Align(
                    alignment: Alignment.center,
                    child: Text(
                      "감정 소개",
                      style: TextStyle(
                        fontSize: 18.sp,
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
                      child: Icon(Icons.close, size: 24.sp),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: EdgeInsets.only(top: 8.h),
                child: Divider(
                  thickness: 1.h,
                  height: 1.h,
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
                          width: 70.w,
                          height: 70.h,
                          fit: BoxFit.contain,
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(top: 8.h),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                RichText(
                                  text: TextSpan(
                                    children: [
                                      TextSpan(
                                        text: "이름 : ",
                                        style: TextStyle(
                                          fontFamily: 'Pretendard',
                                          fontSize: 15.sp,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black,
                                        ),
                                      ),
                                      TextSpan(
                                        text: charName[label] ?? label,
                                        style: TextStyle(
                                          fontFamily: 'Pretendard',
                                          fontSize: 15.sp,
                                          fontWeight: FontWeight.normal,
                                          color: Colors.black,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(height: 4.h),
                                RichText(
                                  text: TextSpan(
                                    children: [
                                      TextSpan(
                                        text: " 역할 : ",
                                        style: TextStyle(
                                          fontSize: 12.sp,
                                          fontFamily: 'Pretendard',
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black,
                                        ),
                                      ),
                                      TextSpan(
                                        text:
                                            "${roleName[label] ?? ""} ${roleDesc[label] ?? ""}",
                                        style: TextStyle(
                                          fontSize: 12.sp,
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
                    SizedBox(height: 12.h),
                    Text(
                      customComment[label] ?? "",
                      style: TextStyle(
                        fontSize: 10.sp,
                        color: Color(0xFF555555),
                        fontFamily: 'Pretendard',
                      ),
                    ),
                    SizedBox(height: 16.h),
                    Divider(thickness: 1.h),
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
            ? Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: EdgeInsets.symmetric(vertical: 25.h),
                child: Column(
                  children: [
                    Stack(
                      children: [
                        Center(
                          child: Text(
                            "감정 그래프",
                            style: TextStyle(
                              fontFamily: 'GyeonggiBatang',
                              fontSize: 32.sp,
                              color: Color(0xFF1A6DFF),
                            ),
                          ),
                        ),
                        Positioned(
                          right: 20.w,
                          top: 0,
                          child: IconButton(
                            icon: Icon(Icons.menu, size: 30.sp),
                            onPressed: showEmotionPopup,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 15.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: Icon(Icons.arrow_left, size: 30.sp),
                          onPressed: () => changeMonth(-1),
                        ),
                        SizedBox(width: 8.w),
                        Builder(
                          builder: (context) {
                            final parts = currentMonth.split('-');
                            int year = int.parse(parts[0]);
                            int month = int.parse(parts[1]);
                            final displayText = "$year년 $month월";

                            return Text(
                              displayText,
                              style: TextStyle(
                                fontSize: 20.sp,
                                fontFamily: 'GyeonggiBatang',
                                color: Color(0xFF626262),
                              ),
                            );
                          },
                        ),
                        SizedBox(width: 8.w),
                        IconButton(
                          icon: Icon(Icons.arrow_right, size: 30.sp),
                          onPressed: () => changeMonth(1),
                        ),
                        SizedBox(width: 8.w),
                      ],
                    ),
                    SizedBox(height: 16.h),
                    if (isFutureMonth)
                      Container(
                        margin: EdgeInsets.symmetric(horizontal: 20.w),
                        padding: EdgeInsets.all(16.h),
                        child: Center(
                          child: Text(
                            "구르밍은 아직 감정을 기다리고있어요!",
                            style: TextStyle(
                              fontSize: 16.sp,
                              color: Color(0xFF1A6DFF),
                              fontFamily: 'GyeonggiBatang',
                            ),
                          ),
                        ),
                      )
                    else if (graphData == null)
                      Center(child: Text("데이터 로드 실패"))
                    else
                      Column(
                        children: [
                          Container(
                            margin: EdgeInsets.symmetric(
                              horizontal: 20.w,
                              vertical: 8.h,
                            ),
                            padding: EdgeInsets.all(16.h),
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
                            width: double.infinity,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "이번 달 일기 총 기록",
                                  style: TextStyle(
                                    fontSize: 18.sp,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF585858),
                                  ),
                                ),
                                SizedBox(height: 4.h),
                                Center(
                                  child: Text(
                                    "${graphData!.diaryCnt}회",
                                    style: TextStyle(
                                      fontSize: 30.sp,
                                      fontFamily: 'GyeonggiTitle',
                                      color: Color(0xFF1A6DFF),
                                    ),
                                  ),
                                ),
                                SizedBox(height: 8.h),
                                Text(
                                  "이번 달에는 어떤 감정이 많았을까요? 행복한 날이 많아지기를 바랍니다!",
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    color: Color(0xFF585858),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // 막대그래프
                          Container(
                            margin: EdgeInsets.symmetric(
                              horizontal: 20.w,
                              vertical: 8.h,
                            ),
                            padding: EdgeInsets.all(16.h),
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
                            width: double.infinity,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "내 감정 순위",
                                  style: TextStyle(
                                    fontSize: 18.sp,
                                    fontFamily: 'Pretendard',
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF585858),
                                  ),
                                ),
                                SizedBox(height: 8.h),
                                Text(
                                  "이번 달에는 어떤 감정이 많았을까요? 행복한 날이 많아지기를 바랍니다!",
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    fontFamily: 'Pretendard',
                                    color: Color(0xFF585858),
                                  ),
                                ),
                                SizedBox(height: 8.h),
                                BarGraphWidget(
                                  emotionState: graphData!.emotionState,
                                ),
                              ],
                            ),
                          ),

                          // 도넛형 그래프
                          Container(
                            margin: EdgeInsets.symmetric(
                              horizontal: 20.w,
                              vertical: 8.h,
                            ),
                            padding: EdgeInsets.all(16.h),
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
                            width: double.infinity,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "내 감정 비율",
                                  style: TextStyle(
                                    fontSize: 18.sp,
                                    fontFamily: 'Pretendard',
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF585858),
                                  ),
                                ),
                                SizedBox(height: 8.h),
                                Text(
                                  "이번 달 나의 감정 비율을 알아봐요. 부디 행복으로 가득차기를!",
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    fontFamily: 'Pretendard',
                                    color: Color(0xFF585858),
                                  ),
                                ),
                                SizedBox(height: 16.h),
                                DoughnutGraphWidgetFL(
                                  emotionState: graphData!.emotionState,
                                ),
                              ],
                            ),
                          ),

                          // 꺾은선 그래프
                          Container(
                            margin: EdgeInsets.symmetric(
                              horizontal: 20.w,
                              vertical: 8.h,
                            ),
                            padding: EdgeInsets.all(16.h),
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
                            width: double.infinity,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "내 감정 추이",
                                  style: TextStyle(
                                    fontSize: 18.sp,
                                    fontFamily: 'Pretendard',
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF585858),
                                  ),
                                ),
                                SizedBox(height: 8.h),
                                Text(
                                  "이번 달 나의 감정의 변화를 한 눈에 확인해보세요. 일기를 통해 쌓인 감정의 흐름을 살펴보며 나를 좀 더 이해하는 시간을 가져보아요!",
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    fontFamily: 'Pretendard',
                                    color: Color(0xFF585858),
                                  ),
                                ),
                                SizedBox(height: 10.h),
                                MultiEmotionLineGraph(
                                  dailyEmotionScores:
                                      graphData!.dailyEmotionScores,
                                ),
                                Text(
                                  "AI 자연어 처리 기술을 활용하여 일기 텍스트에 나타난 표현을 분석한 결과일 뿐이며, 정신건강의학과 전문 평가나 심리검사, 일상 진단 기준 등을 기반으로 산출된 값이 아닙니다.",
                                  style: TextStyle(
                                    fontSize: 10.sp,
                                    fontFamily: 'Pretendard',
                                    color: Color(0xFFFF0000),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 50.h),
                        ],
                      ),
                  ],
                ),
              ),
      ),
    );
  }
}
