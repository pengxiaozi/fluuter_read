import 'dart:convert';
import 'dart:io' show File;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

import '../models/dictionary.dart';
import '../models/word.dart';
import '../services/hive_service.dart';
import 'practice_provider.dart';

class DictionaryState {
  final List<Dictionary> dictionaries;
  final bool isLoading;
  final String? errorMessage;

  const DictionaryState({
    required this.dictionaries,
    this.isLoading = false,
    this.errorMessage,
  });

  DictionaryState copyWith({
    List<Dictionary>? dictionaries,
    bool? isLoading,
    String? errorMessage,
  }) {
    return DictionaryState(
      dictionaries: dictionaries ?? this.dictionaries,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class DictionaryNotifier extends StateNotifier<DictionaryState> {
  final Ref ref;

  DictionaryNotifier(this.ref)
      : super(const DictionaryState(dictionaries: [])) {
    _loadDictionaries();
  }

  Future<void> _loadDictionaries() async {
    final box = Hive.box<Dictionary>(HiveService.dictionaryBoxName);
    
    // 迁移旧数据：如果 enabled 字段不存在，设置为 true
    for (final dict in box.values) {
      if (!dict.enabled) {
        final updated = Dictionary(
          id: dict.id,
          name: dict.name,
          description: dict.description,
          sourceUrl: dict.sourceUrl,
          lastUpdated: dict.lastUpdated,
          wordCount: dict.wordCount,
          enabled: true,
        );
        await box.put(dict.id, updated);
      }
    }
    
    state = state.copyWith(
      dictionaries: box.values.toList(),
      isLoading: false,
    );
  }

  /// 刷新词典列表（公开方法）
  Future<void> refreshDictionaries() async {
    await _loadDictionaries();
  }

  Future<void> importFromLocalFile() async {
    try {
      state = state.copyWith(isLoading: true, errorMessage: null);

      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['txt', 'csv', 'json'],
      );
      if (result == null || result.files.isEmpty) {
        state = state.copyWith(isLoading: false);
        return;
      }

      final file = result.files.first;

      // Web 环境下 file.path 不可用，需要从 bytes 读取。
      String content;
      if (kIsWeb) {
        final bytes = file.bytes;
        if (bytes == null) {
          throw Exception('无法读取文件内容');
        }
        content = utf8.decode(bytes);
      } else {
        final path = file.path;
        if (path == null) {
          throw Exception('无法访问选择的文件路径');
        }
        content = await File(path).readAsString(encoding: utf8);
      }
      final uuid = const Uuid();
      final dictionaryId = uuid.v4();
      final wordBox = Hive.box<Word>(HiveService.wordBoxName);
      int count = 0;
      final extension = file.extension?.toLowerCase();

      if (extension == 'json') {
        // JSON 词典导入
        count = await _importFromJson(
          content: content,
          dictionaryId: dictionaryId,
          wordBox: wordBox,
          uuid: uuid,
        );
      } else {
        // 兼容原先的 | 分隔纯文本格式
        count = await _importFromPipeSeparatedText(
          content: content,
          dictionaryId: dictionaryId,
          wordBox: wordBox,
          uuid: uuid,
        );
      }

      if (count == 0) {
        throw Exception('未成功解析任何单词，请检查文件格式。');
      }

      final dict = Dictionary(
        id: dictionaryId,
        name: file.name,
        description: '从本地文件导入',
        sourceUrl: null,
        lastUpdated: DateTime.now(),
        wordCount: count,
        enabled: true, // 默认启用
      );

      final dictBox =
          Hive.box<Dictionary>(HiveService.dictionaryBoxName);
      await dictBox.put(dict.id, dict);

      await _loadDictionaries();

      // 导入成功后，通知练习模块刷新当前单词
      ref.read(practiceProvider.notifier).skipToNext();
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }
}

Future<int> _importFromPipeSeparatedText({
  required String content,
  required String dictionaryId,
  required Box<Word> wordBox,
  required Uuid uuid,
}) async {
  final lines = const LineSplitter().convert(content);
  if (lines.isEmpty) {
    throw Exception('文件内容为空');
  }

  int count = 0;
  for (final rawLine in lines) {
    final line = rawLine.trim();
    if (line.isEmpty) continue;
    final parts = line.split('|');
    if (parts.length < 2) continue;

    final term = parts[0].trim();
    if (term.isEmpty) continue;

    String? phonetic;
    List<String> definitions;

    if (parts.length >= 3) {
      phonetic = parts[1].trim().isEmpty ? null : parts[1].trim();
      definitions = parts.sublist(2).map((e) => e.trim()).toList();
    } else {
      phonetic = null;
      definitions = [parts[1].trim()];
    }

    if (definitions.isEmpty) continue;

    final word = Word(
      id: uuid.v4(),
      dictionaryId: dictionaryId,
      term: term,
      phonetic: phonetic,
      definitions: definitions,
    );
    await wordBox.put(word.id, word);
    count++;
  }

  return count;
}

Future<int> _importFromJson({
  required String content,
  required String dictionaryId,
  required Box<Word> wordBox,
  required Uuid uuid,
}) async {
  dynamic decoded;
  try {
    decoded = jsonDecode(content);
  } catch (_) {
    // 尝试按 JSON Lines（一行一个 JSON）解析
    final lines = const LineSplitter().convert(content);
    decoded = lines
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .map((e) {
          try {
            return jsonDecode(e);
          } catch (_) {
            return null;
          }
        })
        .where((e) => e != null)
        .toList();
  }

  final List<dynamic> items;
  if (decoded is List) {
    items = decoded;
  } else if (decoded is Map<String, dynamic>) {
    items = [decoded];
  } else {
    throw Exception('不支持的 JSON 结构');
  }

  int count = 0;

  for (final item in items) {
    if (item is! Map<String, dynamic>) continue;

    final headWord = (item['headWord'] as String?)?.trim();
    final nestedWord =
        item['content']?['word'] as Map<String, dynamic>?;
    final wordHead =
        (nestedWord?['wordHead'] as String?)?.trim();
    final term = headWord?.isNotEmpty == true
        ? headWord!
        : (wordHead ?? '');
    if (term.isEmpty) continue;

    final wordContent =
        nestedWord?['content'] as Map<String, dynamic>?;

    String? phonetic;
    if (wordContent != null) {
      phonetic = (wordContent['ukphone'] ??
              wordContent['usphone'] ??
              wordContent['phone']) as String?;
      if (phonetic != null && phonetic.trim().isEmpty) {
        phonetic = null;
      }
    }

    final List<String> definitions = [];
    final List<String> examples = [];
    final List<String> synonyms = [];
    final List<String> phrases = [];
    final List<String> related = [];

    // 翻译行，带词性标签，例如：[n].法律… [vi].起诉… [vt].控告…
    final trans = wordContent?['trans'];
    if (trans is List) {
      final parts = <String>[];
      for (final t in trans) {
        if (t is Map<String, dynamic>) {
          final cn = t['tranCn'];
          final pos = t['pos'];
          if (cn is String && cn.trim().isNotEmpty) {
            final posStr =
                pos is String && pos.trim().isNotEmpty ? pos.trim() : '';
            final part = posStr.isNotEmpty
                ? '[$posStr].${cn.trim()}'
                : cn.trim();
            parts.add(part);
          }
        }
      }
      if (parts.isNotEmpty) {
        definitions.add(parts.join('  '));
      }
    }

    // 例句：中英文成对展示
    final sentence = wordContent?['sentence'];
    final sentences = sentence is Map<String, dynamic>
        ? sentence['sentences']
        : null;
    if (sentences is List && sentences.isNotEmpty) {
      for (final s in sentences) {
        if (s is Map<String, dynamic>) {
          final en = s['sContent'];
          final cn = s['sCn'];
          if (en is String && en.trim().isNotEmpty) {
            final buffer = StringBuffer()..writeln(en.trim());
            if (cn is String && cn.trim().isNotEmpty) {
              buffer.writeln(cn.trim());
            }
            examples.add(buffer.toString().trimRight());
          }
        }
      }
    }

    // 同近：包含 pos + tran
    final syno = wordContent?['syno'];
    if (syno is Map<String, dynamic>) {
      final synos = syno['synos'];
      if (synos is List) {
        for (final s in synos) {
          if (s is Map<String, dynamic>) {
            final pos = s['pos'];
            final tran = s['tran'];
            if (tran is String && tran.trim().isNotEmpty) {
              final posStr =
                  pos is String && pos.trim().isNotEmpty ? pos.trim() : '';
              final line = posStr.isNotEmpty
                  ? '$posStr. ${tran.trim()}'
                  : tran.trim();
              synonyms.add(line);
            }
          }
        }
      }
    }

    // 短语列表
    final phrase = wordContent?['phrase'];
    final phraseList = phrase is Map<String, dynamic>
        ? phrase['phrases']
        : null;
    if (phraseList is List && phraseList.isNotEmpty) {
      for (final p in phraseList) {
        if (p is Map<String, dynamic>) {
          final pContent = p['pContent'];
          final pCn = p['pCn'];
          if (pContent is String && pContent.trim().isNotEmpty) {
            final line = pCn is String && pCn.trim().isNotEmpty
                ? '${pContent.trim()} - ${pCn.trim()}'
                : pContent.trim();
            phrases.add(line);
          }
        }
      }
    }

    // 同根词：包含 hwd + pos + tran
    final relWord = wordContent?['relWord'];
    final rels = relWord is Map<String, dynamic>
        ? relWord['rels']
        : null;
    if (rels is List) {
      for (final r in rels) {
        if (r is Map<String, dynamic>) {
          final pos = r['pos'] as String?;
          final words = r['words'];
          if (words is List) {
            for (final w in words) {
              if (w is Map<String, dynamic>) {
                final hwd = w['hwd'];
                final tran = w['tran'];
                if (hwd is String && hwd.trim().isNotEmpty) {
                  final posPart =
                      pos != null && pos.trim().isNotEmpty
                          ? ' (${pos.trim()})'
                          : '';
                  final tranPart = tran is String &&
                          tran.trim().isNotEmpty
                      ? ' - ${tran.trim()}'
                      : '';
                  related.add('${hwd.trim()}$posPart$tranPart');
                }
              }
            }
          }
        }
      }
    }

    final word = Word(
      id: uuid.v4(),
      dictionaryId: dictionaryId,
      term: term,
      phonetic: phonetic,
      definitions: definitions,
      examples: examples,
      synonymDetails: synonyms,
      phraseDetails: phrases,
      relatedDetails: related,
    );
    await wordBox.put(word.id, word);
    count++;
  }

  return count;
}

final dictionaryProvider =
    StateNotifierProvider<DictionaryNotifier, DictionaryState>((ref) {
  return DictionaryNotifier(ref);
});

