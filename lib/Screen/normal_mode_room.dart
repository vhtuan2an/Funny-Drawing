import 'dart:async';
import 'dart:math';

import 'package:draw_and_guess_promax/Widget/ChatWidget.dart';
import 'package:draw_and_guess_promax/Widget/Drawing.dart';
import 'package:draw_and_guess_promax/Widget/chat_list.dart';
import 'package:draw_and_guess_promax/Widget/loading.dart';
import 'package:draw_and_guess_promax/Widget/normal_mode_status.dart';
import 'package:draw_and_guess_promax/data/word_to_guess.dart';
import 'package:draw_and_guess_promax/model/player_normal_mode.dart';
import 'package:draw_and_guess_promax/model/room.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../firebase.dart';
import '../provider/chat_provider.dart';
import '../provider/user_provider.dart';
import 'home_page.dart';

class NormalModeRoom extends ConsumerStatefulWidget {
  const NormalModeRoom({super.key, required this.selectedRoom});

  final Room selectedRoom;

  @override
  ConsumerState<NormalModeRoom> createState() => _NormalModeRoomState();
}

class _NormalModeRoomState extends ConsumerState<NormalModeRoom> {
  String _wordToDraw = '';
  late String wordToGuess;
  late String hint;
  late List<Map<String, dynamic>> chat = [];
  late DatabaseReference _roomRef;
  late DatabaseReference _playersInRoomRef;
  late DatabaseReference _chatRef;
  late DatabaseReference _drawingRef;
  late DatabaseReference _normalModeDataRef;
  late String roomOwner = widget.selectedRoom.roomOwner!;
  final TextEditingController _controller = TextEditingController();
  late DatabaseReference _playerInRoomIDRef;
  late bool _isEnable;

  var curPoint = 0;
  late final List<PlayerInNormalMode> _playersInRoom = [];
  late List<String> _playersInRoomId = [];
  bool? _isMyTurn;
  int currentPlayerTurnIndex = 0;
  late PlayerInNormalMode? _currentTurnUser;

  var isMyTurn = false;
  var _timeLeft = -1;
  var _pointLeft = 0;
  var _curPlayer = 2;

