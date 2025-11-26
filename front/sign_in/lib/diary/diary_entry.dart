// diary_entry.dart
import 'dart:convert';

class DiaryEntry {
  final String id;
  final DateTime date;
  final String? emoji; // 서버에서 내려오는 base64 문자열 또는 URL 또는 로컬 경로
  final String? text; // 서버의 content
  final String? aiComment;
  final String userName; // 사용자 이름

  DiaryEntry({
    required this.id,
    required this.date,
    this.emoji,
    this.text,
    this.aiComment,
    required this.userName,
  });

  factory DiaryEntry.fromJson(Map<String, dynamic> json) {
    // 날짜 파싱: 안전하게 처리
    DateTime parsedDate;
    try {
      final rawDate = json['diary_date'];
      if (rawDate == null || (rawDate is String && rawDate.isEmpty)) {
        parsedDate = DateTime.now();
      } else {
        parsedDate = DateTime.parse(rawDate.toString());
      }
    } catch (e) {
      // 파싱 실패 시 현재 시간 사용 (로그는 호출 쪽에서 확인 가능)
      print("⚠️ DiaryEntry.fromJson — 날짜 파싱 오류: $e");
      parsedDate = DateTime.now();
    }

    // 이미지(emoji) 데이터: primary_image_url 우선, legacy 필드(emotion_emoji) 대체
    String? emojiData;
    try {
      final rawEmoji = json['primary_image_url'] ?? json['emotion_emoji'];
      if (rawEmoji != null &&
          rawEmoji is String &&
          rawEmoji.trim().isNotEmpty) {
        emojiData = rawEmoji.trim();
        // data URI('data:image/png;base64,...') 형태면 그대로 보관하되
        // 디코딩은 UI쪽에서 처리(또는 _buildEmojiWidget에서 처리)
      } else {
        emojiData = null;
      }
    } catch (e) {
      print("⚠️ DiaryEntry.fromJson — 이미지 파싱 오류: $e");
      emojiData = null;
    }

    return DiaryEntry(
      id: json['id']?.toString() ?? '',
      date: parsedDate,
      emoji: emojiData,
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
