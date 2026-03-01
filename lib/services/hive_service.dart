import 'package:hive_flutter/hive_flutter.dart';

import '../models/dictionary.dart';
import '../models/study_log.dart';
import '../models/word.dart';

class HiveService {
  static const dictionaryBoxName = 'dictionaries';
  static const wordBoxName = 'words';
  static const studyLogBoxName = 'study_logs';
  static const settingsBoxName = 'settings';

  static Future<void> init() async {
    await Hive.initFlutter();

    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(WordAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(DictionaryAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(StudyLogAdapter());
    }

    await Future.wait([
      Hive.openBox<Dictionary>(dictionaryBoxName),
      Hive.openBox<Word>(wordBoxName),
      Hive.openBox<StudyLog>(studyLogBoxName),
      Hive.openBox(settingsBoxName),
    ]);
  }
}

