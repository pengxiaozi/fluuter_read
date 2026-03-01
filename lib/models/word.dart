import 'package:hive/hive.dart';

/// Hive TypeAdapter ID: 0
@HiveType(typeId: 0)
class Word extends HiveObject {
  @HiveField(0)
  String id; // UUID v4

  @HiveField(1)
  String dictionaryId; // 外键，关联 Dictionary

  @HiveField(2)
  String term; // 单词本身

  @HiveField(3)
  String? phonetic; // 音标

  @HiveField(4)
  List<String> definitions; // 释义列表

  @HiveField(5)
  int masteryLevel; // 掌握程度 0-100, 预留给未来算法

  /// 例句列表，每条形如 "英文\n中文"
  @HiveField(6)
  List<String> examples;

  /// 同近信息，例如 "n. [法] 法律；规律…"
  @HiveField(7)
  List<String> synonymDetails;

  /// 短语信息，例如 "by law - 根据法律，在法律上；附则"
  @HiveField(8)
  List<String> phraseDetails;

  /// 同根词信息，例如 "lawful (adj)"
  @HiveField(9)
  List<String> relatedDetails;

  @HiveField(10)
  int reviewCount; // 已复习次数（用于艾宾浩斯曲线）

  @HiveField(11)
  DateTime? nextReviewTime; // 下次复习时间

  @HiveField(12)
  DateTime? learnedTime; // 首次学习时间

  Word({
    required this.id,
    required this.dictionaryId,
    required this.term,
    this.phonetic,
    required this.definitions,
    this.masteryLevel = 0,
    this.examples = const [],
    this.synonymDetails = const [],
    this.phraseDetails = const [],
    this.relatedDetails = const [],
    this.reviewCount = 0,
    this.nextReviewTime,
    this.learnedTime,
  });
}

/// 手写的 Hive TypeAdapter，避免依赖代码生成文件。
class WordAdapter extends TypeAdapter<Word> {
  @override
  final int typeId = 0;

  @override
  Word read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Word(
      id: fields[0] as String,
      dictionaryId: fields[1] as String,
      term: fields[2] as String,
      phonetic: fields[3] as String?,
      definitions: (fields[4] as List?)?.cast<String>() ?? const [],
      masteryLevel: (fields[5] as int?) ?? 0,
      examples: (fields[6] as List?)?.cast<String>() ?? const [],
      synonymDetails: (fields[7] as List?)?.cast<String>() ?? const [],
      phraseDetails: (fields[8] as List?)?.cast<String>() ?? const [],
      relatedDetails: (fields[9] as List?)?.cast<String>() ?? const [],
      reviewCount: (fields[10] as int?) ?? 0,
      nextReviewTime: fields[11] as DateTime?,
      learnedTime: fields[12] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, Word obj) {
    writer
      ..writeByte(13)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.dictionaryId)
      ..writeByte(2)
      ..write(obj.term)
      ..writeByte(3)
      ..write(obj.phonetic)
      ..writeByte(4)
      ..write(obj.definitions)
      ..writeByte(5)
      ..write(obj.masteryLevel)
      ..writeByte(6)
      ..write(obj.examples)
      ..writeByte(7)
      ..write(obj.synonymDetails)
      ..writeByte(8)
      ..write(obj.phraseDetails)
      ..writeByte(9)
      ..write(obj.relatedDetails)
      ..writeByte(10)
      ..write(obj.reviewCount)
      ..writeByte(11)
      ..write(obj.nextReviewTime)
      ..writeByte(12)
      ..write(obj.learnedTime);
  }
}
