import 'package:flutter/material.dart';
import 'package:structia/core/constants/app_constants.dart';
import 'package:structia/core/theme/app_theme.dart';
import 'package:structia/features/home/presentation/screens/home_screen.dart';

void main() {
  runApp(const StructIAApp());
}

class StructIAApp extends StatelessWidget {
  const StructIAApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      home: const HomeScreen(),
    );
  }
}
