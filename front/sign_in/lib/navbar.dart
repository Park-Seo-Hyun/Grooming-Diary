import 'package:flutter/material.dart';

class CustomBottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onTap;

  const CustomBottomNavBar({
    super.key,
    required this.selectedIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF5A9AFF);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFEEEEEE), width: 7.0)),
      ),
      height: 65,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          IconButton(
            onPressed: () => onTap(0),
            icon: Image.asset(
              'assets/calendar.png',
              height: 38,
              color: selectedIndex == 0
                  ? primaryColor
                  : const Color(0xFFD9D9D9),
            ),
          ),
          IconButton(
            onPressed: () => onTap(1),
            icon: Image.asset(
              'assets/graph.png',
              height: 38,
              color: selectedIndex == 1
                  ? primaryColor
                  : const Color(0xFFD9D9D9),
            ),
          ),
          IconButton(
            onPressed: () => onTap(2),
            icon: Image.asset(
              'assets/write.png',
              height: 38,
              color: selectedIndex == 2
                  ? primaryColor
                  : const Color(0xFFD9D9D9),
            ),
          ),
          IconButton(
            onPressed: () => onTap(3),
            icon: Image.asset(
              'assets/mypage.png',
              height: 38,
              color: selectedIndex == 3
                  ? primaryColor
                  : const Color(0xFFD9D9D9),
            ),
          ),
        ],
      ),
    );
  }
}
