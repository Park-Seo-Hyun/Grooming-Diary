import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import '../../services/graph_service.dart';
import 'models/monthly_graph.dart';

class BarGraphWidget extends StatelessWidget {
  final List<EmotionState> emotionState;

  const BarGraphWidget({super.key, required this.emotionState});

  @override
  Widget build(BuildContext context) {
    return SfCartesianChart(
      // 원래 그래프 코드 그대로
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
        majorTickLines: const MajorTickLines(width: 0),
        majorGridLines: const MajorGridLines(width: 0),
        axisLine: const AxisLine(width: 1),
      ),
      primaryYAxis: NumericAxis(
        isVisible: false,
        majorGridLines: const MajorGridLines(width: 0),
        axisLine: const AxisLine(width: 0),
        minimum: 0,
        maximum:
            (emotionState
                .map((e) => e.emotionCnt)
                .reduce((a, b) => a > b ? a : b)
                .toDouble()) *
            1.4,
      ),
      series: <ColumnSeries<EmotionState, String>>[
        ColumnSeries<EmotionState, String>(
          dataSource: emotionState,
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
            labelAlignment: ChartDataLabelAlignment.outer,
            builder: (data, point, series, pointIndex, seriesIndex) {
              final EmotionState e = data as EmotionState;
              final imageUrl = GraphService.baseUrl + e.emotionEmoji;
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.sentiment_neutral, size: 16),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF1D9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      e.emotionCnt.toString(),
                      style: const TextStyle(
                        fontSize: 10,
                        fontFamily: 'Pretendard',
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}
