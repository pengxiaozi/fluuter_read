import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../providers/dictionary_provider.dart';
import '../providers/practice_provider.dart';
import '../services/built_in_dictionaries.dart';
import '../models/dictionary.dart';
import '../models/word.dart';
import '../services/hive_service.dart';

class DictionaryScreen extends ConsumerWidget {
  const DictionaryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(dictionaryProvider);
    final notifier = ref.read(dictionaryProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('词典中心'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'import_local') {
                notifier.importFromLocalFile();
              } else if (value == 'import_built_in') {
                _showBuiltInDialog(context, ref, notifier);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'import_local',
                child: Row(
                  children: [
                    Icon(Icons.file_open_rounded, size: 20),
                    SizedBox(width: 8),
                    Text('从本地文件导入'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'import_built_in',
                child: Row(
                  children: [
                    Icon(Icons.download_rounded, size: 20),
                    SizedBox(width: 8),
                    Text('导入内置词典'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          if (state.isLoading)
            const LinearProgressIndicator(minHeight: 2),
          if (state.errorMessage != null)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Card(
                color: const Color(0xFFFFF2F2),
                elevation: 0,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.error_outline,
                          color: Color(0xFFEB3B5A)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          state.errorMessage!,
                          style: const TextStyle(
                            color: Color(0xFFEB3B5A),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          Expanded(
            child: state.dictionaries.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.menu_book_outlined,
                            size: 64,
                            color: Colors.black.withValues(alpha: 0.08 * 255),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            '还没有词典',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '点击右上角按钮，从本地导入你的词库文件。',
                            style: Theme.of(context).textTheme.bodyMedium,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            '导入后可以点击开关启用/禁用词典，练习时只会从启用的词典中选题。',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    itemCount: state.dictionaries.length,
                    itemBuilder: (context, index) {
                      final dict = state.dictionaries[index];
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      dict.name,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w600,
                                            color: dict.enabled
                                                ? null
                                                : Colors.grey,
                                          ),
                                    ),
                                  ),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        '${dict.wordCount} 词条',
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelMedium,
                                      ),
                                      const SizedBox(width: 8),
                                      Switch(
                                        value: dict.enabled,
                                        onChanged: (value) async {
                                          // 立即更新本地状态
                                          final updated = Dictionary(
                                            id: dict.id,
                                            name: dict.name,
                                            description: dict.description,
                                            sourceUrl: dict.sourceUrl,
                                            lastUpdated: dict.lastUpdated,
                                            wordCount: dict.wordCount,
                                            enabled: value,
                                          );
                                          final dictBox = Hive.box<Dictionary>(
                                              HiveService.dictionaryBoxName);
                                          await dictBox.put(dict.id, updated);
                                          
                                          // 刷新词典列表
                                          await notifier.refreshDictionaries();
                                          
                                          // 如果在练习中，刷新练习
                                          ref.read(practiceProvider.notifier).skipToNext();
                                        },
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline, size: 20),
                                        tooltip: '删除词典',
                                        onPressed: () async {
                                          final confirmed = await showDialog<bool>(
                                            context: context,
                                            builder: (context) => AlertDialog(
                                              title: const Text('删除词典'),
                                              content: Text('确定要删除"${dict.name}"吗？删除后该词典的所有学习记录将丢失。'),
                                              actions: [
                                                TextButton(
                                                  onPressed: () => Navigator.pop(context, false),
                                                  child: const Text('取消'),
                                                ),
                                                FilledButton(
                                                  onPressed: () => Navigator.pop(context, true),
                                                  style: FilledButton.styleFrom(
                                                    backgroundColor: const Color(0xFFFF3B30),
                                                  ),
                                                  child: const Text('删除'),
                                                ),
                                              ],
                                            ),
                                          );
                                          
                                          if (confirmed == true) {
                                            // 删除词典的所有单词
                                            final wordBox = Hive.box<Word>(HiveService.wordBoxName);
                                            final wordsToDelete = wordBox.values
                                                .where((w) => w.dictionaryId == dict.id)
                                                .toList();
                                            for (final word in wordsToDelete) {
                                              await wordBox.delete(word.id);
                                            }
                                            // 删除词典记录
                                            final dictBox = Hive.box<Dictionary>(HiveService.dictionaryBoxName);
                                            await dictBox.delete(dict.id);
                                            
                                            // 刷新列表
                                            await notifier.refreshDictionaries();
                                            
                                            // 刷新练习
                                            ref.read(practiceProvider.notifier).skipToNext();
                                          }
                                        },
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              if (dict.description != null &&
                                  dict.description!.isNotEmpty)
                                Text(
                                  dict.description!,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        color: dict.enabled ? null : Colors.grey,
                                      ),
                                ),
                              const SizedBox(height: 8),
                              Text(
                                '最后更新：${dict.lastUpdated.toLocal().toString().split(".").first}',
                                style: Theme.of(context).textTheme.labelMedium,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _showBuiltInDialog(BuildContext context, WidgetRef ref, dynamic notifier) async {
    // 显示加载对话框
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('导入内置词典'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const LinearProgressIndicator(),
            const SizedBox(height: 16),
            const Text('正在导入考研词汇，请稍候...'),
            const SizedBox(height: 8),
            Text(
              '这可能需要 5-10 秒时间',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );

    try {
      final count = await BuiltInDictionaries.importBuiltIn(
        BuiltInDictionaries.kaoyan,
      );

      // 关闭加载对话框
      if (context.mounted) Navigator.pop(context);

      // 刷新词典列表
      await notifier.refreshDictionaries();
      
      // 强制刷新练习模块
      await Future.delayed(const Duration(milliseconds: 500));
      if (context.mounted) {
        ref.read(practiceProvider.notifier).skipToNext();
      }

      // 显示成功提示
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('考研词汇导入成功！共导入 $count 个单词'),
            backgroundColor: const Color(0xFF34C759),
          ),
        );
      }
    } catch (e) {
      // 关闭加载对话框
      if (context.mounted) Navigator.pop(context);

      // 显示错误提示
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('导入失败：$e'),
            backgroundColor: const Color(0xFFFF3B30),
          ),
        );
      }
    }
  }
}

