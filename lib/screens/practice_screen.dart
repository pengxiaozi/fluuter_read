import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../models/word.dart';
import '../providers/practice_provider.dart';
import '../providers/settings_provider.dart';

class PracticeScreen extends ConsumerStatefulWidget {
  const PracticeScreen({super.key});

  @override
  ConsumerState<PracticeScreen> createState() => _PracticeScreenState();
}

class _PracticeScreenState extends ConsumerState<PracticeScreen>
    with SingleTickerProviderStateMixin {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  final FlutterTts _flutterTts = FlutterTts();
  String? _lastWordId;
  bool _initialized = false;
  TabController? _tabController;

  @override
  void initState() {
    super.initState();
    _initTts();
    _delayedInit();
  }

  void _delayedInit() {
    SchedulerBinding.instance.addPostFrameCallback((_) async {
      if (mounted && !_initialized) {
        _initialized = true;
        final notifier = ref.read(practiceProvider.notifier);
        await notifier.initialize();
        // 初始化 TabController
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _initTabController();
          }
        });
        // Web 平台：使用自动聚焦，不手动调用 requestFocus
        if (!kIsWeb) {
          _focusNode.requestFocus();
        }
      }
    });
  }

  void _initTabController() {
    _tabController?.dispose();
    _tabController = TabController(length: 4, vsync: this);
  }

  Future<void> _initTts() async {
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setPitch(1.0);
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setVolume(1.0);
  }

  Future<void> _speak(String text) async {
    await _flutterTts.stop();
    await _flutterTts.speak(text);
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _tabController?.dispose();
    _flutterTts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final practiceState = ref.watch(practiceProvider);
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(practiceProvider.notifier);

    final word = practiceState.currentWord;

    // 监听单词变化
    if (_initialized) {
      ref.listen<Word?>(
        practiceProvider.select((state) => state.currentWord),
        (previous, next) {
          if (next != null && _lastWordId != next.id) {
            _lastWordId = next.id;
            _controller.clear();
            // 重置 Tab 索引
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && _tabController != null) {
                _tabController!.index = 0;
              }
              // Web 平台：不手动聚焦，依赖 autofoucs
              if (!kIsWeb) {
                _focusNode.requestFocus();
              }
              _speak(next.term);
            });
          }
        },
      );
    }

    // 监听是否正确回答，正确时播放音频
    ref.listen<bool?>(
      practiceProvider.select((state) => state.shouldPlayAudio),
      (previous, next) {
        if (next == true && word != null) {
          SchedulerBinding.instance.addPostFrameCallback((_) {
            if (mounted) _speak(word.term);
          });
          Future.delayed(const Duration(milliseconds: 100), () {
            if (mounted) notifier.resetPlayAudioFlag();
          });
        }
      },
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('肌肉记忆练习'),
        actions: [
          IconButton(
            onPressed: word == null ? null : () => notifier.skipToNext(),
            icon: const Icon(Icons.skip_next),
            tooltip: '跳过本词',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: word == null
            ? Center(
                child: Text(
                  practiceState.feedbackMessage ?? '暂无可练习的单词。',
                  textAlign: TextAlign.center,
                ),
              )
            : Column(
                children: [
                  // 顶部统计和提示
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildStatChip(
                        context,
                        label: '连续正确',
                        value: '${practiceState.consecutiveCorrect}/${settings.requiredCorrectTimes}',
                        icon: Icons.bolt_outlined,
                      ),
                      _buildStatChip(
                        context,
                        label: '今日学习',
                        value: '${practiceState.todayLearnedCount}/${settings.dailyLimit}',
                        icon: Icons.school_outlined,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      _buildStatChip(
                        context,
                        label: '待复习',
                        value: '${practiceState.nextReviewCount}',
                        icon: Icons.schedule,
                      ),
                    ],
                  ),
                  // 反馈提示（顶部小字）
                  if (practiceState.feedbackMessage != null && practiceState.lastIsCorrect != null)
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: (practiceState.lastIsCorrect ?? false)
                            ? const Color(0xFF34C759)
                            : const Color(0xFFFF3B30),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        practiceState.feedbackMessage!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                  // 单词卡片
                  Expanded(
                    child: SingleChildScrollView(
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // 导航按钮
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  _buildIconBtn(
                                    context,
                                    icon: Icons.arrow_back_ios_new_rounded,
                                    onTap: practiceState.feedbackMessage == '已掌握'
                                        ? null
                                        : () => ref.read(practiceProvider.notifier).previousWord(),
                                  ),
                                  _buildIconBtn(
                                    context,
                                    icon: Icons.arrow_forward_ios_rounded,
                                    onTap: practiceState.feedbackMessage == '已掌握'
                                        ? null
                                        : () => ref.read(practiceProvider.notifier).skipToNext(),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              // 单词和发音
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Expanded(
                                    child: SizedBox(
                                      height: 80,
                                      child: Stack(
                                        alignment: Alignment.center,
                                        children: [
                                          Text(
                                            word.term,
                                            style: Theme.of(context)
                                                .textTheme
                                                .displaySmall
                                                ?.copyWith(
                                                  fontWeight: FontWeight.w700,
                                                  color: Colors.black.withValues(alpha: 0.12 * 255),
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(left: 8),
                                    child: GestureDetector(
                                      onTap: () => _speak(word.term),
                                      child: const Icon(
                                        Icons.volume_up_rounded,
                                        size: 18,
                                        color: Color(0xFF007AFF),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              // 输入框
                              TextField(
                                key: ValueKey('input_${word.id}'),
                                controller: _controller,
                                focusNode: _focusNode,
                                textAlign: TextAlign.center,
                                // Web 平台使用 autofocus，避免手动焦点管理
                                autofocus: kIsWeb,
                                // Web 平台禁用选择功能，避免 DOM 焦点问题
                                enableInteractiveSelection: !kIsWeb,
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                      letterSpacing: 6,
                                      fontWeight: FontWeight.w600,
                                    ),
                                textInputAction: TextInputAction.done,
                                onSubmitted: (value) {
                                  if (value.isEmpty) return;
                                  notifier.submitAnswer(value);
                                  _controller.clear();
                                },
                                decoration: InputDecoration(
                                  hintText: '_' * word.term.length,
                                  hintStyle: Theme.of(context)
                                      .textTheme
                                      .titleLarge
                                      ?.copyWith(
                                        letterSpacing: 6,
                                        color: const Color(0xFF8E8E93),
                                      ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                      color: Color(0xFFE5E5EA),
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                      color: Color(0xFFE5E5EA),
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                      color: Color(0xFF007AFF),
                                      width: 1.5,
                                    ),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              // 音标
                              if (settings.showPhonetic && word.phonetic != null)
                                Center(
                                  child: Text(
                                    word.phonetic!,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          color: const Color(0xFF5856D6),
                                        ),
                                  ),
                                ),
                              if (settings.showPhonetic && word.phonetic != null)
                                const SizedBox(height: 8),
                              // 释义
                              if (settings.showDefinition && word.definitions.isNotEmpty)
                                Text(
                                  word.definitions.first,
                                  style: Theme.of(context).textTheme.bodyLarge,
                                ),
                              if (word.nextReviewTime != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.schedule,
                                        size: 14,
                                        color: Colors.grey[600],
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '下次复习：${word.nextReviewTime!.month}月${word.nextReviewTime!.day}日 ${word.nextReviewTime!.hour}:${word.nextReviewTime!.minute.toString().padLeft(2, '0')}',
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelSmall
                                            ?.copyWith(
                                              color: Colors.grey[600],
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              const SizedBox(height: 16),
                              // 单词详情卡片（Tab 切换）
                              _buildWordDetailsTabCard(context, word),
                              const SizedBox(height: 12),
                              // 清除和确认按钮
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  _buildIconBtn(
                                    context,
                                    icon: Icons.clear_rounded,
                                    onTap: () {
                                      _controller.clear();
                                      // Web 平台不手动聚焦，依赖 autofoucs
                                      if (!kIsWeb) {
                                        _focusNode.requestFocus();
                                      }
                                    },
                                  ),
                                  const SizedBox(width: 8),
                                  _buildIconBtn(
                                    context,
                                    icon: Icons.check_rounded,
                                    filled: true,
                                    onTap: () {
                                      final value = _controller.text;
                                      if (value.isEmpty) return;
                                      notifier.submitAnswer(value);
                                      _controller.clear();
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  /// 构建单词详情 Tab 卡片
  Widget _buildWordDetailsTabCard(BuildContext context, Word word) {
    final hasExamples = word.examples.isNotEmpty;
    final hasSynonyms = word.synonymDetails.isNotEmpty;
    final hasPhrases = word.phraseDetails.isNotEmpty;
    final hasRelated = word.relatedDetails.isNotEmpty;

    // 如果没有任何扩展信息，返回空容器
    if (!hasExamples && !hasSynonyms && !hasPhrases && !hasRelated) {
      return const SizedBox.shrink();
    }

    // 构建 Tab 列表
    final tabs = <Tab>[];
    final tabViews = <Widget>[];

    if (hasExamples) {
      tabs.add(const Tab(icon: Icon(Icons.format_quote_rounded, size: 18), text: '例句'));
      tabViews.add(_buildDetailSection(
        context,
        icon: Icons.format_quote_rounded,
        title: '例句',
        color: const Color(0xFF5856D6),
        items: word.examples,
        highlightWord: word.term, // 加粗当前单词
      ));
    }

    if (hasSynonyms) {
      tabs.add(const Tab(icon: Icon(Icons.compare_arrows, size: 18), text: '同近义词'));
      tabViews.add(_buildDetailSection(
        context,
        icon: Icons.compare_arrows,
        title: '同近义词',
        color: const Color(0xFFFF9500),
        items: word.synonymDetails,
      ));
    }

    if (hasPhrases) {
      tabs.add(const Tab(icon: Icon(Icons.library_books_rounded, size: 18), text: '短语'));
      tabViews.add(_buildDetailSection(
        context,
        icon: Icons.library_books_rounded,
        title: '短语',
        color: const Color(0xFF34C759),
        items: word.phraseDetails,
      ));
    }

    if (hasRelated) {
      tabs.add(const Tab(icon: Icon(Icons.account_tree_rounded, size: 18), text: '同根词'));
      tabViews.add(_buildDetailSection(
        context,
        icon: Icons.account_tree_rounded,
        title: '同根词',
        color: const Color(0xFF007AFF),
        items: word.relatedDetails,
      ));
    }

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE9ECEF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TabBar(
            controller: _tabController,
            tabs: tabs,
            labelColor: const Color(0xFF007AFF),
            unselectedLabelColor: Colors.grey[600],
            indicatorColor: const Color(0xFF007AFF),
            indicatorWeight: 2,
            labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            dividerColor: Colors.transparent,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
          ),
          const Divider(height: 1),
          SizedBox(
            height: 200,
            child: TabBarView(
              controller: _tabController,
              children: tabViews,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建详情卡片的单个区块
  Widget _buildDetailSection(
    BuildContext context, {
    required IconData icon,
    required String title,
    required Color color,
    required List<String> items,
    String? highlightWord, // 用于在例句中加粗当前单词
  }) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...items.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: highlightWord != null
                ? _buildHighlightedText(context, item, highlightWord)
                : Text(
                    item,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      height: 1.5,
                    ),
                  ),
          )),
        ],
      ),
    );
  }

  /// 构建带高亮的文本（例句中加粗当前单词）
  Widget _buildHighlightedText(BuildContext context, String text, String highlightWord) {
    // 例句格式："英文\n中文"，只处理英文部分
    final lines = text.split('\n');
    final englishLine = lines.first;
    final chineseLine = lines.length > 1 ? lines.sublist(1).join('\n') : '';

    // 不区分大小写匹配单词
    final pattern = RegExp('(${RegExp.escape(highlightWord)})', caseSensitive: false);
    final parts = englishLine.split(pattern);

    return RichText(
      text: TextSpan(
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.5),
        children: [
          // 英文部分（带加粗）
          ...parts.asMap().entries.map((entry) {
            final index = entry.key;
            final part = entry.value;
            return TextSpan(
              text: part,
              style: index % 2 == 1 // 奇数索引是匹配的单词
                  ? const TextStyle(fontWeight: FontWeight.w700, color: Colors.black)
                  : null,
            );
          }),
          // 中文部分
          if (chineseLine.isNotEmpty) ...[
            const TextSpan(text: '\n'),
            TextSpan(
              text: chineseLine,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ],
      ),
    );
  }
}

Widget _buildStatChip(BuildContext context, {
  required String label,
  required String value,
  required IconData icon,
}) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: const Color(0xFFF2F2F7),
      borderRadius: BorderRadius.circular(999),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: const Color(0xFF007AFF)),
        const SizedBox(width: 6),
        Text(label, style: Theme.of(context).textTheme.labelSmall),
        const SizedBox(width: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    ),
  );
}

Widget _buildIconBtn(BuildContext context, {
  required IconData icon,
  required VoidCallback? onTap,
  bool filled = false,
}) {
  final Color primary = const Color(0xFF007AFF);
  final disabled = onTap == null;
  return InkWell(
    borderRadius: BorderRadius.circular(8),
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: disabled
            ? const Color(0xFFE5E5EA)
            : (filled ? primary : const Color(0xFFF2F2F7)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        icon,
        size: 20,
        color: disabled
            ? const Color(0xFF8E8E93)
            : (filled ? Colors.white : primary),
      ),
    ),
  );
}
