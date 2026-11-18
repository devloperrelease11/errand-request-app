import 'package:material_ui/material_ui.dart';

class AppTheme {
  static const seedColor = Color(0xFF2E6F5E);

  static ThemeData get light => ThemeData(
    colorScheme: ColorScheme.fromSeed(seedColor: seedColor),
    useMaterial3: true,
    appBarTheme: const AppBarTheme(centerTitle: true),
    inputDecorationTheme: const InputDecorationTheme(
      border: OutlineInputBorder(),
      filled: true,
    ),
  );
}
