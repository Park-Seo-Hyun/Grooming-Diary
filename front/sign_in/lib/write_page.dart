import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:sign_in/chat_page.dart';
import 'services/auth_service.dart';

class WritePage extends StatefulWidget {
  WritePage({super.key}); // const 제거

  @override
  State<WritePage> createState() => _WritePageState();
}

class _WritePageState extends State<WritePage> {
  Map<String, dynamic>? todayQuestion;
  List<Map<String, dynamic>> pastAnswers = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchQuestions();
  }

  Future<void> fetchQuestions() async {
    setState(() {
      isLoading = true;
    });

    try {
      final String baseUrl = dotenv.env['BASE_URL']!;
      final String? token = await AuthService().getToken();

      if (token == null) {
        print('토큰이 없음! 로그인 확인 필요');
        setState(() {
          isLoading = false;
        });
        return;
      }

      final url = Uri.parse('$baseUrl/api/positive/main');

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['current_question'] != null &&
            data['current_question']['question'] != null) {
          todayQuestion = Map<String, dynamic>.from(
            data['current_question']['question'],
          );
        } else {
          todayQuestion = null;
        }

        if (data['past_answers'] != null) {
          pastAnswers = List<Map<String, dynamic>>.from(data['past_answers']);
        } else {
          pastAnswers = [];
        }

        if (todayQuestion != null) {
          pastAnswers.removeWhere((item) => item['id'] == todayQuestion!['id']);
        }
      } else {
        print('서버 오류: ${response.body}');
      }
    } catch (e) {
      print('데이터 가져오기 오류: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void openChat(Map<String, dynamic> question, {String mode = "write"}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatPage(
          questionId: question['id'],
          questionText: question['text'],
          questionNumber: question['question_number'],
          mode: mode,
        ),
      ),
    ).then((_) => fetchQuestions());
  }

  Widget buildQuestionLine(int number, String text, double maxWidth) {
    TextSpan hashSpan = const TextSpan(
      text: "   #",
      style: TextStyle(
        fontFamily: 'GyeonggiTitle',
        fontSize: 17,
        color: Color(0xFF1A6DFF),
        fontWeight: FontWeight.bold,
        fontStyle: FontStyle.italic,
      ),
    );

    TextSpan numberSpan = TextSpan(
      text: " ${number.toString().padLeft(2, '0')}   ",
      style: const TextStyle(
        fontFamily: 'GyeonggiTitle',
        fontSize: 22,
        color: Color(0xFF1A6DFF),
        fontWeight: FontWeight.bold,
        fontStyle: FontStyle.italic,
      ),
    );

    TextStyle textStyle = const TextStyle(
      fontFamily: 'GyeonggiBatang',
      fontSize: 15,
      color: Color(0xFF434343),
    );

    final numberPainter = TextPainter(
      text: TextSpan(children: [hashSpan, numberSpan]),
      maxLines: 1,
      textDirection: TextDirection.ltr,
    );
    numberPainter.layout();
    double availableWidth = maxWidth - numberPainter.width;

    String displayText = text;
    final tp = TextPainter(
      text: TextSpan(text: displayText, style: textStyle),
      maxLines: 1,
      textDirection: TextDirection.ltr,
    );
    tp.layout(maxWidth: availableWidth);
    if (tp.didExceedMaxLines) {
      int endIndex = text.length;
      while (endIndex > 0) {
        final checkTp = TextPainter(
          text: TextSpan(
            text: text.substring(0, endIndex) + '...',
            style: textStyle,
          ),
          maxLines: 1,
          textDirection: TextDirection.ltr,
        );
        checkTp.layout(maxWidth: availableWidth);
        if (!checkTp.didExceedMaxLines) break;
        endIndex--;
      }
      displayText = text.substring(0, endIndex) + '...';
    }

    return RichText(
      text: TextSpan(
        children: [
          hashSpan,
          numberSpan,
          WidgetSpan(
            child: Transform.translate(
              offset: const Offset(0, 2),
              child: Text(displayText, style: textStyle),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final maxWidth = MediaQuery.of(context).size.width - 55;

    return isLoading
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Center(
                  child: Text(
                    "긍정 이야기",
                    style: TextStyle(
                      fontFamily: 'GyeonggiBatang',
                      fontSize: 32,
                      color: Color(0xFF1A6DFF),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                if (todayQuestion != null)
                  GestureDetector(
                    onTap: () => openChat(todayQuestion!, mode: "write"),
                    child: buildQuestionLine(
                      todayQuestion!['question_number'] ?? 0,
                      todayQuestion!['text'] ?? '',
                      maxWidth,
                    ),
                  ),
                const SizedBox(height: 25),
                ...pastAnswers.map(
                  (answer) => Container(
                    margin: const EdgeInsets.symmetric(vertical: 20),
                    child: GestureDetector(
                      onTap: () => openChat(answer, mode: "view"),
                      child: buildQuestionLine(
                        answer['question_number'] ?? 0,
                        answer['text'] ?? '',
                        maxWidth,
                      ),
                    ),
                  ),
                ),
                if (todayQuestion == null && pastAnswers.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text('질문이 없습니다.', style: TextStyle(fontSize: 18)),
                    ),
                  ),
                const SizedBox(height: 50),
              ],
            ),
          );
  }
}
