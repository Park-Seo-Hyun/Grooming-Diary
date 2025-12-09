import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'models/monthly_graph.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

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
    'happy': Color(0xFFFFAEAE),
    'sad': Color(0xFF5A9AFF),
    'angry': Color(0xFFBB79DF),
    'fear': Color(0xFF51D383),
    'tender': Color(0xFFF8F815),
    'neutral': Color(0xFFFFBB8A),
  };

  int get pageCount => emotions.length + 1;

  late int initialPage;

  @override
  void initState() {
    super.initState();
    initialPage = 1000 - (1000 % pageCount);
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

    // 오늘 이후 날짜 제외
    final filteredScores = widget.dailyEmotionScores
        .where((e) => !e.date.isAfter(today))
        .toList();

    if (filteredScores.isEmpty) {
      return SizedBox(
        height: 300.h,
        child: Center(child: Text("그래프 데이터가 없습니다.")),
      );
    }

    // X축 전체 날짜 (1일부터 말일까지)
    final monthDays = List<int>.generate(
      widget.dailyEmotionScores.last.date.day,
      (i) => i,
    );

    return SizedBox(
      height: 300.h,
      width: double.infinity,
      child: PageView.builder(
        controller: _pageController,
        itemBuilder: (context, index) {
          final pageIndex = index % pageCount;

          if (pageIndex == 0) {
            return _buildCombinedGraph(filteredScores, monthDays);
          } else {
            final emotion = emotions[pageIndex - 1];
            return _buildSingleEmotionGraph(
              emotion,
              colors[emotion]!,
              filteredScores,
              monthDays,
            );
          }
        },
      ),
    );
  }

  Widget _buildCombinedGraph(
    List<DailyEmotionScore> scores,
    List<int> monthDays,
  ) {
    return Container(
      padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 16.h),
      margin: EdgeInsets.symmetric(horizontal: 0.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5.r,
            offset: Offset(0.w, 2.h),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            "전체",
            style: TextStyle(
              color: Color(0xFF929292),
              fontFamily: 'GyeonggiTitle',
              fontSize: 16.sp,
            ),
          ),
          SizedBox(height: 4.h),
          Expanded(
            child: LineChart(
              LineChartData(
                minX: 0,
                maxX: (monthDays.length - 1).toDouble(),
                minY: 0,
                maxY: 1,
                clipData: FlClipData.all(),
                gridData: FlGridData(
                  show: true,
                  horizontalInterval: 0.25,
                  drawVerticalLine: true,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: Colors.grey.withOpacity(0.3),
                    strokeWidth: 0.5.w,
                    dashArray: [4, 4],
                  ),
                  getDrawingVerticalLine: (value) => FlLine(
                    color: Colors.grey.withOpacity(0.3),
                    strokeWidth: 0.5.w,
                    dashArray: [4, 4],
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 0.25,
                      getTitlesWidget: (value, meta) => Text(
                        value.toStringAsFixed(2),
                        style: TextStyle(fontSize: 10.sp),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 5,
                      getTitlesWidget: (value, meta) {
                        int idx = value.toInt();
                        if (idx < 0 || idx >= monthDays.length) {
                          return SizedBox.shrink();
                        }
                        return Text(
                          monthDays[idx].toString(),
                          style: TextStyle(fontSize: 10.sp),
                        );
                      },
                    ),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border(
                    bottom: BorderSide(color: Colors.grey, width: 1.w),
                    left: BorderSide(color: Colors.grey, width: 1.w),
                    right: BorderSide(color: Colors.transparent),
                    top: BorderSide(color: Colors.transparent),
                  ),
                ),
                lineBarsData: emotions.map((emotion) {
                  final emotionSpots = scores
                      .asMap()
                      .entries
                      .map(
                        (e) => FlSpot(
                          e.value.date.day - 1.toDouble(),
                          getEmotionValue(e.value, emotion),
                        ),
                      )
                      .toList();

                  return LineChartBarData(
                    spots: emotionSpots,
                    isCurved: true,
                    color: colors[emotion]!,
                    barWidth: 2.w,
                    dotData: FlDotData(show: false),
                    belowBarData: BarAreaData(show: false),
                    preventCurveOverShooting: true,
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSingleEmotionGraph(
    String emotion,
    Color color,
    List<DailyEmotionScore> scores,
    List<int> monthDays,
  ) {
    final emotionKorean = {
      'happy': '행복',
      'sad': '슬픔',
      'angry': '화남',
      'fear': '두려움',
      'tender': '불안',
    };

    return Container(
      padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 16.h),
      margin: EdgeInsets.symmetric(horizontal: 0.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5.r,
            offset: Offset(0.w, 2.h),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            emotionKorean[emotion] ?? emotion,
            style: TextStyle(
              color: Color(0xFF929292),
              fontFamily: 'GyeonggiTitle',
              fontSize: 16.sp,
            ),
          ),
          SizedBox(height: 4.h),
          Expanded(
            child: LineChart(
              LineChartData(
                minX: 0,
                maxX: (monthDays.length - 1).toDouble(),
                minY: 0,
                maxY: 1,
                clipData: FlClipData.all(),
                gridData: FlGridData(
                  show: true,
                  horizontalInterval: 0.25,
                  drawVerticalLine: true,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: Colors.grey.withOpacity(0.5),
                    strokeWidth: 0.7.w,
                    dashArray: [4, 4],
                  ),
                  getDrawingVerticalLine: (value) => FlLine(
                    color: Colors.grey.withOpacity(0.5),
                    strokeWidth: 0.7.w,
                    dashArray: [4, 4],
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 0.25,
                      getTitlesWidget: (value, meta) => Text(
                        value.toStringAsFixed(2),
                        style: TextStyle(fontSize: 10.sp),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 5,
                      getTitlesWidget: (value, meta) {
                        int idx = value.toInt();
                        if (idx < 0 || idx >= monthDays.length)
                          return SizedBox.shrink();
                        return Text(
                          monthDays[idx].toString(),
                          style: TextStyle(fontSize: 10.sp),
                        );
                      },
                    ),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border(
                    bottom: BorderSide(color: Colors.grey, width: 1.w),
                    left: BorderSide(color: Colors.grey, width: 1.w),
                    right: BorderSide(color: Colors.transparent),
                    top: BorderSide(color: Colors.transparent),
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: scores
                        .where((e) => !e.date.isAfter(DateTime.now()))
                        .map(
                          (e) => FlSpot(
                            e.date.day - 1.toDouble(),
                            getEmotionValue(e, emotion),
                          ),
                        )
                        .toList(),
                    isCurved: true,
                    curveSmoothness: 0.7,
                    color: color,
                    barWidth: 2.w,
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
