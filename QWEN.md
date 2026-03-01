# 离线肌肉记忆背单词 App - 项目上下文文档

## 项目概述

这是一个**Flutter 跨平台移动应用**，名为"离线肌肉记忆背单词 App"。产品愿景是打造一款极致的、完全离线的、以"肌肉记忆"为核心训练方法的背单词工具。

### 核心特性

- **离线优先**: 所有数据本地存储，无网络请求，保护用户隐私
- **肌肉记忆训练**: 通过"看词 - 打字 - 验证"闭环，强制高频输入练习
- **数据自主**: 支持词典导入/导出，用户完全掌控数据
- **状态管理**: 使用 Riverpod 进行状态管理
- **本地存储**: 使用 Hive 作为嵌入式数据库

### 技术栈

| 类别 | 技术 |
|------|------|
| 框架 | Flutter (SDK ^3.6.0) |
| 状态管理 | flutter_riverpod ^2.5.1 |
| 本地数据库 | hive ^2.2.3, hive_flutter ^1.1.0 |
| 文件选择 | file_picker ^8.1.2 |
| UUID 生成 | uuid ^4.5.1 |
| 路径提供 | path_provider ^2.1.5 |

## 项目结构

```
lib/
├── main.dart              # 应用入口，底部导航栏架构
├── models/                # 数据模型层
│   ├── word.dart          # 单词实体 (Hive TypeAdapter ID: 0)
│   ├── dictionary.dart    # 词典实体 (Hive TypeAdapter ID: 1)
│   └── study_log.dart     # 学习记录实体 (Hive TypeAdapter ID: 2)
├── providers/             # Riverpod 状态管理
│   ├── practice_provider.dart   # 练习会话状态
│   ├── dictionary_provider.dart # 词典管理状态
│   ├── study_log_provider.dart  # 学习记录状态
│   └── settings_provider.dart   # 应用设置状态
├── screens/               # UI 页面层
│   ├── dictionary_screen.dart   # 词典管理中心
│   ├── practice_screen.dart     # 肌肉记忆练习界面
│   ├── study_log_screen.dart    # 学习记录与统计
│   └── settings_screen.dart     # 系统设置
└── services/              # 服务层
    └── hive_service.dart        # Hive 数据库初始化与管理
```

## 数据模型

### Word (单词)
```dart
- id: String              // UUID v4
- dictionaryId: String    // 外键，关联 Dictionary
- term: String            // 单词本身
- phonetic: String?       // 音标
- definitions: List<String>  // 释义列表
- masteryLevel: int       // 掌握程度 0-100
- examples: List<String>  // 例句列表
- synonymDetails: List<String>    // 同近义词信息
- phraseDetails: List<String>     // 短语信息
- relatedDetails: List<String>    // 同根词信息
```

### Dictionary (词典)
```dart
- id: String              // UUID v4
- name: String            // 词典名称
- description: String?    // 描述
- sourceUrl: String?      // 在线下载地址
- lastUpdated: DateTime   // 最后更新时间
- wordCount: int          // 词条总数
```

### StudyLog (学习记录)
```dart
- id: String              // UUID v4
- wordId: String          // 外键，关联 Word
- timestamp: DateTime     // 操作时间
- isCorrect: bool         // 本次是否正确
- attempts: int           // 本次尝试次数
```

## Hive 存储配置

```dart
// Box 名称
- 'dictionaries'    // 词典数据
- 'words'           // 单词数据
- 'study_logs'      // 学习记录
- 'settings'        // 应用设置
```

## 构建与运行

### 环境要求
- Flutter SDK: ^3.6.0
- Dart: 与 Flutter SDK 配套

### 常用命令

```bash
# 获取依赖
flutter pub get

# 运行应用
flutter run

# 构建发布版本
flutter build apk --release      # Android
flutter build ios --release      # iOS

# 代码分析
flutter analyze

# 运行测试
flutter test

# 清理构建缓存
flutter clean
```

## 开发规范

### 代码风格
- 遵循 `flutter_lints` 规则 (见 `analysis_options.yaml`)
- 使用 Material 3 设计规范
- 主题色：活力蓝 (#007AFF)

### 架构模式
- **Riverpod** 进行状态管理
- **分层架构**: models → providers → screens → services
- **手动编写 Hive TypeAdapter**: 避免代码生成，保持简洁

### 核心练习逻辑
1. 从已启用词典中随机抽取未掌握单词
2. 用户输入单词，系统比对 (忽略大小写和首尾空格)
3. 正确：连续正确次数 +1；错误：计数器重置为 0
4. 达到设定次数 (默认 3 次) 后判定为掌握，自动切换下一词

### 词库文件格式规范
```
# 编码：UTF-8
# 分隔符：竖线 |
# 格式：单词 | 音标 | 释义 1|释义 2|...

Apple|/ˈæp.əl/|n. 苹果|v. 将...制成苹果状
Banana|/bəˈnɑː.nə/|n. 香蕉
```

## 支持平台

- ✅ Android
- ✅ iOS
- ✅ Web
- ✅ Windows
- ✅ macOS
- ✅ Linux

## 相关文件

| 文件 | 说明 |
|------|------|
| `pubspec.yaml` | 项目依赖配置 |
| `analysis_options.yaml` | 代码分析规则 |
| `.gitignore` | Git 忽略配置 |
| `test.md` | 产品需求文档 (PRD) |

## 注意事项

1. **Hive Adapter 注册顺序**: 必须按 typeId 顺序注册 (Word=0, Dictionary=1, StudyLog=2)
2. **数据初始化**: `main()` 中需先调用 `HiveService.init()` 再运行 `runApp`
3. **离线设计**: 应用不产生任何非用户主动触发的网络请求
4. **大文件处理**: 导入词库时使用流式读取，避免 OOM
