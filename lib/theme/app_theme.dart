import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  AppColors._();

  static const inkNavy = Color(0xFF14262E);
  static const inkNavyDark = Color(0xFF0D1B21);
  static const parchment = Color(0xFFF2E9D6);
  static const parchmentShade = Color(0xFFE6DAC0);
  static const brass = Color(0xFFB98B2E);
  static const brassLight = Color(0xFFD3AC5C);
  static const emerald = Color(0xFF1F6F54);
  static const brick = Color(0xFF9A3B2B);
  static const inkText = Color(0xFF1C2B2E);
  static const mutedInk = Color(0xFF5C6B6E);
}

class AppTypography {
  AppTypography._();

  static TextStyle eyebrow = GoogleFonts.ibmPlexSans(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    letterSpacing: 2.2,
    color: AppColors.mutedInk,
  );

  static TextStyle amount({Color? color, double fontSize = 20}) {
    return GoogleFonts.ibmPlexMono(
      fontSize: fontSize,
      fontWeight: FontWeight.w600,
      color: color ?? AppColors.inkText,
    );
  }
}

class AppTheme {
  AppTheme._();

  static ThemeData get light {
    final base = ThemeData(useMaterial3: true, brightness: Brightness.light);

    return base.copyWith(
      scaffoldBackgroundColor: AppColors.inkNavy,
      colorScheme: base.colorScheme.copyWith(
        primary: AppColors.brass,
        onPrimary: AppColors.inkNavy,
        secondary: AppColors.emerald,
        error: AppColors.brick,
        surface: AppColors.parchment,
        onSurface: AppColors.inkText,
      ),
      textTheme: TextTheme(
        displaySmall: GoogleFonts.fraunces(
          fontSize: 30,
          fontWeight: FontWeight.w600,
          color: AppColors.inkText,
        ),
        titleLarge: GoogleFonts.fraunces(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: AppColors.inkText,
        ),
        titleMedium: GoogleFonts.ibmPlexSans(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.inkText,
        ),
        bodyLarge: GoogleFonts.ibmPlexSans(
          fontSize: 15,
          color: AppColors.inkText,
        ),
        bodyMedium: GoogleFonts.ibmPlexSans(
          fontSize: 14,
          color: AppColors.inkText,
        ),
        bodySmall: GoogleFonts.ibmPlexSans(
          fontSize: 12,
          color: AppColors.mutedInk,
        ),
        labelLarge: GoogleFonts.ibmPlexSans(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.0,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
        labelStyle: GoogleFonts.ibmPlexSans(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.0,
          color: AppColors.mutedInk,
        ),
        floatingLabelStyle: GoogleFonts.ibmPlexSans(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.0,
          color: AppColors.brass,
        ),
        border: const UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.mutedInk, width: 1),
        ),
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(
            color: AppColors.mutedInk.withValues(alpha: 0.45),
            width: 1,
          ),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.brass, width: 2),
        ),
        errorBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.brick, width: 1),
        ),
        focusedErrorBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.brick, width: 2),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.brass,
          foregroundColor: AppColors.inkNavy,
          disabledBackgroundColor: AppColors.brass.withValues(alpha: 0.5),
          minimumSize: const Size.fromHeight(52),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          textStyle: GoogleFonts.ibmPlexSans(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.1,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.parchment,
          textStyle: GoogleFonts.ibmPlexSans(fontWeight: FontWeight.w600),
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.brass
              : Colors.transparent,
        ),
        side: const BorderSide(color: AppColors.mutedInk, width: 1.4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.inkNavy,
        foregroundColor: AppColors.parchment,
        elevation: 0,
        titleTextStyle: GoogleFonts.fraunces(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColors.parchment,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.parchment,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.inkNavyDark,
        contentTextStyle: GoogleFonts.ibmPlexSans(color: AppColors.parchment),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class LedgerRule extends StatelessWidget {
  final int ticks;
  const LedgerRule({super.key, this.ticks = 28});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 14,
      child: Row(
        children: List.generate(ticks, (i) {
          final tall = i % 5 == 0;
          return Expanded(
            child: Align(
              alignment: Alignment.topCenter,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 1),
                width: 1.4,
                height: tall ? 14 : 7,
                color: AppColors.brass.withValues(alpha: tall ? 0.9 : 0.35),
              ),
            ),
          );
        }),
      ),
    );
  }
}