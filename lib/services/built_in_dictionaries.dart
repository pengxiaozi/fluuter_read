import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

import '../models/dictionary.dart';
import '../models/word.dart';
import '../services/hive_service.dart';

/// 内置词典数据
class BuiltInDictionaries {
  static const _uuid = Uuid();

  /// 考研词典
  static const String kaoyan = 'KaoYan_2';

  /// 获取内置词典列表
  static List<Map<String, String>> getBuiltInList() {
    return [
      {
        'id': kaoyan,
        'name': '考研词汇',
        'description': '全国硕士研究生招生考试英语考试大纲词汇',
      },
    ];
  }

  /// 导入内置词典
  static Future<int> importBuiltIn(String dictionaryId) async {
    final dictBox = Hive.box<Dictionary>(HiveService.dictionaryBoxName);
    final wordBox = Hive.box<Word>(HiveService.wordBoxName);

    // 检查是否已导入，如果已导入先删除旧的
    if (dictBox.containsKey(dictionaryId)) {
      // 删除旧词典的所有单词
      final oldWords = wordBox.values.where((w) => w.dictionaryId == dictionaryId).toList();
      for (final word in oldWords) {
        await wordBox.delete(word.id);
      }
      // 删除旧词典记录
      await dictBox.delete(dictionaryId);
    }

    // 加载 JSON 文件
    final jsonString = await rootBundle.loadString('KaoYan_2.json');
    final lines = LineSplitter.split(jsonString);

    final words = <Word>[];
    int count = 0;

    for (final line in lines) {
      if (line.trim().isEmpty) continue;

      try {
        final data = jsonDecode(line) as Map<String, dynamic>;
        final wordData = _parseWord(data, dictionaryId);
        if (wordData != null) {
          words.add(wordData);
          count++;

          // 每 100 个词保存一次，避免内存溢出
          if (count % 100 == 0) {
            for (final word in words) {
              await wordBox.put(word.id, word);
            }
            words.clear();
          }
        }
      } catch (e) {
        // 跳过解析失败的行
        continue;
      }
    }

    // 保存剩余单词
    for (final word in words) {
      await wordBox.put(word.id, word);
    }

    // 创建词典记录
    final dictionary = Dictionary(
      id: dictionaryId,
      name: '考研词汇',
      description: '全国硕士研究生招生考试英语考试大纲词汇',
      wordCount: wordBox.values.where((w) => w.dictionaryId == dictionaryId).length,
      lastUpdated: DateTime.now(),
      enabled: true, // 默认启用
    );

    await dictBox.put(dictionaryId, dictionary);

    return count;
  }

  /// 解析 JSON 数据为 Word 对象
  static Word? _parseWord(Map<String, dynamic> data, String dictionaryId) {
    try {
      // headWord 在最外层
      final headWord = data['headWord'] as String?;
      
      final content = data['content'] as Map<String, dynamic>?;
      final wordData = content?['word'] as Map<String, dynamic>?;
      final wordContent = wordData?['content'] as Map<String, dynamic>?;

      if (wordContent == null && headWord == null) return null;

      final wordId = wordContent?['wordId'] as String? ?? _uuid.v4();
      // 优先使用 headWord，如果没有则从嵌套结构获取
      final wordHead = headWord?.isNotEmpty == true 
          ? headWord! 
          : (wordContent?['wordHead'] as String? ?? '');

      if (wordHead.isEmpty) return null;

      // 提取音标
      String? phonetic;
      if (wordContent != null) {
        if (wordContent['usphone'] != null) {
          phonetic = '/${wordContent['usphone']}/';
        } else if (wordContent['ukphone'] != null) {
          phonetic = '/${wordContent['ukphone']}/';
        } else if (wordContent['phone'] != null) {
          phonetic = '/${wordContent['phone']}/';
        }
      }

      // 提取释义
      final trans = wordContent?['trans'] as List<dynamic>? ?? [];
      final definitions = <String>[];
      for (final t in trans) {
        if (t is Map<String, dynamic>) {
          final tranCn = t['tranCn'] as String?;
          final pos = t['pos'] as String?;
          if (tranCn != null && tranCn.isNotEmpty) {
            // 如果有 pos 字段，将其添加到释义前面
            final definition = pos != null && pos.isNotEmpty ? '$pos. $tranCn' : tranCn;
            definitions.add(definition);
          }
        }
      }

      // 提取例句
      final examples = <String>[];
      final sentenceData = wordContent?['sentence'] as Map<String, dynamic>?;
      final sentences = sentenceData?['sentences'] as List<dynamic>? ?? [];
      for (final s in sentences) {
        if (s is Map<String, dynamic>) {
          final sContent = s['sContent'] as String?;
          final sCn = s['sCn'] as String?;
          if (sContent != null) {
            final example = sCn != null ? '$sContent\n$sCn' : sContent;
            examples.add(example);
          }
        }
      }

      // 提取短语
      final phraseDetails = <String>[];
      final phraseData = wordContent?['phrase'] as Map<String, dynamic>?;
      final phrases = phraseData?['phrases'] as List<dynamic>? ?? [];
      for (final p in phrases) {
        if (p is Map<String, dynamic>) {
          final pContent = p['pContent'] as String?;
          final pCn = p['pCn'] as String?;
          if (pContent != null) {
            final phrase = pCn != null ? '$pContent - $pCn' : pContent;
            phraseDetails.add(phrase);
          }
        }
      }

      // 提取同根词
      final relatedDetails = <String>[];
      final relWordData = wordContent?['relWord'] as Map<String, dynamic>?;
      final rels = relWordData?['rels'] as List<dynamic>? ?? [];
      for (final r in rels) {
        if (r is Map<String, dynamic>) {
          final words = r['words'] as List<dynamic>? ?? [];
          for (final w in words) {
            if (w is Map<String, dynamic>) {
              final hwd = w['hwd'] as String?;
              final tran = w['tran'] as String?;
              if (hwd != null) {
                // 不显示 pos，只显示单词和释义
                final related = '$hwd${tran != null ? " $tran" : ""}';
                relatedDetails.add(related);
              }
            }
          }
        }
      }

      // 提取同近义词
      final synonymDetails = <String>[];
      final synoData = wordContent?['syno'] as Map<String, dynamic>?;
      final synos = synoData?['synos'] as List<dynamic>? ?? [];
      for (final syn in synos) {
        if (syn is Map<String, dynamic>) {
          final tran = syn['tran'] as String?;
          final hwds = syn['hwds'] as List<dynamic>? ?? [];
          if (tran != null) {
            final synonymWords = hwds.whereType<Map<String, dynamic>>().map((h) => h['w'] as String).join(', ');
            // 不显示 pos，只显示释义和单词
            synonymDetails.add('$tran: $synonymWords');
          }
        }
      }

      return Word(
        id: wordId,
        dictionaryId: dictionaryId,
        term: wordHead,
        phonetic: phonetic,
        definitions: definitions,
        examples: examples,
        phraseDetails: phraseDetails,
        relatedDetails: relatedDetails,
        synonymDetails: synonymDetails,
      );
    } catch (e) {
      return null;
    }
  }
}
