import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'models/monthly_graph.dart';

class DoughnutGraphWidgetFL extends StatelessWidget {
  final List<EmotionState> emotionState;

  const DoughnutGraphWidgetFL({super.key, required this.emotionState});

  @override
  Widget build(BuildContext context) {
    if (emotionState.isEmpty) {
      return SizedBox(
        height: 200,
        child: Center(
          child: Text(
            "감정을 기다리고 있어요!",
            style: const TextStyle(
              fontSize: 16,
              fontFamily: 'GyeonggiBatang',
              color: Colors.black,
            ),
          ),
        ),
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1️⃣ 원형 그래프
        Expanded(
          flex: 2,
          child: SizedBox(
            height: 250,
            child: PieChart(
              PieChartData(
                sectionsSpace: 0,
                centerSpaceRadius: 30, // 도넛 형태
                sections: emotionState.where((e) => e.emotionPercent > 0).map((
                  e,
                ) {
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
                  final isSmall = e.emotionPercent < 5;
                  return PieChartSectionData(
                    value: e.emotionPercent.toDouble(),
                    color: color,
                    radius: 60,
                    title: e.emotionPercent == 0 ? '' : "${e.emotionPercent}%",
                    titleStyle: TextStyle(
                      fontSize: 15,
                      fontFamily: 'Pretendard',
                      fontWeight: FontWeight.bold,
                      color: isSmall ? Colors.black : Colors.white,
                    ),
                    titlePositionPercentageOffset: 0.6,
                  );
                }).toList(),
              ),
              swapAnimationDuration: const Duration(milliseconds: 400),
              swapAnimationCurve: Curves.easeInOut,
            ),
          ),
        ),

        const SizedBox(width: 16),

        // 2️⃣ 감정 설명 박스
        Expanded(
          flex: 1,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: emotionState.map((e) {
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
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(4),
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
    );
  }
}
