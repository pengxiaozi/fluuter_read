# 练习页面设计规范

> 肌肉记忆背单词 App - 核心练习界面设计覆盖  
> 此文件规则 **覆盖** MASTER.md 中的通用规则

---

## 🎯 页面目标

通过"看词→打字→验证"闭环，强制高频输入练习，形成肌肉记忆。

---

## 📐 布局结构

```
┌─────────────────────────────────────┐
│  ← 肌肉记忆练习               ⏭    │  AppBar (高度：56px)
├─────────────────────────────────────┤
│  [连续正确 2/3]  [尝试 1]          │  状态芯片行 (高度：40px)
├─────────────────────────────────────┤
│                                     │
│  ┌─────────────────────────────┐   │
│  │      📖 单词卡片区域        │   │  单词卡 (高度：200px)
│  │  ┌─────────────────────┐    │   │
│  │  │    Apple (背景)     │    │   │
│  │  │    A p p l e (前景) │    │   │
│  │  │    🔊 /ˈæp.əl/      │    │   │
│  │  └─────────────────────┘    │   │
│  └─────────────────────────────┘   │
│                                     │
│  ┌─────────────────────────────┐   │
│  │  [_________________] 输入框 │   │  输入区域 (高度：64px)
│  └─────────────────────────────┘   │
│                                     │
│  ┌─────────────────────────────┐   │
│  │  n. 苹果                    │   │  释义区域 (高度：48px)
│  └─────────────────────────────┘   │
│                                     │
│  ═══════════════════════════════   │  分隔线
│  ●○○○○  连续正确 2/3 次            │  进度条 (高度：40px)
│                                     │
│  ┌─────────────────────────────┐   │
│  │  ✓ 回答正确！               │   │  反馈区域 (高度：40px)
│  └─────────────────────────────┘   │
├─────────────────────────────────────┤
│  例句 | 同近 | 短语 | 同根         │  TabBar (高度：48px)
├─────────────────────────────────────┤
│  ┌─────────────────────────────┐   │
│  │  • Example sentence...      │   │  内容区域 (剩余高度)
│  │    例句翻译...              │   │
│  └─────────────────────────────┘   │
└─────────────────────────────────────┘
```

---

## 🎨 颜色使用

### 单词卡片

| 元素 | 颜色 | 用途 |
|------|------|------|
| 背景文字 | `#000000 12%` | 单词轮廓，半透明 |
| 前景文字 | `#1C1C1E` | 用户输入，实心 |
| 正确字母 | `#34C759` | 动态变绿 |
| 错误字母 | `#FF3B30` | 动态变红 |
| 音标 | `#5856D6` | 紫色系 |
| 发音按钮背景 | `#F2F2F7` | 浅灰 |
| 发音按钮图标 | `#007AFF` | 蓝色 |

### 输入框

| 状态 | 边框颜色 | 背景 |
|------|----------|------|
| 默认 | `#E5E5EA` | `#FFFFFF` |
| 聚焦 | `#007AFF` | `#FFFFFF` |
| 正确 | `#34C759` | `#34C759 12%` |
| 错误 | `#FF3B30` | `#FF3B30 12%` |

### 进度指示器

```dart
// 已完成的正确次数
Color completed = AppColors.success;  // #34C759

// 未完成的部分
Color remaining = AppColors.border;   // #E5E5EA

// 容器背景
Color container = AppColors.background; // #EEF2FF
```

---

## 🧩 组件规格

### 状态芯片 (Chip)

```dart
Container(
  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
  decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(999),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.03),
        blurRadius: 10,
        offset: Offset(0, 4),
      ),
    ],
  ),
  child: Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(Icons.bolt_outlined, size: 16, color: AppColors.primary),
      SizedBox(width: 6),
      Text('连续正确 2/3'),
    ],
  ),
)
```

### 单词卡片

```dart
Card(
  elevation: 0,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(16),
  ),
  child: Container(
    padding: EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      boxShadow: AppColors.clayLg,
    ),
  ),
)
```

### 输入覆盖效果

```dart
Stack(
  alignment: Alignment.center,
  children: [
    // 背景：完整单词，半透明
    Text(
      word.term,
      style: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        color: Colors.black.withOpacity(0.12),
      ),
    ),
    // 前景：用户输入，实心
    RichText(
      text: TextSpan(
        style: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
        children: inputChars.map((ch) => TextSpan(text: ch)).toList(),
      ),
    ),
  ],
)
```

### 进度圆点

```dart
Row(
  mainAxisSize: MainAxisSize.min,
  children: List.generate(
    requiredCount,
    (index) => Container(
      width: 12,
      height: 12,
      margin: EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: index < correctCount 
            ? AppColors.success 
            : AppColors.border,
      ),
    ),
  ),
)
```

---

## ✨ 交互动画

### 输入正确反馈

