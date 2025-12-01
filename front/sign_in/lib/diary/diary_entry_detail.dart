import 'dart:io';

class DiaryEntryDetail {
  final String id;
  final DateTime date;
  final String? imageUrl; // 서버에서 받은 이미지 URL
  final String? text;
  final String? aiComment;
  final String userName;

  File? localImageFile; // 로컬에서 선택한 이미지 저장
  final String? emoji; // 필요하면 서버에서 받아올 수 있음

  DiaryEntryDetail({
    required this.id,
    required this.date,
    this.imageUrl,
    this.text,
    this.aiComment,
    required this.userName,
    this.emoji,
    this.localImageFile,
  });

  factory DiaryEntryDetail.fromJson(Map<String, dynamic> json) {
    // 1️⃣ 날짜 안전 파싱
    DateTime parsedDate;
    try {
      final rawDate = json['diary_date'] ?? json['diaryDate'];
      parsedDate = rawDate != null && rawDate.toString().isNotEmpty
          ? DateTime.tryParse(rawDate.toString()) ?? DateTime.now()
          : DateTime.now();
    } catch (e) {
      print("⚠️ DiaryEntryDetail.fromJson — 날짜 파싱 오류: $e");
      parsedDate = DateTime.now();
    }

    // 2️⃣ 이미지 URL 안전 파싱
    String? image;
    try {
      final rawImage = json['primary_image_url'] ?? json['image_url'];
      if (rawImage != null && rawImage is String && rawImage.isNotEmpty) {
        image = rawImage.trim();
      } else {
        image = null;
      }
    } catch (e) {
      print("⚠️ DiaryEntryDetail.fromJson — 이미지 파싱 오류: $e");
      image = null;
    }

    // 3️⃣ 나머지 필드 처리
    return DiaryEntryDetail(
      id: json['id']?.toString() ?? '',
      date: parsedDate,
      imageUrl: image,
      text: json['content']?.toString() ?? '',
      aiComment: json['ai_comment']?.toString(),
      userName: json['user_name']?.toString() ?? '사용자',
      emoji: json['emoji']?.toString(),
    );
  }

  // 4️⃣ copyWith 추가: 일부 필드만 바꿔 새 객체 생성 가능
  DiaryEntryDetail copyWith({
    String? id,
    DateTime? date,
    String? imageUrl,
    String? text,
    String? aiComment,
    String? userName,
    String? emoji,
    File? localImageFile,
  }) {
    return DiaryEntryDetail(
      id: id ?? this.id,
      date: date ?? this.date,
      imageUrl: imageUrl ?? this.imageUrl,
      text: text ?? this.text,
      aiComment: aiComment ?? this.aiComment,
      userName: userName ?? this.userName,
      emoji: emoji ?? this.emoji,
      localImageFile: localImageFile ?? this.localImageFile,
    );
  }
}
