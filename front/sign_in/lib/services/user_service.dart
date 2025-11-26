import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class UserService {
  // 1. 싱글톤 패턴 적용
  UserService._privateConstructor();
  static final UserService instance = UserService._privateConstructor();

  // 2. FlutterSecureStorage 인스턴스
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // 3. 내부 캐싱
  String? _userName;

  /// 로그인 후 사용자 이름 저장
  Future<void> setUserName(String name) async {
    _userName = name; // 캐시에 저장
    await _storage.write(key: 'user_name', value: name); // storage에 저장
    print('🔹 UserService: 사용자 이름 저장됨: $name'); // 디버깅
  }

  /// 사용자 이름 가져오기
  Future<String?> getUserName() async {
    if (_userName != null) {
      print('🔹 UserService: 캐시에서 이름 가져옴: $_userName'); // 디버깅
      return _userName; // 캐시에 있으면 바로 반환
    }

    // storage에서 읽기
    _userName = await _storage.read(key: 'user_name');
    print('🔹 UserService: storage에서 이름 가져옴: $_userName'); // 디버깅
    return _userName;
  }

  /// 로그아웃 시 사용자 정보 삭제
  Future<void> clearUser() async {
    _userName = null;
    await _storage.delete(key: 'user_name');
    print('🔹 UserService: 사용자 정보 삭제됨');
  }
}
