import 'dart:async';
import 'dart:math';

import 'package:draw_and_guess_promax/Screen/masterpiece_scoring.dart';
import 'package:draw_and_guess_promax/Widget/ChatWidget.dart';
import 'package:draw_and_guess_promax/Widget/Drawing.dart';
import 'package:draw_and_guess_promax/Widget/loading.dart';
import 'package:draw_and_guess_promax/Widget/masterpiece_mode_status.dart';
import 'package:draw_and_guess_promax/Widget/normal_mode_status.dart';
import 'package:draw_and_guess_promax/data/word_to_guess.dart';
import 'package:draw_and_guess_promax/model/player_masterpiece_mode.dart';
import 'package:draw_and_guess_promax/model/room.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../firebase.dart';
import '../model/user.dart';
import '../provider/user_provider.dart';
import 'home_page.dart';

class MasterPieceMode extends ConsumerStatefulWidget {
  const MasterPieceMode({super.key, required this.selectedRoom,});

  final Room selectedRoom;

  @override
  createState() => _MasterPieceModeState();
}

class _MasterPieceModeState extends ConsumerState<MasterPieceMode> {
  late String roomOwner = widget.selectedRoom.roomOwner!;
  String _wordToDraw = '';
  late final String _userId;
  late final List<User> _playersInRoom = [];
  late List<String> _playersInRoomId = [];
  List<Map<String, dynamic>> album = [];
  late DatabaseReference _roomRef;
  late DatabaseReference _playersInRoomRef;
  late DatabaseReference _playerInRoomIDRef;
  late DatabaseReference _myAlbumRef;
  late DatabaseReference _masterpieceModeDataRef;
  late PlayerInMasterPieceMode? _currentUser;


  var _timeLeft = -1;
  late int _curPlayer;

  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _userId = ref.read(userProvider).id!;
    _roomRef = database.child('/rooms/${widget.selectedRoom.roomId}');
    _playersInRoomRef =
        database.child('/players_in_room/${widget.selectedRoom.roomId}');
    _masterpieceModeDataRef =
        database.child('/masterpiece_mode_data/${widget.selectedRoom.roomId}');
    _myAlbumRef = _masterpieceModeDataRef.child('/$_userId/album');
    _playerInRoomIDRef = database.child(
        '/players_in_room/${widget.selectedRoom.roomId}/${ref.read(userProvider).id}');

    _startTimer();
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

    // Lấy thông tin người chơi trong phòng
    _playersInRoomRef.onValue.listen((event) {
      final data = Map<String, dynamic>.from(
        event.snapshot.value as Map<dynamic, dynamic>,
      );
      _playersInRoom.clear();
      for (final player in data.entries) {
        _playersInRoom.add(User(
          id: player.key,
          name: player.value['name'],
          avatarIndex: player.value['avatarIndex'],
        ));
      }

      _playersInRoomId.clear();
      _playersInRoomId = _playersInRoom.map((player) => player.id!).toList();
    });

    // Lấy thông tin từ cần vẽ
    _masterpieceModeDataRef.onValue.listen((event) async {
      final data = Map<String, dynamic>.from(
        event.snapshot.value as Map
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

      setState(() {
        _wordToDraw = data['wordToDraw'] as String;
      });
      final timeLeft = data['timeLeft'] as int;
      setState(() {
        _timeLeft = timeLeft;
      });

      if (timeLeft == 0) {
        await _masterpieceModeDataRef.update({
          'timeLeft': 15,
          'scoringDone': false,
        });

        Navigator.of(context).pushReplacement(MaterialPageRoute(
            builder: (ctx) =>
                MasterPieceScoring(selectedRoom: widget.selectedRoom)));
      }

      // nếu mới vừa chơi lại thì cập nhật lại
      if (data['playAgain'] == true) {
        await _masterpieceModeDataRef.update({
          'playAgain': false,
        });
      }
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
        for(var cp in _playersInRoom) {
        if(cp.id != roomOwner) {
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

  @override
  void dispose() {
    _timer?.cancel(); // Hủy Timer khi widget bị dispose
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isRoomOwner = ref.read(userProvider).id == roomOwner;
    final isLoading =
        _playersInRoomId.isEmpty || _wordToDraw.isEmpty || _timeLeft == -1;
    return Hero(
      tag: isRoomOwner ? 'create_room' : 'find_room',
      child: isLoading
          ? const Loading()
          : PopScope(
              canPop: false,
              onPopInvoked: (didPop) async {
                if (didPop) {
                  return;
                }
                final isQuit = (ref.read(userProvider).id == roomOwner)
                    ? await _showDialog('Cảnh báo',
                        'Nếu bạn thoát, phòng sẽ bị xóa và tất cả người chơi khác cũng sẽ bị đuổi ra khỏi phòng. Bạn có chắc chắn muốn thoát không?')
                    : await _showDialog('Cảnh báo',
                        'Bạn có chắc chắn muốn thoát khỏi phòng không?');

                if (context.mounted && isQuit) {
            _playerOutRoom(ref);
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (ctx) => const HomePage()),
                  (route) => false,
            );
          }
        },
        child: Scaffold(
          resizeToAvoidBottomInset: true,
          body: Stack(children: [
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
                              if (ref
                                  .read(userProvider)
                                  .id ==
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
                      child: Drawing(
                        height: MediaQuery.of(context).size.height - 100,
                        width: MediaQuery.of(context).size.width,
                        selectedRoom: widget.selectedRoom,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 100,
                    left: 0,
                    right: 0,
                    child: Container(
                      color: Colors.transparent,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 15, top: 5),
                        child: MasterpieceModeStatus(
                          word: _wordToDraw,
                          timeLeft: _timeLeft,
                        ),
                      ),
                    ),
                  ),
                ]),
              ),
            ),
    );
  }
}
