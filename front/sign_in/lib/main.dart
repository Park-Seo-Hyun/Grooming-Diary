import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sign_in/welcome_screen.dart';
import 'diary/diary_entry.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// ⬇️ ScreenUtil 추가
import 'package:flutter_screenutil/flutter_screenutil.dart';

// Provider 선언
class DiaryProvider extends ChangeNotifier {
  List<DiaryEntry> _entries = [];

  List<DiaryEntry> get entries => _entries;

  void addEntry(DiaryEntry entry) {
    _entries.add(entry);
    notifyListeners();
  }

  void clearEntries() {
    _entries.clear();
    notifyListeners();
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ⬇️ .env 파일 로드
  await dotenv.load(fileName: ".env");

  String albUrl = dotenv.env['BASE_URL']!.trim();

  runApp(
    ChangeNotifierProvider(
      create: (_) => DiaryProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // ⬇️ ScreenUtilInit 추가 (앱 전체에서 ScreenUtil 사용 가능)
    return ScreenUtilInit(
      designSize: const Size(360, 690), // ⬅️ 실제 디자인 기준 해상도
      minTextAdapt: true,
      builder: (context, child) {
        return MaterialApp(
          title: 'Grooming App',
          theme: ThemeData(
            scaffoldBackgroundColor: Colors.white,
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF1A6DFF),
            ),
            useMaterial3: true,
          ),
          debugShowCheckedModeBanner: false,
          home: child, // ⬅️ 초기 화면으로 LoadingScreen
        );
      },
      child: const LoadingScreen(),
    );
  }
}

class LoadingScreen extends StatefulWidget {
  const LoadingScreen({Key? key}) : super(key: key);

  @override
  _LoadingScreenState createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> {
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const WelcomeScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(height: 270.h), // ⬅️ ScreenUtil 적용 (높이)
            Image.asset(
              'assets/grooming_main.png',
              height: 170.h, // ⬅️ ScreenUtil 적용 (높이)
              fit: BoxFit.contain,
              alignment: Alignment.bottomCenter,
              errorBuilder: (context, error, stackTrace) {
                return Text(
                  'Cloud Image Placeholder',
                  style: TextStyle(
                    fontSize: 24.sp,
                    color: Colors.grey,
                  ), // ⬅️ ScreenUtil 적용 (폰트)
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
