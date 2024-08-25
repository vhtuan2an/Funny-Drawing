import 'dart:async';
import 'dart:convert';

import 'package:draw_and_guess_promax/Widget/loading.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../Widget/button.dart';
import '../data/word_to_guess.dart';
import '../firebase.dart';
import '../model/player_masterpiece_mode.dart';
import '../model/room.dart';
import '../provider/user_provider.dart';
import 'home_page.dart';
import 'master_piece_mode.dart';

class MasterPieceModeRank extends ConsumerStatefulWidget {
  const MasterPieceModeRank({
    super.key,
    required this.selectedRoom,
  });

  final Room selectedRoom;

  @override
  ConsumerState<MasterPieceModeRank> createState() =>
      _MasterPieceModeRankState();
}

class _MasterPieceModeRankState extends ConsumerState<MasterPieceModeRank> {
  late final List<PlayerInMasterPieceMode> _playersInRoom = [];
  late List<String> _playersInRoomId = [];
  late DatabaseReference _roomRef;
  late DatabaseReference _playersInRoomRef;
  late DatabaseReference _playerInRoomIDRef;
  late DatabaseReference _masterpieceModeDataRef;
  late final String _userId;

  late int _curPlayer;
  late String roomOwner;
  List<Map<String, dynamic>> picturesAndScores = [];
  var _wordToDraw = 'Gì vậy';

  final pageController = PageController(
    initialPage: 0,
    viewportFraction: 0.8,
  );

  Timer? _timer;
  Timer? _pauseTimer;

  @override
  void initState() {
    super.initState();
    _userId = ref.read(userProvider).id!;
    _roomRef = database.child('/rooms/${widget.selectedRoom.roomId}');
    _playersInRoomRef =
        database.child('/players_in_room/${widget.selectedRoom.roomId}');
    _masterpieceModeDataRef =
        database.child('/masterpiece_mode_data/${widget.selectedRoom.roomId}');
    _playerInRoomIDRef = database.child(
        '/players_in_room/${widget.selectedRoom.roomId}/${ref.read(userProvider).id}');
    roomOwner = widget.selectedRoom.roomOwner!;
    // Lắng nghe sự kiện thoát phòng
    _roomRef.onValue.listen((event) async {
      // Room has been deleted
      if (event.snapshot.value == null) {
        if (roomOwner != ref.read(userProvider).id) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (ctx) => const HomePage()),
            (route) => false,
          );
          await _showDialog('Phòng đã bị xóa', 'Phòng đã bị xóa bởi chủ phòng',
              isKicked: true);
        }
      }

