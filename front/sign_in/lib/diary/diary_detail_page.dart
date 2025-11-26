// diary_detail_page.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'diary_entry.dart';
import 'diary_page.dart';
import '../services/diary_service.dart';

class DiaryDetailPage extends StatefulWidget {
  final String diaryId;
  final VoidCallback onDelete;
  final Function(DiaryEntry)? onUpdate;

  const DiaryDetailPage({
    super.key,
    required this.diaryId,
    required this.onDelete,
    this.onUpdate,
  });

  @override
  State<DiaryDetailPage> createState() => _DiaryDetailPageState();
}

class _DiaryDetailPageState extends State<DiaryDetailPage> {
  final DiaryService _diaryService = DiaryService();

  bool isLiked = false;
  bool isBookmarked = false;
  DiaryEntry? _entry;
  bool _loading = true;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _fetchDiary();
  }

  Future<void> _fetchDiary() async {
    setState(() {
      _loading = true;
      _error = false;
    });

    try {
      print("🔍 DiaryDetailPage에서 요청 ID: ${widget.diaryId}");

      final data = await _diaryService.getDiaryById(widget.diaryId);

      final entry = DiaryEntry.fromJson(data);

      setState(() {
        _entry = entry;
        _loading = false;
      });
    } catch (e) {
      print('⚠️ 일기 상세 로드 실패: $e');
      setState(() {
        _loading = false;
        _error = true;
      });
    }
  }

  // 🔥 URL 기반 이미지 로드
  Widget _buildImage(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return const SizedBox(height: 120, child: Center(child: Text("이미지 없음")));
    }

    return Image.network(
      imageUrl,
      height: 150,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        return const SizedBox(
          height: 120,
          child: Center(child: Text("이미지 로드 실패")),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_error || _entry == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('일기 상세')),
        body: const Center(
          child: Text('일기를 불러오는 데 실패했습니다.\n(삭제되었거나 존재하지 않는 일기입니다)'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.white,
        title: SizedBox(height: 60, child: Image.asset('assets/cloud.png')),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(7.0),
          child: Divider(color: Color(0xFFEEEEEE), thickness: 7),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 날짜
              Text(
                DateFormat('yyyy.MM.dd').format(_entry!.date),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'GyeonggiTitle',
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A6DFF),
                ),
              ),
              const SizedBox(height: 20),

              // 삭제/수정 버튼
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton(
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        barrierDismissible: false,
                        builder: (context) => AlertDialog(
                          title: const Text('일기를 삭제하실 건가요?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('삭제'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('취소'),
                            ),
                          ],
                        ),
                      );

                      if (confirm == true) {
                        widget.onDelete();
                        Navigator.pop(context);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF5A9AFF),
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('삭제'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () async {
                      final updated = await Navigator.push<DiaryEntry>(
                        context,
                        MaterialPageRoute(
                          builder: (_) => DiaryPage(
                            selectedDate: _entry!.date,
                            initialEntry: _entry,
                          ),
                        ),
                      );

                      if (updated != null) {
                        setState(() {
                          _entry = updated;
                        });
                        if (widget.onUpdate != null) widget.onUpdate!(updated);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF5A9AFF),
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('수정'),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // 사진(URL)
              Center(child: _buildImage(_entry!.emoji)),

              const SizedBox(height: 20),

              // 좋아요/북마크
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => setState(() => isLiked = !isLiked),
                        child: Icon(
                          isLiked ? Icons.favorite : Icons.favorite_outline,
                          color: isLiked ? Colors.red : Colors.grey,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 15),
                      const Icon(
                        Icons.chat_bubble_outline_rounded,
                        color: Colors.grey,
                        size: 28,
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () => setState(() => isBookmarked = !isBookmarked),
                    child: Icon(
                      isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                      color: isBookmarked ? Colors.blue : Colors.grey,
                      size: 28,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // 사용자 + 내용
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: '${_entry!.userName} ',
                      style: const TextStyle(
                        fontFamily: 'GyeonggiTitle',
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    if (_entry!.text != null)
                      TextSpan(
                        text: _entry!.text!,
                        style: const TextStyle(
                          fontFamily: 'GyeonggiBatang',
                          fontSize: 18,
                          color: Color(0xFF626262),
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // AI 코멘트
              if (_entry!.aiComment != null && _entry!.aiComment!.isNotEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(15.0),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE9F0FB),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text.rich(
                    TextSpan(
                      children: [
                        const TextSpan(
                          text: 'AI봇\n',
                          style: TextStyle(
                            fontFamily: 'GyeonggiBatang',
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        TextSpan(
                          text: _entry!.aiComment!,
                          style: const TextStyle(
                            fontFamily: 'GyeonggiBatang',
                            fontSize: 16,
                            color: Color(0xFF626262),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
