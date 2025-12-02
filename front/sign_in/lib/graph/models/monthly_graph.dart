class MonthlyGraphData {
  final String monthlyYear;
  final int diaryCnt;
  final List<EmotionState> emotionState;
  final List<DailyEmotionScore> dailyEmotionScores;

  MonthlyGraphData({
    required this.monthlyYear,
    required this.diaryCnt,
    required this.emotionState,
    required this.dailyEmotionScores,
  });

  factory MonthlyGraphData.fromJson(Map<String, dynamic> json) {
    return MonthlyGraphData(
      monthlyYear: json["monthly_year"],
      diaryCnt: (json["diary_cnt"] as num).toInt(),
      emotionState: (json["emotion_state"] as List)
          .map((e) => EmotionState.fromJson(e))
          .toList(),
      dailyEmotionScores: (json["daily_emotion_scores"] as List)
          .map((e) => DailyEmotionScore.fromJson(e))
          .toList(),
    );
  }
}

class EmotionState {
  final String emotionLabel;
  final String emotionEmoji;
  final int emotionCnt;
  final double emotionPercent;
  final String? emotionImageUrl; // ✅ 새 필드 추가

  EmotionState({
    required this.emotionLabel,
    required this.emotionEmoji,
    required this.emotionCnt,
    required this.emotionPercent,
    this.emotionImageUrl, // 생성자에 추가
  });

  factory EmotionState.fromJson(Map<String, dynamic> json) {
    return EmotionState(
      emotionLabel: json["emotion_label"],
      emotionEmoji: json["emotion_emoji"],
      emotionCnt: (json["emotion_cnt"] as num).toInt(),
      emotionPercent: (json["emotion_percent"] as num).toDouble(),
      emotionImageUrl: json["emotion_image_url"], // 서버에서 내려오는 이미지 URL
    );
  }
}

class DailyEmotionScore {
  final String date;
  final int angry;
  final int fear;
  final int happy;
  final int tender;
  final int sad;

  DailyEmotionScore({
    required this.date,
    required this.angry,
    required this.fear,
    required this.happy,
    required this.tender,
    required this.sad,
  });

  factory DailyEmotionScore.fromJson(Map<String, dynamic> json) {
    return DailyEmotionScore(
      date: json["date"],
      angry: (json["Angry"] as num).toInt(),
      fear: (json["Fear"] as num).toInt(),
      happy: (json["Happy"] as num).toInt(),
      tender: (json["Tender"] as num).toInt(),
      sad: (json["Sad"] as num).toInt(),
    );
  }
}
