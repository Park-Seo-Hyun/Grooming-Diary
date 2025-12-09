import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'diary_page.dart';
import '../services/diary_service.dart';
import 'dart:io';
import 'diary_entry_detail.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

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
        constraints: BoxConstraints(maxWidth: 450.w, maxHeight: 250.h),
        child: Image.file(_entry!.localImageFile!, fit: BoxFit.contain),
      );
    }

    if (_entry?.imageUrl == null || _entry!.imageUrl!.isEmpty) {
      return SizedBox(
        width: 500.w,
        height: 300.h,
        child: Center(child: Text("이미지 없음")),
      );
    }

    final fullUrl = _entry!.imageUrl!.startsWith("http")
        ? _entry!.imageUrl!
        : "${_diaryService.baseUrl}${_entry!.imageUrl}";

    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: 500.w, maxHeight: 300.h),
      child: Image.network(
        fullUrl,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return SizedBox(
            width: 500.w,
            height: 300.h,
            child: Center(child: Text("이미지 로드 실패")),
          );
        },
      ),
    );
  }

  Future<bool> _showDeleteConfirmDialog(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) {
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
                '일기를 삭제하실 건가요?',
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
                '삭제하면 일기는 복구되지 않습니다.',
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
                      onTap: () => Navigator.pop(context, true),
                      borderRadius: BorderRadius.only(
                        bottomRight: Radius.circular(15.r),
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
                          '삭제하기',
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
                      onTap: () => Navigator.pop(context, false),
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(15.r),
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
                          '취소하기',
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
    );

    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_error || _entry == null) {
      return Scaffold(
        appBar: AppBar(title: Text('일기 상세')),
        body: Center(
          child: Text(
            '일기를 불러오는 데 실패했습니다.\n(삭제되었거나 존재하지 않는 일기입니다)',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        scrolledUnderElevation: 0,
        centerTitle: true,
        backgroundColor: Colors.white,
        title: SizedBox(height: 60.h, child: Image.asset('assets/cloud.png')),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(7.h),
          child: Divider(color: Color(0xFFEEEEEE), thickness: 5.h),
        ),
      ),
      body: ListView(
        padding: EdgeInsets.all(30.w),
        children: [
          Text(
            DateFormat('yyyy.MM.dd').format(_entry!.date),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'GyeonggiTitle',
              fontSize: 25.sp,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A6DFF),
            ),
          ),
          SizedBox(height: 20.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
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
                      Navigator.pop(context);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('삭제 중 오류가 발생했습니다.')),
                      );
                    }
                  } catch (e) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text('삭제 중 오류: $e')));
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF5A9AFF),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18.r),
                  ),
                  elevation: 5,
                  shadowColor: Colors.black.withOpacity(0.5),
                ),
                child: Text('삭제', style: TextStyle(fontSize: 13.sp)),
              ),
              SizedBox(width: 10.w),
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
                  backgroundColor: Color(0xFF5A9AFF),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18.r),
                  ),
                  elevation: 5,
                  shadowColor: Colors.black.withOpacity(0.5),
                ),
                child: Text('수정', style: TextStyle(fontSize: 13.sp)),
              ),
            ],
          ),
          SizedBox(height: 20.h),
          Center(child: _buildImage()),
          SizedBox(height: 0.h),
          SizedBox(
            width: double.infinity,
            height: 40.h, // 충분히 높게 잡기
            child: Stack(
              children: [
                Positioned(
                  left: -10.w, // 원하는 x 위치
                  top: 0.h, // 원하는 y 위치
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
                  left: 40.w,
                  top: 0.h,
                  child: IconButton(
                    onPressed: () {},
                    icon: Icon(Icons.chat_bubble_outline, color: Colors.grey),
                  ),
                ),
                Positioned(
                  right: -8.w,
                  top: 0.h,
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

          SizedBox(height: 5.h), // 아이콘-텍스트 간격 조정
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: '${_entry!.userName}  ',
                  style: TextStyle(
                    fontFamily: 'GyeonggiTitle',
                    fontSize: 15.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                if (_entry!.text != null && _entry!.text!.isNotEmpty)
                  TextSpan(
                    text: _entry!.text!,
                    style: TextStyle(
                      fontFamily: 'GyeonggiBatang',
                      fontSize: 13.sp,
                      color: Color(0xFF626262),
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(height: 18.h),
          Text.rich(
            TextSpan(
              text: '댓글 1개',
              style: TextStyle(
                fontFamily: 'GyeonggiBatang',
                fontSize: 12.sp,
                color: Color(0xFF626262),
              ),
            ),
          ),
          SizedBox(height: 15.h),
          if (_entry!.aiComment != null && _entry!.aiComment!.isNotEmpty)
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(15.w),
              decoration: BoxDecoration(
                color: Color(0xFFE9F0FB),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: 'AI봇\n',
                      style: TextStyle(
                        fontFamily: 'GyeonggiBatang',
                        fontSize: 15.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    TextSpan(
                      text: _entry!.aiComment!,
                      style: TextStyle(
                        fontFamily: 'GyeonggiBatang',
                        fontSize: 14.sp,
                        color: Color(0xFF626262),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          SizedBox(height: 30.h), // 하단 여유
        ],
      ),
    );
  }
}
