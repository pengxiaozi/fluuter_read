// 🎨 肌肉记忆背单词 App - Flutter 主题配置
// 极简扁平化设计风格 - 无阴影、无渐变、纯粹简约
// 设计原则：内容即界面

import 'package:flutter/material.dart';

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// 📐 设计令牌 (Design Tokens)
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

/// 主色调 - 专注蓝
class AppColors {
  AppColors._();

  // 核心配色 - 扁平化单色系
  static const Color primary = Color(0xFF007AFF);    // 专注蓝 - 主色调
  static const Color primaryLight = Color(0xFF5AC8FA); // 浅蓝 - 次要色
  static const Color accent = Color(0xFF34C759);     // 成功绿 - CTA/进度
  static const Color background = Color(0xFFF8F9FA); // 浅灰白 - 背景
  static const Color textPrimary = Color(0xFF1C1C1E); // 深灰黑 - 主文字
  
  // 功能色
  static const Color success = Color(0xFF34C759);    // 正确/掌握
  static const Color error = Color(0xFFFF3B30);      // 错误
  static const Color warning = Color(0xFFFF9500);    // 警告
  static const Color info = Color(0xFF5856D6);       // 信息/音标
  
  // 中性色 - 极简灰色系
  static const Color neutralGray = Color(0xFF8E8E93); // 次要文字
  static const Color border = Color(0xFFE5E5EA);      // 边框
  static const Color surface = Color(0xFFFFFFFF);     // 卡片表面
  static const Color divider = Color(0xFFE5E5EA);     // 分隔线
  
  // 间距令牌 - 4px 基准
  static const double spaceXs = 4.0;    // 0.25rem - 紧密间距
  static const double spaceSm = 8.0;    // 0.5rem - 图标间距
  static const double spaceMd = 16.0;   // 1rem - 标准内边距
  static const double spaceLg = 24.0;   // 1.5rem - 区块内边距
  static const double spaceXl = 32.0;   // 2rem - 大间距
  static const double space2xl = 48.0;  // 3rem - 区块边距
  static const double space3xl = 64.0;  // 4rem - Hero 内边距
  
  // 圆角令牌 - 小圆角，更简约
  static const double radiusSm = 6.0;      // 按钮/输入框
  static const double radiusMd = 8.0;      // 卡片
  static const double radiusLg = 12.0;     // 大卡片
  static const double radiusXl = 16.0;     // 模态框
  static const double radiusFull = 9999.0; // 圆形
  
  // 无阴影 - 扁平化设计
  static const List<BoxShadow> none = [];
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// 🎨 ThemeData 配置
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

class AppTheme {
  AppTheme._();
  
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      
      // 背景色
      scaffoldBackgroundColor: AppColors.background,
      
      // 颜色方案
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        secondary: AppColors.primaryLight,
        tertiary: AppColors.accent,
        surface: AppColors.surface,
        error: AppColors.error,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onTertiary: Colors.white,
        onSurface: AppColors.textPrimary,
        onError: Colors.white,
      ),
      
      // 字体配置 - 系统字体，简洁易读
      textTheme: _buildTextTheme(),
      