```dart
// 字母逐个变绿动画
for (int i = 0; i < word.length; i++) {
  await Future.delayed(Duration(milliseconds: i * 50));
  // 第 i 个字母变绿
}

// 轻微弹跳
Animation<double> bounce = Tween<double>(
  begin: 1.0,
  middle: 1.1,
  end: 1.0,
).animate(CurvedAnimation(
  parent: controller,
  curve: Curves.bounceOut,
));
```

### 输入错误反馈

```dart
// 左右抖动
Animation<double> shake = TweenSequence<double>([
  TweenSequenceItem(tween: Tween(begin: 0, end: -8), weight: 1),
  TweenSequenceItem(tween: Tween(begin: -8, end: 8), weight: 1),
  TweenSequenceItem(tween: Tween(begin: 8, end: -8), weight: 1),
  TweenSequenceItem(tween: Tween(begin: -8, end: 0), weight: 1),
]).animate(CurvedAnimation(
  parent: controller,
  curve: Curves.easeInOut,
));
```

### 掌握庆祝

```dart
// 进度条填充动画
Tween<double>(begin: 0.0, end: 1.0).animate(
  CurvedAnimation(
    parent: controller,
    curve: Curves.easeInOut,
  ),
);

// 粒子效果 (可选)
// 使用 flutter_confetti 或自定义粒子
```

---

## 📱 响应式适配

### 移动端 (< 600px)

- 单词卡片高度：200px
- 单词字体：32px
- 输入框字体：24px，字间距 6px
- 底部 Tab 区域高度：240px

### 平板端 (≥ 600px)

- 单词卡片高度：280px
- 单词字体：48px
- 输入框字体：32px，字间距 8px
- 底部 Tab 区域高度：320px

### 桌面端 (≥ 1024px)

- 单词卡片高度：320px
- 单词字体：64px
- 输入框字体：40px，字间距 10px
- 底部 Tab 区域高度：400px
- 最大宽度限制：800px，居中显示

---

## 🎭 暗色模式适配

> ⚠️ 注意：根据设计系统反模式，**不使用暗色模式**  
> 以下仅为参考，实际不实现

若未来需要暗色模式：

| 元素 | 浅色模式 | 暗色模式 |
|------|----------|----------|
| 背景 | `#EEF2FF` | `#1C1C1E` |
| 卡片 | `#FFFFFF` | `#2C2C2E` |
| 文字 | `#312E81` | `#FFFFFF` |
| 边框 | `#E5E5EA` | `#3A3A3C` |

---

## ✅ 验收标准

### 功能验收

- [ ] 单词显示清晰，背景半透明轮廓可见
- [ ] 输入时字母逐个覆盖显示
- [ ] 正确/错误实时反馈（颜色变化）
- [ ] 连续正确次数准确追踪
- [ ] 达到设定次数自动切换下一词
- [ ] 发音按钮可点击并播放音频

### 视觉验收

- [ ] 所有卡片使用 Claymorphism 阴影
- [ ] 进度圆点颜色正确（绿/灰）
- [ ] 状态芯片悬浮效果明显
- [ ] 输入框聚焦状态清晰
- [ ] 反馈信息颜色与状态匹配

### 交互验收

- [ ] 按钮点击有按压反馈
- [ ] 卡片悬停有上浮效果
- [ ] 输入正确时字母动画流畅
- [ ] 输入错误时抖动动画明显
- [ ] 切换单词有淡入淡出过渡

### 无障碍验收

- [ ] 文字对比度 ≥ 4.5:1
- [ ] 所有交互元素可键盘访问
- [ ] 焦点状态清晰可见
- [ ] 支持系统字体大小调整

---

## 📝 开发注意事项

### 性能优化

1. **避免不必要的 rebuild**：使用 `const` 构造函数
2. **动画使用 vsync**：使用 `TickerProviderStateMixin`
3. **音频预加载**：初始化时预加载发音

### 状态管理

```dart
// 使用 Riverpod 管理练习状态
final practiceProvider = StateNotifierProvider<PracticeNotifier, PracticeState>((ref) {
  return PracticeNotifier(ref);
});

// 监听状态变化
ref.listen(practiceProvider, (previous, next) {
  if (next.lastIsCorrect == true) {
    // 播放成功动画
  }
});
```

### 音频处理

```dart
// 初始化 TTS
Future<void> _initTts() async {
  await _flutterTts.setLanguage("en-US");
  await _flutterTts.setPitch(1.0);
  await _flutterTts.setSpeechRate(0.5);
}

// 播放发音
Future<void> _speak(String text) async {
  await _flutterTts.speak(text);
}

// 单词切换时自动播放
WidgetsBinding.instance.addPostFrameCallback((_) {
  if (word != null) {
    _speak(word.term);
  }
});
```

---

**最后更新**: 2026-02-28  
**版本**: 1.0.0
