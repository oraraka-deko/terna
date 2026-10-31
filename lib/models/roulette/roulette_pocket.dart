enum PocketColor { red, black, green }

class RoulettePocket {
  final String label;
  final PocketColor color;

  const RoulettePocket(this.label, this.color);

  bool get isZero => label == '0' || label == '00';
  int? get numberValue => isZero ? null : int.tryParse(label);

  bool get isEven => numberValue != null && numberValue! % 2 == 0;
  bool get isOdd => numberValue != null && numberValue! % 2 != 0;
  bool get isHigh => numberValue != null && numberValue! >= 19 && numberValue! <= 36;
  bool get isLow => numberValue != null && numberValue! >= 1 && numberValue! <= 18;
}

// Exact American Roulette sequence counter-clockwise as shown on the wheel
const List<RoulettePocket> americanWheelPockets = [
  RoulettePocket('0', PocketColor.green),
  RoulettePocket('28', PocketColor.black),
  RoulettePocket('9', PocketColor.red),
  RoulettePocket('26', PocketColor.black),
  RoulettePocket('30', PocketColor.red),
  RoulettePocket('11', PocketColor.black),
  RoulettePocket('7', PocketColor.red),
  RoulettePocket('20', PocketColor.black),
  RoulettePocket('32', PocketColor.red),
  RoulettePocket('17', PocketColor.black),
  RoulettePocket('5', PocketColor.red),
  RoulettePocket('22', PocketColor.black),
  RoulettePocket('34', PocketColor.red),
  RoulettePocket('15', PocketColor.black),
  RoulettePocket('3', PocketColor.red),
  RoulettePocket('24', PocketColor.black),
  RoulettePocket('36', PocketColor.red),
  RoulettePocket('13', PocketColor.black),
  RoulettePocket('1', PocketColor.red),
  RoulettePocket('00', PocketColor.green),
  RoulettePocket('27', PocketColor.red),
  RoulettePocket('10', PocketColor.black),
  RoulettePocket('25', PocketColor.red),
  RoulettePocket('29', PocketColor.black),
  RoulettePocket('12', PocketColor.red),
  RoulettePocket('8', PocketColor.black),
  RoulettePocket('19', PocketColor.red),
  RoulettePocket('31', PocketColor.black),
  RoulettePocket('18', PocketColor.red),
  RoulettePocket('6', PocketColor.black),
  RoulettePocket('21', PocketColor.red),
  RoulettePocket('33', PocketColor.black),
  RoulettePocket('16', PocketColor.red),
  RoulettePocket('4', PocketColor.black),
  RoulettePocket('23', PocketColor.red),
  RoulettePocket('35', PocketColor.black),
  RoulettePocket('14', PocketColor.red),
  RoulettePocket('2', PocketColor.black),
];
