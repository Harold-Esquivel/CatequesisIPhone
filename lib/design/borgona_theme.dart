import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract final class Borgona {
  static final darkMode = ValueNotifier<bool>(false);
  static Future<void> loadPreferences() async {
    final preferences = await SharedPreferences.getInstance();
    darkMode.value = preferences.getBool('dark_mode') ?? false;
  }

  static Future<void> setDarkMode(bool enabled) async {
    final preferences = await SharedPreferences.getInstance();
    if (!await preferences.setBool('dark_mode', enabled)) {
      throw StateError('No se pudo guardar la preferencia');
    }
    darkMode.value = enabled;
  }

  static Color get background =>
      darkMode.value ? const Color(0xFF0F1724) : const Color(0xFFF4F6F9);
  static Color get surface =>
      darkMode.value ? const Color(0xFF1C293B) : Colors.white;
  static Color get sunken =>
      darkMode.value ? const Color(0xFF101B2C) : const Color(0xFFE8ECF2);
  static Color get burgundy =>
      darkMode.value ? const Color(0xFFAE4569) : const Color(0xFF7A1F3D);
  static Color get navy =>
      darkMode.value ? const Color(0xFFEAF0FA) : const Color(0xFF0F1C2E);
  static Color get secondary =>
      darkMode.value ? const Color(0xFFAFBED1) : const Color(0xFF5A6A7A);
  static const darkShadow = Color(0xFF0A1420);
  static List<BoxShadow> get raised => darkMode.value
      ? const [
          BoxShadow(
            color: Color(0x66040810),
            offset: Offset(8, 8),
            blurRadius: 16,
          ),
          BoxShadow(
            color: Color(0x302F435D),
            offset: Offset(-8, -8),
            blurRadius: 16,
          ),
        ]
      : const [
          BoxShadow(
            color: Color(0x2E0F1C2E),
            offset: Offset(8, 8),
            blurRadius: 16,
          ),
          BoxShadow(
            color: Color(0xE6FFFFFF),
            offset: Offset(-8, -8),
            blurRadius: 16,
          ),
        ];
  static List<BoxShadow> get active => [
    BoxShadow(
      color: burgundy.withValues(alpha: .25),
      offset: const Offset(6, 6),
      blurRadius: 14,
    ),
    BoxShadow(
      color: darkMode.value ? const Color(0x302F435D) : const Color(0xE6FFFFFF),
      offset: const Offset(-6, -6),
      blurRadius: 14,
    ),
  ];

  static ThemeData get theme {
    final scheme = ColorScheme.fromSeed(
      seedColor: burgundy,
      brightness: darkMode.value ? Brightness.dark : Brightness.light,
      primary: burgundy,
      secondary: navy,
      onPrimary: Colors.white,
      surface: surface,
      onSurface: navy,
      error: burgundy,
    );
    final base = ThemeData(
      useMaterial3: true,
      fontFamily: 'Inter',
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
    );
    ButtonStyle buttonStyle({bool primary = false}) => ButtonStyle(
      elevation: const WidgetStatePropertyAll(0),
      minimumSize: const WidgetStatePropertyAll(Size(48, 48)),
      padding: const WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      foregroundColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.disabled)
            ? secondary
            : primary
            ? Colors.white
            : burgundy,
      ),
      backgroundColor: const WidgetStatePropertyAll(Colors.transparent),
      side: const WidgetStatePropertyAll(BorderSide.none),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      textStyle: const WidgetStatePropertyAll(
        TextStyle(
          fontFamily: 'Inter',
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
      backgroundBuilder: (context, states, child) => DecoratedBox(
        decoration: BoxDecoration(
          color: primary && !states.contains(WidgetState.disabled)
              ? burgundy
              : surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: raised,
        ),
        child: child,
      ),
    );
    return base.copyWith(
      textTheme: base.textTheme.apply(bodyColor: navy, displayColor: navy),
      disabledColor: secondary,
      dividerColor: Colors.transparent,
      iconTheme: IconThemeData(color: secondary),
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: navy,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: 'Inter',
          color: navy,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: buttonStyle(primary: true),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: buttonStyle(primary: true),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(style: buttonStyle()),
      textButtonTheme: TextButtonThemeData(style: buttonStyle()),
      iconButtonTheme: IconButtonThemeData(style: buttonStyle()),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        labelStyle: TextStyle(color: secondary),
        hintStyle: TextStyle(color: secondary, fontWeight: FontWeight.w400),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: const NeoInputBorder(),
        enabledBorder: const NeoInputBorder(),
        focusedBorder: const NeoInputBorder(focused: true),
        errorBorder: const NeoInputBorder(focused: true),
        focusedErrorBorder: const NeoInputBorder(focused: true),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: background,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: background,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: navy,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: background,
        surfaceTintColor: Colors.transparent,
        headerForegroundColor: navy,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surface,
        side: BorderSide.none,
        labelStyle: TextStyle(color: navy),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      expansionTileTheme: ExpansionTileThemeData(
        shape: Border(),
        collapsedShape: Border(),
        iconColor: burgundy,
        collapsedIconColor: secondary,
        textColor: navy,
        collapsedTextColor: navy,
      ),
      listTileTheme: ListTileThemeData(iconColor: secondary, textColor: navy),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: burgundy),
    );
  }
}

