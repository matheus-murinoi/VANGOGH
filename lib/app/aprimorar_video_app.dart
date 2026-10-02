import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
<<<<<<< HEAD
import 'app_shell.dart';
=======
import 'launch_page.dart';
>>>>>>> origin/main

class AprimorarVideoApp extends StatelessWidget {
  const AprimorarVideoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Aprimorar Vídeo',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      themeMode: ThemeMode.dark,
<<<<<<< HEAD
      home: const AppShell(),
=======
      home: const LaunchPage(),
>>>>>>> origin/main
    );
  }
}
