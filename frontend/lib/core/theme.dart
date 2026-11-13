import 'package:material_ui/material_ui.dart';

const Color dcsvNavy = Color(0xFF1E2A4A);
const Color dcsvAmber = Color(0xFFB7791F);

ThemeData buildTheme() {
  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(seedColor: dcsvNavy),
  );
}
