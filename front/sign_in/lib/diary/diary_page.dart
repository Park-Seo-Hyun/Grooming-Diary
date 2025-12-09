import 'dart:async';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../services/diary_service.dart';
import 'diary_entry_detail.dart';
import 'diary_detail_page.dart';

class DiaryPage extends StatefulWidget {
  final DateTime selectedDate;
  final DiaryEntryDetail? initialEntry;

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
      setState(() {});
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
            borderRadius: BorderRadius.circular(15.r),
          ),
          insetPadding: EdgeInsets.symmetric(horizontal: 50.w),
          child: SizedBox(
            width: 200.w,
            height: 250.h,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(height: 20.h),
                const Text(
                  "일기를 분석하고 있습니다.",
                  style: TextStyle(
                    fontFamily: 'GyeonggiTitle',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF297BFB),
                  ),
                ),
                SizedBox(height: 20.h),
                SizedBox(height: 60.h, child: Image.asset('assets/cloud.png')),
                SizedBox(height: 20.h),
                const Text(
                  "로딩중. .",
                  style: TextStyle(
                    fontFamily: 'GyeonggiTitle',
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF5A9AFF),
                  ),
                ),
                SizedBox(height: 20.h),
                StatefulBuilder(
                  builder: (context, setState) {
                    if (timer == null) {
                      const totalMs = 7000;
                      const tickMs = 20;
                      final totalTicks = totalMs / tickMs;
                      final step = 1 / totalTicks * 5.0;

                      timer = Timer.periodic(
                        const Duration(milliseconds: tickMs),
                        (t) {
                          if (progress >= 1) {
                            t.cancel();
                            Navigator.pop(context);
                          } else {
                            setState(() {
                              progress += step;
                              if (progress > 1) progress = 1;
                            });
                          }
                        },
                      );
                    }

                    return Padding(
                      padding: EdgeInsets.symmetric(horizontal: 30.w),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 10.h,
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
      timer?.cancel();
    });
  }

  Future<void> _saveDiary() async {
    print('날짜: ${widget.selectedDate}');
    print('내용: ${_controller.text}');
    print('선택 이미지: $_selectedImage');
    try {
      final diaryService = DiaryService();
      final fields = {
        'diary_date': widget.selectedDate.toIso8601String(),
        'content': _controller.text,
      };
      print("📌 저장 시도: 날짜=${fields['diary_date']}, 내용=${fields['content']}");
      if (_selectedImage != null) print("📌 이미지 포함: ${_selectedImage!.path}");

      Map<String, dynamic> result;

      if (widget.initialEntry != null) {
        print("🔹 기존 일기 수정 시도: id=${widget.initialEntry!.id}");
        result = await diaryService.updateDiary(
          widget.initialEntry!.id,
          fields,
          _selectedImage,
        );
      } else {
        print("🔹 새 일기 생성 시도");
        result = await diaryService.createDiary(fields, _selectedImage);
      }
      print("📌 서버 응답 결과: $result");

      if (result.isEmpty) throw Exception('서버에서 일기 데이터를 받지 못했습니다.');

      final updatedEntry = DiaryEntryDetail.fromJson(result);
      if (_selectedImage != null) updatedEntry.localImageFile = _selectedImage;

      if (!mounted) return;

      if (widget.initialEntry != null) {
        Navigator.pop(context, updatedEntry);
        print("✅ 수정 완료 후 이전 화면으로 반환");
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => DiaryDetailPage(
              diaryId: updatedEntry.id,
              onDelete: () => Navigator.pop(context),
              onUpdate: (entry) {},
            ),
          ),
        );
        print("✅ 새 일기 저장 완료 후 디테일 페이지 이동");
      }
    } catch (e) {
      print("❌ 일기 저장 실패: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("일기 저장 중 오류 발생: $e")));
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("일기 저장 중 오류 발생")));
    }
  }

  Widget _buildImageWidget() {
    if (_selectedImage != null) {
      return Image.file(
        _selectedImage!,
        height: 60.h,
        width: 60.w,
        fit: BoxFit.cover,
      );
    }
    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        scrolledUnderElevation: 0,
        centerTitle: true,
        backgroundColor: Colors.white,

        title: SizedBox(height: 60.h, child: Image.asset('assets/cloud.png')),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(5.0),
          child: Divider(color: Color(0xFFEEEEEE), thickness: 5),
        ),
        elevation: 0.0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(30.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                "${widget.selectedDate.year}.${widget.selectedDate.month.toString().padLeft(2, '0')}.${widget.selectedDate.day.toString().padLeft(2, '0')}",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'GyeonggiTitle',
                  fontSize: 25.sp,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1A6DFF),
                ),
              ),
              SizedBox(height: 20.h),
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
              SizedBox(height: 30.h),
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: const Color(0xFFE9F0FB),
                  borderRadius: BorderRadius.circular(10.r),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.4),
                      spreadRadius: 2.r,
                      blurRadius: 8.r,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ConstrainedBox(
                      constraints: BoxConstraints(minHeight: 120.h),
                      child: TextField(
                        controller: _controller,
                        keyboardType: TextInputType.multiline,
                        maxLines: null,
                        maxLength: maxLength,
                        style: TextStyle(
                          fontFamily: 'GyeonggiTitle',
                          fontSize: 18.sp,
                          color: const Color(0xFF626262),
                        ),
                        decoration: InputDecoration(
                          hintText: "오늘의 이야기를 작성해주세요",
                          hintStyle: TextStyle(
                            fontFamily: 'GyeonggiTitle',
                            fontSize: 15.sp,
                            color: const Color(0xFF999999),
                          ),
                          border: InputBorder.none,
                          counterText: "",
                        ),
                      ),
                    ),
                    SizedBox(height: 8.h),
                    if (_selectedImage != null)
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8.r),
                            child: _buildImageWidget(),
                          ),
                          Positioned(
                            top: -8.h,
                            right: -8.w,
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
                    SizedBox(
                      height: 30.h,
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
                            width: 100.w,
                            height: 30.h,
                            child: Stack(
                              children: [
                                Positioned(
                                  top: 10.h,
                                  right: 10.w,
                                  child: Text(
                                    "${_controller.text.length}/$maxLength",
                                    style: TextStyle(
                                      fontFamily: 'Pretendard',
                                      fontSize: 14.sp,
                                      color: const Color(0xFFA7A7A7),
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
              SizedBox(height: 30.h),
              Row(
                children: [
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(left: 20.w),
                      child: ElevatedButton(
                        child: Text("취소", style: TextStyle(fontSize: 18.sp)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF5A9AFF),
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 10.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.r),
                          ),
                          elevation: 6,
                          shadowColor: Colors.black.withOpacity(0.5),
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                  ),
                  SizedBox(width: 35.w),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(right: 20.w),
                      child: ElevatedButton(
                        child: Text("저장", style: TextStyle(fontSize: 18.sp)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF5A9AFF),
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 10.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.r),
                          ),
                          elevation: 6,
                          shadowColor: Colors.black.withOpacity(0.5),
                        ),
                        onPressed: () async {
                          await _showAnalyzingDialog();
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
