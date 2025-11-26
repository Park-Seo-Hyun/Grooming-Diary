import 'package:flutter/material.dart';

class MyPage extends StatelessWidget {
  const MyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 25), // 필요 최소 여백
        const Center(
          child: Text(
            "마이 페이지",
            style: TextStyle(
              fontFamily: 'Gyeonggibatang',
              fontSize: 32,
              color: Color(0xFF1A6DFF),
            ),
          ),
        ),
        const SizedBox(height: 10), // 너무 크지 않게 조정
        // 여기에 그래프 위젯 등 화면 내용 추가 가능
      ],
    );
  }
}
