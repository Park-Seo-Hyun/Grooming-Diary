import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class GraphPage extends StatefulWidget {
  const GraphPage({super.key});

  @override
  State<GraphPage> createState() => _GraphPageState();
}

class _GraphPageState extends State<GraphPage> {
  // 현재 선택된 기간 (0: 주간, 1: 월간, 2: 연간)
  int _selectedPeriod = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 40, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTitle(),
              const SizedBox(height: 20),
              _buildPeriodSelector(),
              const SizedBox(height: 20),
              // 📊 막대 그래프 (숫자 제거됨)
              _buildBarChart(),
              const SizedBox(height: 30),
              // 🥯 도넛 차트
              _buildPieChart(),
            ],
          ),
        ),
      ),
    );
  }

  // 상단 제목
  Widget _buildTitle() {
    return const Center(
      child: Text(
        "감정 그래프",
        style: TextStyle(
          fontFamily: 'Gyeonggibatang',
          fontSize: 32,
          color: Color(0xFF1A6DFF),
        ),
      ),
    );
  }

  // 주간/월간/연간 버튼 선택기
  Widget _buildPeriodSelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildPeriodButton("주간", 0),
        _buildPeriodButton("월간", 1),
        _buildPeriodButton("연간", 2),
      ],
    );
  }

  Widget _buildPeriodButton(String text, int index) {
    bool isSelected = _selectedPeriod == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPeriod = index;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
        margin: const EdgeInsets.symmetric(horizontal: 5),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFB9D4FF)
              : Color(0xFFEDF4FF), // 선택된 버튼 색상 변경
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isSelected ? Colors.white : Color(0xFF827C7C),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // 📊 감정 막대그래프
  Widget _buildBarChart() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFFF7F7F7),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      height: 280,
      child: BarChart(
        BarChartData(
          // Y축 최대값 설정 (데이터 최대값 3 + 여유 공간 1)
          maxY: 4,

          barTouchData: BarTouchData(enabled: false),

          // 가로축 (감정 라벨) 설정
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                getTitlesWidget: (value, meta) {
                  switch (value.toInt()) {
                    case 0:
                      return const Text("행복", style: TextStyle(fontSize: 12));
                    case 1:
                      return const Text("평온", style: TextStyle(fontSize: 12));
                    case 2:
                      return const Text("슬픔", style: TextStyle(fontSize: 12));
                    case 3:
                      return const Text("불안", style: TextStyle(fontSize: 12));
                    case 4:
                      return const Text("화남", style: TextStyle(fontSize: 12));
                    default:
                      return const Text("");
                  }
                },
              ),
            ),
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),

          gridData: FlGridData(show: false),
          borderData: FlBorderData(show: false),

          // 막대 그룹 (숫자 제거를 위해 _bar 함수 사용)
          barGroups: [
            _bar(0, 3, const Color(0xFFFFAEAE)), // 행복 (3)
            _bar(1, 2, const Color(0xFFF9F969)), // 평온 (2)
            _bar(2, 1, const Color(0xFF5A9AFF)), // 슬픔 (1)
            _bar(3, 1, const Color(0xFF51D383)), // 불안 (1)
            _bar(4, 0, const Color(0xFFCA57E4)), // 화남 (0)
          ],
        ),
      ),
    );
  }

  // 막대 위에 아무것도 표시하지 않는 기본 막대 그룹 함수
  BarChartGroupData _bar(int x, double y, Color color) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          width: 18, // 굵기(너비) 설정
          color: color,
          borderRadius: BorderRadius.circular(4),

          // getBadges 속성을 제거하여 숫자 표시를 없앰
        ),
      ],
    );
  }

  // 🥯 도넛 차트
  Widget _buildPieChart() {
    // 임시 데이터 (총 100% 기준으로 비율 계산)
    final double happy = 40;
    final double calm = 30;
    final double joy = 20;
    final double anxiety = 10;
    final totalValue = happy + calm + joy + anxiety;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFFF7F7F7),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      height: 260,
      child: Stack(
        alignment: Alignment.center,
        children: [
          PieChart(
            PieChartData(
              sectionsSpace: 4,
              centerSpaceRadius: 70, // 도넛 차트 중앙 빈 공간 크기
              sections: [
                _pie(happy, const Color(0xFFFFAEAE), '행복'),
                _pie(calm, const Color(0xFFF9F969), '평온'),
                _pie(joy, const Color(0xFF5A9AFF), '기쁨'),
                _pie(anxiety, const Color(0xFF51D383), '불안'),
              ],
            ),
          ),
          // 중앙 텍스트 (총합)
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '총 합',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              Text(
                '${totalValue.toStringAsFixed(0)}%',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A6DFF),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 도넛 차트 섹션 데이터 생성 함수
  PieChartSectionData _pie(double value, Color color, String titleText) {
    final double percentage = value; // 값 자체가 퍼센트라고 가정

    return PieChartSectionData(
      value: value,
      color: color,
      radius: 40, // 섹션의 반지름 (도넛 두께)
      title: '${percentage.toStringAsFixed(0)}%', // 섹션 위에 퍼센트 표시
      titleStyle: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    );
  }
}
