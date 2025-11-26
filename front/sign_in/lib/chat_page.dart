import 'package:flutter/material.dart';
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

  // 저장/수정 통합 로직
  Future<void> handleSaveOrModify() async {
    final textToSave = _controller.text.trim();
    if (textToSave.isEmpty) return;

    bool success;
    if (answerText == null || answerText!.isEmpty) {
      success = await chatService.saveAnswer(widget.questionId, textToSave);
    } else {
      success = await chatService.modifyAnswer(widget.questionId, textToSave);
    }

    if (success) {
      setState(() {
        answerText = textToSave;
        currentMode = "read";
        _controller.clear();
      });
      if (mounted) FocusScope.of(context).unfocus();
    }
  }

  // ✅ [수정됨] 뒤로가기 시 실행될 팝업창 (텍스트 중앙 정렬 적용)
  Future<void> _showExitDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.white,
          // 팝업창 전체 둥근 모서리
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          // 📌 [포인트 1] 팝업창 너비 늘리기 (좌우 여백을 20으로 줄임)
          insetPadding: const EdgeInsets.symmetric(horizontal: 30),

          child: Column(
            mainAxisSize: MainAxisSize.min, // 내용물만큼만 높이 잡기
            children: [
              const SizedBox(height: 30), // 상단 여백
              // --- 제목 ---
              const Text(
                '그만 작성하실 건가요?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Pretendard',
                  fontSize: 24, // 크기 살짝 조정 (너무 크면 줄바꿈 될 수 있음)
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F74F8),
                ),
              ),
              const SizedBox(height: 15),

              // --- 내용 ---
              const Text(
                '작성 중인 일기는 저장되지 않습니다.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Pretendard',
                  fontSize: 16,
                  color: Color(0xFF1F74F8),
                ),
              ),
              const SizedBox(height: 30), // 버튼과 내용 사이 여백
              // --- 버튼 영역 (꽉 차게) ---
              Row(
                children: [
                  // 1. 왼쪽 버튼 (나가기)
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        Navigator.of(context).pop(); // 다이얼로그 닫기
                        Navigator.of(context).pop(); // 페이지 뒤로가기
                      },
                      // 📌 [포인트 2] 왼쪽 아래만 둥글게
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(15),
                      ),
                      child: Container(
                        height: 56, // 버튼 높이 지정
                        decoration: const BoxDecoration(
                          color: Color(0xFF99BEF7), // 연한 하늘색 (Hex 코드 오타 수정함)
                          borderRadius: BorderRadius.only(
                            bottomLeft: Radius.circular(15),
                          ),
                        ),
                        alignment: Alignment.center,
                        child: const Text(
                          '나가기',
                          style: TextStyle(
                            color: Color(0xFFFFFFFF),
                            fontFamily: 'Pretendard',
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // 2. 오른쪽 버튼 (계속 작성하기)
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        Navigator.of(context).pop(); // 다이얼로그만 닫기
                      },
                      // 📌 [포인트 3] 오른쪽 아래만 둥글게
                      borderRadius: const BorderRadius.only(
                        bottomRight: Radius.circular(15),
                      ),
                      child: Container(
                        height: 56, // 버튼 높이
                        decoration: const BoxDecoration(
                          color: Color(0xFF5A9AFF), // 진한 파란색
                          borderRadius: BorderRadius.only(
                            bottomRight: Radius.circular(15),
                          ),
                        ),
                        alignment: Alignment.center,
                        child: const Text(
                          '계속 작성하기',
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
  }

  // 말풍선 위젯
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
              padding: const EdgeInsets.all(16),
              margin: isQuestion
                  ? const EdgeInsets.only(left: 25, right: 8, top: 8, bottom: 8)
                  : const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
              decoration: BoxDecoration(
                color: isQuestion
                    ? const Color(0xFFFFEAFF)
                    : const Color(0xFFE9F0FB),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                text,
                softWrap: true,
                style: TextStyle(
                  fontSize: 20,
                  color: const Color(0xFF626262),
                  fontFamily: isQuestion
                      ? 'GyeonggiTitle' // 질문 폰트
                      : 'GyeonggiBatang', // 대답 폰트
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -10,
            left: isQuestion ? 40 : null,
            right: isQuestion ? null : 20,
            child: CustomPaint(
              painter: BubbleTailPainter(
                color: isQuestion
                    ? const Color(0xFFFFEAFF)
                    : const Color(0xFFE9F0FB),
                isQuestion: isQuestion,
              ),
              size: const Size(20, 20),
            ),
          ),
        ],
      ),
    );
  }

  // 입력창 위젯
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
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFE9F0FB),
                borderRadius: BorderRadius.circular(20),
              ),
              child: TextField(
                controller: _controller,
                maxLines: 4,
                maxLength: 50,
                style: const TextStyle(
                  fontFamily: 'GyeonggiBatang',
                  fontSize: 20,
                  color: Color(0xFF626262),
                ),
                decoration: const InputDecoration(
                  hintText: '질문에 답장해주세요!',
                  hintStyle: TextStyle(
                    color: Color(0xFFAAA7A7),
                    fontFamily: 'GyeonggiBatang',
                    fontSize: 18,
                  ),
                  border: InputBorder.none,
                  counterText: '',
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
          ),
          Positioned(
            bottom: -10,
            right: 20,
            child: CustomPaint(
              painter: BubbleTailPainter(
                color: const Color(0xFFE9F0FB),
                isQuestion: false,
              ),
              size: const Size(20, 20),
            ),
          ),
          Positioned(
            right: 20,
            bottom: 15,
            child: Text(
              '${_controller.text.length}/50',
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // ✅ [PopScope 적용] 뒤로가기 제어
    return PopScope(
      // 쓰기 모드(write)일 때는 맘대로 못 나감(false), 읽기 모드(read)면 자유롭게 나감(true)
      canPop: currentMode == "read",
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return; // 이미 나갔으면 무시

        // 쓰기 모드라면 팝업 띄우기
        if (currentMode == "write") {
          await _showExitDialog();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          backgroundColor: Colors.white,
          title: SizedBox(
            height: 60,
            child: Image.asset(
              'assets/cloud.png',
              errorBuilder: (context, error, stackTrace) {
                return const Text(
                  'Cloud',
                  style: TextStyle(fontSize: 24, color: Colors.grey),
                );
              },
            ),
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1.0),
            child: Container(color: const Color(0xFFEEEEEE), height: 7.0),
          ),
          elevation: 0.0,
        ),
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 10),
                      const Center(
                        child: Text(
                          "긍정 이야기",
                          style: TextStyle(
                            fontFamily: 'GyeonggiBatang',
                            fontSize: 32,
                            color: Color(0xFF1A6DFF),
                          ),
                        ),
                      ),
                      const SizedBox(height: 60),
                      Text(
                        "      #${widget.questionNumber.toString().padLeft(2, '0')}번째 질문",
                        style: const TextStyle(
                          fontSize: 18,
                          color: Color(0xFF626262),
                          fontFamily: 'GyeonggiTitle',
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 15),
                      buildBubble(text: widget.questionText, isQuestion: true),
                      const SizedBox(height: 20),

                      // ✅ 읽기 모드 & 답변 존재
                      if (answerText != null &&
                          answerText!.isNotEmpty &&
                          currentMode == "read") ...[
                        buildBubble(text: answerText!, isQuestion: false),
                        const SizedBox(height: 20),
                        Align(
                          alignment: Alignment.bottomRight,
                          child: Padding(
                            padding: const EdgeInsets.only(right: 25.0),
                            child: ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  currentMode = "write";
                                  _controller.text = answerText ?? '';
                                });
                              },
                              child: const Text('수정'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF5A9AFF),
                                foregroundColor: Colors.white,
                                minimumSize: const Size(80, 36),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                textStyle: const TextStyle(
                                  fontFamily: 'gyeonggiTitle',
                                  fontSize: 22,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],

                      // ✅ 쓰기 모드
                      if (currentMode == "write") ...[
                        buildUserInput(),
                        const SizedBox(height: 20),
                        Align(
                          alignment: Alignment.bottomRight,
                          child: Padding(
                            padding: const EdgeInsets.only(right: 25.0),
                            child: ElevatedButton(
                              onPressed: _controller.text.trim().isEmpty
                                  ? null
                                  : handleSaveOrModify,
                              child: const Text('저장'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF5A9AFF),
                                foregroundColor: Colors.white,
                                minimumSize: const Size(80, 36),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                textStyle: const TextStyle(
                                  fontFamily: 'gyeonggiTitle',
                                  fontSize: 22,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 50),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
