import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'models/monthly_graph.dart';

class MultiEmotionLineGraph extends StatefulWidget {
  final List<DailyEmotionScore> dailyEmotionScores;

  const MultiEmotionLineGraph({super.key, required this.dailyEmotionScores});

  @override
  State<MultiEmotionLineGraph> createState() => _MultiEmotionLineGraphState();
}

class _MultiEmotionLineGraphState extends State<MultiEmotionLineGraph> {
  late PageController _pageController;

  final emotions = ['happy', 'sad', 'angry', 'fear', 'tender'];
  final colors = {
    'happy': Colors.yellow,
    'sad': Colors.blue,
    'angry': Colors.red,
    'fear': Colors.purple,
    'tender': Colors.green,
  };

  int initialPage = 1000; // 무한 스크롤 느낌
  int get pageCount => emotions.length + 1;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: initialPage);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();

    // 오늘 이후 날짜 제거
    final filteredScores = widget.dailyEmotionScores
        .where((e) => !e.date.isAfter(today))
        .toList();

    // 데이터가 없으면 빈 컨테이너 반환
    if (filteredScores.isEmpty) {
      return const SizedBox(
        height: 300,
        child: Center(child: Text("그래프 데이터가 없습니다.")),
      );
    }

    return SizedBox(
      height: 300,
      child: PageView.builder(
        controller: _pageController,
        itemBuilder: (context, index) {
          final pageIndex = index % pageCount;

          if (pageIndex == 0) {
            return _buildCombinedGraph(filteredScores);
          } else {
            final emotion = emotions[pageIndex - 1];
            return _buildSingleEmotionGraph(
              emotion,
              colors[emotion]!,
              filteredScores,
            );
          }
        },
      ),
    );
  }

  Widget _buildCombinedGraph(List<DailyEmotionScore> scores) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: LineChart(
        LineChartData(
          minX: 0,
          maxX: (scores.length - 1).toDouble(),
          clipData: FlClipData.all(),
          minY: 0,
          maxY: 1,
          gridData: FlGridData(
            show: true,
            horizontalInterval: 0.25,
            getDrawingHorizontalLine: (value) =>
                FlLine(color: Colors.grey.withOpacity(0.3), strokeWidth: 0.5),
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 0.25,
                getTitlesWidget: (value, meta) => Text(
                  (value * 100).toStringAsFixed(0) + '%',
                  style: const TextStyle(fontSize: 10),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  int index = value.toInt();
                  if (index < 0 || index >= scores.length)
                    return const SizedBox.shrink();
                  return Text(
                    (index + 1).toString(),
                    style: const TextStyle(fontSize: 10),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(
            show: true,
            border: const Border(
              bottom: BorderSide(color: Colors.grey, width: 1),
              left: BorderSide(color: Colors.grey, width: 1),
              right: BorderSide(color: Colors.transparent),
              top: BorderSide(color: Colors.transparent),
            ),
          ),
          lineBarsData: emotions.map((emotion) {
            return LineChartBarData(
              spots: scores
                  .asMap()
                  .entries
                  .map(
                    (e) => FlSpot(
                      // x값 안전하게 제한
                      e.key.toDouble().clamp(0, (scores.length - 1).toDouble()),
                      getEmotionValue(e.value, emotion),
                    ),
                  )
                  .toList(),
              isCurved: true,
              color: colors[emotion]!,
              barWidth: 2,
              dotData: FlDotData(show: false),
              belowBarData: BarAreaData(show: false),
              preventCurveOverShooting: true, // 곡선이 x축 넘어가는 것 방지
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildSingleEmotionGraph(
    String emotion,
    Color color,
    List<DailyEmotionScore> scores,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            emotion.toUpperCase(),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: LineChart(
              LineChartData(
                minX: 0,
                maxX: (scores.length - 1).toDouble(),
                clipData: FlClipData.all(),
                minY: 0,
                maxY: 1,
                gridData: FlGridData(
                  show: true,
                  horizontalInterval: 0.25,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: Colors.grey.withOpacity(0.3),
                    strokeWidth: 0.5,
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 0.25,
                      getTitlesWidget: (value, meta) => Text(
                        value.toStringAsFixed(2),
                        style: const TextStyle(fontSize: 10),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        int index = value.toInt();
                        if (index < 0 || index >= scores.length)
                          return const SizedBox.shrink();
                        return Text(
                          (index + 1).toString(),
                          style: const TextStyle(fontSize: 10),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: const Border(
                    bottom: BorderSide(color: Colors.grey, width: 1),
                    left: BorderSide(color: Colors.grey, width: 1),
                    right: BorderSide(color: Colors.transparent),
                    top: BorderSide(color: Colors.transparent),
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: scores
                        .asMap()
                        .entries
                        .map(
                          (e) => FlSpot(
                            e.key.toDouble().clamp(
                              0,
                              (scores.length - 1).toDouble(),
                            ),
                            getEmotionValue(e.value, emotion), // 선택한 감정만
                          ),
                        )
                        .toList(),
                    isCurved: true,
                    curveSmoothness: 0.7,
                    color: color, // 선택한 감정 색상
                    barWidth: 2,
                    dotData: FlDotData(show: false),
                    belowBarData: BarAreaData(show: false),
                    preventCurveOverShooting: true,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  double getEmotionValue(DailyEmotionScore score, String emotion) {
    switch (emotion) {
      case 'happy':
        return score.happy;
      case 'sad':
        return score.sad;
      case 'angry':
        return score.angry;
      case 'fear':
        return score.fear;
      case 'tender':
        return score.tender;
      default:
        return 0;
    }
  }
}
