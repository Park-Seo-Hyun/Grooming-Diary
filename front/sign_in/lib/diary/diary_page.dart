import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import '../services/diary_service.dart';
import 'diary_entry.dart';

class DiaryPage extends StatefulWidget {
  final DateTime selectedDate;
  final DiaryEntry? initialEntry;
  const DiaryPage({super.key, required this.selectedDate, this.initialEntry});

  @override
  State<DiaryPage> createState() => _DiaryPageState();
}

class _DiaryPageState extends State<DiaryPage> {
  late TextEditingController _controller;
  File? _selectedImage;
  String? _existingImageBase64;
  final ImagePicker _picker = ImagePicker();
  static const int maxLength = 100;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialEntry?.text ?? '');
    _existingImageBase64 = widget.initialEntry?.emoji;
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final image = await _picker.pickImage(source: source);
      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
          _existingImageBase64 = null;
        });
      }
    } catch (e) {
      print("이미지 선택 에러: $e");
    }
  }

  Future<void> _saveDiary() async {
    try {
      final fields = {
        'diary_date': widget.selectedDate.toIso8601String(),
        'content': _controller.text,
      };

      final diaryService = DiaryService();
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

      final newEntry = DiaryEntry.fromJson(result);

      if (!mounted) return;

      Navigator.pop(context, newEntry); // DiaryDetailPage로 반환
    } catch (e) {
      print("❌ 일기 저장 실패: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("일기 저장 중 오류 발생")));
    }
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
              const SizedBox(height: 20),
              const Text(
                "오늘 하루는 어땠나요?",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'GyeonggiTitle',
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A6DFF),
                ),
              ),
              const SizedBox(height: 16),
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
                            fontSize: 18,
                            color: Color(0xFF999999),
                          ),
                          border: InputBorder.none,
                          counterText: "",
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (_selectedImage != null ||
                        (_existingImageBase64 != null &&
                            _existingImageBase64!.isNotEmpty))
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: _selectedImage != null
                                ? Image.file(
                                    _selectedImage!,
                                    height: 60,
                                    width: 60,
                                    fit: BoxFit.cover,
                                  )
                                : Image.memory(
                                    base64Decode(_existingImageBase64!),
                                    height: 60,
                                    width: 60,
                                    fit: BoxFit.cover,
                                  ),
                          ),
                          Positioned(
                            top: -8,
                            right: -8,
                            child: GestureDetector(
                              onTap: () => setState(() {
                                _selectedImage = null;
                                _existingImageBase64 = null;
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
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const SizedBox(height: 30),
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
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10, left: 10),
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
                  ],
                ),
              ),
              const SizedBox(height: 30),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      child: const Text("취소", style: TextStyle(fontSize: 18)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF5A9AFF),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      child: const Text("저장", style: TextStyle(fontSize: 18)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF5A9AFF),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      onPressed: _saveDiary,
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
