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
    if (_entry?.localImageFile != null) {
      return ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 280),
        child: Image.file(_entry!.localImageFile!, fit: BoxFit.contain),
      );
    }

    if (_entry?.imageUrl == null || _entry!.imageUrl!.isEmpty) {
      return const SizedBox(
        width: 500,
        height: 300,
        child: Center(child: Text("이미지 없음")),
      );
    }

    final fullUrl = _entry!.imageUrl!.startsWith("http")
        ? _entry!.imageUrl!
        : "${_diaryService.baseUrl}${_entry!.imageUrl}";

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 500, maxHeight: 300),
      child: Image.network(
        fullUrl,
        fit: BoxFit.contain,
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

  // 🔹 삭제 확인 다이얼로그 (디자인 & 기능 그대로)
  Future<bool> _showDeleteConfirmDialog(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          insetPadding: const EdgeInsets.symmetric(horizontal: 30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 30),
              const Text(
                '일기를 삭제하실 건가요?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Pretendard',
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F74F8),
                ),
              ),
              const SizedBox(height: 5),
              const Text(
                '삭제하면 일기는 복구되지 않습니다.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Pretendard',
                  fontSize: 13,
                  color: Color(0xFF1F74F8),
                ),
              ),
              const SizedBox(height: 30),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => Navigator.pop(context, true),
                      borderRadius: const BorderRadius.only(
                        bottomRight: Radius.circular(15),
                      ),
                      child: Container(
                        height: 56,
                        decoration: const BoxDecoration(
                          color: Color(0xFF99BEF7),
                          borderRadius: BorderRadius.only(
                            bottomLeft: Radius.circular(15),
                          ),
                        ),
                        alignment: Alignment.center,
                        child: const Text(
                          '삭제하기',
                          style: TextStyle(
                            color: Colors.white,
                            fontFamily: 'Pretendard',
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: InkWell(
                      onTap: () => Navigator.pop(context, false),
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(15),
                      ),
                      child: Container(
                        height: 56,
                        decoration: const BoxDecoration(
                          color: Color(0xFF5A9AFF),
                          borderRadius: BorderRadius.only(
                            bottomRight: Radius.circular(15),
                          ),
                        ),
                        alignment: Alignment.center,
                        child: const Text(
                          '취소하기',
                          style: TextStyle(
                            color: Colors.white,
                            fontFamily: 'Pretendard',
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );

    return result ?? false;
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
                  // 🔹 삭제 버튼
                  ElevatedButton(
                    onPressed: () async {
                      final confirm = await _showDeleteConfirmDialog(context);
                      if (!confirm) return;

                      try {
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
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text('삭제 중 오류: $e')));
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF5A9AFF),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      elevation: 5,
                      shadowColor: Colors.black.withOpacity(0.5),
                    ),
                    child: const Text('삭제'),
                  ),

                  const SizedBox(width: 8),
                  // 🔹 수정 버튼 (기존 그대로)
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
                          _entry = updated;
                        });
                        if (widget.onUpdate != null) widget.onUpdate!(updated);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF5A9AFF),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      elevation: 5,
                      shadowColor: Colors.black.withOpacity(0.5),
                    ),
                    child: const Text('수정'),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Center(child: _buildImage()),
              const SizedBox(height: 0),
              SizedBox(
                width: double.infinity,
                height: 40,
                child: Stack(
                  children: [
                    Positioned(
                      top: 5,
                      left: -7,
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
                    Positioned(
                      top: 5,
                      left: 40,
                      child: IconButton(
                        onPressed: () {},
                        icon: const Icon(
                          Icons.chat_bubble_outline,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                    Positioned(
                      top: 5,
                      right: -10,
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
              const SizedBox(height: 20),
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
              const SizedBox(height: 25),
              SizedBox(
                child: Text.rich(
                  const TextSpan(
                    text: '댓글 1개',
                    style: TextStyle(
                      fontFamily: 'GyeonggiBatang',
                      fontSize: 12,
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
