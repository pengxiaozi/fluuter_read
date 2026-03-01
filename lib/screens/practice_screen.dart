import 'dart:async';

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
  TextEditingController? _controller;
  final FlutterTts _flutterTts = FlutterTts();
  String? _lastWordId;
  bool _initialized = false;
  TabController? _tabController;
  Timer? _focusTimer;
  
  // Web 平台专用：使用 FocusKey 来管理焦点
  final GlobalKey _inputKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _initTts();
    _delayedInit();
  }

  void _createInputController() {
    _controller?.dispose();
    _focusTimer?.cancel();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller?.dispose();
    _tabController?.dispose();
    _flutterTts.stop();
    _focusTimer?.cancel();
    super.dispose();
  }

  void _delayedInit() {
    SchedulerBinding.instance.addPostFrameCallback((_) async {
      if (mounted && !_initialized) {
        _initialized = true;
        final notifier = ref.read(practiceProvider.notifier);
        await notifier.initialize();
        _createInputController();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _initTabController();
          }
        });
      }
    });
  }

  void _tryRequestFocus() {
    if (!mounted) return;
    _focusTimer?.cancel();

    // Web 平台下使用 FocusScope 聚焦，通过 GlobalKey 获取 RenderBox
    if (kIsWeb) {
      _focusTimer = Timer(const Duration(milliseconds: 200), () {
        if (!mounted) return;
        final context = _inputKey.currentContext;
        if (context != null) {
          FocusScope.of(context).requestFocus();
        }
      });
      return;
    }

    // 非 Web 平台正常聚焦
    _focusTimer = Timer(const Duration(milliseconds: 100), () {
      if (mounted) {
        final context = _inputKey.currentContext;
        if (context != null) {
          FocusScope.of(context).requestFocus();
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
  Widget build(BuildContext context) {
    final practiceState = ref.watch(practiceProvider);
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(practiceProvider.notifier);

    final word = practiceState.currentWord;

    if (_initialized) {
      ref.listen<Word?>(
        practiceProvider.select((state) => state.currentWord),
        (previous, next) {
          if (next != null && _lastWordId != next.id) {
            _lastWordId = next.id;
            _createInputController();
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && _tabController != null) {
                _tabController!.index = 0;
              }
              _speak(next.term);
              SchedulerBinding.instance.addPostFrameCallback((_) {
                _tryRequestFocus();
              });
            });
          }
        },
      );
    }

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
          if (word != null)
            IconButton(
              onPressed: () {
                print('=== 当前单词数据 ===');
                print('term: ${word.term}');
                print('definitions: ${word.definitions}');
                print('examples: ${word.examples}');
                print('===================');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('例句数：${word.examples.length}, 短语数：${word.phraseDetails.length}'),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
              icon: const Icon(Icons.bug_report),
              tooltip: '查看数据',
            ),
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
                  Expanded(
                    child: SingleChildScrollView(
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
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
                              // 输入框 - 使用 Focus 包装
                              Focus(
                                onFocusChange: (hasFocus) {
                                  // Web 平台下，聚焦时确保输入框可用
                                  if (kIsWeb && hasFocus) {
                                    SchedulerBinding.instance.addPostFrameCallback((_) {
                                      _controller?.selection = TextSelection.collapsed(
                                        offset: _controller?.text.length ?? 0,
                                      );
                                    });
                                  }
                                },
                                child: TextField(
                                  key: _inputKey,
                                  controller: _controller,
                                  textAlign: TextAlign.center,
                                  enableInteractiveSelection: true,
                                  keyboardType: TextInputType.text,
                                  autofocus: false,
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                        letterSpacing: 6,
                                        fontWeight: FontWeight.w600,
                                      ),
                                  textInputAction: TextInputAction.done,
                                  onSubmitted: (value) {
                                    if (value.isEmpty) return;
                                    notifier.submitAnswer(value);
                                    _controller?.clear();
                                  },
                                  decoration: InputDecoration(
                                    hintText: kIsWeb ? '点击输入框开始输入' : '_' * word.term.length,
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
                              ),
                              const SizedBox(height: 16),
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
                              _buildWordDetailsTabCard(context, word),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  _buildIconBtn(
                                    context,
                                    icon: Icons.clear_rounded,
                                    onTap: () {
                                      _controller?.clear();
                                      SchedulerBinding.instance.addPostFrameCallback((_) {
                                        _tryRequestFocus();
                                      });
                                    },
                                  ),
                                  const SizedBox(width: 8),
                                  _buildIconBtn(
                                    context,
                                    icon: Icons.check_rounded,
                                    filled: true,
                                    onTap: () {
                                      final value = _controller?.text ?? '';
                                      if (value.isEmpty) return;
                                      notifier.submitAnswer(value);
                                      _controller?.clear();
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

  Widget _buildWordDetailsTabCard(BuildContext context, Word word) {
    final hasExamples = word.examples.isNotEmpty;
    final hasSynonyms = word.synonymDetails.isNotEmpty;
    final hasPhrases = word.phraseDetails.isNotEmpty;
    final hasRelated = word.relatedDetails.isNotEmpty;

    if (!hasExamples && !hasSynonyms && !hasPhrases && !hasRelated) {
      return const SizedBox.shrink();
    }

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
        highlightWord: word.term,
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

  Widget _buildDetailSection(
    BuildContext context, {
    required IconData icon,
    required String title,
    required Color color,
    required List<String> items,
    String? highlightWord,
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

  Widget _buildHighlightedText(BuildContext context, String text, String highlightWord) {
    final lines = text.split('\n');
    final englishLine = lines.first;
    final chineseLine = lines.length > 1 ? lines.sublist(1).join('\n') : '';

    final escapedWord = RegExp.escape(highlightWord);
    final pattern = RegExp('\\b(${escapedWord}s?|${escapedWord}ed|${escapedWord}ing)\\b', caseSensitive: false);

    final matches = pattern.allMatches(englishLine).toList();
    if (matches.isEmpty) {
      return RichText(
        text: TextSpan(
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.5),
          children: [
            TextSpan(text: englishLine),
            if (chineseLine.isNotEmpty) ...[
              const TextSpan(text: '\n'),
              TextSpan(text: chineseLine, style: TextStyle(color: Colors.grey[600])),
            ],
          ],
        ),
      );
    }

    final children = <TextSpan>[];
    int lastEnd = 0;

    for (final match in matches) {
      if (match.start > lastEnd) {
        children.add(TextSpan(text: englishLine.substring(lastEnd, match.start)));
      }
      children.add(TextSpan(
        text: match.group(0),
        style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF007AFF)),
      ));
      lastEnd = match.end;
    }

    if (lastEnd < englishLine.length) {
      children.add(TextSpan(text: englishLine.substring(lastEnd)));
    }

    if (chineseLine.isNotEmpty) {
      children.add(const TextSpan(text: '\n'));
      children.add(TextSpan(text: chineseLine, style: TextStyle(color: Colors.grey[600])));
    }

    return RichText(
      text: TextSpan(
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.5),
        children: children,
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
  final Color primaryColor = const Color(0xFF007AFF);
  return GestureDetector(
    onTap: onTap,
    child: Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: filled ? primaryColor : const Color(0xFFF2F2F7),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(
        icon,
        size: 20,
        color: filled ? Colors.white : primaryColor,
      ),
    ),
  );
}
