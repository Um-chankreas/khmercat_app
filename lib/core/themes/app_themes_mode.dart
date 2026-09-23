import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:khmer_cat_app/core/themes/app_colors.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

double fs(double size) {
  if (kIsWeb) return size;
  final isAndroid = Platform.isAndroid;
  return isAndroid
      ? size * 0.89
      : size; // tweak multiplier to taste, e.g. 0.90–0.95
}

double lh(double height) {
  if (kIsWeb) return height;
  return Platform.isAndroid
      ? height * 0.95
      : height; // tighten slightly more on Android
}

class AppThemesMode {
  static ThemeData lightTheme = ThemeData(
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.whiteColor,
    ),
    useMaterial3: true,
    useSystemColors: true,
    platform: TargetPlatform.iOS,
    scaffoldBackgroundColor: AppColors.lightBackground,
    fontFamily: GoogleFonts.inter().fontFamily,
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      contentPadding: EdgeInsets.symmetric(
        horizontal: 8,
        vertical: Platform.isIOS ? 16 : 8,
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.red),
        borderRadius: BorderRadius.circular(16),
      ),
      errorBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.red),
        borderRadius: BorderRadius.circular(16),
      ),
      fillColor: AppColors.whiteColor,
      hintStyle: GoogleFonts.inter(
        fontWeight: FontWeight.w400,
        fontSize: fs(16),
        color: AppColors.lightGrey.withValues(alpha: 0.4),
        height: lh(1.3),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: AppColors.lightGrey.withValues(alpha: 0.1),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: AppColors.lightGrey.withValues(alpha: 0.1),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: AppColors.lightGrey.withValues(alpha: 0.4),
        ),
      ),
    ),
    appBarTheme: AppBarTheme(
      centerTitle: false,
      toolbarHeight: 56,
      backgroundColor: AppColors.whiteColor,
    ),
    textTheme: GoogleFonts.interTextTheme().copyWith(
      titleMedium: GoogleFonts.inter(
        fontWeight: FontWeight.w600,
        fontSize: fs(16),
        height: lh(1.3),
      ),
      titleLarge: GoogleFonts.inter(
        fontWeight: FontWeight.w600,
        fontSize: fs(20),
        height: lh(1.3),
      ),
      bodyLarge: GoogleFonts.inter(
        fontWeight: FontWeight.w400,
        fontSize: fs(18),
        height: lh(1.3),
      ),
      bodyMedium: GoogleFonts.inter(
        fontWeight: FontWeight.w400,
        fontSize: fs(16),
        height: lh(1.3),
      ),
      bodySmall: GoogleFonts.inter(
        fontWeight: FontWeight.w400,
        fontSize: fs(14),
        height: lh(1.3),
      ),
    ),
    colorScheme:
        .fromSeed(
          seedColor: AppColors.appPrimaryBlue,
          brightness: Brightness.light,
          surface: AppColors.whiteColor,
          contrastLevel: 0,
        ).copyWith(
          surface: AppColors.whiteColor,
          primary: AppColors.appPrimaryBlue,
          onSurface: Colors.black,
          secondary: AppColors.lightGrey,
        ),
  );

  static ThemeData darkTheme = ThemeData(
    scaffoldBackgroundColor: AppColors.darkColor,
    useMaterial3: true,
    textTheme: GoogleFonts.interTextTheme().copyWith(
      titleMedium: GoogleFonts.inter(
        fontWeight: FontWeight.w600,
        fontSize: fs(16),
      ),
      titleLarge: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 20),
      bodyLarge: GoogleFonts.inter(fontWeight: FontWeight.w400, fontSize: 18),
      bodyMedium: GoogleFonts.inter(fontWeight: FontWeight.w400, fontSize: 16),
      bodySmall: GoogleFonts.inter(fontWeight: FontWeight.w400, fontSize: 14),
    ),
    colorScheme:
        .fromSeed(
          seedColor: AppColors.appPrimaryBlue,
          brightness: Brightness.dark,
          surface: AppColors.darkGray,
          contrastLevel: 0,
        ).copyWith(
          surface: AppColors.darkGray,
          primary: AppColors.appPrimaryBlue,
          secondary: AppColors.lightGrey,
          onSurface: Colors.white,
        ),
  );
}
