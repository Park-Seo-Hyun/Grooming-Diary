import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart'; // 🔹 ScreenUtil 추가
import 'services/auth_service.dart';
import 'welcome_screen.dart';

class RegistrationPage extends StatefulWidget {
  const RegistrationPage({super.key});

  @override
  State<RegistrationPage> createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController idController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController birthController = TextEditingController();

  String? selectedGender;
  DateTime? selectedDate;
  bool agreePrivacy = false; // ✅ 개인정보 수집 동의 체크 상태
  bool isIdChecked = false; // 🔹 아이디 중복 확인 여부
  final AuthService _authService = AuthService();

  @override
  void dispose() {
    nameController.dispose();
    idController.dispose();
    passwordController.dispose();
    birthController.dispose();
    super.dispose();
  }

  void _selectGender(String gender) {
    setState(() {
      selectedGender = gender;
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1950),
      lastDate: DateTime(2100),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF5A9AFF),
              onPrimary: Colors.white,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: Color(0xFF5A9AFF)),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
        birthController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  // 🔹 TextField 크기 조정 ScreenUtil 적용
  Widget _buildTextField(
    TextEditingController controller,
    String hintText,
    bool obscureText, {
    bool isBirthdateField = false,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 30.w), // 🔹 수정
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        readOnly: isBirthdateField,
        onTap: isBirthdateField ? () => _selectDate(context) : null,
        style: TextStyle(fontSize: 20.sp), // 🔹 ScreenUtil 적용
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(
            fontFamily: 'GyeonggiTitle',
            fontSize: 20.sp, // 🔹 ScreenUtil 적용
            color: const Color(0xFFCFCFCF),
          ),
          suffixIcon: isBirthdateField
              ? const Icon(Icons.calendar_month, color: Color(0xFFCFCFCF))
              : null,
          enabledBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: Color(0xFFCFCFCF), width: 3.0),
          ),
          focusedBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: Color(0xFF5A9AFF), width: 3.0),
          ),
        ),
      ),
    );
  }

  Widget _buildIdFieldWithCheckButton() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 30.w), // 🔹 ScreenUtil 적용
      child: Stack(
        alignment: Alignment.centerRight,
        children: [
          TextField(
            controller: idController,
            style: TextStyle(fontSize: 15.sp), // 🔹 ScreenUtil 적용
            decoration: const InputDecoration(
              hintText: "아이디",
              hintStyle: TextStyle(
                fontFamily: 'GyeonggiTitle',
                fontSize: 20,
                color: Color(0xFFCFCFCF),
              ),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Color(0xFFCFCFCF), width: 3.0),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Color(0xFF5A9AFF), width: 3.0),
              ),
            ),
          ),
          Positioned(
            right: 0,
            bottom: 8.h, // 🔹 ScreenUtil 적용
            child: SizedBox(
              height: 30.h, // 🔹 ScreenUtil 적용
              child: ElevatedButton(
                onPressed: _checkDuplicate, // ✅ 함수 그대로 유지
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF83B3FF),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      10.r,
                    ), // 🔹 ScreenUtil 적용
                  ),
                  padding: EdgeInsets.symmetric(
                    horizontal: 20.w,
                  ), // 🔹 ScreenUtil 적용
                  elevation: 2,
                ),
                child: Text(
                  "중복확인",
                  style: TextStyle(
                    fontFamily: 'GyeonggiTitle',
                    fontSize: 15.sp, // 🔹 ScreenUtil 적용
                    color: const Color(0xFFFFFFFF),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 🔹 기존 중복 확인 함수 그대로 유지, 성공 시 isIdChecked true
  Future<void> _checkDuplicate() async {
    final id = idController.text.trim();
    if (id.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('아이디를 입력해주세요.')));
      return;
    }

    try {
      final result = await _authService.checkDuplicateId(id);
      final isAvailable = result["is_available"] ?? false;
      final message = result["message"] ?? "";

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isAvailable
                ? (message.isNotEmpty ? message : "사용 가능한 아이디입니다.")
                : (message.isNotEmpty ? message : "이미 사용 중인 아이디입니다."),
          ),
        ),
      );

      setState(() {
        isIdChecked = isAvailable; // 🔹 중복 확인 성공 여부 저장
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("오류 발생: $e")));
    }
  }

  Widget _buildGenderButton(String gender) {
    final isSelected = selectedGender == gender;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 5.w), // 🔹 ScreenUtil 적용
      child: SizedBox(
        width: 143.w, // 🔹 ScreenUtil 적용
        height: 39.h, // 🔹 ScreenUtil 적용
        child: ElevatedButton(
          onPressed: () => _selectGender(gender),
          style: ElevatedButton.styleFrom(
            backgroundColor: isSelected
                ? const Color(0xFF9BAFFF)
                : const Color(0xFFD9D9D9),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(5.r), // 🔹 ScreenUtil 적용
            ),
            elevation: 0,
          ),
          child: Text(
            gender,
            style: TextStyle(
              fontFamily: 'GyeonggiTitle',
              fontSize: 22.sp, // 🔹 ScreenUtil 적용
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _register() async {
    final name = nameController.text.trim();
    final id = idController.text.trim();
    final password = passwordController.text.trim();
    final birth = birthController.text.trim();

    if (name.isEmpty ||
        id.isEmpty ||
        password.isEmpty ||
        birth.isEmpty ||
        selectedGender == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('모든 항목을 입력해주세요.')));
      return;
    }

    final result = await _authService.register(
      userName: name,
      userId: id,
      userPwd: password,
      birthDate: birth,
      gender: selectedGender!,
    );

    if (result["success"] == true) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('✅ 회원가입 성공! 이제 로그인해주세요.')));
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const WelcomeScreen()),
      );
    } else {
      final message = result["message"] ?? "회원가입 실패";
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("회원가입 실패"),
          content: Text(
            message == "USER_ALREADY_EXISTS" ? "이미 존재하는 아이디입니다." : message,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("확인"),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.white,
        title: SizedBox(
          height: 60.h, // 🔹 ScreenUtil 적용
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
          preferredSize: Size.fromHeight(5.h), // 🔹 ScreenUtil 적용
          child: Container(color: const Color(0xFFEEEEEE), height: 5.h),
        ),
        elevation: 0.0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.w), // 🔹 ScreenUtil 적용
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: 15.h), // 🔹 ScreenUtil 적용
            Center(
              child: Text(
                "회원가입",
                style: TextStyle(
                  fontFamily: 'Gyeonggibatang',
                  fontSize: 33.sp, // 🔹 ScreenUtil 적용
                  color: const Color(0xFF5A9AFF),
                ),
              ),
            ),
            SizedBox(height: 40.h), // 🔹 ScreenUtil 적용

            _buildTextField(nameController, "이름 (실명 입력)", false),
            SizedBox(height: 25.h), // 🔹 ScreenUtil 적용
            _buildIdFieldWithCheckButton(),
            SizedBox(height: 25.h), // 🔹 ScreenUtil 적용
            _buildTextField(passwordController, "비밀번호", true),
            SizedBox(height: 25.h), // 🔹 ScreenUtil 적용
            _buildTextField(
              birthController,
              "생년월일",
              false,
              isBirthdateField: true,
            ),
            SizedBox(height: 35.h), // 🔹 ScreenUtil 적용

            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [_buildGenderButton("남성"), _buildGenderButton("여성")],
              ),
            ),
            SizedBox(height: 15.h), // 🔹 ScreenUtil 적용
            // ✅ 개인정보 수집 동의 체크박스
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: 15.w,
              ), // 🔹 ScreenUtil 적용
              child: Row(
                children: [
                  Checkbox(
                    value: agreePrivacy,
                    onChanged: (bool? value) {
                      setState(() {
                        agreePrivacy = value ?? false;
                      });
                    },
                    activeColor: const Color(0xFF5A9AFF),
                  ),
                  Expanded(
                    child: Text(
                      '개인정보 제 3자 제공 동의(필수)',
                      style: TextStyle(
                        fontFamily: 'GyeonggiTitle',
                        fontSize: 16.sp, // 🔹 ScreenUtil 적용
                      ),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 15.h), // 🔹 ScreenUtil 적용
            Center(
              child: SizedBox(
                width: 295.w, // 🔹 ScreenUtil 적용
                height: 59.h, // 🔹 ScreenUtil 적용
                child: ElevatedButton(
                  // 🔹 동의 + 아이디 중복 확인 완료 시 활성화
                  onPressed: agreePrivacy && isIdChecked ? _register : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: agreePrivacy && isIdChecked
                        ? const Color(0xFF5A9AFF)
                        : Colors.grey,
                    elevation: 5.0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        10.r,
                      ), // 🔹 ScreenUtil 적용
                    ),
                  ),
                  child: Text(
                    "회원가입",
                    style: TextStyle(
                      fontFamily: 'GyeonggiTitle',
                      fontSize: 30.sp, // 🔹 ScreenUtil 적용
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: 20.h), // 🔹 ScreenUtil 적용
          ],
        ),
      ),
    );
  }
}
