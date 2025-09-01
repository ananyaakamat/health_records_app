import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/themes/app_theme.dart';
import 'core/constants/app_constants.dart';
import 'presentation/screens/home_screen.dart';
import 'presentation/providers/theme_provider.dart';

void main() {
  runApp(const ProviderScope(child: HealthRecordsApp()));
}

class HealthRecordsApp extends ConsumerWidget {
  const HealthRecordsApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);

    return MaterialApp(
      title: AppConstants.appName,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      home: const HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
