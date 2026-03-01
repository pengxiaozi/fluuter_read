import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../services/hive_service.dart';

class AppSettings {
  final int dailyLimit; // 每日学习数量
  final int requiredCorrectTimes;
  final bool showPhonetic;
  final bool showDefinition;

  const AppSettings({
    this.dailyLimit = 20,
    this.requiredCorrectTimes = 3,
    this.showPhonetic = true,
    this.showDefinition = true,
  });

  AppSettings copyWith({
    int? dailyLimit,
    int? requiredCorrectTimes,
    bool? showPhonetic,
    bool? showDefinition,
  }) {
    return AppSettings(
      dailyLimit: dailyLimit ?? this.dailyLimit,
      requiredCorrectTimes: requiredCorrectTimes ?? this.requiredCorrectTimes,
      showPhonetic: showPhonetic ?? this.showPhonetic,
      showDefinition: showDefinition ?? this.showDefinition,
    );
  }
}

class SettingsNotifier extends StateNotifier<AppSettings> {
  SettingsNotifier() : super(const AppSettings()) {
    _load();
  }

  Future<void> _load() async {
    final box = Hive.box(HiveService.settingsBoxName);
    final dailyLimit = box.get('dailyLimit', defaultValue: 20) as int;
    final required = box.get('requiredCorrectTimes', defaultValue: 3) as int;
    final phonetic = box.get('showPhonetic', defaultValue: true) as bool;
    final definition = box.get('showDefinition', defaultValue: true) as bool;
    state = AppSettings(
      dailyLimit: dailyLimit,
      requiredCorrectTimes: required,
      showPhonetic: phonetic,
      showDefinition: definition,
    );
  }

  Future<void> updateDailyLimit(int value) async {
    final box = Hive.box(HiveService.settingsBoxName);
    await box.put('dailyLimit', value);
    state = state.copyWith(dailyLimit: value);
  }

  Future<void> updateRequiredCorrectTimes(int value) async {
    final box = Hive.box(HiveService.settingsBoxName);
    await box.put('requiredCorrectTimes', value);
    state = state.copyWith(requiredCorrectTimes: value);
  }

  Future<void> updateShowPhonetic(bool value) async {
    final box = Hive.box(HiveService.settingsBoxName);
    await box.put('showPhonetic', value);
    state = state.copyWith(showPhonetic: value);
  }

  Future<void> updateShowDefinition(bool value) async {
    final box = Hive.box(HiveService.settingsBoxName);
    await box.put('showDefinition', value);
    state = state.copyWith(showDefinition: value);
  }
}

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, AppSettings>((ref) {
  return SettingsNotifier();
});

