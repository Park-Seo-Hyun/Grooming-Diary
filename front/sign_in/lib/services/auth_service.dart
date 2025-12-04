import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AuthService {
  final storage = const FlutterSecureStorage();
  final String baseUrl = dotenv.env['BASE_URL']!;

  /// 🔐 로그인
  Future<bool> login({required String userId, required String userPwd}) async {
    try {
      final url = Uri.parse('$baseUrl/auth/login');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({"user_id": userId, "user_pwd": userPwd}),
      );

      print('🔹 서버 응답 상태: ${response.statusCode}');
      print('🔹 서버 응답 바디: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final token = data['token']?['access_token'];

        if (token != null && token.isNotEmpty) {
          await storage.write(key: 'jwt', value: token);
          print('✅ 로그인 성공(JWT 저장됨)');
          return true;
        } else {
          print('❌ 서버에 토큰이 없습니다.');
          return false;
        }
      } else {
        print('❌ 로그인 실패: ${response.body}');
        return false;
      }
    } catch (e) {
      print('❌ 로그인 오류: $e');
      return false;
    }
  }

  /// 📝 회원가입 요청
  Future<Map<String, dynamic>> register({
    required String userName,
    required String userId,
    required String userPwd,
    required String birthDate,
    required String gender,
  }) async {
    try {
      final apiGender = (gender == "남성") ? "M" : "F";
      final url = Uri.parse('$baseUrl/auth/register');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "user_name": userName,
          "user_id": userId,
          "user_pwd": userPwd,
          "birth_date": birthDate,
          "gender": apiGender,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {"success": true};
      } else if (response.statusCode == 409) {
        // 중복 아이디 에러 처리
        return {"success": false, "message": "USER_ALREADY_EXISTS"};
      } else {
        return {"success": false, "message": response.body};
      }
    } catch (e) {
      return {"success": false, "message": e.toString()};
    }
  }

  /// 🔎 아이디 중복 확인 (GET /auth/check-id?user_id=입력값)
  Future<Map<String, dynamic>> checkDuplicateId(String userId) async {
    try {
      final url = Uri.parse(
        '$baseUrl/auth/check_id?user_id=$userId',
      ); // 쿼리 파라미터
      final response = await http.get(
        url,
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          "is_available": data['is_available'] ?? false,
          "message": data['message'] ?? "",
        };
      } else {
        return {"is_available": false, "message": "서버 오류"};
      }
    } catch (e) {
      return {"is_available": false, "message": e.toString()};
    }
  }

  Future<String?> getToken() async => await storage.read(key: 'jwt');

  Future<void> logout() async {
    await storage.delete(key: 'jwt');
    print('🔒 로그아웃 완료 (JWT 삭제)');
  }
}

extension AuthServiceExtension on AuthService {
  /// 🗑 회원 탈퇴
  Future<bool> deleteAccount() async {
    try {
      final token = await getToken();
      if (token == null) {
        print('❌ JWT가 없습니다. 로그인이 필요합니다.');
        return false;
      }

      final url = Uri.parse('$baseUrl/auth/unsubscribe'); // 서버 경로 확인 필요
      final response = await http.delete(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        await logout(); // 탈퇴 후 JWT 삭제
        print('✅ 회원 탈퇴 성공');
        return true;
      } else {
        print('❌ 회원 탈퇴 실패: ${response.body}');
        return false;
      }
    } catch (e) {
      print('❌ 회원 탈퇴 오류: $e');
      return false;
    }
  }
}
