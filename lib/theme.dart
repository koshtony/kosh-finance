import 'package:flutter/material.dart';

/// Kosh brand palette — a warm honey/hive theme.
const Color kBrandColor = Color(0xFFD97706); // honey amber
const Color kBrandDark = Color(0xFF3E2723); // hive brown
const Color kHoneyLight = Color(0xFFFDE68A); // pale honeycomb
const Color kCreamBackground = Color(0xFFFFFBF0);

const Color kPositiveColor = Color(0xFF4D7C0F); // olive green — profit/good
const Color kWarningColor = Color(0xFFC2410C); // burnt orange — over budget
const Color kNeutralColor = Color(0xFF78716C); // warm stone gray

ThemeData buildAppTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: kBrandColor,
    brightness: Brightness.light,
  ).copyWith(
    primary: kBrandColor,
    secondary: kBrandDark,
    surface: Colors.white,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: kCreamBackground,
    fontFamily: 'Roboto',
    appBarTheme: const AppBarTheme(
      centerTitle: false,
      elevation: 0,
      scrolledUnderElevation: 1,
      backgroundColor: kCreamBackground,
      foregroundColor: kBrandDark,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.white,
      indicatorColor: kHoneyLight,
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return TextStyle(
          fontSize: 11,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          color: selected ? kBrandDark : kNeutralColor,
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return IconThemeData(color: selected ? kBrandDark : kNeutralColor);
      }),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFEEE3CC)),
      ),
      margin: EdgeInsets.zero,
    ),
    tabBarTheme: TabBarThemeData(
      labelColor: kBrandDark,
      unselectedLabelColor: kNeutralColor,
      indicatorColor: kBrandColor,
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: kBrandColor,
      foregroundColor: Colors.white,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: kBrandColor,
        foregroundColor: Colors.white,
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: kBrandColor,
        foregroundColor: Colors.white,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: kBrandColor, width: 2),
      ),
      filled: true,
      fillColor: Colors.white,
    ),
  );
}

String formatMoney(num? v) {
  if (v == null) return '—';
  final isNegative = v < 0;
  final abs = v.abs();
  final s = abs.toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
        (m) => '${m[1]},',
      );
  return '${isNegative ? '-' : ''}KES $s';
}
