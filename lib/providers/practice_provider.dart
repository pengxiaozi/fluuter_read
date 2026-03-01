import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

import '../models/dictionary.dart';
import '../models/study_log.dart';
import '../models/word.dart';
import '../services/ebbinghaus_service.dart';
import '../services/hive_service.dart';
import 'settings_provider.dart';

/// 练习状态
class PracticeState {
  final Word? currentWord;
  final int consecutiveCorrect; // 当前单词连续正确次数
  final String? lastInput;
  final bool? lastIsCorrect;
  final String? feedbackMessage;
  final List<String> historyWordIds;
  final int historyIndex;
  final int todayLearnedCount; // 今日已学习数量
  final int nextReviewCount; // 待复习数量
  final bool shouldPlayAudio; // 是否应该播放音频

  const PracticeState({
    this.currentWord,
    this.consecutiveCorrect = 0,
    this.lastInput,
    this.lastIsCorrect,
    this.feedbackMessage,
    this.historyWordIds = const [],
    this.historyIndex = -1,
    this.todayLearnedCount = 0,
    this.nextReviewCount = 0,
    this.shouldPlayAudio = false,
  });

  PracticeState copyWith({
    Word? currentWord,
    bool clearCurrentWord = false,
    int? consecutiveCorrect,
    String? lastInput,
    bool? lastIsCorrect,
    String? feedbackMessage,
    List<String>? historyWordIds,
    int? historyIndex,
    int? todayLearnedCount,
    int? nextReviewCount,
    bool? shouldPlayAudio,
  }) {
    return PracticeState(
      currentWord: clearCurrentWord ? null : (currentWord ?? this.currentWord),
      consecutiveCorrect: consecutiveCorrect ?? this.consecutiveCorrect,
      lastInput: lastInput ?? this.lastInput,
      lastIsCorrect: lastIsCorrect ?? this.lastIsCorrect,
      feedbackMessage: feedbackMessage,
      historyWordIds: historyWordIds ?? this.historyWordIds,
      historyIndex: historyIndex ?? this.historyIndex,
      todayLearnedCount: todayLearnedCount ?? this.todayLearnedCount,
      nextReviewCount: nextReviewCount ?? this.nextReviewCount,
      shouldPlayAudio: shouldPlayAudio ?? this.shouldPlayAudio,
    );
  }
}

/// 练习 notifier
class PracticeNotifier extends StateNotifier<PracticeState> {
  final Ref ref;
  final _random = Random();
  final _uuid = const Uuid();
  bool _initialized = false;

  PracticeNotifier(this.ref) : super(const PracticeState());

