// diary_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'auth_service.dart';

class DiaryService {
  // .env에서 BASE_URL 읽기 (없으면 로컬호스트 기본값)
  final String baseUrl = dotenv.env['BASE_URL'] ?? 'http://localhost:3000';
  final AuthService _authService = AuthService();

  // 헤더 생성 (Bearer Token 포함)
  Future<Map<String, String>> _getHeaders() async {
    String? token = await _authService.getToken();
    if (token == null) {
      throw Exception("로그인 토큰이 없습니다. 다시 로그인해주세요.");
    }
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // 월별 일기 가져오기
  Future<Map<String, dynamic>> getMonthlyDiaries(String monthlyYear) async {
    final url = Uri.parse('$baseUrl/api/diaries/main/$monthlyYear');
    try {
      final headers = await _getHeaders();
      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final decodedBody = utf8.decode(response.bodyBytes);
        return jsonDecode(decodedBody) as Map<String, dynamic>;
      } else {
        final errorBody = utf8.decode(response.bodyBytes);
        throw Exception('월별 데이터 로드 실패 (${response.statusCode}): $errorBody');
      }
    } catch (e) {
      print("❌ getMonthlyDiaries 서비스 에러 발생: $e");
      throw Exception('서버 연결 오류: $e');
    }
  }

  // 일기 상세 조회 (API 명세: /api/diaries/detail/{id})
  Future<Map<String, dynamic>> getDiaryById(String id) async {
    if (id.isEmpty) {
      throw Exception('빈 id로 상세조회 시도됨');
    }

    final url = Uri.parse('$baseUrl/api/diaries/detail/$id');

    try {
      final headers = await _getHeaders();
      print('🔍 일기 상세 요청 URL: $url'); // 디버깅용 로그

      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final decodedBody = utf8.decode(response.bodyBytes);
        final decodedJson = jsonDecode(decodedBody) as Map<String, dynamic>;
        return decodedJson;
      } else {
        final errorBody = utf8.decode(response.bodyBytes);
        print('⚠️ API 오류 응답(${response.statusCode}): $errorBody');
        throw Exception('일기 상세 조회 실패 (${response.statusCode}): $errorBody');
      }
    } catch (e) {
      print("❌ getDiaryById 에러: $e");
      rethrow;
    }
  }

  // 일기 생성
  Future<Map<String, dynamic>> createDiary(
    Map<String, String> fields,
    File? imageFile,
  ) async {
    final url = Uri.parse('$baseUrl/api/diaries/new');
    final request = http.MultipartRequest('POST', url);

    String? token = await _authService.getToken();
    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    request.fields.addAll(fields);
    if (imageFile != null) {
      request.files.add(
        await http.MultipartFile.fromPath('image', imageFile.path),
      );
    }

    final streamResponse = await request.send();
    final response = await http.Response.fromStream(streamResponse);

    if (response.statusCode == 200 || response.statusCode == 201) {
      final decodedBody = utf8.decode(response.bodyBytes);
      return jsonDecode(decodedBody) as Map<String, dynamic>;
    } else {
      final errorBody = utf8.decode(response.bodyBytes);
      throw Exception('일기 작성 실패 (${response.statusCode}): $errorBody');
    }
  }

  // 일기 수정
  Future<Map<String, dynamic>> updateDiary(
    String id,
    Map<String, String> fields,
    File? imageFile,
  ) async {
    final url = Uri.parse('$baseUrl/api/diaries/modify/$id');
    final request = http.MultipartRequest('PUT', url);

    String? token = await _authService.getToken();
    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    request.fields.addAll(fields);
    if (imageFile != null) {
      request.files.add(
        await http.MultipartFile.fromPath('image', imageFile.path),
      );
    }

    final streamResponse = await request.send();
    final response = await http.Response.fromStream(streamResponse);

    if (response.statusCode == 200) {
      final decodedBody = utf8.decode(response.bodyBytes);
      return jsonDecode(decodedBody) as Map<String, dynamic>;
    } else {
      final errorBody = utf8.decode(response.bodyBytes);
      throw Exception('일기 수정 실패 (${response.statusCode}): $errorBody');
    }
  }

  // 일기 삭제
  Future<bool> deleteDiary(String id) async {
    final url = Uri.parse('$baseUrl/api/diaries/$id');
    final headers = await _getHeaders();

    final response = await http.delete(url, headers: headers);

    // 200 또는 204 모두 성공으로 처리
    if (response.statusCode == 200 || response.statusCode == 204) return true;

    print(
      '⚠️ deleteDiary 실패 (${response.statusCode}): ${utf8.decode(response.bodyBytes)}',
    );
    return false;
  }
}
