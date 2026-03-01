import 'package:hive/hive.dart';

/// Hive TypeAdapter ID: 1
@HiveType(typeId: 1)
class Dictionary extends HiveObject {
  @HiveField(0)
  String id; // UUID v4

  @HiveField(1)
  String name; // 词典名称

  @HiveField(2)
  String? description; // 描述

  @HiveField(3)
  String? sourceUrl; // 在线下载地址（预留）

  @HiveField(4)
  DateTime lastUpdated; // 最后更新时间

  @HiveField(5)
  int wordCount; // 词条总数

  @HiveField(6)
  bool enabled; // 是否启用（用于练习）

  Dictionary({
    required this.id,
    required this.name,
    this.description,
    this.sourceUrl,
    required this.lastUpdated,
    required this.wordCount,
    this.enabled = true,
  });
}

/// 手写的 Hive TypeAdapter，避免依赖代码生成文件。
class DictionaryAdapter extends TypeAdapter<Dictionary> {
  @override
  final int typeId = 1;

  @override
  Dictionary read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Dictionary(
      id: fields[0] as String,
      name: fields[1] as String,
      description: fields[2] as String?,
      sourceUrl: fields[3] as String?,
      lastUpdated: fields[4] as DateTime,
      wordCount: fields[5] as int,
      enabled: (fields[6] as bool?) ?? true,
    );
  }

  @override
  void write(BinaryWriter writer, Dictionary obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.sourceUrl)
      ..writeByte(4)
      ..write(obj.lastUpdated)
      ..writeByte(5)
      ..write(obj.wordCount)
      ..writeByte(6)
      ..write(obj.enabled);
  }
}