      final data = Map<String, dynamic>.from(
        event.snapshot.value as Map<dynamic, dynamic>,
      );
      _curPlayer = data['curPlayer'] as int;
      roomOwner = data['roomOwner']!;
    });

    _masterpieceModeDataRef.onValue.listen((event) {
      final data = Map<String, dynamic>.from(
        event.snapshot.value as Map<dynamic, dynamic>,
      );

      // khi không còn ai trong phòng
      if (data['noOneInRoom'] == true) {
        _roomRef.remove();
        _playersInRoomRef.remove();
        _masterpieceModeDataRef.remove();

        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (ctx) => const HomePage()),
          (route) => false,
        );
        if (_userId == widget.selectedRoom.roomOwner) {
          _showDialog('Thông báo', 'Phòng đã bị xóa vì không còn người chơi',
              isKicked: true);
        }
      }

      if (data['playAgain'] == true) {
        _playAgain();
      }

      _wordToDraw = data['wordToDraw'] as String;
    });

    _getPlayerInRoom();
    _getPicturesAndScores();
    _startTimer();
  }

  void _playAgain() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (ctx) => const HomePage(),
      ),
      (route) => false,
    );
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => MasterPieceMode(
          selectedRoom: widget.selectedRoom,
        ),
      ),
    );
  }

  Future<void> _getPicturesAndScores() async {
    final masterpieceSnapshot = await _masterpieceModeDataRef.get();
    final masterpieceData = Map<String, dynamic>.from(
      masterpieceSnapshot.value as Map<dynamic, dynamic>,
    );

    // Chờ cho việc upload ảnh hoàn tất
    while (!(masterpieceData['uploadDone'] as bool)) {
      print('Cho doi la khong hanh phuc');
      await Future.delayed(const Duration(milliseconds: 200));
    }

    picturesAndScores.clear();
    for (var player in _playersInRoom) {
      final albumSnapshot =
          await _masterpieceModeDataRef.child('/album/${player.id}').get();
      final albumData = Map<String, String>.from(albumSnapshot.value as Map);

      final scoreSnapshot =
          await _masterpieceModeDataRef.child('/score/${player.id}').get();
      final scoreData = Map<String, int>.from(scoreSnapshot.value as Map);
      // tính tổng điểm
      final totalScore =
          scoreData.values.fold(0, (prev, element) => prev + element);

      picturesAndScores.add({
        'Id': player.id,
        'Name': player.name,
        'AvatarIndex': player.avatarIndex,
        'TotalScore': totalScore,
        'Color': albumData['Color'] as String,
        'Offset': albumData['Offset'] as String,
      });
    }
    setState(() {
      if (picturesAndScores.isNotEmpty) {
        picturesAndScores
            .sort((a, b) => b['TotalScore'].compareTo(a['TotalScore']));

        int rank = 1;
        for (int i = 0; i < picturesAndScores.length; i++) {
          if (i > 0 &&
              picturesAndScores[i]['TotalScore'] !=
                  picturesAndScores[i - 1]['TotalScore']) {
            rank = i + 1;
          }
          picturesAndScores[i]['Rank'] = rank;
        }
      }
    });

    print('================================ picturesAndScores:');
    print(picturesAndScores.length);
    picturesAndScores.forEach((element) {
      print(element['Name']);
      print(element['TotalScore']);
    });
  }

  Future<void> _getPlayerInRoom() async {
    final snapshot = await _playersInRoomRef.get();
    final playersInRoomData = Map<String, dynamic>.from(
      snapshot.value as Map<dynamic, dynamic>,
    );

    setState(() {
      _playersInRoom.clear();
      for (final player in playersInRoomData.entries) {
        _playersInRoom.add(PlayerInMasterPieceMode(
          id: player.key,
          name: player.value['name'],
          avatarIndex: player.value['avatarIndex'],
          point: player.value['point'],
        ));
      }

      _playersInRoomId.clear();
      _playersInRoomId = _playersInRoom.map((player) => player.id!).toList();
      print('Debug:');
      _playersInRoomId.forEach((element) => print('Player in room: $element'));
    });
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      if (pageController.page!.round() == picturesAndScores.length - 1) {
        // Nếu đã đến trang cuối cùng, cuộn về trang đầu tiên
        pageController.animateToPage(
          0,
          duration: Duration(milliseconds: picturesAndScores.length * 400),
          curve: Curves.easeInOutQuad,
        );
      } else {
        // Nếu chưa đến trang cuối cùng, cuộn đến trang tiếp theo
        pageController.nextPage(
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOutQuad,
        );
      }
    });
  }

  // todo: sao nó không dừng
  void _pausingTimer() {
    _timer?.cancel();
    _pauseTimer?.cancel();
    _pauseTimer = Timer(const Duration(seconds: 5), () {
      _startTimer();
    });
  }

  late Completer<bool> _completer;

  Future<bool> _showDialog(String title, String content,
      {bool isKicked = false}) async {
    _completer = Completer<bool>();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(content),
          backgroundColor: const Color(0xFF00C4A0),
          actions: [
            if (!isKicked)
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _completer.complete(false);
                },
                child: const Text(
                  'Hủy',
                  style: TextStyle(
                    color: Color(0xFF000000),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _completer.complete(true);
              },
              child: Text(
                isKicked ? 'OK' : 'Thoát',
                style: TextStyle(
                  color: isKicked ? Colors.black : Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
    return _completer.future;
  }

  Future<void> _playerOutRoom(WidgetRef ref) async {
    final userId = ref.read(userProvider).id;
    if (userId == null) return;

    final currentPlayerCount = _curPlayer;
    if (currentPlayerCount > 0) {
      // Nếu còn 2 người chơi thì xóa phòng
      if (currentPlayerCount <= 2) {
        await _masterpieceModeDataRef.update({
          'noOneInRoom': true,
        });
      } else {
        // Nếu còn nhiều hơn 2 người chơi thì giảm số người chơi
        await _playersInRoomRef.child(userId).remove();
      }
    }

    // Chuyển chủ phòng nếu chủ phòng thoát
    await _playerInRoomIDRef.remove();
    if (roomOwner == userId) {
      print("Chu phong");
      for (var cp in _playersInRoom) {
        if (cp.id != roomOwner) {
          await _roomRef.update({
            'roomOwner': cp.id,
          });
          break;
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final double widthOfPicture = MediaQuery.of(context).size.width * 0.75;
    final double heightOfPicture = MediaQuery.of(context).size.height * 0.5;
    const double scale = 0.6;

    Widget buildMedal(int index) {
      switch (index) {
        case 0:
          return const Padding(
            padding: EdgeInsets.only(right: 5),
            child: Image(
              image: AssetImage('assets/images/gold-medal.png'),
              width: 30,
              height: 30,
            ),
          );
        case 1:
          return const Padding(
            padding: EdgeInsets.only(right: 5),
            child: Image(
              image: AssetImage('assets/images/silver-medal.png'),
              width: 30,
              height: 30,
            ),
          );
        case 2:
          return const Padding(
            padding: EdgeInsets.only(right: 5),
            child: Image(
              image: AssetImage('assets/images/bronze-medal.png'),
              width: 30,
              height: 30,
            ),
          );
        default:
          return const SizedBox();
      }
    }

    if (picturesAndScores.isEmpty) {
      return const Loading();
    }

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) {
          return;
        }
        final isQuit = (ref.read(userProvider).id == roomOwner)
            ? await _showDialog('Cảnh báo',
                'Nếu bạn thoát, phòng sẽ bị xóa và tất cả người chơi khác cũng sẽ bị đuổi ra khỏi phòng. Bạn có chắc chắn muốn thoát không?')
            : await _showDialog(
                'Cảnh báo', 'Bạn có chắc chắn muốn thoát khỏi phòng không?');

        if (context.mounted && isQuit) {
          _playerOutRoom(ref);
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (ctx) => const HomePage()),
            (route) => false,
          );
        }
      },
      child: Stack(
        children: [
          // nền
          Container(
              width: double.infinity,
              height: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment(0.00, -1.00),
                  end: Alignment(0, 1),
                  colors: [Color(0xFF00C4A0), Color(0xFFD05700)],
                ),
              )),
          // Chủ đề
          Positioned(
            top: 100,
            height: 50,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                'Chủ đề: $_wordToDraw',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge!
                    .copyWith(color: Colors.black),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          // Trang chính
          Positioned(
              top: 150,
              left: 0,
              right: 0,
              bottom: 100,
              child: picturesAndScores.isEmpty
                  ? Center(
                      child: Text(
                        'không tải được tranh',
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium!
                            .copyWith(color: Colors.black),
                      ),
                    )
                  : GestureDetector(
                      onTap: () {
                        _pausingTimer();
                      },
                      child: PageView(
                        scrollDirection: Axis.horizontal,
                        controller: pageController,
                        children: [
                          for (final picAndScore in picturesAndScores)
                            Container(
                              width: double.infinity,
                              height: double.infinity,
                              color: Colors.transparent, // Nền trong suốt
                              child: Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  // Ảnh lớn ở giữa
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(15),
                                    child: Container(
                                      color: Colors.white,
                                      width: widthOfPicture,
                                      height: heightOfPicture,
                                      child: Stack(children: [
                                        picAndScore['Offset']
                                                .toString()
                                                .isNotEmpty
                                            ? CustomPaint(
                                                painter: PaintCanvas(
                                                  points: scaleOffset(
                                                      decodeOffsetList(
                                                          picAndScore[
                                                              'Offset']),
                                                      scale: scale),
                                                  paints: scalePaint(
                                                      decodePaintList(
                                                          picAndScore['Color']),
                                                      scale: scale),
                                                ),
                                                size: Size(widthOfPicture,
                                                    heightOfPicture),
                                              )
                                            : Container(
                                                width: widthOfPicture,
                                                height: heightOfPicture,
                                                color: Colors
                                                    .transparent, // Placeholder while loading
                                              ),
                                        Positioned(
                                            bottom: 0,
                                            left: 0,
                                            right: 0,
                                            child: Container(
                                              width: widthOfPicture,
                                              height: 50,
                                              color: picAndScore['Rank'] == 1
                                                  ? const Color(0xFFB78900)
                                                      .withOpacity(0.2)
                                                  : picAndScore['Rank'] == 2
                                                      ? const Color(0xFF349AAC)
                                                          .withOpacity(0.2)
                                                      : picAndScore['Rank'] == 3
                                                          ? const Color(
                                                                  0xFF67CD34)
                                                              .withOpacity(0.2)
                                                          : Colors.black
                                                              .withOpacity(0.2),
                                              child: Center(
                                                child: Text(
                                                  'Hạng ${picAndScore['Rank']}',
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .titleLarge!
                                                      .copyWith(
                                                          color: picAndScore['Rank'] ==
                                                                  1
                                                              ? const Color(
                                                                  0xFFB78900)
                                                              : picAndScore[
                                                                          'Rank'] ==
                                                                      2
                                                                  ? const Color(
                                                                      0xFF349AAC)
                                                                  : picAndScore[
                                                                              'Rank'] ==
                                                                          3
                                                                      ? const Color(
                                                                          0xFF67CD34)
                                                                      : Colors
                                                                          .white),
                                                ),
                                              ),
                                            )),
                                      ]),
                                    ),
                                  ),
                                  // Phần dưới với avatar, tên và điểm
                                  Padding(
                                    padding: const EdgeInsets.only(right: 15),
                                    child: SizedBox(
                                      width: widthOfPicture + 50,
                                      height: 130,
                                      child: Column(
                                        mainAxisSize: MainAxisSize.max,
                                        children: [
                                          Stack(
                                            alignment: Alignment.center,
                                            children: [
                                              Container(
                                                  margin: const EdgeInsets.only(
                                                      left: 30),
                                                  decoration:
                                                      const BoxDecoration(
                                                    color: Colors.white,
                                                    borderRadius:
                                                        BorderRadius.all(
                                                      Radius.circular(45),
                                                    ),
                                                  ),
                                                  child: const SizedBox(
                                                    //height: double.infinity,
                                                    height: 50,
                                                    width: double.infinity,
                                                  )),
                                              Row(
                                                children: [
                                                  // Avatar
                                                  Container(
                                                    width: 70,
                                                    height: 70,
                                                    margin:
                                                        const EdgeInsets.all(
                                                            10),
                                                    decoration: BoxDecoration(
                                                      shape: BoxShape.circle,
                                                      image: DecorationImage(
                                                        image: AssetImage(
                                                            'assets/images/avatars/avatar${picAndScore['AvatarIndex']}.png'),
                                                        fit: BoxFit.fill,
                                                      ),
                                                    ),
                                                  ),
                                                  // Tên người chơi
                                                  Expanded(
                                                    child: Row(
                                                      children: [
                                                        Text(
                                                          picAndScore['Name']
                                                              as String,
                                                          style: Theme.of(
                                                                  context)
                                                              .textTheme
                                                              .titleLarge!
                                                              .copyWith(
                                                                  color: Colors
                                                                      .black),
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                        ),
                                                        if (picAndScore['Id']!
                                                            .contains(
                                                                'admin-')) ...[
                                                          const SizedBox(
                                                              width: 5),
                                                          SizedBox(
                                                            width: 20,
                                                            height: 20,
                                                            child: Image.asset(
                                                                'assets/images/admin.png'),
                                                          )
                                                        ],
                                                      ],
                                                    ),
                                                  ),
                                                  // Điểm
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                            right: 20),
                                                    child: Text(
                                                      '${picAndScore['TotalScore']}',
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .titleLarge!
                                                          .copyWith(
                                                              color:
                                                                  Colors.black),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              // Đeo huy chương
                                              Positioned(
                                                bottom: 0,
                                                left: 30,
                                                child: buildMedal(
                                                    picAndScore['Rank'] - 1),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  //const SizedBox(height: 10),
                                ],
                              ),
                            ),
                        ],
                      ),
                    )),
          // Nút thoát
          if (ref.read(userProvider).id == roomOwner)
            Positioned(
              bottom: 50,
              left: 0,
              right: 0,
              child: Align(
                alignment: Alignment.center,
                child: Button(
                  onClick: (ctx) async {
                    if (_playersInRoom.isNotEmpty) {
                      await _masterpieceModeDataRef.update({
                        'wordToDraw': pickRandomWordToGuess(),
                        'timeLeft': widget.selectedRoom.timePerRound,
                        'scoringDone': false,
                        'uploadDone': false,
                        'showingIndex': 0,
                      });
                      await _masterpieceModeDataRef.child('album').remove();
                      await _masterpieceModeDataRef.child('score').remove();
                      if (ref.read(userProvider).id == roomOwner) {
                        await _masterpieceModeDataRef.update({
                          'playAgain': true,
                        });
                      }
                      _playAgain();
                    }
                  },
                  title: 'Chơi lại',
                  imageAsset: 'assets/images/play-again.png',
                  borderRadius: 25,
                ),
              ),
            )
          else
            Positioned(
              bottom: 50,
              left: 0,
              right: 0,
              child: Center(
                child: Text(
                  'Chờ chủ phòng chơi lại...',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium!
                      .copyWith(color: Colors.black),
                ),
              ),
            ),
          // App bar
          Container(
            width: double.infinity,
            height: 100,
            decoration: const BoxDecoration(color: Color(0xFF00C4A1)),
            child: Column(
              children: [
                const SizedBox(height: 35),
                Expanded(
                  flex: 1,
                  child: Center(
                    child: Text(
                      'Tuyệt tác của mọi người',
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge!
                          .copyWith(color: Colors.black),
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    pageController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  // Hàm decode chuỗi JSON thành List<Paint>
  List<Paint> decodePaintList(String jsonStr) {
    List<Map<String, dynamic>> decodedList =
        List<Map<String, dynamic>>.from(json.decode(jsonStr));
    return decodedList.map((paintMap) {
      Paint paint = Paint()
        ..color = Color(paintMap['color'])
        ..strokeWidth = paintMap['strokeWidth']
        ..strokeCap = StrokeCap.values.firstWhere(
          (e) => e.toString() == 'StrokeCap.' + paintMap['strokeCap'],
          orElse: () => StrokeCap.butt, // Default value if not found
        );
      // Add other properties if needed
      return paint;
    }).toList();
  }

  // Hàm decode chuỗi JSON thành List<List<Offset>>
  List<List<Offset>> decodeOffsetList(String jsonStr) {
    List<List<Offset>> offsetList = [];

    if (jsonStr.isNotEmpty) {
      // Decode the JSON string
      List<dynamic> decodedList = json.decode(jsonStr);

      // Process each inner list
      for (var innerList in decodedList) {
        if (innerList is List) {
          List<Offset> tempList = [];
          for (int i = 0; i < innerList.length; i += 2) {
            tempList.add(
                Offset(innerList[i] as double, innerList[i + 1] as double));
          }
          offsetList.add(tempList);
        }
      }
    }
    return offsetList;
  }

  // Hàm thu nhỏ offset
  List<List<Offset>> scaleOffset(List<List<Offset>> offsetList,
      {double scale = 1.0}) {
    List<List<Offset>> points = [];
    for (List<Offset> iList in offsetList) {
      List<Offset> tmp1 = [];
      for (Offset os in iList) {
        if (os.dx != -1 && os.dy != -1) {
          tmp1.add(Offset(os.dx * scale, os.dy * scale));
        } else {
          tmp1.add(os);
        }
      }
      points.add(tmp1);
    }
    return points;
  }

  // Hàm thu nhỏ stroke width
  List<Paint> scalePaint(List<Paint> paintList, {double scale = 1.0}) {
    List<Paint> paints = [];
    for (Paint paint in paintList) {
      Paint tmp = Paint()
        ..color = paint.color
        ..strokeWidth = paint.strokeWidth * scale
        ..strokeCap = paint.strokeCap;
      paints.add(tmp);
    }
    return paints;
  }
}

class PaintCanvas extends CustomPainter {
  final List<List<Offset>> points;
  final List<Offset> tmp;
  final List<Paint> paints;

  PaintCanvas({
    required this.points,
    this.tmp = const [],
    required this.paints,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < points.length; i++) {
      for (int j = 0; j < points[i].length - 1; j++) {
        if (points[i][j] != const Offset(-1, -1) &&
            points[i][j + 1] != const Offset(-1, -1)) {
          canvas.drawLine(points[i][j], points[i][j + 1], paints[i]);
        }
      }
    }

    if (paints.isNotEmpty) {
      Paint tmpPaint = paints.last;

      for (int j = 0; j < tmp.length - 1; j++) {
        if (tmp[j] != const Offset(-1, -1) &&
            tmp[j + 1] != const Offset(-1, -1)) {
          canvas.drawLine(tmp[j], tmp[j + 1], tmpPaint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(PaintCanvas oldDelegate) => true;
}
