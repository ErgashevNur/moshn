import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get dark => ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF09090A),
        colorScheme: const ColorScheme.dark(
          surface: Color(0xFF1A1A1E),
          primary: Color(0xFFF4F4F2),
          onPrimary: Color(0xFF0A0A0B),
        ),
        textTheme: GoogleFonts.soraTextTheme(ThemeData.dark().textTheme),
        useMaterial3: true,
        appBarTheme: AppBarTheme(
          backgroundColor: const Color(0xFF09090A),
          foregroundColor: const Color(0xFFF4F4F2),
          elevation: 0,
          scrolledUnderElevation: 0,
          titleTextStyle: GoogleFonts.sora(
            fontSize: 19,
            fontWeight: FontWeight.w600,
            color: const Color(0xFFF4F4F2),
            letterSpacing: 19 * -0.02,
          ),
        ),
        cardTheme: CardThemeData(
          color: const Color(0xFF1A1A1E),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
            side: const BorderSide(color: Color(0x16FFFFFF), width: 1),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF1A1A1E),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0x16FFFFFF), width: 1),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0x16FFFFFF), width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide:
                const BorderSide(color: Color(0xFFF4F4F2), width: 1.5),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          hintStyle: const TextStyle(color: Color(0x99F4F4F2), fontSize: 15),
          labelStyle:
              const TextStyle(color: Color(0x99F4F4F2), fontSize: 15),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFF4F4F2),
            foregroundColor: const Color(0xFF0A0A0B),
            elevation: 0,
            minimumSize: const Size(double.infinity, 54),
            shape: const StadiumBorder(),
            textStyle: GoogleFonts.sora(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: const Color(0xFF131316),
          selectedItemColor: const Color(0xFFF4F4F2),
          unselectedItemColor: const Color(0x99F4F4F2),
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          selectedLabelStyle: GoogleFonts.sora(
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: GoogleFonts.sora(
            fontSize: 10.5,
            fontWeight: FontWeight.w400,
          ),
        ),
      );

  static ThemeData get light => ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFF4F3F0),
        colorScheme: const ColorScheme.light(
          surface: Color(0xFFFFFFFF),
          primary: Color(0xFF14140F),
          onPrimary: Color(0xFFF6F5F2),
        ),
        textTheme: GoogleFonts.soraTextTheme(ThemeData.light().textTheme),
        useMaterial3: true,
        appBarTheme: AppBarTheme(
          backgroundColor: const Color(0xFFF4F3F0),
          foregroundColor: const Color(0xFF14140F),
          elevation: 0,
          scrolledUnderElevation: 0,
          titleTextStyle: GoogleFonts.sora(
            fontSize: 19,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF14140F),
            letterSpacing: 19 * -0.02,
          ),
        ),
        cardTheme: CardThemeData(
          color: const Color(0xFFFFFFFF),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
            side: const BorderSide(color: Color(0x1714140F), width: 1),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFFFFFFF),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0x1714140F), width: 1),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0x1714140F), width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide:
                const BorderSide(color: Color(0xFF14140F), width: 1.5),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          hintStyle: const TextStyle(color: Color(0x9414140F), fontSize: 15),
          labelStyle:
              const TextStyle(color: Color(0x9414140F), fontSize: 15),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF14140F),
            foregroundColor: const Color(0xFFF6F5F2),
            elevation: 0,
            minimumSize: const Size(double.infinity, 54),
            shape: const StadiumBorder(),
            textStyle: GoogleFonts.sora(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: const Color(0xFFFFFFFF),
          selectedItemColor: const Color(0xFF14140F),
          unselectedItemColor: const Color(0x9414140F),
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          selectedLabelStyle: GoogleFonts.sora(
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: GoogleFonts.sora(
            fontSize: 10.5,
            fontWeight: FontWeight.w400,
          ),
        ),
      );
}