  final _scrollController = ScrollController();

  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _roomRef = database.child('/rooms/${widget.selectedRoom.roomId}');
    _playersInRoomRef =
        database.child('/players_in_room/${widget.selectedRoom.roomId}');
    _drawingRef = database.child('/normal_mode_data/draw/');
    _chatRef =
        database.child('/normal_mode_data/${widget.selectedRoom.roomId}/chat/');
    _normalModeDataRef =
        database.child('/normal_mode_data/${widget.selectedRoom.roomId}');
    _playerInRoomIDRef = database.child(
        '/players_in_room/${widget.selectedRoom.roomId}/${ref.read(userProvider).id}');
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
        _playersInRoom.add(PlayerInNormalMode(
          id: player.key,
          name: player.value['name'],
          avatarIndex: player.value['avatarIndex'],
          point: player.value['point'],
          isCorrect: player.value['isCorrect'],
        ));
      }

      _playersInRoomId.clear();
      _playersInRoomId = _playersInRoom.map((player) => player.id!).toList();
    });

    // Lấy thông tin từ chat
    _chatRef.onValue.listen((event) {
      final data = Map<String, dynamic>.from(
        event.snapshot.value as Map<dynamic, dynamic>,
      );

      final newChat = data.entries.map((e) {
        return {
          "id": e.value['id'],
          "userName": e.value['userName'],
          'avatarIndex': e.value['avatarIndex'],
          "message": e.value['message'],
          "timestamp": e.value['timestamp'],
        };
      }).toList();

      ref.read(chatProvider.notifier).updateChat(newChat);

      // đảm bảo rằng việc cuộn chỉ xảy ra sau khi giao diện đã được cập nhật hoàn tất.
      // Trùng với hàm _scrollToBottom()
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    });

    // Lấy thông tin từ cần vẽ và lượt chơi
    _normalModeDataRef.onValue.listen((event) {
      final data = Map<String, dynamic>.from(
        event.snapshot.value as Map<dynamic, dynamic>,
      );

      // khi không còn ai trong phòng
      if (data['noOneInRoom'] == true) {
        _roomRef.remove();
        _playersInRoomRef.remove();
        _normalModeDataRef.remove();

        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (ctx) => const HomePage()),
          (route) => false,
        );
        _showDialog('Thông báo', 'Phòng đã bị xóa vì không còn người chơi',
            isKicked: true);
      }

      wordToGuess = data['wordToDraw'];
      setState(() {
        _wordToDraw = data['wordToDraw'] as String;
      });
      final turn = data['turn'] as String;
      final timeLeft = data['timeLeft'] as int;
      final pointLeft = data['point'] as int;
      setState(() {
        _timeLeft = timeLeft;
        _pointLeft = pointLeft;
      });

      // Lấy tên người chơi hiện tại đang vẽ
      _currentTurnUser =
          _playersInRoom.firstWhere((player) => player.id == turn);

      // Cập nhật thời gian còn lại (chỉ chủ phòng mới được cập nhật trên Firebase)
      _startTimer();

      // Lấy vị trí của người chơi hiện tại
      currentPlayerTurnIndex = _playersInRoomId.indexOf(turn);
      setState(() {
        if (turn == ref.read(userProvider).id) {
          isMyTurn = true;
        } else {
          isMyTurn = false;
        }
      });

      // Chủ phòng cập nhật lượt chơi khi có người đoán đúng từ hoặc hết giờ
      if (((_pointLeft ==
                  (max(10, _playersInRoom.length) -
                      _playersInRoom.length +
                      1)) ||
              timeLeft == 0) &&
          ref.read(userProvider).id == roomOwner) {
        currentPlayerTurnIndex =
            (currentPlayerTurnIndex + 1) % _playersInRoomId.length;
        _normalModeDataRef.update({
          'userGuessed': null,
          'turn': _playersInRoomId[currentPlayerTurnIndex],
          'wordToDraw': pickRandomWordToGuess(),
          'timeLeft': widget.selectedRoom.timePerRound,
          'point': (max(10, _playersInRoom.length)),
        });
        for (var player in _playersInRoom) {
          _playersInRoomRef.update({
            player.id!: {
              'name': player.name,
              'avatarIndex': player.avatarIndex,
              'point': player.point,
              'isCorrect': false,
            }
          });
        }
        ref.read(chatProvider.notifier).addMessage(
            'answer',
            'Đáp án là: $wordToGuess',
            'Đáp án',
            widget.selectedRoom.roomId,
            -1);

        // Xóa bảng vẽ
        _drawingRef.remove();
      }
    });
    _playerInRoomIDRef.onValue.listen((event) {
      final data = Map<String, dynamic>.from(
        event.snapshot.value as Map<dynamic, dynamic>,
      );
      bool isCorrect = data['isCorrect'];
      curPoint = data['point'];
      setState(() {
        _isEnable = !isCorrect;
        print("EnableChat: " + _isEnable.toString());
      });
    });

    // Kiểm tra lượt để hiển thị chat
    _normalModeDataRef.onValue.listen((event) {
      final data = Map<String, dynamic>.from(
        event.snapshot.value as Map<dynamic, dynamic>,
      );
      setState(() {
        _isMyTurn = data['turn'] == ref.read(userProvider).id;
        var player = ref.read(userProvider);
        var point = 0;
        for (var pl in _playersInRoom) {
          if (pl.id == player.id) {
            point = pl.point;
            break;
          }
        }
        if (_isMyTurn == true) {
          _playersInRoomRef.update({
            player.id!: {
              'name': player.name,
              'avatarIndex': player.avatarIndex,
              'point': point,
              'isCorrect': true,
            }
          });
        } else {
          _playersInRoomRef.update({
            player.id!: {
              'name': player.name,
              'avatarIndex': player.avatarIndex,
              'point': point,
              'isCorrect': false,
            }
          });
        }
      });
    });
  }

  void _startTimer() {
    if (roomOwner == ref.read(userProvider).id) {
      _timer?.cancel(); // Hủy Timer nếu đã tồn tại
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_timeLeft > 0) {
          _normalModeDataRef.update({'timeLeft': _timeLeft - 1});
        } else {
          timer.cancel(); // Hủy Timer khi thời gian kết thúc
        }
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _showChat() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF00C4A1),
      builder: (ctx) {
        return SizedBox(
          height: MediaQuery.of(ctx).size.height * 0.8,
          child: Chat(
            roomId: widget.selectedRoom.roomId,
            height: MediaQuery.of(ctx).size.height,
            width: MediaQuery.of(ctx).size.width,
          ),
        );
      },
    );
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
        _normalModeDataRef.update({
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
          _roomRef.update({
            'roomOwner': cp.id,
          });
          break;
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatMessages = ref.watch(chatProvider);

    void onSubmitted() {
      if (_controller.text.isEmpty || wordToGuess.isEmpty) {
        return;
      }
      if (ref.read(chatProvider.notifier).checkGuess(
              wordToGuess, _controller.text, ref.read(userProvider).id!) ==
          "") {
        ref.read(chatProvider.notifier).addMessage(
              ref.read(userProvider).id!,
              _controller.text,
              ref.read(userProvider).name,
              widget.selectedRoom.roomId,
              ref.read(userProvider).avatarIndex,
            );
        _controller.clear();
      } else {
        if (_isEnable) {
          final userName = ref.read(userProvider).name;
          _playerInRoomIDRef
              .update({"point": curPoint + _pointLeft, "isCorrect": true});
          _normalModeDataRef.update({
            "point": _pointLeft - 1,
          });
          ref.read(chatProvider.notifier).addMessage(
              'system',
              '$userName đã đoán đúng',
              'Hệ thống',
              widget.selectedRoom.roomId,
              -1);
          _controller.clear();
          FocusScope.of(context).unfocus();
        }
      }
    }

    final isRoomOwner = ref.read(userProvider).id == roomOwner;
    final isLoading = _isMyTurn == null || _currentTurnUser == null;
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
                      : await _showDialog('Cảnh báo', 'Bạn có chắc chắn muốn thoát khỏi phòng không?');

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
                                  'Vẽ và đoán',
                                  style: Theme
                                .of(context)
                                .textTheme
                                .titleLarge!
                                .copyWith(color: Colors.black),
                            overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(10),
                          child: SizedBox(
                            height: 45,
                            width: 45,
                            child: IconButton(
                              tooltip: 'Chat',
                              onPressed: _showChat,
                              icon: Image.asset('assets/images/chat.png'),
                              iconSize: 45,
                            ),
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
                    child: NormalModeStatus(
                      isMyTurn: isMyTurn,
                      word: _wordToDraw,
                      timeLeft: _timeLeft,
                      player: _currentTurnUser!,
                    ),
                  ),
                ),
              ),
              // Chat
              if (_isMyTurn == false) ...[
                // Bình phong
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    alignment: Alignment.bottomCenter,
                    padding: const EdgeInsets.all(15),
                    color: const Color(0xFF00C4A1),
                    height: 120,
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          child: TextField(
                            controller: _controller,
                            decoration: InputDecoration(
                              hintText:
                              'Hãy cho ${_currentTurnUser!
                                  .name} biết câu trả lời của bạn',
                              hintStyle: const TextStyle(
                                color: Colors.black45,
                                fontWeight: FontWeight.normal,
                                fontSize: 18,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(50),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(50),
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(50),
                              ),
                            ),
                            onSubmitted: (_) {
                              onSubmitted();
                            },
                          ),
                        ),
                        SizedBox(
                          height: 50,
                          width: 50,
                          child: IconButton(
                            onPressed: onSubmitted,
                            icon: Image.asset('assets/images/send.png'),
                            iconSize: 45,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              Positioned(
                  bottom: 90,
                  left: 0,
                  right: 0,
                  child: Container(
                      padding: const EdgeInsets.only(
                          left: 15, right: 15, top: 5),
                      height: 100,
                      decoration: const BoxDecoration(
                          color: Color(0xFF00C4A1),
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(15),
                            topRight: Radius.circular(15),
                          )),
                      child: ChatList(
                          scrollController: _scrollController,
                          chatMessages: chatMessages))),
            ]),
          ),
        )
    );
  }
}
