import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'diary_page.dart';
import '../services/diary_service.dart';
import 'dart:io';
import 'diary_entry_detail.dart';

class DiaryDetailPage extends StatefulWidget {
  final String diaryId;
  final VoidCallback onDelete;
  final Function(DiaryEntryDetail)? onUpdate;

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
  DiaryEntryDetail? _entry;
  bool _loading = true;
  bool _error = false;
  bool isLiked = false;
  bool isBookmarked = false;

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
      final data = await _diaryService.getDiaryById(widget.diaryId);
      final entry = DiaryEntryDetail.fromJson(data);

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

  Widget _buildImage() {
    // 1️⃣ 로컬 이미지가 있으면 비율 유지하며 표시
    if (_entry?.localImageFile != null) {
      return ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 500, // 최대 가로
          maxHeight: 280, // 최대 세로
        ),
        child: Image.file(
          _entry!.localImageFile!,
          fit: BoxFit.contain, // 비율 유지, 잘리지 않음
        ),
      );
    }

    // 2️⃣ 서버 이미지가 없으면 "이미지 없음"
    if (_entry?.imageUrl == null || _entry!.imageUrl!.isEmpty) {
      return const SizedBox(
        width: 500,
        height: 300,
        child: Center(child: Text("이미지 없음")),
      );
    }

    // 3️⃣ 서버 URL + 캐시 무시 쿼리 추가
    final fullUrl = _entry!.imageUrl!.startsWith("http")
        ? _entry!.imageUrl!
        : "${_diaryService.baseUrl}${_entry!.imageUrl}";

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 500, maxHeight: 300),
      child: Image.network(
        fullUrl,
        fit: BoxFit.contain, // 비율 유지
        errorBuilder: (context, error, stackTrace) {
          return const SizedBox(
            width: 500,
            height: 300,
            child: Center(child: Text("이미지 로드 실패")),
          );
        },
      ),
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
          child: Divider(color: Color(0xFFEEEEEE), thickness: 5),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
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
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton(
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        barrierDismissible: false,
                        builder: (context) => AlertDialog(
                          title: const Text('일기를 삭제하시겠습니까?'),
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
                        try {
                          print('Deleting diary with id: ${widget.diaryId}');
                          final success = await _diaryService.deleteDiary(
                            widget.diaryId,
                          );
                          if (success) {
                            widget.onDelete();
                            Navigator.pop(context); // 삭제 후 뒤로
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('삭제 중 오류가 발생했습니다.')),
                            );
                          }
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('삭제 중 오류: $e')),
                          );
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF5A9AFF),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ), // 둥글기
                      elevation: 5, // 그림자
                      shadowColor: Colors.black.withOpacity(0.5), // 그림자 색
                    ),
                    child: const Text('삭제'),
                  ),

                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () async {
                      final updated = await Navigator.push<DiaryEntryDetail?>(
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
                          _entry = updated; // localImageFile 포함 갱신
                        });
                        if (widget.onUpdate != null) widget.onUpdate!(updated);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF5A9AFF),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ), // 둥글기
                      elevation: 5, // 그림자
                      shadowColor: Colors.black.withOpacity(0.5), // 그림자 색
                    ),

                    child: const Text('수정'),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Center(child: _buildImage()),

              // 1️⃣ _DiaryDetailPageState 안에 상태 변수 추가

              // 2️⃣ Center(child: _buildImage()), 아래와 const SizedBox(height: 20), 사이에 Row 추가
              const SizedBox(height: 0), // 사진과 아이콘 사이 간격
              SizedBox(
                width: double.infinity,
                height: 40, // 아이콘 영역 높이
                child: Stack(
                  children: [
                    // 하트
                    Positioned(
                      top: 5, // 위쪽 간격
                      left: -7, // 왼쪽 간격
                      child: IconButton(
                        onPressed: () {
                          setState(() {
                            isLiked = !isLiked;
                          });
                        },
                        icon: Icon(
                          isLiked ? Icons.favorite : Icons.favorite_border,
                          color: isLiked ? Colors.red : Colors.grey,
                        ),
                      ),
                    ),
                    // 말풍선
                    Positioned(
                      top: 5,
                      left: 40, // 하트와 간격
                      child: IconButton(
                        onPressed: () {
                          // 말풍선 색 변경 없음
                        },
                        icon: const Icon(
                          Icons.chat_bubble_outline,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                    // 북마크
                    Positioned(
                      top: 5,
                      right: -10, // 오른쪽 끝에서 간격
                      child: IconButton(
                        onPressed: () {
                          setState(() {
                            isBookmarked = !isBookmarked;
                          });
                        },
                        icon: Icon(
                          isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                          color: isBookmarked ? Colors.blue : Colors.grey,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20), // 기존 여백 유지

              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: '${_entry!.userName} ',
                      style: const TextStyle(
                        fontFamily: 'GyeonggiTitle',
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    if (_entry!.text != null && _entry!.text!.isNotEmpty)
                      TextSpan(
                        text: _entry!.text!,
                        style: const TextStyle(
                          fontFamily: 'GyeonggiBatang',
                          fontSize: 15,
                          color: Color(0xFF626262),
                        ),
                      ),
                  ],
                ),
              ),
              SizedBox(height: 25),
              SizedBox(
                child: Text.rich(
                  TextSpan(
                    text: '댓글 1개',
                    style: const TextStyle(
                      fontFamily: 'GyeonggiBatang',
                      fontSize: 12, // 가독성 있게 조정
                      color: Color(0xFF626262),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 22),
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
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        TextSpan(
                          text: _entry!.aiComment!,
                          style: const TextStyle(
                            fontFamily: 'GyeonggiBatang',
                            fontSize: 14,
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
