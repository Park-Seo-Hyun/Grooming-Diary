import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:sign_in/diary/diary_entry_detail.dart';

class DiaryEntry {
  final String id;
  final DateTime date;
  final String? emoji; // 홈페이지용 이미지/이모지
  final String? text; // 서버의 content
  final String? aiComment;
  final String userName;

  DiaryEntry({
    required this.id,
    required this.date,
    this.emoji,
    this.text,
    this.aiComment,
    required this.userName,
  });

  factory DiaryEntry.fromDetail(DiaryEntryDetail detail) {
    // DiaryEntryDetail → DiaryEntry 변환용
    return DiaryEntry(
      id: detail.id,
      date: detail.date,
      emoji: detail.imageUrl, // 홈페이지는 base64/URL 그대로
      text: detail.text,
      aiComment: detail.aiComment,
      userName: detail.userName,
    );
  }

  factory DiaryEntry.fromJson(Map<String, dynamic> json) {
    DateTime parsedDate;
    try {
      parsedDate = DateTime.parse(json['diary_date']?.toString() ?? '');
    } catch (_) {
      parsedDate = DateTime.now();
    }

    return DiaryEntry(
      id: json['id']?.toString() ?? '',
      date: parsedDate,
      emoji: json['primary_image_url']?.toString(),
      text: json['content']?.toString() ?? '',
      aiComment: json['ai_comment']?.toString(),
      userName: json['user_name']?.toString() ?? '사용자',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'diary_date': date.toIso8601String(),
      'primary_image_url': emoji,
      'content': text,
      'ai_comment': aiComment,
      'user_name': userName,
    };
  }
}
