/// Types of mini-missions available in Arcade Mode.
enum HarvestOrderType {
  frontRowRush,
  cleanHands,
  firefighter,
  goldenHunter,
  comboMaster,
}

/// Dynamic short-term mini harvest order/mission giving players continuous goals.
class HarvestOrder {
  final HarvestOrderType type;
  final String title;
  final int target;
  final int rewardPoints;
  final double rewardHealth;
  int progress;

  HarvestOrder({
    required this.type,
    required this.title,
    required this.target,
    required this.rewardPoints,
    this.rewardHealth = 0.0,
    this.progress = 0,
  });

  bool get isCompleted => progress >= target;
  double get progressRatio => (progress / target).clamp(0.0, 1.0);

  /// Generates a random new order based on current game state.
  static HarvestOrder generateRandom(int index) {
    final types = HarvestOrderType.values;
    final type = types[index % types.length];
    return switch (type) {
      HarvestOrderType.frontRowRush => HarvestOrder(
          type: type,
          title: 'Stack 4 in Front Row',
          target: 4,
          rewardPoints: 400,
        ),
      HarvestOrderType.cleanHands => HarvestOrder(
          type: type,
          title: 'Catch 6 Clean Bales',
          target: 6,
          rewardPoints: 450,
          rewardHealth: 15.0,
        ),
      HarvestOrderType.firefighter => HarvestOrder(
          type: type,
          title: 'Toss 1 Burning Bale',
          target: 1,
          rewardPoints: 500,
        ),
      HarvestOrderType.goldenHunter => HarvestOrder(
          type: type,
          title: 'Catch 1 Golden Bale',
          target: 1,
          rewardPoints: 500,
          rewardHealth: 20.0,
        ),
      HarvestOrderType.comboMaster => HarvestOrder(
          type: type,
          title: 'Reach 5x Combo',
          target: 5,
          rewardPoints: 600,
        ),
    };
  }
}
