import 'package:flutter/material.dart';

/// Tema futurista com estilo neon, escuro e azul
class AppTheme {
  // Cores base - Escuro
  static const Color _backgroundDark = Color(0xFF0A0E27);
  static const Color _surfaceDark = Color(0xFF151932);
  static const Color _surfaceVariantDark = Color(0xFF1E2340);
  
  // Cores neon azul
  static const Color _neonBlue = Color(0xFF00D9FF);
  static const Color _neonBlueBright = Color(0xFF00F0FF);
  static const Color _neonBlueDark = Color(0xFF0099CC);
  static const Color _neonCyan = Color(0xFF00FFFF);
  static const Color _neonPurple = Color(0xFF7B2CBF);
  static const Color _neonIndigo = Color(0xFF4F46E5);
  
  // Cores de texto
  static const Color _textPrimary = Color(0xFFE8EAFF);
  static const Color _textSecondary = Color(0xFFA0A5C7);
  static const Color _textTertiary = Color(0xFF6B7280);
  
  // Cores de estado
  static const Color _error = Color(0xFFFF3B5C);
  static const Color _success = Color(0xFF00FF88);
  static const Color _warning = Color(0xFFFFC700);
  
  /// Retorna o tema escuro futurista
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      
      // Esquema de cores
      colorScheme: ColorScheme.dark(
        primary: _neonBlue,
        onPrimary: _backgroundDark,
        primaryContainer: _neonBlue.withOpacity(0.2),
        onPrimaryContainer: _neonCyan,
        
        secondary: _neonCyan,
        onSecondary: _backgroundDark,
        secondaryContainer: _neonCyan.withOpacity(0.2),
        onSecondaryContainer: _neonBlue,
        
        tertiary: _neonPurple,
        onTertiary: Colors.white,
        
        error: _error,
        onError: Colors.white,
        errorContainer: _error.withOpacity(0.2),
        
        surface: _surfaceDark,
        onSurface: _textPrimary,
        surfaceVariant: _surfaceVariantDark,
        onSurfaceVariant: _textSecondary,
        
        background: _backgroundDark,
        onBackground: _textPrimary,
        
        outline: _neonBlue.withOpacity(0.3),
        outlineVariant: _neonBlue.withOpacity(0.1),
        
        shadow: Colors.black.withOpacity(0.5),
      ),
      
      // Scaffold
      scaffoldBackgroundColor: _backgroundDark,
      
      // AppBar
      appBarTheme: AppBarTheme(
        backgroundColor: _surfaceDark,
        foregroundColor: _textPrimary,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          color: _textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
        iconTheme: IconThemeData(
          color: _neonBlue,
          size: 24,
        ),
      ),
      
