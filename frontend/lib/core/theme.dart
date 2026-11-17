import 'package:material_ui/material_ui.dart';

const Color dcsvNavy = Color(0xFF1E2A4A);
const Color dcsvAmber = Color(0xFFB7791F);

const Color _background = Color(0xFFF4F5F7);
const Color _border = Color(0xFFE2E5EB);

ThemeData buildTheme() {
  // Bỏ tông tím Material tự sinh: nền xám trung tính, bề mặt trắng,
  // màu chính là navy, màu nhấn là vàng đồng.
  final scheme = ColorScheme.fromSeed(seedColor: dcsvNavy).copyWith(
    primary: dcsvNavy,
    onPrimary: Colors.white,
    secondary: dcsvAmber,
    onSecondary: Colors.white,
    surface: Colors.white,
    surfaceTint: Colors.transparent,
    surfaceContainerLowest: Colors.white,
    surfaceContainerLow: Colors.white,
    surfaceContainer: Colors.white,
    surfaceContainerHigh: Colors.white,
    surfaceContainerHighest: _background,
    outlineVariant: _border,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    fontFamily: 'BeVietnamPro',
    scaffoldBackgroundColor: _background,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      scrolledUnderElevation: 0,
    ),
    // Card phẳng: viền mảnh, không bóng.
    cardTheme: CardThemeData(
      elevation: 0,
      color: Colors.white,
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: _border),
      ),
    ),
    dividerTheme: const DividerThemeData(color: _border),
    tabBarTheme: const TabBarThemeData(
      indicatorColor: dcsvAmber,
      labelColor: dcsvNavy,
      dividerColor: _border,
    ),
    inputDecorationTheme: const InputDecorationTheme(
      border: OutlineInputBorder(),
    ),
  );
}
