import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/settings_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '学习计划',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          '每日学习数量',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                      Text(
                        '${settings.dailyLimit}',
                        style: Theme.of(context)
                            .textTheme
                            .bodyLarge
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  Slider(
                    value: settings.dailyLimit.toDouble(),
                    min: 10,
                    max: 200,
                    divisions: 19,
                    label: '${settings.dailyLimit}',
                    onChanged: (value) {
                      notifier.updateDailyLimit(value.round());
                    },
                  ),
                  const Text(
                    '基于艾宾浩斯记忆曲线，每日学习新单词数量',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '练习设置',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          '每个单词需要连续正确次数',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                      Text(
                        '${settings.requiredCorrectTimes}',
                        style: Theme.of(context)
                            .textTheme
                            .bodyLarge
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  Slider(
                    value: settings.requiredCorrectTimes.toDouble(),
                    min: 1,
                    max: 10,
                    divisions: 9,
                    label: '${settings.requiredCorrectTimes}',
                    onChanged: (value) {
                      notifier.updateRequiredCorrectTimes(value.round());
                    },
                  ),
                  const Text(
                    '连续正确判定为掌握后，进入艾宾浩斯复习周期',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('显示音标'),
                  subtitle: const Text('在练习时显示英式/美式发音符号'),
                  value: settings.showPhonetic,
                  onChanged: notifier.updateShowPhonetic,
                ),
                const Divider(height: 1),
                SwitchListTile(
                  title: const Text('显示中文释义'),
                  subtitle: const Text('在英文单词下方显示翻译和解释'),
                  value: settings.showDefinition,
                  onChanged: notifier.updateShowDefinition,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '艾宾浩斯记忆曲线',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    '根据艾宾浩斯遗忘曲线，在以下时间点复习效果最佳：',
                    style: TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '• 20 分钟后\n• 1 小时后\n• 9 小时后\n• 1 天后\n• 2 天后\n• 6 天后\n• 31 天后',
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

