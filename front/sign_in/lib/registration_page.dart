import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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

  Widget _buildTextField(
    TextEditingController controller,
    String hintText,
    bool obscureText, {
    bool isBirthdateField = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30.0),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        readOnly: isBirthdateField,
        onTap: isBirthdateField ? () => _selectDate(context) : null,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(
            fontFamily: 'GyeonggiTitle',
            fontSize: 24,
            color: Color(0xFFCFCFCF),
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
      padding: const EdgeInsets.symmetric(horizontal: 30.0),
      child: Stack(
        alignment: Alignment.centerRight,
        children: [
          TextField(
            controller: idController,
            decoration: const InputDecoration(
              hintText: "아이디",
              hintStyle: TextStyle(
                fontFamily: 'GyeonggiTitle',
                fontSize: 24,
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
            bottom: 10,
            child: SizedBox(
              height: 40,
              child: ElevatedButton(
                onPressed: _checkDuplicate,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF83B3FF),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  elevation: 2,
                ),
                child: const Text(
                  "중복확인",
                  style: TextStyle(
                    fontFamily: 'GyeonggiTitle',
                    fontSize: 20,
                    color: Color(0xFFFFFFFF),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

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
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("오류 발생: $e")));
    }
  }

  Widget _buildGenderButton(String gender) {
    final isSelected = selectedGender == gender;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5.0),
      child: SizedBox(
        width: 143.0,
        height: 39.0,
        child: ElevatedButton(
          onPressed: () => _selectGender(gender),
          style: ElevatedButton.styleFrom(
            backgroundColor: isSelected
                ? const Color(0xFF9BAFFF)
                : const Color(0xFFD9D9D9),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(5.0),
            ),
            elevation: 0,
          ),
          child: Text(
            gender,
            style: const TextStyle(
              fontFamily: 'GyeonggiTitle',
              fontSize: 24,
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 30),
            const Center(
              child: Text(
                "회원가입",
                style: TextStyle(
                  fontFamily: 'Gyeonggibatang',
                  fontSize: 40,
                  color: Color(0xFF5A9AFF),
                ),
              ),
            ),
            const SizedBox(height: 70),

            _buildTextField(nameController, "이름 (실명 입력)", false),
            const SizedBox(height: 30),
            _buildIdFieldWithCheckButton(),
            const SizedBox(height: 30),
            _buildTextField(passwordController, "비밀번호", true),
            const SizedBox(height: 30),
            _buildTextField(
              birthController,
              "생년월일",
              false,
              isBirthdateField: true,
            ),
            const SizedBox(height: 40),

            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [_buildGenderButton("남성"), _buildGenderButton("여성")],
              ),
            ),
            const SizedBox(height: 30),

            // ✅ 개인정보 수집 동의 체크박스
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30.0),
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
                  const Expanded(
                    child: Text(
                      '개인정보 제 3자 제공 동의(필수)',
                      style: TextStyle(
                        fontFamily: 'GyeonggiTitle',
                        fontSize: 18,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),
            Center(
              child: SizedBox(
                width: 302,
                height: 62,
                child: ElevatedButton(
                  onPressed: agreePrivacy ? _register : null, // ✅ 동의해야 활성화
                  style: ElevatedButton.styleFrom(
                    backgroundColor: agreePrivacy
                        ? const Color(0xFF5A9AFF)
                        : Colors.grey,
                    elevation: 5.0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                  ),
                  child: const Text(
                    "회원가입",
                    style: TextStyle(
                      fontFamily: 'GyeonggiTitle',
                      fontSize: 30,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
