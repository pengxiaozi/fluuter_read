import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../providers/study_log_provider.dart';

class StudyLogScreen extends ConsumerStatefulWidget {
  const StudyLogScreen({super.key});

  @override
  ConsumerState<StudyLogScreen> createState() => _StudyLogScreenState();
}

class _StudyLogScreenState extends ConsumerState<StudyLogScreen> {
  final FlutterTts _flutterTts = FlutterTts();

  @override
  void initState() {
    super.initState();
    _initTts();
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
    _flutterTts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(studyLogProvider);
    final notifier = ref.read(studyLogProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('学习记录'),
        actions: [
          IconButton(
            onPressed: () => notifier.reload(),
            icon: const Icon(Icons.refresh),
            tooltip: '刷新',
          ),
        ],
      ),
      body: state.dailyStats.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.history,
                      size: 64,
                      color: Colors.black.withValues(alpha: 0.08 * 255),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '暂无学习记录',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '开始在"练习"中输入单词，我们会为你记录每一次尝试。',
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              itemCount: state.dailyStats.length,
              itemBuilder: (context, index) {
                final dailyStats = state.dailyStats[index];
                return _buildDailySection(context, dailyStats);
              },
            ),
    );
  }

  Widget _buildDailySection(BuildContext context, DailyStats dailyStats) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 日期标题
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFF2F2F7),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            dailyStats.date,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
        // 单词列表 - 紧凑布局
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: dailyStats.words.map((word) => _buildWordChip(context, word)).toList(),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildWordChip(BuildContext context, WordStudyRecord record) {
    final totalAttempts = record.correctCount + record.incorrectCount;
    final correctRate = totalAttempts > 0
        ? (record.correctCount / totalAttempts * 100).toInt()
        : 0;

    return Container(
      constraints: const BoxConstraints(minWidth: 120),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE5E5EA), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // 单词和播放按钮
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    record.word.term,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 4),
                SizedBox(
                  width: 24,
                  height: 24,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    onPressed: () => _speak(record.word.term),
                    icon: const Icon(Icons.volume_up_rounded, size: 16),
                    tooltip: '播放发音',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            // 中文释义
            if (record.word.definitions.isNotEmpty)
              Flexible(
                child: Text(
                  record.word.definitions.first,
                  style: const TextStyle(fontSize: 11, color: Color(0xFF8E8E93)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            const SizedBox(height: 6),
            // 统计信息
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildMiniStatChip(
                  label: '${record.correctCount}',
                  color: const Color(0xFF34C759),
                  tooltip: '正确',
                ),
                const SizedBox(width: 4),
                _buildMiniStatChip(
                  label: '${record.incorrectCount}',
                  color: const Color(0xFFFF3B30),
                  tooltip: '错误',
                ),
                const Spacer(),
                Text(
                  '$correctRate%',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: correctRate >= 80
                        ? const Color(0xFF34C759)
                        : correctRate >= 50
                            ? const Color(0xFFFF9500)
                            : const Color(0xFFFF3B30),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniStatChip({
    required String label,
    required Color color,
    required String tooltip,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1 * 255),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
