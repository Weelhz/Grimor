import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ThemeUtils {
  // Standard color palette
  static const Color primaryColor = Color(0xFF1976D2);
  static const Color primaryColorLight = Color(0xFF42A5F5);
  static const Color primaryColorDark = Color(0xFF1565C0);
  static const Color accentColor = Color(0xFF03DAC6);
  static const Color errorColor = Color(0xFFB00020);
  static const Color warningColor = Color(0xFFFF9800);
  static const Color successColor = Color(0xFF4CAF50);
  
  // Background colors
  static const Color lightBackground = Color(0xFFFAFAFA);
  static const Color darkBackground = Color(0xFF121212);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color darkSurface = Color(0xFF1E1E1E);
  
  // Text colors
  static const Color lightTextPrimary = Color(0xFF212121);
  static const Color lightTextSecondary = Color(0xFF757575);
  static const Color darkTextPrimary = Color(0xFFFFFFFF);
  static const Color darkTextSecondary = Color(0xFFBDBDBD);
  
  // Get the current theme mode
  static ThemeMode getCurrentThemeMode(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark 
        ? ThemeMode.dark 
        : ThemeMode.light;
  }
  
  // Check if current theme is dark
  static bool isDarkMode(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark;
  }
  
  // Get primary color based on theme
  static Color getPrimaryColor(BuildContext context) {
    return Theme.of(context).primaryColor;
  }
  
  // Get background color based on theme
  static Color getBackgroundColor(BuildContext context) {
    return Theme.of(context).scaffoldBackgroundColor;
  }
  
  // Get surface color based on theme
  static Color getSurfaceColor(BuildContext context) {
    return Theme.of(context).cardColor;
  }
  
  // Get text color based on theme
  static Color getTextColor(BuildContext context) {
    return Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;
  }
  
  // Get secondary text color based on theme
  static Color getSecondaryTextColor(BuildContext context) {
    return Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey;
  }
  
  // Create a color with opacity based on theme
  static Color getColorWithOpacity(BuildContext context, Color color, double opacity) {
    return color.withOpacity(opacity);
  }
  
  // Get appropriate divider color
  static Color getDividerColor(BuildContext context) {
    return Theme.of(context).dividerColor;
  }
  
  // Get icon color based on theme
  static Color getIconColor(BuildContext context) {
    return Theme.of(context).iconTheme.color ?? Colors.grey;
  }
  
  // Get app bar color based on theme
  static Color getAppBarColor(BuildContext context) {
    return Theme.of(context).appBarTheme.backgroundColor ?? primaryColor;
  }
  
  // Create mood-based color scheme
  static ColorScheme createMoodColorScheme({
    required String moodName,
    required bool isDarkMode,
  }) {
    final moodColors = _getMoodColors(moodName);
    
    if (isDarkMode) {
      return ColorScheme.dark(
        primary: moodColors['primary']!,
        onPrimary: Colors.white,
        secondary: moodColors['secondary']!,
        onSecondary: Colors.white,
        surface: const Color(0xFF1E1E1E),
        onSurface: Colors.white,
        background: const Color(0xFF121212),
        onBackground: Colors.white,
        error: errorColor,
        onError: Colors.white,
      );
    } else {
      return ColorScheme.light(
        primary: moodColors['primary']!,
        onPrimary: Colors.white,
        secondary: moodColors['secondary']!,
        onSecondary: Colors.white,
        surface: Colors.white,
        onSurface: Colors.black,
        background: const Color(0xFFFAFAFA),
        onBackground: Colors.black,
        error: errorColor,
        onError: Colors.white,
      );
    }
  }
  
  // Get mood-specific colors
  static Map<String, Color> _getMoodColors(String moodName) {
    switch (moodName.toLowerCase()) {
      case 'calm':
        return {
          'primary': const Color(0xFF4CAF50),
          'secondary': const Color(0xFF81C784),
        };
      case 'peaceful':
        return {
          'primary': const Color(0xFF81C784),
          'secondary': const Color(0xFFA5D6A7),
        };
      case 'sad':
        return {
          'primary': const Color(0xFF2196F3),
          'secondary': const Color(0xFF64B5F6),
        };
      case 'happy':
        return {
          'primary': const Color(0xFFFFC107),
          'secondary': const Color(0xFFFFD54F),
        };
      case 'excited':
        return {
          'primary': const Color(0xFFF44336),
          'secondary': const Color(0xFFEF5350),
        };
      case 'mysterious':
        return {
          'primary': const Color(0xFF9C27B0),
          'secondary': const Color(0xFFBA68C8),
        };
      case 'romantic':
        return {
          'primary': const Color(0xFFE91E63),
          'secondary': const Color(0xFFF06292),
        };
      default:
        return {
          'primary': primaryColor,
          'secondary': accentColor,
        };
    }
  }
  
  // Create gradient based on mood
  static LinearGradient createMoodGradient({
    required String moodName,
    required bool isDarkMode,
    AlignmentGeometry begin = Alignment.topLeft,
    AlignmentGeometry end = Alignment.bottomRight,
  }) {
    final moodColors = _getMoodColors(moodName);
    final primary = moodColors['primary']!;
    final secondary = moodColors['secondary']!;
    
    if (isDarkMode) {
      return LinearGradient(
        begin: begin,
        end: end,
        colors: [
          primary.withOpacity(0.3),
          secondary.withOpacity(0.1),
          Colors.black.withOpacity(0.9),
        ],
      );
    } else {
      return LinearGradient(
        begin: begin,
        end: end,
        colors: [
          primary.withOpacity(0.2),
          secondary.withOpacity(0.1),
          Colors.white.withOpacity(0.9),
        ],
      );
    }
  }
  
  // Get reading-appropriate colors
  static Map<String, Color> getReadingColors(BuildContext context) {
    final isDark = isDarkMode(context);
    
    return {
      'background': isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF5F5F5),
      'text': isDark ? const Color(0xFFE0E0E0) : const Color(0xFF212121),
      'secondary': isDark ? const Color(0xFFBDBDBD) : const Color(0xFF757575),
      'accent': getPrimaryColor(context),
      'surface': isDark ? const Color(0xFF2D2D2D) : Colors.white,
    };
  }
  
  // Create reading theme
  static ThemeData createReadingTheme({
    required bool isDarkMode,
    required double fontSize,
    required String fontFamily,
  }) {
    final baseTheme = isDarkMode ? ThemeData.dark() : ThemeData.light();
    
    return baseTheme.copyWith(
      scaffoldBackgroundColor: isDarkMode 
          ? const Color(0xFF1A1A1A) 
          : const Color(0xFFF5F5F5),
      textTheme: baseTheme.textTheme.copyWith(
        bodyLarge: TextStyle(
          fontSize: fontSize,
          fontFamily: fontFamily,
          color: isDarkMode ? const Color(0xFFE0E0E0) : const Color(0xFF212121),
          height: 1.5,
        ),
        bodyMedium: TextStyle(
          fontSize: fontSize * 0.9,
          fontFamily: fontFamily,
          color: isDarkMode ? const Color(0xFFBDBDBD) : const Color(0xFF757575),
          height: 1.4,
        ),
      ),
    );
  }
  
  // Get system UI overlay style
  static SystemUiOverlayStyle getSystemUiOverlayStyle(BuildContext context) {
    final isDark = isDarkMode(context);
    
    return SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
      systemNavigationBarColor: getBackgroundColor(context),
      systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
    );
  }
  
  // Apply system UI overlay style
  static void applySystemUiOverlayStyle(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(getSystemUiOverlayStyle(context));
  }
  
  // Get elevation color
  static Color getElevationColor(BuildContext context, double elevation) {
    final isDark = isDarkMode(context);
    
    if (isDark) {
      // Material Design 3 elevation tinting for dark theme
      final tintOpacity = (elevation / 24).clamp(0.0, 1.0);
      return Color.lerp(
        getSurfaceColor(context),
        getPrimaryColor(context),
        tintOpacity * 0.05,
      )!;
    } else {
      return getSurfaceColor(context);
    }
  }
  
  // Create card theme
  static CardTheme createCardTheme(BuildContext context) {
    return CardTheme(
      color: getSurfaceColor(context),
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
  
  // Create button theme
  static ElevatedButtonThemeData createElevatedButtonTheme(BuildContext context) {
    return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: getPrimaryColor(context),
        elevation: 2,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
  
  // Create app bar theme
  static AppBarTheme createAppBarTheme(BuildContext context) {
    final isDark = isDarkMode(context);
    
    return AppBarTheme(
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      foregroundColor: isDark ? Colors.white : Colors.black,
      elevation: 0,
      centerTitle: true,
      systemOverlayStyle: getSystemUiOverlayStyle(context),
      titleTextStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: isDark ? Colors.white : Colors.black,
      ),
    );
  }
  
  // Create input decoration theme
  static InputDecorationTheme createInputDecorationTheme(BuildContext context) {
    return InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: getDividerColor(context)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: getDividerColor(context)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: getPrimaryColor(context), width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: errorColor),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
  }
  
  // Animate theme transition
  static Widget createThemeTransition({
    required Widget child,
    required Duration duration,
  }) {
    return AnimatedSwitcher(
      duration: duration,
      child: child,
      transitionBuilder: (Widget child, Animation<double> animation) {
        return FadeTransition(opacity: animation, child: child);
      },
    );
  }
  
  // Create shimmer effect colors
  static List<Color> getShimmerColors(BuildContext context) {
    final isDark = isDarkMode(context);
    
    if (isDark) {
      return [
        const Color(0xFF2D2D2D),
        const Color(0xFF404040),
        const Color(0xFF2D2D2D),
      ];
    } else {
      return [
        const Color(0xFFE0E0E0),
        const Color(0xFFF5F5F5),
        const Color(0xFFE0E0E0),
      ];
    }
  }
}

// Theme animation utilities
class ThemeAnimationUtils {
  static Widget createColorTransition({
    required Animation<double> animation,
    required Color fromColor,
    required Color toColor,
    required Widget child,
  }) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final color = Color.lerp(fromColor, toColor, animation.value)!;
        return ColorFiltered(
          colorFilter: ColorFilter.mode(color, BlendMode.modulate),
          child: child,
        );
      },
      child: child,
    );
  }
  
  static Widget createScaleTransition({
    required Animation<double> animation,
    required Widget child,
  }) {
    return ScaleTransition(
      scale: animation,
      child: child,
    );
  }
  
  static Widget createSlideTransition({
    required Animation<double> animation,
    required Offset offset,
    required Widget child,
  }) {
    return SlideTransition(
      position: animation.drive(Tween(begin: offset, end: Offset.zero)),
      child: child,
    );
  }
}