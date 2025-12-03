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
  final String? emotionImageUrl;

  EmotionState({
    required this.emotionLabel,
    required this.emotionEmoji,
    required this.emotionCnt,
    required this.emotionPercent,
    this.emotionImageUrl,
  });

  factory EmotionState.fromJson(Map<String, dynamic> json) {
    return EmotionState(
      emotionLabel: json["emotion_label"],
      emotionEmoji: json["emotion_emoji"],
      emotionCnt: (json["emotion_cnt"] as num).toInt(),
      emotionPercent: (json["emotion_percent"] as num).toDouble(),
      emotionImageUrl: json["emotion_image_url"],
    );
  }
}

class DailyEmotionScore {
  final DateTime date; // DateTime으로 안전하게 변환
  final double angry;
  final double fear;
  final double happy;
  final double tender;
  final double sad;

  DailyEmotionScore({
    required this.date,
    required this.angry,
    required this.fear,
    required this.happy,
    required this.tender,
    required this.sad,
  });

  factory DailyEmotionScore.fromJson(Map<String, dynamic> json) {
    DateTime parsedDate;
    try {
      parsedDate = DateTime.parse(json["date"]);
    } catch (_) {
      parsedDate = DateTime.now(); // 안전하게 기본값 설정
    }

    return DailyEmotionScore(
      date: parsedDate,
      angry: (json["Angry"] as num).toDouble(),
      fear: (json["Fear"] as num).toDouble(),
      happy: (json["Happy"] as num).toDouble(),
      tender: (json["Tender"] as num).toDouble(),
      sad: (json["Sad"] as num).toDouble(),
    );
  }
}
