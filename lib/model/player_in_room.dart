class PlayerInRoom {
  PlayerInRoom({
    required this.name,
    required this.avatarIndex,
  });

  final String name;
  final int avatarIndex;

  factory PlayerInRoom.fromRTDB(Object snapshot) {
    final data = snapshot as Map<String, dynamic>;
    return PlayerInRoom(
      name: data['name'],
      avatarIndex: data['avatarIndex'],
    );
  }
}
