import 'package:flutter/material.dart';

class Appearance {
  const Appearance({
    this.themeMode,
    this.platform,
    double textScaleFactor,
  }) : _textScaleFactor = textScaleFactor;

  final ThemeMode themeMode;
  final TargetPlatform platform;
  final double _textScaleFactor;

  //暂时只返回一个, 添加黑暗模式后 根据themeMode返回
  ColorScheme get colorScheme => ColorScheme(
        primary: const Color(0xFF1E64D2),
        primaryVariant: const Color(0xFF1E64D2),
        onPrimary: const Color(0xFF1E64D2),
        secondary: const Color(0xFF8FA6C9),
        secondaryVariant: const Color(0xFF8FA6C9),
        onSecondary: const Color(0xFF8FA6C9),
        surface: const Color(0xFFFFFFFF),
        onSurface: const Color(0xFFFFFFFF),
        background: const Color(0xF8F8F8),
        onBackground: const Color(0xF8F8F8),
        error: const Color(0xFFE95C65),
        onError: const Color(0xFFE95C65),
        brightness: Brightness.light,
      );

  TextTheme get textTheme => TextTheme(
      headline6: TextStyle(
        //  /// Used for the primary text in app bars and dialogs (e.g., [AppBar.title]and [AlertDialog.title]).
        color: Colors.black,
        fontWeight: FontWeight.w500,
        fontSize: 18.5,
      ),
      overline: TextStyle(
        //  /// Used for the primary text in app bars and dialogs (e.g., [AppBar.title]and [AlertDialog.title]).
        color: colorScheme.error,
//            fontWeight: FontWeight.w500,
        fontSize: 11,
      ));

  Appearance.fromJson(Map<String, dynamic> json)
      : themeMode = (json['themeMode'] as int) == 0
            ? ThemeMode.light
            : (json['themeMode'] as int) == 1 ? ThemeMode.dark : ThemeMode.system,
        platform = json['platform'] as int == 0 ? TargetPlatform.iOS : TargetPlatform.android,
        _textScaleFactor = json['textScaleFactor'] as double;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'themeMode': themeMode == ThemeMode.light ? 0 : themeMode == ThemeMode.dark ? 1 : 2,
      'platform': platform == TargetPlatform.iOS ? 0 : 1,
      'textScaleFactor': _textScaleFactor,
    };
  }

  Appearance copy({
    ThemeMode themeMode,
    TargetPlatform platform,
    double textScaleFactor,
  }) {
    return Appearance(
      themeMode: themeMode ?? this.themeMode,
      platform: platform ?? this.platform,
      textScaleFactor: textScaleFactor ?? _textScaleFactor,
    );
  }
}

//
//const TextStyle _errorTextStyle = TextStyle(
//  color: Color(0xD0FF0000),
//  fontFamily: 'monospace',
//  fontSize: 48.0,
//  fontWeight: FontWeight.w900,
//  decoration: TextDecoration.underline,
//  decorationColor: Color(0xFFFFFF00),
//  decorationStyle: TextDecorationStyle.double,
//  debugLabel: 'fallback style; consider putting your text in a Material',
//);

/// 主题配色  目前仅蓝色一套
//class ColorScheme {
//
//  const ColorScheme({
//    @required this.primary,
//    @required this.warning,
//    @required this.prompt,
//    @required this.secondaryBackground,
//    @required this.surface,
//    @required this.background,
//    @required this.brightness,
//  }); // : assert(primary != null);
//
//  const ColorScheme.blue({
//    this.primary = const Color(0xFF1E64D2),
//    this.warning = const Color(0xFFE95C65),
//    this.prompt = const Color(0xFFFFBE51),
//    this.secondaryBackground = const Color(0xFF8FA6C9),
//    this.surface = const Color(0xFFFFFFFF),
//    this.background = const Color(0xF8F8F8),
//    this.brightness = Brightness.light,
//  });
//
//  /// 主题色
//  final Color primary;
//
//  /// 强烈的警告色
//  final Color warning;
//
//  /// 提示色 黄色
//  final Color prompt;
//
//  /// 背景颜色, 较为强烈
//  final Color secondaryBackground;
//
//  /// 白色
//  final Color surface;
//
//  /// 背景色
//  final Color background;
//
//
//  final Brightness brightness;
//
//  ThemeData themeData() {
//    return ThemeData(
////        primaryColor:
////    textTheme:
//      appBarTheme: AppBarTheme(
////  textTheme:
//        color: background,
//        elevation: 0,
//        iconTheme: IconThemeData(color: primary),
//        brightness: brightness,
//      ),
//      scaffoldBackgroundColor: surface,
//    );
//  }
//}