/// The shared raised material used throughout the content, never inset.
class NeoDecoration extends BoxDecoration {
  NeoDecoration({
    Color? color,
    super.image,
    super.gradient,
    super.borderRadius,
    BoxBorder? border,
    List<BoxShadow>? boxShadow,
    super.shape,
  }) : super(color: color ?? Borgona.surface, boxShadow: Borgona.raised);
}

class NeoSurface extends StatelessWidget {
  const NeoSurface({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.radius = 24,
    this.color,
  });
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double radius;
  final Color? color;
  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    return Container(
      margin: margin,
      padding: padding,
      decoration: NeoDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: child,
    );
  }
}

/// Compatible with existing cards, with one consistent two-shadow material.
class NeoCard extends StatelessWidget {
  const NeoCard({
    super.key,
    required this.child,
    this.margin,
    this.color,
    this.elevation,
    this.shape,
    this.clipBehavior,
    this.surfaceTintColor,
  });
  final Widget child;
  final EdgeInsetsGeometry? margin;
  final Color? color;
  final double? elevation;
  final ShapeBorder? shape;
  final Clip? clipBehavior;
  final Color? surfaceTintColor;
  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    return NeoSurface(
      margin: margin ?? const EdgeInsets.all(4),
      color: color == Borgona.background
          ? Borgona.surface
          : color ?? Borgona.surface,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(24),
        clipBehavior: clipBehavior ?? Clip.none,
        child: child,
      ),
    );
  }
}

class NeoInputBorder extends OutlineInputBorder {
  const NeoInputBorder({this.focused = false})
    : super(
        borderRadius: const BorderRadius.all(Radius.circular(16)),
        borderSide: BorderSide.none,
      );
  final bool focused;
  @override
  NeoInputBorder copyWith({
    BorderSide? borderSide,
    BorderRadius? borderRadius,
    double? gapPadding,
  }) => NeoInputBorder(focused: focused);
  @override
  void paint(
    Canvas canvas,
    Rect rect, {
    double? gapStart,
    double gapExtent = 0,
    double gapPercentage = 0,
    TextDirection? textDirection,
  }) {
    final rounded = borderRadius.toRRect(rect);
    for (final shadow in Borgona.raised) {
      canvas.drawRRect(rounded.shift(shadow.offset), shadow.toPaint());
    }
    canvas.drawRRect(rounded, Paint()..color = Borgona.surface);
    if (focused) {
      canvas.drawRRect(
        rounded,
        Paint()..color = Borgona.burgundy.withValues(alpha: .025),
      );
    }
  }
}
