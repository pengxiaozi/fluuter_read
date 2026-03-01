import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../models/study_log.dart';
import '../models/word.dart';
import '../services/hive_service.dart';

/// 每日学习统计
class DailyStats {
  final String date;
  final List<WordStudyRecord> words;

  const DailyStats({required this.date, required this.words});
}

/// 单词学习记录
class WordStudyRecord {
  final Word word;
  final int correctCount;
  final int incorrectCount;
  final List<StudyLog> logs;

  const WordStudyRecord({
    required this.word,
    required this.correctCount,
    required this.incorrectCount,
    required this.logs,
  });
}

class StudyLogState {
  final List<DailyStats> dailyStats;

  const StudyLogState({required this.dailyStats});

  StudyLogState copyWith({List<DailyStats>? dailyStats}) {
    return StudyLogState(dailyStats: dailyStats ?? this.dailyStats);
  }
}

class StudyLogNotifier extends StateNotifier<StudyLogState> {
  StudyLogNotifier() : super(const StudyLogState(dailyStats: [])) {
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    try {
      final logBox = Hive.box<StudyLog>(HiveService.studyLogBoxName);
      final wordBox = Hive.box<Word>(HiveService.wordBoxName);
      final logs = logBox.values.toList()
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

      // 按日期分组
      final Map<String, Map<String, WordStudyRecord>> dailyMap = {};

      for (final log in logs) {
        final date = _formatDate(log.timestamp);
        
        if (!dailyMap.containsKey(date)) {
          dailyMap[date] = {};
        }

        final word = wordBox.get(log.wordId);
        if (word == null) continue;

        if (!dailyMap[date]!.containsKey(log.wordId)) {
          dailyMap[date]![log.wordId] = WordStudyRecord(
            word: word,
            correctCount: log.isCorrect ? 1 : 0,
            incorrectCount: log.isCorrect ? 0 : 1,
            logs: [log],
          );
        } else {
          // 更新现有记录
          final existing = dailyMap[date]![log.wordId]!;
          final updatedLogs = List<StudyLog>.from(existing.logs)..add(log);
          dailyMap[date]![log.wordId] = WordStudyRecord(
            word: existing.word,
            correctCount: existing.correctCount + (log.isCorrect ? 1 : 0),
            incorrectCount: existing.incorrectCount + (log.isCorrect ? 0 : 1),
            logs: updatedLogs,
          );
        }
      }

      // 转换为 DailyStats 列表
      final dailyStats = dailyMap.entries.map((entry) {
        return DailyStats(
          date: entry.key,
          words: entry.value.values.toList(),
        );
      }).toList();

      dailyStats.sort((a, b) => b.date.compareTo(a.date));
      state = state.copyWith(dailyStats: dailyStats);
    } catch (e) {
      state = const StudyLogState(dailyStats: []);
    }
  }

  String _formatDate(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final logDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (logDate == today) {
      return '今天';
    } else if (logDate == yesterday) {
      return '昨天';
    } else {
      return '${dateTime.month}月${dateTime.day}日';
    }
  }

  /// 添加学习记录
  void addLog(StudyLog log) {
    reload();
  }

  /// 重新加载数据
  Future<void> reload() async {
    await _loadLogs();
  }
}

final studyLogProvider =
    StateNotifierProvider<StudyLogNotifier, StudyLogState>((ref) {
  return StudyLogNotifier();
});

