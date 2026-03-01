import 'package:hive/hive.dart';

/// Hive TypeAdapter ID: 2
@HiveType(typeId: 2)
class StudyLog extends HiveObject {
  @HiveField(0)
  String id; // UUID v4

  @HiveField(1)
  String wordId; // 外键，关联Word

  @HiveField(2)
  DateTime timestamp; // 操作时间

  @HiveField(3)
  bool isCorrect; // 本次是否正确

  @HiveField(4)
  int attempts; // 本次尝试次数

  StudyLog({
    required this.id,
    required this.wordId,
    required this.timestamp,
    required this.isCorrect,
    required this.attempts,
  });
}

/// 手写的 Hive TypeAdapter，避免依赖代码生成文件。
class StudyLogAdapter extends TypeAdapter<StudyLog> {
  @override
  final int typeId = 2;

  @override
  StudyLog read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return StudyLog(
      id: fields[0] as String,
      wordId: fields[1] as String,
      timestamp: fields[2] as DateTime,
      isCorrect: fields[3] as bool,
      attempts: fields[4] as int,
    );
  }

  @override
  void write(BinaryWriter writer, StudyLog obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.wordId)
      ..writeByte(2)
      ..write(obj.timestamp)
      ..writeByte(3)
      ..write(obj.isCorrect)
      ..writeByte(4)
      ..write(obj.attempts);
  }
}

