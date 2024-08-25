class PlayerInNormalMode {
  PlayerInNormalMode({
    required this.id,
    required this.name,
    required this.avatarIndex,
    required this.point,
    required this.isCorrect,
  });

  final String? id;
  final String name;
  final int avatarIndex;
  final int point;
  final bool isCorrect;
}
