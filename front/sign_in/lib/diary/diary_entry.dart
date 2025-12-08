import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:sign_in/diary/diary_entry_detail.dart';

class DiaryEntry {
  final String id;
  final DateTime date;
  final String? emojiUrl; // 네트워크 이미지 URL
  final String? text; // 서버의 content
  final String? aiComment;
  final String userName;

  DiaryEntry({
    required this.id,
    required this.date,
    this.emojiUrl,
    this.text,
    this.aiComment,
    required this.userName,
  });

  // DiaryEntryDetail → DiaryEntry 변환용
  factory DiaryEntry.fromDetail(DiaryEntryDetail detail) {
    return DiaryEntry(
      id: detail.id,
      date: detail.date,
      emojiUrl: detail.imageUrl, // URL로 가져오기
      text: detail.text,
      aiComment: detail.aiComment,
      userName: detail.userName,
    );
  }

  // JSON → DiaryEntry (네트워크 URL 전용)
  factory DiaryEntry.fromJson(Map<String, dynamic> json) {
    // 날짜 파싱
    DateTime parsedDate;
    try {
      parsedDate = DateTime.parse(json['diary_date']?.toString() ?? '');
    } catch (_) {
      parsedDate = DateTime.now();
    }

    // BASE_URL + 상대 경로 처리
    final String baseUrl = dotenv.env['BASE_URL'] ?? 'http://localhost:3000';
    String? emojiUrl =
        json['emotion_emoji']?.toString() ??
        json['primary_image_url']?.toString();

    if (emojiUrl != null && !emojiUrl.startsWith('http')) {
      // 상대 경로이면 BASE_URL 붙이기
      emojiUrl = '$baseUrl$emojiUrl';
    }

    return DiaryEntry(
      id: json['id']?.toString() ?? '',
      date: parsedDate,
      emojiUrl: emojiUrl,
      text: json['content']?.toString() ?? '',
      aiComment: json['ai_comment']?.toString(),
      userName: json['user_name']?.toString() ?? '사용자',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'diary_date': date.toIso8601String(),
      'primary_image_url': emojiUrl,
      'content': text,
      'ai_comment': aiComment,
      'user_name': userName,
    };
  }
}
