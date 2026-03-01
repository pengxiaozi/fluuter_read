import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'screens/dictionary_screen.dart';
import 'screens/practice_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/study_log_screen.dart';
import 'services/hive_service.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await HiveService.init();
  runApp(const ProviderScope(child: MainApp()));
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  int _currentIndex = 1;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '离线肌肉记忆背单词',
      // 🎨 应用新的设计系统主题
      theme: AppTheme.lightTheme,
      home: Scaffold(
        body: IndexedStack(
          index: _currentIndex,
          children: const [
            DictionaryScreen(),
            PracticeScreen(),
            StudyLogScreen(),
            SettingsScreen(),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.menu_book_outlined),
              label: '词典',
            ),
            NavigationDestination(
              icon: Icon(Icons.fitness_center_outlined),
              label: '练习',
            ),
            NavigationDestination(
              icon: Icon(Icons.history),
              label: '记录',
            ),
            NavigationDestination(
              icon: Icon(Icons.settings),
              label: '设置',
            ),
          ],
        ),
      ),
    );
  }
}