      // Card
      cardTheme: CardThemeData(
        color: _surfaceVariantDark,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: _neonBlue.withOpacity(0.2),
            width: 1,
          ),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),
      
      // Input Decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _surfaceDark,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: _neonBlue.withOpacity(0.3),
            width: 1.5,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: _neonBlue.withOpacity(0.3),
            width: 1.5,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: _neonBlue,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: _error,
            width: 1.5,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: _error,
            width: 2,
          ),
        ),
        labelStyle: TextStyle(
          color: _textSecondary,
          fontSize: 14,
        ),
        hintStyle: TextStyle(
          color: _textTertiary,
          fontSize: 14,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      
      // Button Themes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _neonBlue,
          foregroundColor: _backgroundDark,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
      
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: _neonBlue,
          foregroundColor: _backgroundDark,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
      
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: _neonBlue,
          side: BorderSide(
            color: _neonBlue,
            width: 1.5,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
      
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: _neonBlue,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
      
      // Icon Theme
      iconTheme: IconThemeData(
        color: _neonBlue,
        size: 24,
      ),
      
      // Chip Theme
      chipTheme: ChipThemeData(
        backgroundColor: _surfaceDark,
        deleteIconColor: _error,
        labelStyle: TextStyle(
          color: _textPrimary,
          fontSize: 12,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
          side: BorderSide(
            color: _neonBlue.withOpacity(0.2),
            width: 1,
          ),
        ),
      ),
      
      // Divider
      dividerTheme: DividerThemeData(
        color: _neonBlue.withOpacity(0.2),
        thickness: 1,
        space: 1,
      ),
      
      // ListTile
      listTileTheme: ListTileThemeData(
        textColor: _textPrimary,
        iconColor: _neonBlue,
        selectedTileColor: _neonBlue.withOpacity(0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      
      // Menu Bar
      menuBarTheme: MenuBarThemeData(
        style: MenuStyle(
          backgroundColor: WidgetStateProperty.all(_surfaceDark),
          elevation: WidgetStateProperty.all(0),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),
      
      // Popup Menu
      popupMenuTheme: PopupMenuThemeData(
        color: _surfaceDark,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: _neonBlue.withOpacity(0.2),
            width: 1,
          ),
        ),
        textStyle: TextStyle(
          color: _textPrimary,
          fontSize: 14,
        ),
      ),
      
      // Snackbar
      snackBarTheme: SnackBarThemeData(
        backgroundColor: _surfaceVariantDark,
        contentTextStyle: TextStyle(
          color: _textPrimary,
          fontSize: 14,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        behavior: SnackBarBehavior.floating,
      ),
      
      // Dialog
      dialogTheme: DialogThemeData(
        backgroundColor: _surfaceDark,
        elevation: 16,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: _neonBlue.withOpacity(0.3),
            width: 1,
          ),
        ),
        titleTextStyle: TextStyle(
          color: _textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        contentTextStyle: TextStyle(
          color: _textSecondary,
          fontSize: 14,
        ),
      ),
      
      // Checkbox
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return _neonBlue;
          }
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(_backgroundDark),
        side: BorderSide(
          color: _neonBlue.withOpacity(0.5),
          width: 2,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
      ),
      
      // Text Theme
      textTheme: TextTheme(
        displayLarge: TextStyle(
          color: _textPrimary,
          fontSize: 57,
          fontWeight: FontWeight.w400,
          letterSpacing: -0.25,
        ),
        displayMedium: TextStyle(
          color: _textPrimary,
          fontSize: 45,
          fontWeight: FontWeight.w400,
        ),
        displaySmall: TextStyle(
          color: _textPrimary,
          fontSize: 36,
          fontWeight: FontWeight.w400,
        ),
        headlineLarge: TextStyle(
          color: _textPrimary,
          fontSize: 32,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
        headlineMedium: TextStyle(
          color: _textPrimary,
          fontSize: 28,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
        headlineSmall: TextStyle(
          color: _textPrimary,
          fontSize: 24,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
        titleLarge: TextStyle(
          color: _textPrimary,
          fontSize: 22,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.15,
        ),
        titleMedium: TextStyle(
          color: _textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.15,
        ),
        titleSmall: TextStyle(
          color: _textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.1,
        ),
        bodyLarge: TextStyle(
          color: _textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.5,
        ),
        bodyMedium: TextStyle(
          color: _textSecondary,
          fontSize: 14,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.25,
        ),
        bodySmall: TextStyle(
          color: _textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.4,
        ),
        labelLarge: TextStyle(
          color: _textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.1,
        ),
        labelMedium: TextStyle(
          color: _textPrimary,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
        labelSmall: TextStyle(
          color: _textSecondary,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
  
  /// Cores do tema para uso direto
  static const Color neonBlue = _neonBlue;
  static const Color neonBlueBright = _neonBlueBright;
  static const Color neonBlueDark = _neonBlueDark;
  static const Color neonCyan = _neonCyan;
  static const Color neonPurple = _neonPurple;
  static const Color neonIndigo = _neonIndigo;
  static const Color backgroundDark = _backgroundDark;
  static const Color surfaceDark = _surfaceDark;
  static const Color surfaceVariantDark = _surfaceVariantDark;
  static const Color textPrimary = _textPrimary;
  static const Color textSecondary = _textSecondary;
  static const Color textTertiary = _textTertiary;
  static const Color error = _error;
  static const Color success = _success;
  static const Color warning = _warning;
  
  /// BoxShadow neon para efeitos de brilho
  static List<BoxShadow> get neonGlowBlue => [
    BoxShadow(
      color: _neonBlue.withOpacity(0.5),
      blurRadius: 8,
      spreadRadius: 0,
    ),
    BoxShadow(
      color: _neonBlue.withOpacity(0.3),
      blurRadius: 16,
      spreadRadius: 2,
    ),
  ];
  
  static List<BoxShadow> get neonGlowCyan => [
    BoxShadow(
      color: _neonCyan.withOpacity(0.5),
      blurRadius: 8,
      spreadRadius: 0,
    ),
    BoxShadow(
      color: _neonCyan.withOpacity(0.3),
      blurRadius: 16,
      spreadRadius: 2,
    ),
  ];
  
  static List<BoxShadow> get neonGlowStrong => [
    BoxShadow(
      color: _neonBlue.withOpacity(0.8),
      blurRadius: 12,
      spreadRadius: 0,
    ),
    BoxShadow(
      color: _neonCyan.withOpacity(0.6),
      blurRadius: 24,
      spreadRadius: 4,
    ),
  ];
  
  /// Decoração de container com borda neon
  static BoxDecoration neonBorderDecoration({
    Color? borderColor,
    double borderWidth = 1.5,
    double borderRadius = 12,
    Color? fillColor,
    List<BoxShadow>? shadows,
  }) {
    return BoxDecoration(
      color: fillColor ?? _surfaceVariantDark,
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: borderColor ?? _neonBlue.withOpacity(0.3),
        width: borderWidth,
      ),
      boxShadow: shadows ?? neonGlowBlue,
    );
  }
}

