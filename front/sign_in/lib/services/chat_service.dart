import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class ChatService {
  final String baseUrl = dotenv.env['BASE_URL']!.trim();

  // 답변 가져오기 (String 반환)
  Future<String?> fetchAnswer(String questionId, String mode) async {
    final String? token = await AuthService().getToken();
    if (token == null) return null;

    Uri url;
    if (mode == "write") {
      url = Uri.parse('$baseUrl/api/positive/question'); // 새 질문용 (임시)
    } else {
      url = Uri.parse('$baseUrl/api/positive/answers/$questionId'); // 과거 답 조회
    }

    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['answer'] as String?; // 서버 응답 구조에 맞게 'answer' 키 사용
    } else {
      print('서버 오류: ${response.body}');
      return null;
    }
  }

  // 새 답 저장
  Future<bool> saveAnswer(String questionId, String answer) async {
    final String? token = await AuthService().getToken();
    if (token == null) return false;

    final url = Uri.parse('$baseUrl/api/positive/answer');
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'question_id': questionId, 'answer': answer}),
    );

    return response.statusCode == 200 || response.statusCode == 201;
  }

  // 답 수정
  Future<bool> modifyAnswer(String questionId, String answer) async {
    final String? token = await AuthService().getToken();
    if (token == null) return false;

    final url = Uri.parse('$baseUrl/api/positive/modify/$questionId');
    final response = await http.put(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'answer': answer}),
    );

    return response.statusCode == 200;
  }
}
