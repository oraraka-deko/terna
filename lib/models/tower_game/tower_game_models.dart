/// Difficulties available in Tower Climb
enum TowerDifficulty {
  easy,
  medium,
  master,
}

extension TowerDifficultyExtension on TowerDifficulty {
  String get label {
    switch (this) {
      case TowerDifficulty.easy:
        return 'Easy';
      case TowerDifficulty.medium:
        return 'Medium';
      case TowerDifficulty.master:
        return 'Master';
    }
  }

  String get dots {
    switch (this) {
      case TowerDifficulty.easy:
        return '•';
      case TowerDifficulty.medium:
        return '••';
      case TowerDifficulty.master:
        return '•••';
    }
  }

  int get trapCount {
    switch (this) {
      case TowerDifficulty.easy:
        return 1;
      case TowerDifficulty.medium:
        return 2;
      case TowerDifficulty.master:
        return 3;
    }
  }

  List<double> get multipliers {
    switch (this) {
      case TowerDifficulty.easy:
        return const [1.18, 1.48, 1.85, 2.31, 2.89, 3.61, 4.51];
      case TowerDifficulty.medium:
        return const [1.58, 2.64, 4.40, 7.33, 12.20, 20.40, 33.90];
      case TowerDifficulty.master:
        return const [2.38, 5.95, 14.88, 37.20, 93.00, 232.50, 581.25];
    }
  }
}

enum TowerCurrency {
  ton,
  stars,
}

enum TowerTileStatus {
  hidden,
  safe,
  trap,
}

class TowerTileState {
  final TowerTileStatus status;
  final bool isPicked;

  const TowerTileState({
    this.status = TowerTileStatus.hidden,
    this.isPicked = false,
  });

  TowerTileState copyWith({
    TowerTileStatus? status,
    bool? isPicked,
  }) {
    return TowerTileState(
      status: status ?? this.status,
      isPicked: isPicked ?? this.isPicked,
    );
  }
}

class TowerOutcome {
  final bool won;
  final double amount;
  final TowerCurrency currency;
  final bool isGrandWin;

  const TowerOutcome({
    required this.won,
    required this.amount,
    required this.currency,
    this.isGrandWin = false,
  });
}

