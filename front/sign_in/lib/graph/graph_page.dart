// graph_page.dart
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import '../services/graph_service.dart';
import 'models/monthly_graph.dart';

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

  @override
  void initState() {
    super.initState();
    currentMonth = widget.initialYearMonth;
    loadGraphData();
  }

  Future<void> loadGraphData() async {
    setState(() => isLoading = true);
    final data = await GraphService().getMonthlyGraphData(currentMonth);
    setState(() {
      graphData = data;
      isLoading = false;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),
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
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : graphData == null
                  ? const Center(child: Text("데이터 로드 실패"))
                  : SingleChildScrollView(
                      child: Column(
                        children: [
                          // 1️⃣ 월 총 일기 횟수
                          Container(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 30,
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

                          // 2️⃣ 막대그래프
                          Container(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 30,
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
                                SizedBox(
                                  width: double.infinity,
                                  height: 250,
                                  child: SfCartesianChart(
                                    plotAreaBorderWidth: 0,
                                    primaryXAxis: CategoryAxis(
                                      axisLabelFormatter: (args) {
                                        final koreanLabels = {
                                          "Happy": "행복",
                                          "Sad": "슬픔",
                                          "Angry": "화남",
                                          "Fear": "불안",
                                          "Tender": "평온",
                                          "Neutral": "중립",
                                        };
                                        return ChartAxisLabel(
                                          koreanLabels[args.text] ?? args.text,
                                          const TextStyle(
                                            fontSize: 12,
                                            fontFamily: 'GyeonggiBatang',
                                            color: Color(0xFF827C7C),
                                          ),
                                        );
                                      },
                                      majorTickLines: const MajorTickLines(
                                        width: 0,
                                      ),
                                      majorGridLines: const MajorGridLines(
                                        width: 0,
                                      ),
                                      axisLine: const AxisLine(width: 1),
                                    ),
                                    primaryYAxis: NumericAxis(
                                      isVisible: false,
                                      majorGridLines: const MajorGridLines(
                                        width: 0,
                                      ),
                                      axisLine: const AxisLine(width: 0),
                                      minimum: 0,
                                      maximum:
                                          (graphData!.emotionState
                                              .map((e) => e.emotionCnt)
                                              .reduce((a, b) => a > b ? a : b)
                                              .toDouble()) *
                                          1.4,
                                    ),
                                    series: <ColumnSeries<EmotionState, String>>[
                                      ColumnSeries<EmotionState, String>(
                                        dataSource: graphData!.emotionState,
                                        xValueMapper: (e, _) => e.emotionLabel,
                                        yValueMapper: (e, _) => e.emotionCnt,
                                        width: 0.6,
                                        pointColorMapper: (e, _) {
                                          switch (e.emotionLabel) {
                                            case "Happy":
                                              return const Color(0xFFFFAEAE);
                                            case "Sad":
                                              return const Color(0xFF5A9AFF);
                                            case "Angry":
                                              return const Color(0xFFBB79DF);
                                            case "Fear":
                                              return const Color(0xFF51D383);
                                            case "Tender":
                                              return const Color(0xFFF8F815);
                                            case "Neutral":
                                              return const Color(0xFFFFBB8A);
                                          }
                                          return Colors.blue;
                                        },
                                        color: Colors.blue,
                                        dataLabelSettings: DataLabelSettings(
                                          isVisible: true,
                                          labelAlignment:
                                              ChartDataLabelAlignment.outer,
                                          builder:
                                              (
                                                data,
                                                point,
                                                series,
                                                pointIndex,
                                                seriesIndex,
                                              ) {
                                                final EmotionState e =
                                                    data as EmotionState;
                                                final imageUrl =
                                                    GraphService.baseUrl +
                                                    e.emotionEmoji;
                                                return Column(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    SizedBox(
                                                      width: 24,
                                                      height: 24,
                                                      child: Image.network(
                                                        imageUrl,
                                                        fit: BoxFit.cover,
                                                        errorBuilder:
                                                            (
                                                              context,
                                                              error,
                                                              stackTrace,
                                                            ) => const Icon(
                                                              Icons
                                                                  .sentiment_neutral,
                                                              size: 16,
                                                            ),
                                                      ),
                                                    ),
                                                    const SizedBox(height: 3),
                                                    Container(
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            horizontal: 10,
                                                            vertical: 1,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        color: const Color(
                                                          0xFFFFF1D9,
                                                        ),
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              8,
                                                            ),
                                                      ),
                                                      child: Text(
                                                        e.emotionCnt.toString(),
                                                        style: const TextStyle(
                                                          fontSize: 10,
                                                          fontFamily:
                                                              'Pretendard',
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                );
                                              },
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // 3️⃣ 도넛형 원형그래프
                          Container(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 30,
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
                                  "이번 달 감정 비율",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontFamily: 'Pretendard',
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF585858),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  "이번 달 나의 감정 비율을 알아봐요. 부디 행복으로 가득차기를...",
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontFamily: 'Pretendard',
                                    color: Color(0xFF585858),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // 1️⃣ 원형그래프
                                    Expanded(
                                      flex: 2,
                                      child: SizedBox(
                                        height: 250,
                                        child: SfCircularChart(
                                          series: <DoughnutSeries<EmotionState, String>>[
                                            DoughnutSeries<
                                              EmotionState,
                                              String
                                            >(
                                              dataSource:
                                                  graphData!.emotionState,
                                              xValueMapper:
                                                  (EmotionState e, _) =>
                                                      e.emotionLabel,
                                              yValueMapper:
                                                  (EmotionState e, _) =>
                                                      e.emotionPercent,
                                              pointColorMapper:
                                                  (EmotionState e, _) {
                                                    switch (e.emotionLabel) {
                                                      case "Happy":
                                                        return const Color(
                                                          0xFFFFAEAE,
                                                        );
                                                      case "Sad":
                                                        return const Color(
                                                          0xFF5A9AFF,
                                                        );
                                                      case "Angry":
                                                        return const Color(
                                                          0xFFBB79DF,
                                                        );
                                                      case "Fear":
                                                        return const Color(
                                                          0xFF51D383,
                                                        );
                                                      case "Tender":
                                                        return const Color(
                                                          0xFFF8F815,
                                                        );
                                                      case "Neutral":
                                                        return const Color(
                                                          0xFFFFBB8A,
                                                        );
                                                    }
                                                    return Colors.grey;
                                                  },
                                              dataLabelMapper:
                                                  (EmotionState e, _) =>
                                                      "${e.emotionPercent}%",
                                              dataLabelSettings: DataLabelSettings(
                                                isVisible: true,
                                                builder:
                                                    (
                                                      data,
                                                      point,
                                                      series,
                                                      pointIndex,
                                                      seriesIndex,
                                                    ) {
                                                      final EmotionState e =
                                                          data as EmotionState;

                                                      // 0%는 라벨 표시 안 함
                                                      if (e.emotionPercent == 0)
                                                        return Container();

                                                      final isSmall =
                                                          e.emotionPercent < 5;

                                                      return Center(
                                                        child: Container(
                                                          padding:
                                                              const EdgeInsets.all(
                                                                4,
                                                              ),
                                                          child: Text(
                                                            "${e.emotionPercent}%",
                                                            textAlign: TextAlign
                                                                .center,
                                                            style: TextStyle(
                                                              fontSize: 12,
                                                              fontFamily:
                                                                  'Pretendard',
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              color: isSmall
                                                                  ? Colors.black
                                                                  : Colors
                                                                        .white,
                                                            ),
                                                          ),
                                                        ),
                                                      );
                                                    },
                                                labelPosition:
                                                    ChartDataLabelPosition
                                                        .inside,
                                                connectorLineSettings:
                                                    const ConnectorLineSettings(
                                                      type: ConnectorType.curve,
                                                      length: '15%',
                                                      color: Colors.grey,
                                                    ),
                                              ),
                                              radius: '100%',
                                              innerRadius: '30%', // 도넛형
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    // 2️⃣ 감정 설명 박스
                                    Expanded(
                                      flex: 1,
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: graphData!.emotionState.map((
                                          e,
                                        ) {
                                          if (e.emotionPercent == 0)
                                            return Container(); // 0%는 표시 X

                                          Color color;
                                          switch (e.emotionLabel) {
                                            case "Happy":
                                              color = const Color(0xFFFFAEAE);
                                              break;
                                            case "Sad":
                                              color = const Color(0xFF5A9AFF);
                                              break;
                                            case "Angry":
                                              color = const Color(0xFFBB79DF);
                                              break;
                                            case "Fear":
                                              color = const Color(0xFF51D383);
                                              break;
                                            case "Tender":
                                              color = const Color(0xFFF8F815);
                                              break;
                                            case "Neutral":
                                              color = const Color(0xFFFFBB8A);
                                              break;
                                            default:
                                              color = Colors.grey;
                                          }

                                          String labelKorean = {
                                            "Happy": "행복",
                                            "Sad": "슬픔",
                                            "Angry": "화남",
                                            "Fear": "불안",
                                            "Tender": "평온",
                                            "Neutral": "중립",
                                          }[e.emotionLabel]!;

                                          return Padding(
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 4,
                                            ),
                                            child: Row(
                                              children: [
                                                Container(
                                                  width: 16,
                                                  height: 16,
                                                  decoration: BoxDecoration(
                                                    color: color,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          4,
                                                        ),
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  labelKorean,
                                                  style: const TextStyle(
                                                    fontSize: 14,
                                                    fontFamily: 'Pretendard',
                                                    color: Color(0xFF585858),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        }).toList(),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          // 4️⃣ 꺾은선 그래프
                          Container(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 30,
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
                                    fontSize: 16,
                                    fontFamily: 'Pretendard',
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF585858),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  "이번 달 나의 감정의 변화를 한 눈에 확인해보세요. 일기를 통해 쌓인 감젖ㅇ의 흐름을 살펴보며 나를 좀 더 이해하는 시간을 가져보아요.",
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontFamily: 'Pretendard',
                                    color: Color(0xFF585858),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                SizedBox(
                                  height: 250,
                                  child: SfCartesianChart(
                                    primaryXAxis: NumericAxis(
                                      edgeLabelPlacement:
                                          EdgeLabelPlacement.shift,
                                      majorGridLines: const MajorGridLines(
                                        width: 0,
                                      ),
                                    ),
                                    primaryYAxis: NumericAxis(
                                      minimum: 0,
                                      maximum: 10,
                                      interval: 1,
                                      majorGridLines: const MajorGridLines(
                                        width: 0.5,
                                      ),
                                    ),
                                    series:
                                        <LineSeries<DailyEmotionScore, int>>[
                                          LineSeries<DailyEmotionScore, int>(
                                            dataSource:
                                                graphData!.dailyEmotionScores,
                                            xValueMapper:
                                                (DailyEmotionScore e, index) =>
                                                    index,
                                            yValueMapper:
                                                (DailyEmotionScore e, _) =>
                                                    e.happy.toDouble(),
                                            color: Colors.green,
                                            width: 2,
                                            markerSettings:
                                                const MarkerSettings(
                                                  isVisible: true,
                                                  color: Colors.green,
                                                  height: 4,
                                                  width: 4,
                                                ),
                                            dataLabelSettings:
                                                const DataLabelSettings(
                                                  isVisible: false,
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
            ),
          ],
        ),
      ),
    );
  }
}
