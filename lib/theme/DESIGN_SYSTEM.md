# 🎨 极简扁平化设计系统

> **项目**: 离线肌肉记忆背单词 App  
> **风格**: 极简扁平化 (Minimal Flat)  
> **设计原则**: 内容即界面 · 无阴影 · 无渐变 · 纯粹简约

---

## 📋 目录

1. [设计理念](#设计理念)
2. [配色方案](#配色方案)
3. [字体系统](#字体系统)
4. [组件样式](#组件样式)
5. [使用示例](#使用示例)

---

## 🎯 设计理念

### 极简主义

- **少即是多** - 移除所有不必要的装饰
- **内容优先** - 让内容本身成为视觉焦点
- **清晰第一** - 高对比度、明确的边界、易读性优先

### 扁平化原则

| ❌ 不要 | ✅ 应该 |
|--------|--------|
| 阴影 | 细边框 (1px) |
| 渐变 | 纯色填充 |
| 纹理 | 简洁背景 |
| 装饰线 | 功能分割线 |
| 复杂动画 | 简洁过渡 (100-200ms) |

---

## 🎨 配色方案

### 核心配色

```
主色调：#007AFF (专注蓝)
辅助色：#5AC8FA (浅蓝)
强调色：#34C759 (成功绿)
背景色：#F8F9FA (浅灰白)
文字色：#1C1C1E (深灰黑)
```

### 功能色

| 用途 | 颜色 | 色值 |
|------|------|------|
| 成功 | Green | `#34C759` |
| 错误 | Red | `#FFFF3B30` |
| 警告 | Orange | `#FFFF9500` |
| 信息 | Purple | `#FF5856D6` |

### 中性灰色系

| 用途 | 颜色 | 色值 |
|------|------|------|
| 主要文字 | Dark Gray | `#1C1C1E` |
| 次要文字 | Medium Gray | `#8E8E93` |
| 边框/分割线 | Light Gray | `#E5E5EA` |
| 背景 | Off-White | `#F8F9FA` |
| 卡片表面 | Pure White | `#FFFFFF` |

---

## 📐 设计令牌

### 间距系统 (4px 基准)

```dart
AppColors.spaceXs   = 4px   // 紧密间距
AppColors.spaceSm   = 8px   // 图标间距
AppColors.spaceMd   = 16px  // 标准内边距
AppColors.spaceLg   = 24px  // 区块内边距
AppColors.spaceXl   = 32px  // 大间距
AppColors.space2xl  = 48px  // 区块边距
AppColors.space3xl  = 64px  // Hero 内边距
```

### 圆角系统 (小圆角)

```dart
AppColors.radiusSm   = 6px   // 按钮/输入框
AppColors.radiusMd   = 8px   // 卡片
AppColors.radiusLg   = 12px  // 大卡片
AppColors.radiusXl   = 16px  // 模态框
AppColors.radiusFull = 9999px // 圆形/芯片
```

### 边框系统

```dart
// 标准边框
BorderSide(color: AppColors.border, width: 1)

// 聚焦边框
BorderSide(color: AppColors.primary, width: 2)

// 错误边框
BorderSide(color: AppColors.error, width: 1)
```

### 无阴影

```dart
// 扁平化设计 - 不使用阴影
static const List<BoxShadow> none = [];
```

---

## 🔤 字体系统

### 字号规范

| 类型 | 字号 | 字重 | 行高 | 用途 |
|------|------|------|------|------|
| displaySmall | 24px | w600 | 1.3 | 单词显示 |
| titleLarge | 16px | w600 | 1.5 | 卡片标题 |
| titleMedium | 14px | w600 | 1.5 | 小标题 |
| bodyLarge | 16px | w400 | 1.6 | 正文内容 |
| bodyMedium | 14px | w400 | 1.6 | 次要文字 |
| labelMedium | 12px | w500 | 1.5 | 标签、注释 |

### 字体使用

```dart
// 标题 - 简洁现代
TextStyle(
  fontSize: 24,
  fontWeight: FontWeight.w600,
  letterSpacing: -0.5,
)

// 正文 - 易读清晰
TextStyle(
  fontSize: 16,
  fontWeight: FontWeight.w400,
  height: 1.6,
  letterSpacing: 0.15,
)
```

---

## 🧩 组件样式

### 卡片 (Card)

```dart
Card(
  elevation: 0,  // 无阴影
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(8),
    side: const BorderSide(color: AppColors.border, width: 1), // 细边框
  ),
  child: Container(
    padding: EdgeInsets.all(16),
    color: AppColors.surface,
  ),
)
```

**或者使用预定义样式：**

```dart
Container(
  decoration: MinimalStyle.card,
  padding: EdgeInsets.all(16),
  child: Text('内容'),
)
```

### 按钮 (Button)

```dart
// 主按钮
ElevatedButton(
  style: ElevatedButton.styleFrom(
    backgroundColor: AppColors.primary,
    foregroundColor: Colors.white,
    elevation: 0,  // 无阴影
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(6),
    ),
  ),
  child: Text('开始练习'),
)

// 次要按钮
TextButton(
  style: TextButton.styleFrom(
    foregroundColor: AppColors.primary,
  ),
  child: Text('取消'),
)
```

### 输入框 (TextField)

```dart
TextField(
  decoration: InputDecoration(
    filled: true,
    fillColor: AppColors.background,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(6),
      borderSide: BorderSide(color: AppColors.border, width: 1),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(6),
      borderSide: BorderSide(color: AppColors.primary, width: 2),
    ),
  ),
)
```

### 图标按钮

```dart
Container(
  width: 32,
  height: 32,
  decoration: MinimalStyle.iconButton,
  child: Icon(Icons.close, size: 20),
)
```

### 芯片 (Chip)

```dart
Container(
  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
  decoration: BoxDecoration(
    color: AppColors.primary.withOpacity(0.1),
    borderRadius: BorderRadius.circular(999),
    border: Border.all(color: AppColors.border),
  ),
  child: Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(Icons.check, size: 14, color: AppColors.primary),
      SizedBox(width: 4),
      Text('连续正确 2/3'),
    ],
  ),
)
```

### 状态反馈

```dart
// 成功状态
Container(
  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
  decoration: MinimalStyle.success,
  child: Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(Icons.check_circle, size: 18, color: AppColors.success),
      SizedBox(width: 6),
      Text('回答正确'),
    ],
  ),
)

// 错误状态
Container(
  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
  decoration: MinimalStyle.error,
  child: Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(Icons.error_outline, size: 18, color: AppColors.error),
      SizedBox(width: 6),
      Text('回答错误'),
    ],
  ),
)
```

---

## 📱 页面布局示例

### 练习页面

```
┌─────────────────────────────────────┐
│  ← 肌肉记忆练习               ⏭    │  AppBar (白色，细边框底)
├─────────────────────────────────────┤
│  [连续正确 2/3]  [尝试 1]          │  状态芯片 (细边框)
├─────────────────────────────────────┤
│  ┌─────────────────────────────┐   │
│  │      Apple                  │   │  单词卡 (白色，细边框)
│  │      /ˈæp.əl/               │   │
│  └─────────────────────────────┘   │
│                                     │
│  ┌─────────────────────────────┐   │
│  │  [_________________]        │   │  输入框 (浅灰背景)
│  └─────────────────────────────┘   │
│                                     │
│  n. 苹果                           │  释义 (无边框)
│                                     │
│  ───────────────────────────────   │  分隔线 (1px)
│  ○○○○○  连续正确 2/3 次            │  进度 (纯色圆点)
│                                     │
│  ✓ 回答正确！                      │  反馈 (绿色文字)
└─────────────────────────────────────┘
```

---

## ✨ 动画规范

### 动画时长

| 类型 | 时长 | 用途 |
|------|------|------|
| `fast` | 100ms | 快速反馈 (按钮点击) |
| `standard` | 150ms | 标准过渡 (页面切换) |
| `slow` | 200ms | 慢速强调 (完成状态) |

### 动画曲线

```dart
// 简洁过渡
Curves.easeInOut

// 干脆利落
Curves.easeOut
```

### 使用示例

```dart
// 按钮点击反馈
InkWell(
  onTap: () {},
  child: Container(
    decoration: MinimalStyle.button,
    child: Text('点击'),
  ),
)

// 页面过渡
AnimatedSwitcher(
  duration: AppAnimations.standard,
  switchInCurve: AppAnimations.defaultCurve,
  switchOutCurve: AppAnimations.defaultCurve,
  child: currentWidget,
)
```

---

## ✅ 使用清单

### 必须遵守

- [ ] 不使用阴影 (`elevation: 0`)
- [ ] 不使用渐变 (纯色填充)
- [ ] 使用 1px 细边框定义边界
- [ ] 背景色使用 `#F8F9FA` (浅灰白)
- [ ] 卡片使用白色 `#FFFFFF`
- [ ] 动画时长 ≤ 200ms

### 可以使用

- [ ] 细边框 (1px)
- [ ] 纯色背景
- [ ] 简洁图标 (线性图标)
- [ ] 高对比度文字

### 禁止使用

- [ ] ❌ 阴影效果
- [ ] ❌ 渐变效果
- [ ] ❌ 纹理/图案
- [ ] ❌ 复杂装饰
- [ ] ❌ 慢动画 (>300ms)

---

## 🎯 设计对比

### Before (有阴影)

```
卡片：白色 + 双层阴影 + 圆角 12px
按钮：蓝色 + 阴影 + 悬停上浮
输入框：白色 + 内阴影 + 外边框
```

### After (极简扁平)

```
卡片：白色 + 1px 边框 + 圆角 8px
按钮：蓝色纯色 + 无阴影 + 无悬停位移
输入框：浅灰背景 + 1px 边框 + 聚焦变蓝
```

---

## 📚 参考资源

- [Apple Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/)
- [Material Design 3](https://m3.material.io/)
- [Flat UI Design Principles](https://www.smashingmagazine.com/2019/02/designing-simple-effective-flat-ui-components/)

---

**最后更新**: 2026-02-28  
**版本**: 2.0.0 (极简扁平化)  
**状态**: ✅ 已应用
