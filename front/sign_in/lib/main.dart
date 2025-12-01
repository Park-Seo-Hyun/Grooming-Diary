import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sign_in/welcome_screen.dart';
import 'diary/diary_entry.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // ⬅️ 추가됨

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
    return MaterialApp(
      title: 'Grooming App',
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.white,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1A6DFF)),
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
      home: const LoadingScreen(),
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
    await Future.delayed(const Duration(seconds: 3));
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
            const SizedBox(height: 270),
            Image.asset(
              'assets/grooming_main.png',
              height: 230,
              fit: BoxFit.contain,
              alignment: Alignment.bottomCenter,
              errorBuilder: (context, error, stackTrace) {
                return const Text(
                  'Cloud Image Placeholder',
                  style: TextStyle(fontSize: 24, color: Colors.grey),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
