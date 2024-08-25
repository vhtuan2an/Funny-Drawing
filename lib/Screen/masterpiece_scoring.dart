import 'dart:async';
import 'dart:convert';

import 'package:draw_and_guess_promax/Screen/master_piece_mode_rank.dart';
import 'package:draw_and_guess_promax/Widget/button.dart';
import 'package:draw_and_guess_promax/Widget/loading.dart';
import 'package:draw_and_guess_promax/Widget/masterpiece_scoring_status.dart';
import 'package:draw_and_guess_promax/model/player_masterpiece_mode.dart';
import 'package:draw_and_guess_promax/model/room.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../firebase.dart';
import '../provider/user_provider.dart';
import 'home_page.dart';

class MasterPieceScoring extends ConsumerStatefulWidget {
  const MasterPieceScoring({
    super.key,
    required this.selectedRoom,
  });

  final Room selectedRoom;

  @override
  createState() => _MasterPieceScoringState();
}

class _MasterPieceScoringState extends ConsumerState<MasterPieceScoring> {
  late String roomOwner = widget.selectedRoom.roomOwner!;
  late final List<PlayerInMasterPieceMode> _playersInRoom = [];
  late List<String> _playersInRoomId = [];
  late DatabaseReference _roomRef;
  late DatabaseReference _playersInRoomRef;
  late DatabaseReference _playerInRoomIDRef;
  late DatabaseReference _masterpieceModeDataRef;
  List<int> buttonStates = [1, 2, 3, 4, 5];
  var _selectedPoint = 0;
  late final String _userId;

  List<Map<String, dynamic>> pictures = [];
  int _showingIndex = 0;

  var _timeLeft = -1;
  late int _curPlayer;
  static const _timeToScore = 15;

  Timer? _timer;

  Timer? _debounceTimer;
  final int _debounceDuration = 300; // duration in milliseconds

  late StreamSubscription _roomSubscription;
  late StreamSubscription _masterpieceModeDataSubscription;

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

    // Cập nhật thời gian còn lại (chỉ chủ phòng mới được cập nhật trên Firebase)
    _startTimer();

