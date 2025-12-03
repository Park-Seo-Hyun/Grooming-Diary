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
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: 25),
                child: Column(
                  children: [
                    const Center(
                      child: Text(
                        "감정 그래프",
                        style: TextStyle(
                          fontFamily: 'GyeonggiBatang',
                          fontSize: 32,
                          color: Color(0xFF1A6DFF),
                        ),
                      ),
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
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (graphData == null)
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
                            child: DoughnutGraphWidgetFL(
                              emotionState: graphData!.emotionState,
                            ),
                          ),

                          // 꺾은선그래프
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
                            child: MultiEmotionLineGraph(
                              dailyEmotionScores: graphData!.dailyEmotionScores,
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