      // 卡片主题 - 无边框无阴影
      cardTheme: CardTheme(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppColors.radiusMd),
          side: const BorderSide(color: AppColors.border, width: 1),
        ),
        margin: const EdgeInsets.all(AppColors.spaceSm),
      ),
      
      // 输入框主题
      inputDecorationTheme: _buildInputTheme(),
      
      // 按钮主题 - 扁平化
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: AppColors.spaceLg,
            vertical: AppColors.spaceMd,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppColors.radiusSm),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0,
          ),
        ),
      ),
      
      // 导航栏主题
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.primary.withOpacity(0.1),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            );
          }
          return const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.neutralGray,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(
              color: AppColors.primary,
              size: 24,
            );
          }
          return const IconThemeData(
            color: AppColors.neutralGray,
            size: 24,
          );
        }),
      ),
      
      // 滑块主题
      sliderTheme: SliderThemeData(
        activeTrackColor: AppColors.primary,
        inactiveTrackColor: AppColors.primary.withOpacity(0.3),
        thumbColor: AppColors.primary,
        overlayColor: AppColors.primary.withOpacity(0.12),
        trackHeight: 4,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
      ),
      
      // 开关主题
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.accent;
          }
          return AppColors.neutralGray;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.accent.withOpacity(0.5);
          }
          return AppColors.border;
        }),
      ),
      
      // 标签页主题
      tabBarTheme: const TabBarTheme(
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.neutralGray,
        indicatorColor: AppColors.primary,
        labelStyle: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
      
      // 进度条主题
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: AppColors.primary,
        linearTrackColor: AppColors.border,
        circularTrackColor: AppColors.border,
      ),
      
      // 芯片主题
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.background,
        selectedColor: AppColors.primary.withOpacity(0.1),
        labelStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppColors.radiusFull),
          side: const BorderSide(color: AppColors.border),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppColors.spaceSm,
          vertical: AppColors.spaceXs,
        ),
      ),
      
      // 分割线
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
        space: 1,
      ),
    );
  }
  
  static TextTheme _buildTextTheme() {
    return const TextTheme(
      // 标题字体 - 简洁现代
      displayLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.5,
        height: 1.2,
      ),
      displayMedium: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.25,
        height: 1.25,
      ),
      displaySmall: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        height: 1.3,
      ),
      headlineLarge: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        height: 1.35,
      ),
      headlineMedium: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        height: 1.4,
      ),
      headlineSmall: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        height: 1.45,
      ),
      titleLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        height: 1.5,
      ),
      titleMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        height: 1.5,
      ),
      titleSmall: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        height: 1.5,
      ),
      // 正文字体 - 易读清晰
      bodyLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.6,
        letterSpacing: 0.15,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.6,
        letterSpacing: 0.25,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        height: 1.5,
        letterSpacing: 0.4,
      ),
      // 标签字体
      labelLarge: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
      ),
      labelMedium: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
      ),
      labelSmall: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
      ),
    );
  }
  
  static InputDecorationTheme _buildInputTheme() {
    return InputDecorationTheme(
      filled: true,
      fillColor: AppColors.background,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppColors.spaceMd,
        vertical: AppColors.spaceMd,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppColors.radiusSm),
        borderSide: const BorderSide(
          color: AppColors.border,
          width: 1,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppColors.radiusSm),
        borderSide: const BorderSide(
          color: AppColors.border,
          width: 1,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppColors.radiusSm),
        borderSide: const BorderSide(
          color: AppColors.primary,
          width: 2,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppColors.radiusSm),
        borderSide: const BorderSide(
          color: AppColors.error,
          width: 1,
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppColors.radiusSm),
        borderSide: const BorderSide(
          color: AppColors.error,
          width: 2,
        ),
      ),
      hintStyle: const TextStyle(
        color: AppColors.neutralGray,
        fontWeight: FontWeight.w400,
      ),
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// 🎭 极简组件样式助手 - 无阴影、无渐变、纯粹扁平
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

class MinimalStyle {
  MinimalStyle._();
  
  /// 极简卡片装饰 - 仅边框
  static BoxDecoration get card => BoxDecoration(
    color: AppColors.surface,
    borderRadius: BorderRadius.circular(AppColors.radiusMd),
    border: Border.all(color: AppColors.border, width: 1),
  );
  
  /// 极简按钮装饰 - 纯色无阴影
  static BoxDecoration get button => BoxDecoration(
    color: AppColors.primary,
    borderRadius: BorderRadius.circular(AppColors.radiusSm),
  );
  
  /// 极简输入框装饰 - 纯色背景 + 细边框
  static BoxDecoration get input => BoxDecoration(
    color: AppColors.background,
    borderRadius: BorderRadius.circular(AppColors.radiusSm),
    border: Border.all(color: AppColors.border, width: 1),
  );
  
  /// 极简图标按钮装饰 - 纯色背景
  static BoxDecoration get iconButton => BoxDecoration(
    color: AppColors.background,
    borderRadius: BorderRadius.circular(AppColors.radiusSm),
    border: Border.all(color: AppColors.border, width: 1),
  );
  
  /// 成功状态装饰 - 纯色背景 + 细边框
  static BoxDecoration get success => BoxDecoration(
    color: AppColors.success.withOpacity(0.1),
    borderRadius: BorderRadius.circular(AppColors.radiusFull),
    border: Border.all(
      color: AppColors.success.withOpacity(0.3),
      width: 1,
    ),
  );
  
  /// 错误状态装饰 - 纯色背景 + 细边框
  static BoxDecoration get error => BoxDecoration(
    color: AppColors.error.withOpacity(0.1),
    borderRadius: BorderRadius.circular(AppColors.radiusFull),
    border: Border.all(
      color: AppColors.error.withOpacity(0.3),
      width: 1,
    ),
  );
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// ✨ 动画曲线 - 简洁快速
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

class AppAnimations {
  AppAnimations._();
  
  /// 标准过渡动画 (150ms) - 更快更干脆
  static const Duration standard = Duration(milliseconds: 150);
  
  /// 快速反馈动画 (100ms)
  static const Duration fast = Duration(milliseconds: 100);
  
  /// 慢速强调动画 (200ms)
  static const Duration slow = Duration(milliseconds: 200);
  
  /// 简洁过渡曲线
  static const Curve defaultCurve = Curves.easeInOut;
  
  /// 干脆利落曲线
  static const Curve sharpCurve = Curves.easeOut;
}
