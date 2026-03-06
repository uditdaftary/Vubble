import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

// ─────────────────────────────────────────────
//  COLORS
// ─────────────────────────────────────────────
class AppColors {
  AppColors._();

  static const Color bg           = Color(0xFF08080E);
  static const Color surface      = Color(0xFF0F0F1A);
  static const Color surfaceHigh  = Color(0xFF181828);
  static const Color violet       = Color(0xFF7B2FFF);
  static const Color lime         = Color(0xFFC8FF00);
  static const Color coral        = Color(0xFFFF3D5F);
  static const Color cyan         = Color(0xFF00D9FF);
  static const Color amber        = Color(0xFFFFB020);
  static const Color textPrimary  = Color(0xFFF0F0FF);
  static const Color textMuted    = Color(0xFF8888AA);
  static const Color border       = Color(0xFF222235);
}

// ─────────────────────────────────────────────
//  TEXT STYLES  (Syne headings · Plus Jakarta Sans body)
// ─────────────────────────────────────────────
class AppText {
  AppText._();

  static TextStyle display({double size = 30}) => GoogleFonts.syne(
    fontSize: size, fontWeight: FontWeight.w800,
    color: AppColors.textPrimary, letterSpacing: -0.6,
  );

  static TextStyle heading({double size = 20}) => GoogleFonts.syne(
    fontSize: size, fontWeight: FontWeight.w700,
    color: AppColors.textPrimary, letterSpacing: -0.3,
  );

  static TextStyle body({double size = 14, Color? color}) =>
    GoogleFonts.plusJakartaSans(
      fontSize: size, fontWeight: FontWeight.w400,
      color: color ?? AppColors.textPrimary,
    );

  static TextStyle label({double size = 11, Color? color}) =>
    GoogleFonts.plusJakartaSans(
      fontSize: size, fontWeight: FontWeight.w700,
      color: color ?? AppColors.textMuted, letterSpacing: 1.3,
    );

  /// Use this for ALL TextFormField `style:` — black text, visible on white fill
  static TextStyle input({double size = 14}) => GoogleFonts.plusJakartaSans(
    fontSize: size, fontWeight: FontWeight.w500,
    color: const Color(0xFF0D0D1A),
  );

  static TextStyle price({double size = 20, Color? color}) =>
    GoogleFonts.syne(
      fontSize: size, fontWeight: FontWeight.w800,
      color: color ?? AppColors.lime,
    );
}

// ─────────────────────────────────────────────
//  THEME DATA
// ─────────────────────────────────────────────
class AppTheme {
  AppTheme._();

  static ThemeData get dark => ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.bg,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.violet,
      secondary: AppColors.lime,
      surface: AppColors.surface,
      error: AppColors.coral,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.bg,
      elevation: 0,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      titleTextStyle: GoogleFonts.syne(
        fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary,
      ),
      iconTheme: const IconThemeData(color: AppColors.textPrimary),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFDDDDEE)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFDDDDEE)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.violet, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.coral),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.coral, width: 1.5),
      ),
      // ← typed text: always dark/readable on white fill
      hintStyle: GoogleFonts.plusJakartaSans(
        color: Color(0xFF9999AA), fontSize: 14),
      counterStyle: GoogleFonts.plusJakartaSans(
        color: Color(0xFF9999AA), fontSize: 11),
      prefixIconColor: Color(0xFF9999AA),
      suffixIconColor: Color(0xFF9999AA),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.violet,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: GoogleFonts.syne(fontSize: 15, fontWeight: FontWeight.w700),
      ),
    ),
  );
}

// ─────────────────────────────────────────────
//  CATEGORY UTILITIES
// ─────────────────────────────────────────────
class GigCategory {
  GigCategory._();

  static const Map<String, Color> colors = {
    'Tutoring' : AppColors.violet,
    'Delivery' : AppColors.cyan,
    'Writing'  : AppColors.lime,
    'Coding'   : AppColors.amber,
    'Errands'  : AppColors.coral,
    'Other'    : Color(0xFF7777AA),
  };

  static const Map<String, String> emojis = {
    'Tutoring' : '📚',
    'Delivery' : '🚚',
    'Writing'  : '✍️',
    'Coding'   : '💻',
    'Errands'  : '🏃',
    'Other'    : '⚡',
  };

  static Color colorOf(String cat) => colors[cat] ?? const Color(0xFF7777AA);
  static String emojiOf(String cat) => emojis[cat] ?? '⚡';
}

class RentalCategory {
  RentalCategory._();

  static const Map<String, Color> colors = {
    'Electronics' : AppColors.cyan,
    'Lab Gear'    : AppColors.violet,
    'Books'       : AppColors.lime,
    'Sports'      : AppColors.coral,
    'Clothing'    : AppColors.amber,
    'Other'       : Color(0xFF7777AA),
  };

  static const Map<String, String> emojis = {
    'Electronics' : '📷',
    'Lab Gear'    : '🔬',
    'Books'       : '📖',
    'Sports'      : '⚽',
    'Clothing'    : '🥼',
    'Other'       : '📦',
  };

  static Color colorOf(String cat) => colors[cat] ?? const Color(0xFF7777AA);
  static String emojiOf(String cat) => emojis[cat] ?? '📦';
}

// ─────────────────────────────────────────────
//  SHARED WIDGETS
// ─────────────────────────────────────────────

/// Gradient-border card wrapper
class GlowCard extends StatelessWidget {
  final Widget child;
  final List<Color>? gradientColors;
  final double radius;
  final EdgeInsetsGeometry? padding;

  const GlowCard({
    super.key,
    required this.child,
    this.gradientColors,
    this.radius = 16,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final colors = gradientColors ?? [AppColors.violet, AppColors.cyan];
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: colors),
        borderRadius: BorderRadius.circular(radius),
      ),
      padding: const EdgeInsets.all(1.5),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(radius - 1.5),
        ),
        padding: padding,
        child: child,
      ),
    );
  }
}

/// Solid surface card
class SurfaceCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double radius;
  final Color? borderColor;

  const SurfaceCard({
    super.key,
    required this.child,
    this.padding,
    this.radius = 16,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: borderColor ?? AppColors.border),
      ),
      child: child,
    );
  }
}

/// Pill badge (category chip)
class CategoryBadge extends StatelessWidget {
  final String label;
  final Color color;
  final String? emoji;

  const CategoryBadge({super.key, required this.label, required this.color, this.emoji});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (emoji != null) ...[
            Text(emoji!, style: const TextStyle(fontSize: 11)),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11, fontWeight: FontWeight.w700, color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/// Gradient CTA button
class GradientButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final List<Color>? colors;
  final bool isLoading;
  final double? width;

  const GradientButton({
    super.key,
    required this.label,
    this.onTap,
    this.colors,
    this.isLoading = false,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    final grad = colors ?? [AppColors.violet, const Color(0xFF5500FF)];
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        width: width,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: grad),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: grad.first.withOpacity(0.35),
              blurRadius: 18, offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Center(
          child: isLoading
            ? const SizedBox(
                width: 22, height: 22,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
              )
            : Text(label, style: GoogleFonts.syne(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
        ),
      ),
    );
  }
}

/// Star rating row
class StarRating extends StatelessWidget {
  final double rating;
  final int count;

  const StarRating({super.key, required this.rating, this.count = 0});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '★ $rating',
          style: GoogleFonts.syne(
            fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.amber,
          ),
        ),
        if (count > 0) ...[
          const SizedBox(width: 4),
          Text(
            '($count)',
            style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.textMuted),
          ),
        ],
      ],
    );
  }
}