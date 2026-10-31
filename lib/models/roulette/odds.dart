enum BetType {
  straight,    // Single number (0, 00, 1-36) -> 35:1
  split,       // 2 adjacent numbers -> 17:1
  street,      // 3 consecutive row numbers -> 11:1
  corner,      // 4 adjacent numbers -> 8:1
  fiveNumber,  // 0, 00, 1, 2, 3 -> 6:1
  sixLine,     // 6 numbers (two rows) -> 5:1
  column,      // 1st, 2nd, 3rd column (12 numbers) -> 2:1
  dozen,       // 1st 12, 2nd 12, 3rd 12 -> 2:1
  evenOdd,     // Even / Odd -> 1:1
  color,       // Red / Black -> 1:1
  highLow,     // 1-18 / 19-36 -> 1:1
}

extension BetTypeDetails on BetType {
  String get title {
    switch (this) {
      case BetType.straight: return 'Straight Up';
      case BetType.split: return 'Split Bet';
      case BetType.street: return 'Street Bet';
      case BetType.corner: return 'Corner Bet';
      case BetType.fiveNumber: return 'Five Number (Top Line)';
      case BetType.sixLine: return 'Six Line';
      case BetType.column: return 'Column Bet';
      case BetType.dozen: return 'Dozen Bet';
      case BetType.evenOdd: return 'Even / Odd';
      case BetType.color: return 'Red / Black';
      case BetType.highLow: return '1-18 / 19-36';
    }
  }

  String get payoutText {
    switch (this) {
      case BetType.straight: return '35:1';
      case BetType.split: return '17:1';
      case BetType.street: return '11:1';
      case BetType.corner: return '8:1';
      case BetType.fiveNumber: return '6:1';
      case BetType.sixLine: return '5:1';
      case BetType.column: return '2:1';
      case BetType.dozen: return '2:1';
      case BetType.evenOdd: return '1:1';
      case BetType.color: return '1:1';
      case BetType.highLow: return '1:1';
    }
  }

  String get description {
    switch (this) {
      case BetType.straight: return 'Bet on a single exact pocket (0, 00, 1-36).';
      case BetType.split: return 'Bet on 2 adjacent numbers.';
      case BetType.street: return 'Bet on a row of 3 consecutive numbers.';
      case BetType.corner: return 'Bet on a square of 4 adjacent numbers.';
      case BetType.fiveNumber: return 'Bet covering 0, 00, 1, 2, and 3.';
      case BetType.sixLine: return 'Bet covering two adjacent rows of 3 numbers.';
      case BetType.column: return 'Bet on one of three vertical 12-number columns.';
      case BetType.dozen: return 'Bet on 1st 12 (1-12), 2nd 12 (13-24), or 3rd 12 (25-36).';
      case BetType.evenOdd: return 'Bet on any Even or Odd number (excluding 0 & 00).';
      case BetType.color: return 'Bet on Red or Black pocket.';
      case BetType.highLow: return 'Bet on Low (1-18) or High (19-36) numbers.';
    }
  }
}

class Bet {
  final String id;
  final BetType type;
  final Set<String> targetPockets;
  final int amount;

  const Bet({
    required this.id,
    required this.type,
    required this.targetPockets,
    required this.amount,
  });

  int get payoutMultiplier {
    switch (type) {
      case BetType.straight: return 35;
      case BetType.split: return 17;
      case BetType.street: return 11;
      case BetType.corner: return 8;
      case BetType.fiveNumber: return 6;
      case BetType.sixLine: return 5;
      case BetType.column:
      case BetType.dozen: return 2;
      case BetType.evenOdd:
      case BetType.color:
      case BetType.highLow: return 1;
    }
  }
}