import 'dart:async';

import 'package:draw_and_guess_promax/Screen/home_page.dart';
import 'package:draw_and_guess_promax/Widget/Drawing.dart';
import 'package:draw_and_guess_promax/Widget/knockoff_mode_status.dart';
import 'package:draw_and_guess_promax/Widget/loading.dart';
import 'package:draw_and_guess_promax/model/room.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../firebase.dart';
import '../model/user.dart';
import '../provider/user_provider.dart';

class KnockoffMode extends ConsumerStatefulWidget {
  const KnockoffMode({super.key, required this.selectedRoom});

  final Room selectedRoom;

  @override
  createState() => _KnockoffModeState();
}

class _KnockoffModeState extends ConsumerState<KnockoffMode> {
  late String roomOwner = widget.selectedRoom.roomOwner!;
  late final String _userId;
  late DatabaseReference _roomRef;
  late DatabaseReference _playersInRoomRef;
  late DatabaseReference _knockoffModeDataRef;
  late DatabaseReference _playerInRoomIDRef;
  late final List<User> _playersInRoom = [];
  late List<String> _playersInRoomId = [];
  late DatabaseReference _myDataRef;
  var _timeLeft = -1;
  int? _totalTurn;
  late int _curPlayer;

  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _userId = ref.read(userProvider).id!;
    _roomRef = database.child('/rooms/${widget.selectedRoom.roomId}');
    _playersInRoomRef =
        database.child('/players_in_room/${widget.selectedRoom.roomId}');
    _knockoffModeDataRef =
        database.child('/knockoff_mode_data/${widget.selectedRoom.roomId}');
    _myDataRef = _knockoffModeDataRef.child('/$_userId');
    _timeLeft = widget.selectedRoom.timePerRound;

