import 'dart:async';
import 'dart:math';

import 'package:draw_and_guess_promax/Screen/knock_off_mode.dart';
import 'package:draw_and_guess_promax/Screen/master_piece_mode.dart';
import 'package:draw_and_guess_promax/Screen/normal_mode_room.dart';
import 'package:draw_and_guess_promax/Widget/player.dart';
import 'package:draw_and_guess_promax/Widget/room_mode.dart';
import 'package:draw_and_guess_promax/data/play_mode_data.dart';
import 'package:draw_and_guess_promax/model/room.dart';
import 'package:draw_and_guess_promax/provider/chat_provider.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../Widget/button.dart';
import '../data/word_to_guess.dart';
import '../firebase.dart';
import '../model/user.dart';
import '../provider/user_provider.dart';
import 'home_page.dart';

class WaitingRoom extends ConsumerStatefulWidget {
  const WaitingRoom({
    super.key,
    required this.selectedRoom,
    this.isGuest = true,
  });

  final Room selectedRoom;
  final bool isGuest;

  @override
  ConsumerState<WaitingRoom> createState() => _WaitingRoomState();
}

class _WaitingRoomState extends ConsumerState<WaitingRoom> {
  late DatabaseReference _roomRef;
  late DatabaseReference _playersInRoomRef;
  late bool isPlayed = false;
  var currentPlayers = <User>[];
  var isWaitingStart = false;
  var isWaitingInvite = false;
  late bool _isGuest;
  @override
  void initState() {
    super.initState();
    _roomRef = database.child('/rooms/${widget.selectedRoom.roomId}');
    _playersInRoomRef =
        database.child('/players_in_room/${widget.selectedRoom.roomId}');
    _isGuest = widget.isGuest;

    _roomRef.onValue.listen((event) async {
      // Room has been deleted
      if (event.snapshot.value == null) {
        if (widget.selectedRoom.roomOwner != ref.read(userProvider).id) {
          await _showDialog('Phòng đã bị xóa', 'Phòng đã bị xóa bởi chủ phòng',
              isKicked: true);
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (ctx) => const HomePage()),
            (route) => false,
          );
        }
      } else {
        final data = Map<String, dynamic>.from(
            event.snapshot.value as Map<dynamic, dynamic>);
        isPlayed = data['isPlayed'];
        if (data['isPlayed'] == true) {
          startMode(widget.selectedRoom.mode);
        }

        _isGuest = data['roomOwner'] != ref.read(userProvider).id;
      }
    });

    _playersInRoomRef.onValue.listen((event) {
      final data = Map<String, dynamic>.from(
          event.snapshot.value as Map<dynamic, dynamic>);

      setState(() {
        currentPlayers.clear();
        for (var player in data.entries) {
          currentPlayers.add(User(
            id: player.key,
            name: player.value['name'],
            avatarIndex: player.value['avatarIndex'],
          ));
        }
      });

      // Cập nhật số người chơi trong phòng
      _roomRef.update({'curPlayer': currentPlayers.length});
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
                  _completer.complete(false); // Hoàn thành với giá trị true
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
                _completer.complete(true); // Hoàn thành với giá trị true
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
    return _completer.future; // Trả về Future từ Completer
  }

  Future<void> _playOutRoom(WidgetRef ref) async {
    final userId = ref.read(userProvider).id;
    if (userId == null) return;

    if (widget.selectedRoom.roomOwner == userId) {
      // Chủ phòng thoát, xóa phòng
      await _roomRef.remove();
      await _playersInRoomRef.remove();
    } else {
      // Người chơi thoát, xóa người chơi trong phòng
      final playerRef = database
          .child('/players_in_room/${widget.selectedRoom.roomId}/$userId');
      await playerRef.remove();
    }
  }

  Future<void> startMode(String mode) async {
    // Khởi tạo trạng thái của phòng chế độ Vẽ và đoán
    if (mode == 'Vẽ và đoán') {
      if (widget.selectedRoom.roomOwner == ref.read(userProvider).id) {
        var normalModeDataRef =
            database.child('/normal_mode_data/${widget.selectedRoom.roomId}');
        // Khởi tạo trạng thái của phòng
        await normalModeDataRef.update({
          'wordToDraw': pickRandomWordToGuess(),
          'turn': currentPlayers[Random().nextInt(currentPlayers.length)].id,
          'timeLeft': widget.selectedRoom.timePerRound,
          'point': 10,
          // 'endGame': false,
        });
      }

      Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (ctx) => const HomePage()),
          (route) => false);
      Navigator.of(context).push(MaterialPageRoute(
          builder: (ctx) => NormalModeRoom(selectedRoom: widget.selectedRoom)));

      ref.read(chatProvider.notifier).clearChat();
    }
    // Khởi tạo trạng thái của phòng chế độ Tam sao thất bản
    else if (mode == 'Tam sao thất bản') {
      if (widget.selectedRoom.roomOwner == ref.read(userProvider).id) {
        var knockoffModeDataRef =
            database.child('/knockoff_mode_data/${widget.selectedRoom.roomId}');
        // Khởi tạo trạng thái của phòng
        await knockoffModeDataRef.update({
          'turn': 1,
          'playerDone': 0,
          'timeLeftMode': widget.selectedRoom.timePerRound,
          'albumShowingIndex': 0,
          'playAgain': false,
        });
      }
      Navigator.of(context).pushReplacement(MaterialPageRoute(
          builder: (ctx) => KnockoffMode(selectedRoom: widget.selectedRoom)));
    } else if (mode == 'Tuyệt tác') {
      if (widget.selectedRoom.roomOwner == ref.read(userProvider).id) {
        var masterPieceModeDataRef = database.child('/masterpiece_mode_data/${widget.selectedRoom.roomId}');
        // Khởi tạo trạng thái của phòng
        await masterPieceModeDataRef.update({
          'wordToDraw': pickRandomWordToGuess(),
          'timeLeft': widget.selectedRoom.timePerRound,
          'scoringDone': false,
          'showingIndex': 0,
          'playAgain': false,
          'uploadDone': false,
          // 'endGame': false,
        });
      }

      Navigator.of(context).pushReplacement(MaterialPageRoute(
          builder: (ctx) => MasterPieceMode(selectedRoom: widget.selectedRoom)));
    } else {
      throw 'Unknown mode: $mode';
    }
  }

  Future<void> _startClick(context) async {
    ScaffoldMessenger.of(context).clearSnackBars();
    if (currentPlayers.length < 2) {
      const sackBar = SnackBar(
        content: Text('Phòng cần ít nhất 2 người chơi'),
      );
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(sackBar);
      return;
    }
    setState(() {
      isWaitingStart = true;
    });

    await _roomRef.update({'isPlayed': true});
    startMode(widget.selectedRoom.mode);
    setState(() {
      isWaitingStart = false;
    });
  }

  void _inviteClick() {
    setState(() {
      isWaitingInvite = true;
    });
    print('đã mời');
    setState(() {
      isWaitingInvite = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) {
          return;
        }
        final isQuit = (ref.read(userProvider).id ==
                widget.selectedRoom.roomOwner)
            ? await _showDialog('Cảnh báo',
                'Nếu bạn thoát, phòng sẽ bị xóa và tất cả người chơi khác cũng sẽ bị đuổi ra khỏi phòng. Bạn có chắc chắn muốn thoát không?')
            : await _showDialog(
                'Cảnh báo', 'Bạn có chắc chắn muốn thoát khỏi phòng không?');

        if (context.mounted && isQuit) {
          _playOutRoom(ref);
          if (_isGuest) {
            Navigator.of(context).pop();
          } else {
            Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (ctx) => const HomePage()),
                (route) => false);
          }
        }
      },
      child: Scaffold(
        body: Stack(
          children: [
            // Nền
            Container(
              width: double.infinity,
              height: double.infinity,
              decoration: const BoxDecoration(color: Color(0xFF00C4A0)),
            ),
            // Appbar
            Container(
              width: double.infinity,
              height: 100,
              decoration: const BoxDecoration(color: Colors.white),
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
                              }

                              await _playOutRoom(ref);
                              if (_isGuest) {
                                Navigator.of(context).pop();
                              } else {
                                Navigator.of(context).pushAndRemoveUntil(
                                    MaterialPageRoute(
                                        builder: (ctx) => const HomePage()),
                                    (route) => false);
                              }
                            },
                            icon: Image.asset('assets/images/back.png'),
                            iconSize: 45,
                          ),
                        ),
                      ),
                      Text(
                        'Phòng chờ',
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge!
                            .copyWith(color: Colors.black),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // id phòng
            Positioned(
              top: 100,
              left: 0,
              child: Padding(
                padding: const EdgeInsets.only(top: 8, right: 8, left: 8),
                child: Text(
                  widget.selectedRoom.isPrivate
                      ? 'Id phòng: ${widget.selectedRoom.roomId}\nMật khẩu: ${widget.selectedRoom.password}'
                      : 'Id phòng: ${widget.selectedRoom.roomId}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ),
            // Thông tin
            Positioned(
              top: widget.selectedRoom.isPrivate ? 162 : 138,
              bottom: 120,
              left: 0,
              right: 0,
              child: ListView(
                padding: EdgeInsets.zero,
                scrollDirection: Axis.vertical,
                children: [
                  // Text chế độ
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 15, vertical: 10),
                    child: Text(
                      'Chế độ:',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  // Chế độ đã chọn
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Hero(
                      tag: _isGuest
                          ? widget.selectedRoom.roomId
                          : widget.selectedRoom.mode,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: RoomMode(
                          mode: widget.selectedRoom.mode,
                          description: availablePlayMode
                              .firstWhere((mode) =>
                                  mode.mode == widget.selectedRoom.mode)
                              .description,
                          selecting: ValueNotifier<String>(
                              'bla'), // dòng này không cần thiết nhưng lỡ thiết kế vậy rồi :((
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 15, vertical: 10),
                    child: Text(
                      'Người chơi trong phòng (${currentPlayers.length}/${widget.selectedRoom.maxPlayer}):',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  // Danh sách người chơi
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    child: GridView.builder(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      // Đặt physics là NeverScrollableScrollPhysics() để không cuộn được
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3, // Số cột trong lưới
                        crossAxisSpacing: 0, // Khoảng cách giữa các cột
                        mainAxisSpacing: 20, // Khoảng cách giữa các hàng
                      ),
                      itemCount: currentPlayers.length,
                      // Số lượng avatar
                      itemBuilder: (BuildContext context, int index) {
                        // Tạo một avatar từ index
                        return Player(
                          player: currentPlayers[index],
                          roomOwner: widget.selectedRoom.roomOwner!,
                          sizeImg: 80,
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
            // Nút
            // Khách tham gia phòng
            if (_isGuest)
              Positioned(
                bottom: 50,
                left: MediaQuery.of(context).size.width / 2 - (150) / 2,
                child: Row(
                  children: [
                    Hero(
                      tag: 'find_room',
                      child: Button(
                        onClick: (ctx) {
                          _inviteClick();
                        },
                        title: 'Mời',
                        imageAsset: 'assets/images/invite.png',
                        width: 150,
                      ),
                    )
                  ],
                ),
              )
            // Chủ phòng
            else ...[
              Positioned(
                bottom: 50,
                left: 15,
                right: 15,
                child: Hero(
                  tag: 'create_room',
                  child: Row(
                    children: [
                      Expanded(
                        flex: 1,
                        child: Button(
                          onClick: (ctx) {
                            _inviteClick();
                          },
                          title: 'Mời',
                          imageAsset: 'assets/images/invite.png',
                          //width: 150,
                          isWaiting: isWaitingInvite,
                          isEnable: !isWaitingStart && !isWaitingInvite,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 1,
                        child: Button(
                          onClick: (ctx) {
                            _startClick(ctx);
                          },
                          title: 'Bắt đầu',
                          imageAsset: 'assets/images/play.png',
                          //width: 150,
                          isWaiting: isWaitingStart,
                          isEnable: !isWaitingStart && !isWaitingInvite,
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ],
            // Lời nhắc vui
            Positioned(
              bottom: 20,
              left: 0,
              right: 0,
              child: Text(
                _isGuest
                    ? 'Chờ chủ phòng bắt đầu...'
                    : currentPlayers.length < 2
                        ? 'Cần thêm 1 người để bắt đầu'
                        : 'Bắt đầu thôi nào!!',
                style: Theme.of(context).textTheme.bodySmall!.copyWith(
                      color: currentPlayers.length < 2
                          ? const Color(0xFFCA322D)
                          : Colors.white,
                      fontWeight: currentPlayers.length < 2
                          ? FontWeight.bold
                          : FontWeight.w300,
                    ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
