import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../graph/models/monthly_graph.dart';

class GraphService {
  static final String baseUrl = dotenv.env['BASE_URL']!;
  final storage = const FlutterSecureStorage();

  Future<MonthlyGraphData?> getMonthlyGraphData(String yearMonth) async {
    try {
      // 🔑 AuthService에서 저장한 jwt 키로 읽기
      String? accessToken = await storage.read(key: 'jwt');

      if (accessToken == null) {
        print("토큰이 없습니다. 로그인이 필요합니다.");
        return null;
      }

      final response = await http.get(
        Uri.parse("$baseUrl/api/graphs/monthly/$yearMonth"),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      );

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(utf8.decode(response.bodyBytes));
        return MonthlyGraphData.fromJson(jsonData);
      } else {
        print("Error: ${response.statusCode} - ${response.body}");
        return null;
      }
    } catch (e) {
      print("GraphService Error: $e");
      return null;
    }
  }
}
