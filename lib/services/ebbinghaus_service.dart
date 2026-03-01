/// 艾宾浩斯记忆曲线复习间隔（单位：分钟）
/// 20 分钟、1 小时、9 小时、1 天、2 天、6 天、31 天
class EbbinghausCurve {
  static const List<int> reviewIntervals = [
    20, // 第一次复习：20 分钟后
    60, // 第二次复习：1 小时后
    540, // 第三次复习：9 小时后
    1440, // 第四次复习：1 天后
    2880, // 第五次复习：2 天后
    8640, // 第六次复习：6 天后
    44640, // 第七次复习：31 天后
  ];

  /// 根据当前复习次数，计算下次复习时间
  static DateTime getNextReviewTime({
    required int reviewCount,
    DateTime? baseTime,
  }) {
    final base = baseTime ?? DateTime.now();
    
    if (reviewCount >= reviewIntervals.length) {
      // 已完成所有复习周期，3 个月后复习
      return base.add(const Duration(days: 90));
    }
    
    final intervalMinutes = reviewIntervals[reviewCount];
    return base.add(Duration(minutes: intervalMinutes));
  }

  /// 获取复习阶段描述
  static String getReviewStageDescription(int reviewCount) {
    if (reviewCount >= reviewIntervals.length) {
      return '已掌握';
    }
    final stages = [
      '20 分钟后复习',
      '1 小时后复习',
      '9 小时后复习',
      '1 天后复习',
      '2 天后复习',
      '6 天后复习',
      '31 天后复习',
    ];
    return stages[reviewCount];
  }

  /// 计算剩余时间（人类可读格式）
  static String formatTimeRemaining(DateTime targetTime) {
    final now = DateTime.now();
    final diff = targetTime.difference(now);
    
    if (diff.isNegative) {
      return '已到期';
    }
    
    if (diff.inMinutes < 1) {
      return '${diff.inSeconds}秒后';
    }
    
    if (diff.inHours < 1) {
      return '${diff.inMinutes}分钟后';
    }
    
    if (diff.inDays < 1) {
      return '${diff.inHours}小时后';
    }
    
    return '${diff.inDays}天后';
  }
}
