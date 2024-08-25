import 'dart:math';

import 'package:draw_and_guess_promax/Screen/waiting_room.dart';
import 'package:draw_and_guess_promax/Widget/room_mode.dart';
import 'package:draw_and_guess_promax/data/play_mode_data.dart';
import 'package:draw_and_guess_promax/data/word_to_guess.dart';
import 'package:draw_and_guess_promax/firebase.dart';
import 'package:draw_and_guess_promax/model/room.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../Widget/button.dart';
import '../model/user.dart';
import '../provider/user_provider.dart';

final random = Random();

class CreateRoom extends ConsumerStatefulWidget {
  const CreateRoom({super.key});

  @override
  ConsumerState<CreateRoom> createState() => _CreateRoomState();
}

class _CreateRoomState extends ConsumerState<CreateRoom> {
  final selecting = ValueNotifier<String>('none');
  final _passwordController = TextEditingController();
  var _isWaiting = false;
  final timeChoices = [30, 60, 90, 120, 180, 210, 300];

  late int _timePerRound;

  int get timePerRound {
    return _timePerRound;
  }

  set timePerRound(int value) {
    if (value >= 30 && value <= 300) {
      _timePerRound = value;
    }
  }

  int _maxPlayer = 5;

  int get maxPlayer {
    return _maxPlayer;
  }

  set maxPlayer(int value) {
    if (value >= 2 && value <= 10) {
      _maxPlayer = value;
    }
  }

  String _pickRandomRoomId() {
    final number = random.nextInt(1000000);
    final roomId = number.toString().padLeft(6, '0');
    return roomId;
  }

