import 'dart:async';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../services/diary_service.dart';
import 'diary_entry_detail.dart';
import 'diary_detail_page.dart';

class DiaryPage extends StatefulWidget {
  final DateTime selectedDate;
  final DiaryEntryDetail? initialEntry; // ✅ DiaryEntryDetail 타입

  const DiaryPage({super.key, required this.selectedDate, this.initialEntry});

  @override
  State<DiaryPage> createState() => _DiaryPageState();
}

class _DiaryPageState extends State<DiaryPage> {
  late TextEditingController _controller;
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();
  static const int maxLength = 100;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialEntry?.text ?? '');
    _selectedImage = widget.initialEntry?.localImageFile;
    _controller.addListener(() {
      setState(() {}); // 글자가 바뀔 때마다 build 재실행
    });
  }

  Future<void> _pickImage(ImageSource source) async {
    final image = await _picker.pickImage(source: source);
    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
    }
  }

  Future<void> _showAnalyzingDialog() async {
    double progress = 0;
    Timer? timer;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          insetPadding: const EdgeInsets.symmetric(horizontal: 50),
          child: SizedBox(
            width: 200,
            height: 250,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                const Text(
                  "일기를 분석하고 있습니다.",
                  style: TextStyle(
                    fontFamily: 'GyeonggiTitle',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF297BFB),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(height: 60, child: Image.asset('assets/cloud.png')),

                const SizedBox(height: 20),
                const Text(
                  "로딩중. .",
                  style: TextStyle(
                    fontFamily: 'GyeonggiTitle',
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF5A9AFF),
                  ),
                ),
                const SizedBox(height: 20),
                StatefulBuilder(
                  builder: (context, setState) {
                    if (timer == null) {
                      const totalMs = 7000; // 5초
                      const tickMs = 20; // 20ms마다 갱신
                      final totalTicks = totalMs / tickMs; // 총 갱신 횟수
                      final step = 1 / totalTicks * 5.0; // 매번 증가량

                      timer = Timer.periodic(
                        const Duration(milliseconds: tickMs),
                        (t) {
                          if (progress >= 1) {
                            t.cancel();
                            Navigator.pop(context); // 팝업 닫기
                          } else {
                            setState(() {
                              progress += step;
                              if (progress > 1) progress = 1; // 마지막은 정확히 1
                            });
                          }
                        },
                      );
                    }

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 30),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 10,
                        backgroundColor: const Color(0xFFE9F0FB),
                        color: const Color(0xFF5A9AFF),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    ).then((_) {
      timer?.cancel(); // 팝업 종료 시 Timer 안전하게 취소
    });
  }

  Future<void> _saveDiary() async {
    try {
      final diaryService = DiaryService();
      final fields = {
        'diary_date': widget.selectedDate.toIso8601String(),
        'content': _controller.text,
      };

      Map<String, dynamic> result;

      if (widget.initialEntry != null) {
        // 수정
        result = await diaryService.updateDiary(
          widget.initialEntry!.id,
          fields,
          _selectedImage,
        );
      } else {
        // 새 작성
        result = await diaryService.createDiary(fields, _selectedImage);
      }

      if (result.isEmpty) throw Exception('서버에서 일기 데이터를 받지 못했습니다.');

      final updatedEntry = DiaryEntryDetail.fromJson(result);

      // 로컬 이미지가 있으면 저장
      if (_selectedImage != null) {
        updatedEntry.localImageFile = _selectedImage;
      }

      if (!mounted) return;

      // 🔹 수정인지 새 작성인지 분기
      if (widget.initialEntry != null) {
        // 수정: 이전 화면으로 반환
        Navigator.pop(context, updatedEntry);
      } else {
        // 새 작성: 바로 디테일 페이지로 이동
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => DiaryDetailPage(
              diaryId: updatedEntry.id,
              onDelete: () => Navigator.pop(context), // 삭제 후 뒤로가기
              onUpdate: (entry) {}, // 수정 콜백 필요 시
            ),
          ),
        );
      }
    } catch (e) {
      print("❌ 일기 저장 실패: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("일기 저장 중 오류 발생")));
    }
  }

  Widget _buildImageWidget() {
    if (_selectedImage != null) {
      return Image.file(
        _selectedImage!,
        height: 60,
        width: 60,
        fit: BoxFit.cover,
      );
    }
    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
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
                "${widget.selectedDate.year}.${widget.selectedDate.month.toString().padLeft(2, '0')}.${widget.selectedDate.day.toString().padLeft(2, '0')}",
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'GyeonggiTitle',
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A6DFF),
                ),
              ),
              const SizedBox(height: 35),
              const Text(
                "오늘 하루는 어땠나요?",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'GyeonggiTitle',
                  fontSize: 25,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF1A6DFF),
                ),
              ),
              const SizedBox(height: 50),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFE9F0FB),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.4),
                      spreadRadius: 2,
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 120),
                      child: TextField(
                        controller: _controller,
                        keyboardType: TextInputType.multiline,
                        maxLines: null,
                        maxLength: maxLength,
                        style: const TextStyle(
                          fontFamily: 'GyeonggiTitle',
                          fontSize: 18,
                          color: Color(0xFF626262),
                        ),
                        decoration: const InputDecoration(
                          hintText: "오늘의 이야기를 작성해주세요",
                          hintStyle: TextStyle(
                            fontFamily: 'GyeonggiTitle',
                            fontSize: 15,
                            color: Color(0xFF999999),
                          ),
                          border: InputBorder.none,
                          counterText: "",
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (_selectedImage != null)
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: _buildImageWidget(),
                          ),
                          Positioned(
                            top: -8,
                            right: -8,
                            child: GestureDetector(
                              onTap: () => setState(() {
                                _selectedImage = null;
                              }),
                              child: const CircleAvatar(
                                radius: 12,
                                backgroundColor: Colors.red,
                                child: Icon(
                                  Icons.close,
                                  size: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    Container(
                      height: 30, // Row 전체 높이
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          IconButton(
                            onPressed: () => _pickImage(ImageSource.gallery),
                            icon: const Icon(
                              Icons.image,
                              color: Color(0xFF5A9AFF),
                            ),
                          ),
                          IconButton(
                            onPressed: () => _pickImage(ImageSource.camera),
                            icon: const Icon(
                              Icons.camera_alt,
                              color: Color(0xFF5A9AFF),
                            ),
                          ),
                          const Spacer(),
                          SizedBox(
                            width: 100, // Stack의 너비 지정
                            height: 30, // Stack의 높이 지정
                            child: Stack(
                              children: [
                                Positioned(
                                  top: 10, // 위쪽 위치 조정
                                  right: 10, // 왼쪽 위치 조정
                                  child: Text(
                                    "${_controller.text.length}/$maxLength",
                                    style: const TextStyle(
                                      fontFamily: 'Pretendard',
                                      fontSize: 14,
                                      color: Color(0xFFA7A7A7),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              Row(
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 20), // ← 바깥여백 추가
                      child: ElevatedButton(
                        child: const Text("취소", style: TextStyle(fontSize: 18)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF5A9AFF),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 6, // ← 그림자 높이 조절 (0~24 정도)
                          shadowColor: Colors.black.withOpacity(
                            0.5,
                          ), // ← 그림자 색상/투명도
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                  ),
                  const SizedBox(width: 35),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 20), // ← 바깥여백 추가
                      child: ElevatedButton(
                        child: const Text("저장", style: TextStyle(fontSize: 18)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF5A9AFF),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 6, // ← 그림자 높이 조절 (0~24 정도)
                          shadowColor: Colors.black.withOpacity(0.5),
                        ),
                        onPressed: () async {
                          // 1. 저장 여부 팝업 띄우기
                          // 1. 분석 팝업 띄우고 3초 동안 진행
                          await _showAnalyzingDialog();

                          // 2. 팝업 종료 후 바로 저장
                          _saveDiary();
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
