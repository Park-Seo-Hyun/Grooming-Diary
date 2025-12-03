import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class MyPageService {
  final AuthService authService;

  MyPageService({required this.authService});

  /// 📝 마이페이지 정보 불러오기
  Future<Map<String, dynamic>?> fetchMyPageData() async {
    try {
      final token = await authService.getToken();
      if (token == null) {
        print('❌ JWT가 없습니다. 로그인 필요');
        return null;
      }

      final url = Uri.parse('${authService.baseUrl}/api/mypage');
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data;
      } else {
        print('❌ 마이페이지 불러오기 실패: ${response.body}');
        return null;
      }
    } catch (e) {
      print('❌ 마이페이지 요청 오류: $e');
      return null;
    }
  }
}
