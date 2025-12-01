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
    // 1️⃣ 로컬 이미지가 있으면 무조건 표시
    if (_entry?.localImageFile != null) {
      return Image.file(
        _entry!.localImageFile!,
        height: 150,
        fit: BoxFit.cover,
      );
    }

    // 2️⃣ 서버 이미지가 없으면 "이미지 없음"
    if (_entry?.imageUrl == null || _entry!.imageUrl!.isEmpty) {
      return const SizedBox(height: 150, child: Center(child: Text("이미지 없음")));
    }

    // 3️⃣ 서버 URL + 캐시 무시 쿼리 추가
    final fullUrl = _entry!.imageUrl!.startsWith("http")
        ? "${_entry!.imageUrl}?v=${DateTime.now().millisecondsSinceEpoch}"
        : "${_diaryService.baseUrl}${_entry!.imageUrl}?v=${DateTime.now().millisecondsSinceEpoch}";

    return Image.network(
      fullUrl,
      height: 150,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return const SizedBox(
          height: 150,
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
                    ),
                    child: const Text('수정'),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Center(child: _buildImage()),
              const SizedBox(height: 20),
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
                    if (_entry!.text != null && _entry!.text!.isNotEmpty)
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