  void _startClick(BuildContext context) async {
    if (selecting.value == 'none') {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn chế độ chơi'),
        ),
      );
      return;
    }

    setState(() {
      _isWaiting = true;
    });
    print(_passwordController.text);
    print(_maxPlayer);
    print(selecting.value);

    final user = ref.read(userProvider);

    final createdRoom = Room(
        roomId: _pickRandomRoomId(),
        roomOwner: user.id,
        password: _passwordController.text,
        isPrivate: _passwordController.text == '' ? false : true,
        maxPlayer: _maxPlayer,
        curPlayer: 1,
        mode: selecting.value,
      isPlayed: false,
      timePerRound: timePerRound,
    );

    // Tạo tham chiếu đến mục rooms trên firebase
    final roomsRef = database.child('/rooms/${createdRoom.roomId}');
    await roomsRef.update({
      'roomOwner': user.id,
      'password': createdRoom.password,
      'isPrivate': createdRoom.isPrivate,
      'maxPlayer': createdRoom.maxPlayer,
      'curPlayer': createdRoom.curPlayer,
      'mode': createdRoom.mode,
      'isPlayed': createdRoom.isPlayed,
      'timePerRound': createdRoom.timePerRound,
    });

    final User player = ref.read(userProvider);

    final playersInRoomRef =
        database.child('/players_in_room/${createdRoom.roomId}');
    await playersInRoomRef.update({
      player.id!: {
        'name': player.name,
        'avatarIndex': player.avatarIndex,
        'point': 0,
        'isCorrect': false,
      }
    });

    Navigator.of(context).pushReplacement(MaterialPageRoute(
        builder: (ctx) => WaitingRoom(
              selectedRoom: createdRoom,
              isGuest: false,
            )));
    setState(() {
      _isWaiting = false;
    });
  }

  void updateTimePerRound() {
    switch (selecting.value) {
      case 'Vẽ và đoán':
        timePerRound = 60;
        break;
      case 'Tam sao thất bản':
        timePerRound = 90;
        break;
      case 'Tuyệt tác':
        timePerRound = 60;
        break;
      default:
        timePerRound = 60;
    }
    // Cập nhật UI
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    updateTimePerRound();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          icon: Image.asset('assets/images/back.png'),
                          iconSize: 45,
                        ),
                      ),
                    ),
                    Text(
                      'Tạo phòng',
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
          // Các thành phần giao diện ở giữa
          Positioned(
            top: 100,
            bottom: 120,
            left: 0,
            right: 0,
            child: ListView(
              padding: EdgeInsets.zero,
              scrollDirection: Axis.vertical,
              children: [
                const SizedBox(height: 10),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                  child: Text(
                    'Chế độ chơi:',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                //Modes
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Column(
                    children: [
                      for (final mode in availablePlayMode)
                        Hero(
                          tag: mode.mode,
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: InkWell(
                              onTap: () {
                                if (_isWaiting) return;
                                print(mode.mode);
                                selecting.value = mode.mode;
                                updateTimePerRound();
                              },
                              child: RoomMode(
                                mode: mode.mode,
                                description: mode.description,
                                selecting: selecting,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                // Mật khẩu
                Padding(
                  padding: const EdgeInsets.all(15),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(10),
                        child: Text(
                          'Mật khẩu:',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      Row(
                        children: [
                          const SizedBox(width: 10),
                          Expanded(
                            child: SizedBox(
                              height: 40,
                              child: TextField(
                                enabled: !_isWaiting,
                                controller: _passwordController,
                                decoration: InputDecoration(
                                  hintText: 'Đặt mật khẩu',
                                  hintStyle:
                                      Theme.of(context).textTheme.bodySmall,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide:
                                        const BorderSide(color: Colors.white),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide:
                                        const BorderSide(color: Colors.white),
                                  ),
                                ),
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          IconButton(
                            onPressed: () {
                              // Unfocus keyboard
                              FocusScope.of(context).unfocus();
                            },
                            icon: const Icon(
                              Icons.done,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 10),
                        ],
                      ),
                    ],
                  ),
                ),
                // Số người chơi tối đa
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(width: 5),
                      Padding(
                        padding: const EdgeInsets.all(10),
                        child: Text(
                          'Người chơi tối đa:',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      const SizedBox(width: 15),
                      Row(
                        children: [
                          IconButton(
                            onPressed: () {
                              if (_isWaiting) return;
                              setState(() {
                                maxPlayer--;
                              });
                            },
                            icon: const Icon(
                              Icons.remove,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(
                              width: 25,
                              child: Text(
                                '$maxPlayer',
                                textAlign: TextAlign.center,
                              )),
                          IconButton(
                            onPressed: () {
                              if (_isWaiting) return;
                              setState(() {
                                maxPlayer++;
                              });
                            },
                            icon: const Icon(
                              Icons.add,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Thời gian chơi mỗi vòng
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(width: 5),
                      Padding(
                        padding: const EdgeInsets.all(10),
                        child: Text(
                          'Thời gian mỗi vòng (giây):',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      const SizedBox(width: 15),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(children: [
                          for (final time in timeChoices) ...[
                            ChoiceChip(
                              label: Text('$time'),
                              backgroundColor: Colors.transparent,
                              selected: time == timePerRound,
                              surfaceTintColor: Colors.transparent,

                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25),
                                // Độ cong của viền bo tròn
                                side: BorderSide(
                                  color: time == timePerRound
                                      ? Colors.white
                                      : Colors.transparent,
                                  // Màu viền khi được chọn
                                  width: 1, // Độ dày của viền
                                ),
                              ),
                              selectedColor: Colors.white.withOpacity(0.2),
                              // Màu nền khi được chọn, có độ trong suốt
                              onSelected: (value) {
                                setState(() {
                                  timePerRound = time;
                                });
                              },
                            ),
                            const SizedBox(width: 10)
                          ]
                        ]),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 100),
              ],
            ),
          ),
          // Nút
          Positioned(
            bottom: 50,
            left: 0,
            right: 0,
            child: Align(
              alignment: Alignment.center,
              child: Hero(
                tag: 'create_room',
                flightShuttleBuilder: (flightContext, animation, direction,
                    fromContext, toContext) {
                  return Button(
                    onClick: (ctx) {
                      _startClick(ctx);
                    },
                    title: 'Tạo phòng',
                    imageAsset: 'assets/images/play.png',
                    isWaiting: _isWaiting,
                    isEnable: !_isWaiting,
                  );
                },
                child: Button(
                  onClick: (ctx) {
                    _startClick(ctx);
                  },
                  title: 'Tạo phòng',
                  imageAsset: 'assets/images/play.png',
                  isWaiting: _isWaiting,
                  isEnable: !_isWaiting,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