  /// 初始化（只在第一次调用时执行）
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    await _updateCounts();
    await _loadNextWord();
  }

  /// 更新今日学习和待复习数量
  Future<void> _updateCounts() async {
    final wordBox = Hive.box<Word>(HiveService.wordBoxName);
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);

    // 今日已学习
    final todayLearned = wordBox.values.where((w) {
      final learnedTime = w.learnedTime;
      if (learnedTime == null) return false;
      return learnedTime.isAfter(todayStart);
    }).length;

    // 待复习（已到复习时间）
    final nextReview = wordBox.values.where((w) {
      final nextTime = w.nextReviewTime;
      if (nextTime == null) return false;
      return nextTime.isBefore(now);
    }).length;

    state = state.copyWith(
      todayLearnedCount: todayLearned,
      nextReviewCount: nextReview,
    );
  }

  /// 加载下一个单词
  Future<void> _loadNextWord() async {
    final wordBox = Hive.box<Word>(HiveService.wordBoxName);
    final dictBox = Hive.box<Dictionary>(HiveService.dictionaryBoxName);

    // 获取所有启用的词典 ID
    final enabledDictIds = dictBox.values
        .where((d) => d.enabled)
        .map((d) => d.id)
        .toSet();

    // 检查是否有启用的词典
    if (enabledDictIds.isEmpty) {
      state = state.copyWith(
        clearCurrentWord: true,
        feedbackMessage: '请先在词典中心启用词典',
      );
      return;
    }

    // 只从启用的词典中加载单词
    final enabledWords = wordBox.values
        .where((w) => enabledDictIds.contains(w.dictionaryId))
        .toList();

    if (enabledWords.isEmpty) {
      // 调试：打印所有单词的 dictionaryId
      final allDictIds = wordBox.values.map((w) => w.dictionaryId).toSet();
      state = state.copyWith(
        clearCurrentWord: true,
        feedbackMessage: '启用的词典中没有单词。启用 ID: $enabledDictIds, 单词中的词典 ID: $allDictIds',
      );
      return;
    }

    final settings = ref.read(settingsProvider);
    final now = DateTime.now();

    // 优先复习到期的单词
    final dueForReview = enabledWords.where((w) {
      final nextTime = w.nextReviewTime;
      if (nextTime == null) return false;
      return nextTime.isBefore(now);
    }).toList();

    if (dueForReview.isNotEmpty) {
      // 按到期时间排序，最早到期的优先
      dueForReview.sort((a, b) {
        final aTime = a.nextReviewTime!;
        final bTime = b.nextReviewTime!;
        return aTime.compareTo(bTime);
      });
      final next = dueForReview.first;
      await _loadWord(next);
      return;
    }

    // 检查是否达到每日学习上限
    if (state.todayLearnedCount >= settings.dailyLimit) {
      state = state.copyWith(
        clearCurrentWord: true,
        feedbackMessage: '今日学习已完成',
      );
      return;
    }

    // 学习新单词
    final newWords = enabledWords.where((w) {
      return w.learnedTime == null; // 从未学习过
    }).toList();

    if (newWords.isEmpty) {
      // 没有新单词，检查是否有未掌握的
      final notMastered = enabledWords.where((w) {
        return w.reviewCount < EbbinghausCurve.reviewIntervals.length;
      }).toList();

      if (notMastered.isEmpty) {
        state = state.copyWith(
          clearCurrentWord: true,
          feedbackMessage: '已掌握所有单词',
        );
        return;
      }

      final next = notMastered[_random.nextInt(notMastered.length)];
      await _loadWord(next);
      return;
    }

    // 从新单词中随机选择
    final next = newWords[_random.nextInt(newWords.length)];
    await _loadWord(next);
  }

  /// 加载指定单词
  Future<void> _loadWord(Word word) async {
    final newHistory = List<String>.from(state.historyWordIds)..add(word.id);
    state = state.copyWith(
      currentWord: word,
      consecutiveCorrect: 0,
      lastInput: null,
      lastIsCorrect: null,
      feedbackMessage: null,
      historyWordIds: newHistory,
      historyIndex: newHistory.length - 1,
    );
  }

  /// 提交答案
  Future<void> submitAnswer(String input) async {
    final word = state.currentWord;
    if (word == null) return;

    final normalizedInput = input.trim().toLowerCase();
    final normalizedAnswer = word.term.trim().toLowerCase();
    final isCorrect = normalizedInput == normalizedAnswer;
    final newConsecutiveCorrect = isCorrect ? state.consecutiveCorrect + 1 : 0;

    // 记录到 Hive
    await _saveToHive(word, input, isCorrect, newConsecutiveCorrect);

    final settings = ref.read(settingsProvider);
    final required = settings.requiredCorrectTimes;

    String feedback;
    if (isCorrect) {
      // 更新单词状态
      final wordBox = Hive.box<Word>(HiveService.wordBoxName);
      final updatedWord = Word(
        id: word.id,
        dictionaryId: word.dictionaryId,
        term: word.term,
        phonetic: word.phonetic,
        definitions: word.definitions,
        masteryLevel: word.masteryLevel,
        examples: word.examples,
        synonymDetails: word.synonymDetails,
        phraseDetails: word.phraseDetails,
        relatedDetails: word.relatedDetails,
        reviewCount: word.reviewCount,
        nextReviewTime: word.nextReviewTime,
        learnedTime: word.learnedTime ?? DateTime.now(),
      );

      if (newConsecutiveCorrect >= required) {
        // 判定为掌握，进入艾宾浩斯复习周期
        updatedWord.reviewCount = word.reviewCount + 1;
        updatedWord.nextReviewTime = EbbinghausCurve.getNextReviewTime(
          reviewCount: updatedWord.reviewCount,
        );
        feedback = '已掌握';

        // 保存更新后的单词
        await wordBox.put(word.id, updatedWord);

        // 更新状态
        state = state.copyWith(
          consecutiveCorrect: newConsecutiveCorrect,
          lastInput: input,
          lastIsCorrect: isCorrect,
          feedbackMessage: feedback,
          shouldPlayAudio: true,
        );

        // 更新计数
        await _updateCounts();

        // 立即切换到下一个单词
        if (mounted) {
          await _loadNextWord();
        }
        return;
      } else {
        feedback = '正确 $newConsecutiveCorrect/$required';
      }

      // 回答正确时播放音频
      state = state.copyWith(
        consecutiveCorrect: newConsecutiveCorrect,
        lastInput: input,
        lastIsCorrect: isCorrect,
        feedbackMessage: feedback,
        shouldPlayAudio: true,
      );
      return;
    } else {
      feedback = '错误';
    }

    state = state.copyWith(
      consecutiveCorrect: newConsecutiveCorrect,
      lastInput: input,
      lastIsCorrect: isCorrect,
      feedbackMessage: feedback,
      shouldPlayAudio: false,
    );
  }

  /// 保存学习记录到 Hive
  Future<void> _saveToHive(
    Word word,
    String input,
    bool isCorrect,
    int consecutiveCorrect,
  ) async {
    try {
      final logBox = Hive.box<StudyLog>(HiveService.studyLogBoxName);
      final log = StudyLog(
        id: _uuid.v4(),
        wordId: word.id,
        timestamp: DateTime.now(),
        isCorrect: isCorrect,
        attempts: consecutiveCorrect,
      );
      await logBox.put(log.id, log);

      // 更新每日统计
      final settingsBox = Hive.box(HiveService.settingsBoxName);
      final today = '${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}';
      final statsKey = 'stats_$today';
      Map<String, dynamic> stats =
          settingsBox.get(statsKey, defaultValue: {
        'new_words_learned': 0,
        'words_reviewed': 0,
        'total_attempts': 0,
        'correct_attempts': 0,
      }) as Map<String, dynamic>;

      stats['new_words_learned'] =
          (stats['new_words_learned'] as int) +
              (word.learnedTime == null ? 1 : 0);
      stats['words_reviewed'] =
          (stats['words_reviewed'] as int) +
              (word.learnedTime != null ? 1 : 0);
      stats['total_attempts'] = (stats['total_attempts'] as int) + 1;
      stats['correct_attempts'] =
          (stats['correct_attempts'] as int) + (isCorrect ? 1 : 0);

      await settingsBox.put(statsKey, stats);
    } catch (e) {
      // 保存学习记录失败
    }
  }

  /// 重置播放音频标志
  void resetPlayAudioFlag() {
    state = state.copyWith(shouldPlayAudio: false);
  }

  /// 跳过当前单词
  Future<void> skipToNext() async {
    await _loadNextWord();
  }

  /// 返回上一个单词
  Future<void> previousWord() async {
    if (state.historyWordIds.isEmpty || state.historyIndex <= 0) {
      return;
    }
    final newIndex = state.historyIndex - 1;
    final wordId = state.historyWordIds[newIndex];
    final wordBox = Hive.box<Word>(HiveService.wordBoxName);
    final prev = wordBox.get(wordId);
    if (prev == null) {
      return;
    }

    state = state.copyWith(
      currentWord: prev,
      historyIndex: newIndex,
      consecutiveCorrect: 0,
      lastInput: null,
      lastIsCorrect: null,
      feedbackMessage: null,
    );
  }

  /// 重置学习进度
  Future<void> resetProgress() async {
    final wordBox = Hive.box<Word>(HiveService.wordBoxName);
    for (final word in wordBox.values) {
      final updatedWord = Word(
        id: word.id,
        dictionaryId: word.dictionaryId,
        term: word.term,
        phonetic: word.phonetic,
        definitions: word.definitions,
        masteryLevel: 0,
        examples: word.examples,
        synonymDetails: word.synonymDetails,
        phraseDetails: word.phraseDetails,
        relatedDetails: word.relatedDetails,
        reviewCount: 0,
        nextReviewTime: null,
        learnedTime: null,
      );
      await wordBox.put(word.id, updatedWord);
    }
    await _updateCounts();
    await _loadNextWord();
  }
}

final practiceProvider =
    StateNotifierProvider<PracticeNotifier, PracticeState>((ref) {
  return PracticeNotifier(ref);
});