    // Lắng nghe sự kiện thoát phòng
    _roomSubscription = _roomRef.onValue.listen((event) async {
      // Room has been deleted
      if (event.snapshot.value == null) {
        if (roomOwner != ref.read(userProvider).id) {
          if (context.mounted) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (ctx) => const HomePage()),
              (route) => false,
            );
          }
          await _showDialog('Phòng đã bị xóa', 'Phòng đã bị xóa bởi chủ phòng',
              isKicked: true);
        }
      }

      final data = Map<String, dynamic>.from(
        event.snapshot.value as Map<dynamic, dynamic>,
      );
      _curPlayer = data['curPlayer'] as int;
      roomOwner = data['roomOwner'] as String;
    });

    _getPlayerInRoom();
    Future.delayed(const Duration(milliseconds: 300), () {
      _getPictures();
    });

    // Lấy thông tin từ cần vẽ
    _masterpieceModeDataSubscription =
        _masterpieceModeDataRef.onValue.listen((event) async {
      final data = Map<String, dynamic>.from(
          event.snapshot.value as Map<dynamic, dynamic>);

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

      // Cancel any existing debounce timer
      if (_debounceTimer?.isActive ?? false) _debounceTimer?.cancel();

      // Set up a new debounce timer
      _debounceTimer =
          Timer(Duration(milliseconds: _debounceDuration), () async {
        setState(() {
          _showingIndex = data['showingIndex'] as int;
          _timeLeft = data['timeLeft'] as int;
        });

        final scoringDone = data['scoringDone'] as bool;

        // Kiểm tra điều kiện chuyển màn hình ở những giây đầu
        if (scoringDone) {
          _timer?.cancel();
          Navigator.of(context).pushReplacement(MaterialPageRoute(
              builder: (context) => MasterPieceModeRank(
                    selectedRoom: widget.selectedRoom,
                  )));
        }

        if (_timeLeft == 0) {
                  // Cập nhật điểm
                  final path = '/score/${pictures.firstWhere((
                      e) => e['Index'] == _showingIndex)['Id']}';
                  await _masterpieceModeDataRef.child(path).update({
                    '${ref
                        .read(userProvider)
                        .id}': _selectedPoint,
                  });
                  _selectedPoint = 0;

          // Chủ phòng chuyển bức tranh tiếp theo
          if (ref.read(userProvider).id == roomOwner) {
            await _masterpieceModeDataRef.update({
              'showingIndex': _showingIndex + 1,
              'timeLeft': _timeToScore,
            });

            if (_showingIndex >= pictures.length - 1) {
              await _masterpieceModeDataRef.update({
                'scoringDone': true,
              });
              print('Chuyển sang màn hình xếp hạng');
            }
          }
        }
      });
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

  void _startTimer() {
    if (roomOwner == ref.read(userProvider).id) {
      _timer?.cancel(); // Hủy Timer nếu đã tồn tại
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) async {
        if (_timeLeft > 0) {
          await _masterpieceModeDataRef.update({'timeLeft': _timeLeft - 1});
        } else {
          timer.cancel(); // Hủy Timer khi thời gian kết thúc
        }
      });
    }
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

  Future<void> _getPictures() async {
    final masterpieceSnapshot = await _masterpieceModeDataRef.get();
    final masterpieceData = Map<String, dynamic>.from(
      masterpieceSnapshot.value as Map<dynamic, dynamic>,
    );

    // Chờ cho việc upload ảnh hoàn tất (khai sáng vl)
    while (!(masterpieceData['uploadDone'] as bool)) {
      await Future.delayed(const Duration(milliseconds: 200));
    }

    List<Map<String, dynamic>> newPictures = [];
    var count = 0;
    for (var id in _playersInRoomId) {
      final snapshot = await _masterpieceModeDataRef.child('/album/$id').get();

      // Kiểm tra nếu snapshot.value là null
      if (snapshot.value == null) {
        print('Không có dữ liệu cho người chơi với id: $id');
        continue; // Bỏ qua người chơi này và tiếp tục vòng lặp
      }

      final data = Map<String, dynamic>.from(snapshot.value as Map);
      final color = data['Color'] as String;
      final offset = data['Offset'] as String;
      newPictures.add({
        'Index': count,
        'Id': id,
        'Color': color,
        'Offset': offset,
      });
      count++;
    }
    setState(() {
      pictures = newPictures;
    });

    print('Debug:');
    print(pictures.length);
    pictures.forEach((element) {
      print(element['Index']);
      print(element['Id']);
    });
  }

  @override
  void dispose() {
    _timer?.cancel(); // Hủy Timer khi widget bị dispose
    _roomSubscription.cancel();
    _masterpieceModeDataSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_showingIndex >= pictures.length ||
        pictures.length < _playersInRoom.length) {
      return const Loading();

      // debug only
      /*return Stack(children: [
        const Loading(),
        Positioned(
          top: 35,
          child: Container(
            color: Colors.black54,
            padding: const EdgeInsets.all(10),
            child: Text(
              'Debug:'
              '\n_showingIndex: $_showingIndex'
              '\n_timeLeft: $_timeLeft'
              '\n_playersInRoomId.length: ${_playersInRoomId.length}'
              '\n_picture.length: ${pictures.length}'
              '\n_myId: ${ref.read(userProvider).id}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ),
      ]);*/
    }

    final offsetList = decodeOffsetList(pictures[_showingIndex]['Offset']!);
    final paintList = decodePaintList(pictures[_showingIndex]['Color']!);

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
      child: Stack(children: [
        // App bar
        Container(
          width: double.infinity,
          height: 100,
          decoration: const BoxDecoration(color: Color(0xFF00C4A1)),
          child: Column(
            children: [
              const SizedBox(height: 35),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(10),
                    child: SizedBox(
                      height: 45,
                      width: 45,
                      child: IconButton(
                        onPressed: () async {
                          if (ref.read(userProvider).id ==
                              widget.selectedRoom.roomOwner) {
                            final isQuit = await _showDialog('Cảnh báo',
                                'Nếu bạn thoát, phòng sẽ bị xóa và tất cả người chơi khác cũng sẽ bị đuổi ra khỏi phòng. Bạn có chắc chắn muốn thoát không?');
                            if (!isQuit) return;
                          } else {
                            final isQuit = await _showDialog('Cảnh báo',
                                'Bạn có chắc chắn muốn thoát khỏi phòng không?');
                            if (!isQuit) return;
                          }

                          await _playerOutRoom(ref);
                          if (context.mounted) {
                            Navigator.of(context).pop();
                          }
                        },
                        icon: Image.asset('assets/images/back.png'),
                        iconSize: 45,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'Tuyệt tác',
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge!
                          .copyWith(color: Colors.black),
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.all(10),
                    child: SizedBox(
                      height: 45,
                      width: 45,
                      child: null,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        // Drawing board
        Positioned(
          child: Padding(
            padding: const EdgeInsets.only(top: 100),
            child: Container(
              color: Colors.white,
              child: CustomPaint(
                painter: PaintCanvas(
                  points: offsetList,
                  paints: paintList,
                ),
                size: Size(MediaQuery.of(context).size.width,
                    MediaQuery.of(context).size.height),
              ),
            ),
          ),
        ),
        // status
        Positioned(
          child: Padding(
            padding: const EdgeInsets.only(top: 100),
            child: Container(
              color: Colors.transparent,
              child: Padding(
                  padding: const EdgeInsets.only(left: 15, top: 5),
                  child: MasterpieceScoringStatus(
                    timeLeft: _timeLeft,
                    player: _playersInRoom.firstWhere((element) =>
                        element.id == pictures[_showingIndex]['Id']),
                    isMyTurn: _userId == pictures[_showingIndex]['Id'],
                  )),
            ),
          ),
        ),
        // Chấm điểm
        if (ref.read(userProvider).id != pictures[_showingIndex]['Id'])
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 10, bottom: 10),
                  child: Text(
                    'Bức tranh này xứng đáng nhận được...',
                    style: Theme.of(context).textTheme.bodySmall!.copyWith(
                          color: Colors.black,
                        ),
                  ),
                ),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        for (final number in buttonStates)
                          SizedBox(
                            width: MediaQuery.of(context).size.width * 0.2 - 10,
                            child: Button(
                              title: '$number',
                              color: number == _selectedPoint
                                  ? const Color(0xFF00C4A0)
                                  : Colors.grey,
                              onClick: (ctx) {
                                setState(() {
                                  _selectedPoint = number;
                                });
                              },
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        // debug only
        /*Positioned(
          top: 35,
          child: Container(
            color: Colors.black54,
            padding: const EdgeInsets.all(10),
            child: Text(
              'Debug:'
              '\n_showingIndex: $_showingIndex'
              '\n_timeLeft: $_timeLeft'
              '\n_playersInRoomId.length: ${_playersInRoomId.length}'
              '\n_picture.length: ${pictures.length}'
              '\n_picture[$_showingIndex][\'Id\']: ${pictures[_showingIndex]['Id']}'
              '\n_myId: ${ref.read(userProvider).id}'
              '\n_picture[$_showingIndex][\'Id\'] == myId: ${pictures[_showingIndex]['Id'] == ref.read(userProvider).id}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ),*/
      ]),
    );
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
