import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'services/chat_service.dart';
import 'bubble_tail.dart';

class ChatPage extends StatefulWidget {
  final String questionId;
  final String questionText;
  final int questionNumber;
  final String mode; // write: 새 답 작성, read: 과거 질문 보기

  const ChatPage({
    super.key,
    required this.questionId,
    required this.questionText,
    required this.questionNumber,
    this.mode = "write",
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _controller = TextEditingController();
  String? answerText;
  bool isLoading = true;
  String currentMode = "write";

  final ChatService chatService = ChatService();

  @override
  void initState() {
    super.initState();
    currentMode = widget.mode;
    fetchAnswer();
  }

  Future<void> fetchAnswer() async {
    setState(() => isLoading = true);
    final fetched = await chatService.fetchAnswer(widget.questionId, "read");

    setState(() {
      answerText = fetched ?? '';
      isLoading = false;
      if (answerText != null && answerText!.isNotEmpty) {
        currentMode = "read";
      } else {
        currentMode = "write";
      }
    });
  }

  void _showModifySuccessDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Align(
            alignment: Alignment.bottomCenter,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 400.w, maxHeight: 180.h),
              child: Container(
                padding: EdgeInsets.all(20.w),
                decoration: BoxDecoration(
                  color: Colors.red[200],
                  borderRadius: BorderRadius.circular(15.r),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 10,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      size: 40.sp,
                      color: Colors.red,
                    ),
                    SizedBox(height: 10.h),
                    Text(
                      "수정이 완료되었습니다!",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 17.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                    SizedBox(height: 15.h),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(dialogContext);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                      ),
                      child: Text("확인", style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> handleSaveOrModify() async {
    final textToSave = _controller.text.trim();
    if (textToSave.isEmpty) return;

    bool success;
    bool isModify = answerText != null && answerText!.isNotEmpty; // 수정 여부 체크

    if (!isModify) {
      // 새 글 저장
      success = await chatService.saveAnswer(widget.questionId, textToSave);
    } else {
      // 기존 글 수정
      success = await chatService.modifyAnswer(widget.questionId, textToSave);
    }

    if (success) {
      setState(() {
        answerText = textToSave;
        currentMode = "read";
        _controller.clear();
      });
      if (mounted) FocusScope.of(context).unfocus();

      if (isModify) {
        // 수정일 때만 팝업
        _showModifySuccessDialog(context);
      }
    }
  }

  Future<void> _showExitDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
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
                        Navigator.of(context).pop();
                        Navigator.of(context).pop();
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
                        Navigator.of(context).pop();
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
    );
  }

  Widget buildBubble({required String text, required bool isQuestion}) {
    double screenWidth = MediaQuery.of(context).size.width;
    double bubbleMaxWidth = screenWidth * 0.8;

    return Align(
      alignment: isQuestion ? Alignment.centerLeft : Alignment.centerRight,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: bubbleMaxWidth),
            child: Container(
              padding: EdgeInsets.all(16.w),
              margin: isQuestion
                  ? EdgeInsets.only(
                      left: 25.w,
                      right: 8.w,
                      top: 8.h,
                      bottom: 8.h,
                    )
                  : EdgeInsets.symmetric(vertical: 8.h, horizontal: 8.w),
              decoration: BoxDecoration(
                color: isQuestion ? Color(0xFFFFEAFF) : Color(0xFFE9F0FB),
                borderRadius: BorderRadius.circular(16.r),
              ),
              child: Text(
                text,
                softWrap: true,
                style: TextStyle(
                  fontSize: 15.sp,
                  color: Color(0xFF626262),
                  fontFamily: isQuestion ? 'GyeonggiTitle' : 'GyeonggiBatang',
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -10.h,
            left: isQuestion ? 40.w : null,
            right: isQuestion ? null : 20.w,
            child: CustomPaint(
              painter: BubbleTailPainter(
                color: isQuestion ? Color(0xFFFFEAFF) : Color(0xFFE9F0FB),
                isQuestion: isQuestion,
              ),
              size: Size(20.w, 20.h),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildUserInput() {
    double screenWidth = MediaQuery.of(context).size.width;
    double bubbleMaxWidth = screenWidth * 0.8;

    return Align(
      alignment: Alignment.centerRight,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: bubbleMaxWidth),
            child: Container(
              padding: EdgeInsets.all(16.w),
              margin: EdgeInsets.symmetric(vertical: 8.h),
              decoration: BoxDecoration(
                color: Color(0xFFE9F0FB),
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: TextField(
                controller: _controller,
                maxLines: 4,
                maxLength: 50,
                style: TextStyle(
                  fontFamily: 'GyeonggiBatang',
                  fontSize: 15.sp,
                  color: Color(0xFF626262),
                ),
                decoration: InputDecoration(
                  hintText: '질문에 답장해주세요!',
                  hintStyle: TextStyle(
                    color: Color(0xFFAAA7A7),
                    fontFamily: 'GyeonggiBatang',
                    fontSize: 15.sp,
                  ),
                  border: InputBorder.none,
                  counterText: '',
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
          ),
          Positioned(
            bottom: -10.h,
            right: 20.w,
            child: CustomPaint(
              painter: BubbleTailPainter(
                color: Color(0xFFE9F0FB),
                isQuestion: false,
              ),
              size: Size(20.w, 20.h),
            ),
          ),
          Positioned(
            right: 20.w,
            bottom: 15.h,
            child: Text(
              '${_controller.text.length}/50',
              style: TextStyle(fontSize: 16.sp, color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (currentMode == "write") {
          await _showExitDialog();
          return false;
        }
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          backgroundColor: Colors.white,
          title: SizedBox(
            height: 60.h,
            child: Image.asset(
              'assets/cloud.png',
              errorBuilder: (context, error, stackTrace) {
                return Text(
                  'Cloud',
                  style: TextStyle(fontSize: 24.sp, color: Colors.grey),
                );
              },
            ),
          ),
          bottom: PreferredSize(
            preferredSize: Size.fromHeight(1.0.h),
            child: Container(color: Color(0xFFEEEEEE), height: 5.h),
          ),
          elevation: 0.0,
        ),
        body: isLoading
            ? Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.all(16.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(height: 15.h),
                      Center(
                        child: Text(
                          "긍정 이야기",
                          style: TextStyle(
                            fontFamily: 'GyeonggiBatang',
                            fontSize: 32.sp,
                            color: Color(0xFF1A6DFF),
                          ),
                        ),
                      ),
                      SizedBox(height: 45.h),
                      Text(
                        "      #${widget.questionNumber.toString().padLeft(2, '0')}번째 질문",
                        style: TextStyle(
                          fontSize: 15.sp,
                          color: Color(0xFF626262),
                          fontFamily: 'GyeonggiTitle',
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 15.h),
                      buildBubble(text: widget.questionText, isQuestion: true),
                      SizedBox(height: 20.h),

                      if (answerText != null &&
                          answerText!.isNotEmpty &&
                          currentMode == "read") ...[
                        buildBubble(text: answerText!, isQuestion: false),
                        SizedBox(height: 20.h),
                        Align(
                          alignment: Alignment.bottomRight,
                          child: Padding(
                            padding: EdgeInsets.only(right: 25.w),
                            child: ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  currentMode = "write";
                                  _controller.text = answerText ?? '';
                                });
                              },
                              child: Text('수정'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color(0xFF5A9AFF),
                                foregroundColor: Colors.white,
                                minimumSize: Size(70.w, 30.h),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10.r),
                                ),
                                textStyle: TextStyle(
                                  fontFamily: 'gyeonggiTitle',
                                  fontSize: 18.sp,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],

                      if (currentMode == "write") ...[
                        buildUserInput(),
                        SizedBox(height: 20.h),
                        Align(
                          alignment: Alignment.bottomRight,
                          child: Padding(
                            padding: EdgeInsets.only(right: 25.w),
                            child: ElevatedButton(
                              onPressed: _controller.text.trim().isEmpty
                                  ? null
                                  : handleSaveOrModify,
                              child: Text('저장'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color(0xFF5A9AFF),
                                foregroundColor: Colors.white,
                                minimumSize: Size(70.w, 30.h),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10.r),
                                ),
                                textStyle: TextStyle(
                                  fontFamily: 'gyeonggiTitle',
                                  fontSize: 18.sp,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                      SizedBox(height: 50.h),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
