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
  final bool isNewWrite;

  const DiaryPage({
    super.key,
    required this.selectedDate,
    this.initialEntry,
    this.isNewWrite = false,
  });

  @override
  State<DiaryPage> createState() => _DiaryPageState();
}

class _DiaryPageState extends State<DiaryPage> {
  late TextEditingController _controller;
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();
  static const int maxLength = 100;
  bool _isSaving = false;

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

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            // Timer가 아직 생성되지 않았으면 생성
            if (timer == null) {
              const totalMs = 7000; // 팝업 전체 시간
              const tickMs = 20; // 50fps 정도
              final totalTicks = totalMs / tickMs;
              final step = 1 / totalTicks; // 부드럽게 증가

              timer = Timer.periodic(const Duration(milliseconds: tickMs), (t) {
                if (progress >= 1) {
                  t.cancel();
                  Navigator.pop(context); // 팝업 닫기
                } else {
                  setState(() {
                    progress += step;
                    if (progress > 1) progress = 1;
                  });
                }
              });
            }

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
                    SizedBox(
                      height: 60.h,
                      child: Image.asset('assets/cloud.png'),
                    ),
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
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 30.w),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 10.h,
                        backgroundColor: const Color(0xFFE9F0FB),
                        color: const Color(0xFF5A9AFF),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    timer?.cancel();
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
        // 저장 성공하면 디테일 페이지로 이동
        final detailResult = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DiaryDetailPage(
              diaryId: result['id'], // 서버에서 받은 id
              onDelete: () => Navigator.pop(context, true),
              onUpdate: (_) {},
              isNewWrite: true,
            ),
          ),
        );

        // DiaryDetailPage에서 true를 반환하면 HomePage 갱신
        if (detailResult == true) {
          Navigator.pop(context, true);
        }

        print("📌 저장 후 디테일 페이지 이동 완료!");
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

  Future<bool> _showExitDialog() async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) {
            return Dialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15.r),
              ),
              insetPadding: EdgeInsets.symmetric(horizontal: 30.w),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(height: 30.h),
                  Text(
                    '그만 작성하실 건가요?',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Pretendard',
                      fontSize: 24.sp,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F74F8),
                    ),
                  ),
                  SizedBox(height: 5.h),
                  Text(
                    '작성 중인 일기는 저장되지 않습니다.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Pretendard',
                      fontSize: 13.sp,
                      color: Color(0xFF1F74F8),
                    ),
                  ),
                  SizedBox(height: 30.h),
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () {
                            Navigator.of(context).pop(
                              true,
                            ); // true 반환 → WillPopScope에서 뒤로가기 허용 → HomePage로 이동
                          },

                          borderRadius: BorderRadius.only(
                            bottomLeft: Radius.circular(15.r),
                          ),
                          child: Container(
                            height: 56.h,
                            decoration: BoxDecoration(
                              color: Color(0xFF99BEF7),
                              borderRadius: BorderRadius.only(
                                bottomLeft: Radius.circular(15.r),
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '나가기',
                              style: TextStyle(
                                color: Colors.white,
                                fontFamily: 'Pretendard',
                                fontSize: 18.sp,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: InkWell(
                          onTap: () {
                            Navigator.of(
                              context,
                            ).pop(false); // false 반환 → 계속 작성
                          },
                          borderRadius: BorderRadius.only(
                            bottomRight: Radius.circular(15.r),
                          ),
                          child: Container(
                            height: 56.h,
                            decoration: BoxDecoration(
                              color: Color(0xFF5A9AFF),
                              borderRadius: BorderRadius.only(
                                bottomRight: Radius.circular(15.r),
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '계속 작성하기',
                              style: TextStyle(
                                color: Colors.white,
                                fontFamily: 'Pretendard',
                                fontSize: 18.sp,
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
        ) ??
        false; // null이면 false 반환
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // 새 일기든 수정이든 상관없이 항상 팝업 띄우기
        bool exit = await _showExitDialog();
        return exit; // true면 뒤로가기, false면 계속 작성
      },

      child: Scaffold(
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
                          onPressed:
                              _isSaving // << 요청 중이면 버튼 비활성화
                              ? null
                              : () async {
                                  setState(
                                    () => _isSaving = true,
                                  ); // 버튼 즉시 비활성화

                                  await _showAnalyzingDialog();

                                  try {
                                    await _saveDiary(); // 서버 요청
                                  } catch (e) {
                                    print("❌ 저장 중 에러 발생: $e");
                                    if (mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text("일기 저장 중 오류 발생: $e"),
                                        ),
                                      );
                                    }
                                  } finally {
                                    if (mounted)
                                      setState(
                                        () => _isSaving = false,
                                      ); // 요청 끝나면 버튼 다시 활성화
                                  }
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
      ),
    );
  }
}