    // Lắng nghe sự kiện thoát phòng
    _roomRef.onValue.listen((event) async {
      // Room has been deleted
      if (event.snapshot.value == null) {
        if (widget.selectedRoom.roomOwner != _userId) {
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
    _playersInRoomRef.onValue.listen((event) async {
      final data = Map<String, dynamic>.from(
        event.snapshot.value as Map<dynamic, dynamic>,
      );
      _playersInRoom.clear();
      var index = 0;
      for (final player in data.entries) {
        if (player.key == ref.read(userProvider).id) {
          await _myDataRef.update({"indexTurn": index});
        }
        _playersInRoom.add(User(
          id: player.key,
          name: player.value['name'],
          avatarIndex: player.value['avatarIndex'],
        ));
        index++;
      }
      _playersInRoomId.clear();
      _playersInRoomId = _playersInRoom.map((player) => player.id!).toList();
    });

    // Cập nhật thời gian còn lại
    _myDataRef.onValue.listen((event) {
      final data = Map<String, dynamic>.from(
        event.snapshot.value as Map<dynamic, dynamic>,
      );
      final timeLeft = data['timeLeft'] as int;
      setState(() {
        _timeLeft = timeLeft;
      });
      _startTimer();
    });

    _knockoffModeDataRef.onValue.listen((event) {
      final data = Map<String, dynamic>.from(
        event.snapshot.value as Map<dynamic, dynamic>,
      );

      // khi không còn ai trong phòng
      if (data['noOneInRoom'] == true) {
        _roomRef.remove();
        _playersInRoomRef.remove();
        _knockoffModeDataRef.remove();

        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (ctx) => const HomePage()),
          (route) => false,
        );
        if (_userId == widget.selectedRoom.roomOwner) {
          _showDialog('Thông báo', 'Phòng đã bị xóa vì không còn người chơi',
              isKicked: true);
        }
      }

      _totalTurn = data['turn'] as int;
    });
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel(); // Hủy Timer nếu đã tồn tại
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (_timeLeft > 0) {
        await _myDataRef.update({'timeLeft': _timeLeft - 1});
      } else {
        timer.cancel(); // Hủy Timer khi thời gian kết thúc
      }
    });
  }

  Future<void> _playerOutRoom(WidgetRef ref) async {
    final userId = ref.read(userProvider).id;
    if (userId == null) return;

    final currentPlayerCount = _curPlayer;
    if (currentPlayerCount > 0) {
      // Nếu còn 2 người chơi thì xóa phòng
      if (currentPlayerCount <= 2) {
        _knockoffModeDataRef.update({
          'noOneInRoom': true,
        });
      } else {
        // Nếu còn nhiều hơn 2 người chơi thì giảm số người chơi
        await _playersInRoomRef.child(userId).remove();
      }
    }

    // Todo: Chuyển chủ phòng nếu chủ phòng thoát
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

  Future<void> _onCompleteDrawing() async {
    setState(() {
      _timeLeft = 0;
    });
    await _myDataRef.update({'timeLeft': _timeLeft});
  }

  @override
  Widget build(BuildContext context) {
    final isRoomOwner =
        ref.read(userProvider).id == widget.selectedRoom.roomOwner;
    final isLoading = _totalTurn == null;
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
                  final isQuit = (ref.read(userProvider).id ==
                          widget.selectedRoom.roomOwner)
                      ? await _showDialog('Cảnh báo',
                          'Nếu bạn thoát, phòng sẽ bị xóa và tất cả người chơi khác cũng sẽ bị đuổi ra khỏi phòng. Bạn có chắc chắn muốn thoát không?')
                      : await _showDialog('Cảnh báo', 'Bạn có chắc chắn muốn thoát khỏi phòng không?');

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
                                        final isQuit = await _showDialog(
                                            'Cảnh báo',
                                            'Nếu bạn thoát, phòng sẽ bị xóa và tất cả người chơi khác cũng sẽ bị đuổi ra khỏi phòng. Bạn có chắc chắn muốn thoát không?');
                                        if (!isQuit) return;
                                      } else {
                                        final isQuit = await _showDialog(
                                            'Cảnh báo',
                                            'Bạn có chắc chắn muốn thoát khỏi phòng không?');
                                        if (!isQuit) return;
                                      }

                                      await _playerOutRoom(ref);
                                if (context.mounted) {
                                  Navigator.of(context).pushAndRemoveUntil(
                                    MaterialPageRoute(
                                        builder: (ctx) => const HomePage()),
                                        (route) => false,
                                  );
                                }
                              },
                              icon: Image.asset('assets/images/back.png'),
                              iconSize: 45,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            'Tam sao thất bản',
                            style: Theme
                                .of(context)
                                .textTheme
                                .titleLarge!
                                .copyWith(color: Colors.black),
                            overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                ),
                        ),
                              //if (_totalTurn! % 2 == 1 && _timeLeft > 0)
                              Padding(
                            padding: const EdgeInsets.all(10),
                            child: SizedBox(
                              height: 45,
                              width: 45,
                                  child: _totalTurn! % 2 == 1 && _timeLeft > 0
                                      ? IconButton(
                                          tooltip: 'Hoàn thành vẽ',
                                onPressed: _onCompleteDrawing,
                                icon: Image.asset('assets/images/done.png'),
                                iconSize: 45,
                                        )
                                      : null,
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
                    height: MediaQuery
                        .of(context)
                        .size
                        .height - 100,
                    width: MediaQuery
                        .of(context)
                        .size
                        .width,
                    selectedRoom: widget.selectedRoom,
                  ),
                ),
              ),
              // Hint
              Positioned(
                top: 100,
                left: 0,
                right: 0,
                child: Container(
                  color: Colors.transparent,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 15, top: 5),
                    child: KnockoffModeStatus(
                      timeLeft: _timeLeft,
                      turn: _totalTurn!,
                    ),
                  ),
                ),
              ),
            ],
          ),
        )
    );
  }

  @override
  void dispose() {
    _timer?.cancel(); // Hủy Timer khi widget bị dispose
    super.dispose();
  }
}
