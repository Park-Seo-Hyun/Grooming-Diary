class DiaryEntry {
  final String id;
  final DateTime date;
  final String? emoji; // 이제 URL 기준
  final String? text;
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
    return DiaryEntry(
      id: detail.id,
      date: detail.date,
      emoji: detail.imageUrl, // 이제 URL
      text: detail.text,
      aiComment: detail.aiComment,
      userName: detail.userName,
    );
  }

  factory DiaryEntry.fromJson(
    Map<String, dynamic> json, {
    bool fromHomepage = false,
  }) {
    DateTime parsedDate;
    try {
      parsedDate = DateTime.parse(json['diary_date']?.toString() ?? '');
    } catch (_) {
      parsedDate = DateTime.now();
    }

    String? imageData;

    if (fromHomepage) {
      // 홈페이지용 Base64
      imageData = json['emotion_emoji']?.toString();
    } else {
      // URL 기반
      imageData = json['primary_image_url']?.toString();
    }

    return DiaryEntry(
      id: json['id']?.toString() ?? '',
      date: parsedDate,
      emoji: imageData,
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
