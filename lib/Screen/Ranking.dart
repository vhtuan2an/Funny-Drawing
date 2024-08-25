
import 'dart:async';

import 'package:draw_and_guess_promax/Screen/waiting_room.dart';
import 'package:draw_and_guess_promax/Widget/player.dart';
import 'package:draw_and_guess_promax/model/room.dart';
import 'package:draw_and_guess_promax/model/user.dart';
import 'package:draw_and_guess_promax/provider/user_provider.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:draw_and_guess_promax/model/player_normal_mode.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

import '../firebase.dart';

class Ranking extends ConsumerStatefulWidget {
  const Ranking({
    super.key,
    required this.selectedRoom,
  });

  final Room selectedRoom;

  @override
  _Ranking createState() => _Ranking();
}

class _Ranking extends ConsumerState<Ranking> {

  late DatabaseReference _playerInRoomRef;
  late DatabaseReference _roomRef;
  late String _roomOwnerId = "";
  final List<PlayerInNormalMode> _playersInRoom = [];

  @override
  void initState() {
    super.initState();
    _playerInRoomRef = database.child('/players_in_room/${widget.selectedRoom.roomId}');
    _playerInRoomRef.onValue.listen((event) {
      final data = Map<String, dynamic>.from(
        event.snapshot.value as Map<dynamic, dynamic>,
      );
      setState(() {
        _playersInRoom.clear();
        for (final player in data.entries) {
          _playersInRoom.add(PlayerInNormalMode(
            id: player.key,
            name: player.value['name'],
            avatarIndex: player.value['avatarIndex'],
            point: player.value['point'],
            isCorrect: player.value['isCorrect'],
          ));
          _playersInRoom.sort((a, b) => b.point.compareTo(a.point));
        }
      });
    });
    _roomRef = database.child('/rooms/${widget.selectedRoom.roomId}');
    _roomRef.get().then((value) {
      final data = Map<String, dynamic>.from(
        value.value as Map<dynamic, dynamic>,
      );
      _roomOwnerId = data['roomOwner'];
    });
    Future.delayed(Duration(seconds: 5), () {
      Navigator.of(context).pushReplacement(MaterialPageRoute(
          builder: (ctx) => WaitingRoom(
            selectedRoom: widget.selectedRoom,
            isGuest: ref.read(userProvider).id != widget.selectedRoom.roomOwner,
          )));
    });
  }


  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text(
            'BẢNG XẾP HẠNG',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          backgroundColor: Color(0xFF00C4A1),
        ),
        body: Center(
          child: Container(
            alignment: Alignment.center,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center, // Đặt Column ở giữa theo chiều dọc
              crossAxisAlignment: CrossAxisAlignment.center, // Đặt các widget con ở giữa theo chiều ngang
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center, // Đặt Row ở giữa theo chiều ngang
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 10.0), // Padding top cho ảnh đầu
                      child: Image.asset(
                        'assets/images/gold-medal.png',
                        width: 100, // Đặt chiều rộng ảnh
                        height: 100, // Đặt chiều cao ảnh
                      ),
                    ),
                    // Player(player: User(id: "1", name: "Thing", avatarIndex: 2), sizeImg: 100),
                    Padding(
                      padding: const EdgeInsets.all(8.0), // Padding giữa các ảnh
                      child: Image.asset(
                        'assets/images/avatars/avatar3.png',
                        width: 100, // Đặt chiều rộng ảnh
                        height: 100, // Đặt chiều cao ảnh
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(left: 8.0), // Padding left cho text
                        child: Text(
                          "Thinh", // Ví dụ về văn bản dài
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis, // Hiển thị ... khi văn bản quá dài
                          softWrap: false, // Không xuống dòng
                          maxLines: 1, // Giới hạn số dòng
                        ),
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center, // Đặt Row ở giữa theo chiều ngang
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 10.0), // Padding top cho ảnh đầu
                      child: Image.asset(
                        'assets/images/silver-medal.png',
                        width: 100, // Đặt chiều rộng ảnh
                        height: 100, // Đặt chiều cao ảnh
                      ),
                    ),
                    // Player(player: User(id: "1", name: "Thing", avatarIndex: 2), sizeImg: 100),
                    Padding(
                      padding: const EdgeInsets.all(8.0), // Padding giữa các ảnh
                      child: Image.asset(
                        'assets/images/avatars/avatar3.png',
                        width: 100, // Đặt chiều rộng ảnh
                        height: 100, // Đặt chiều cao ảnh
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(left: 8.0), // Padding left cho text
                        child: Text(
                          "Thinh", // Ví dụ về văn bản dài
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis, // Hiển thị ... khi văn bản quá dài
                          softWrap: false, // Không xuống dòng
                          maxLines: 1, // Giới hạn số dòng
                        ),
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center, // Đặt Row ở giữa theo chiều ngang
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 10.0), // Padding top cho ảnh đầu
                      child: Image.asset(
                        'assets/images/bronze-medal.png',
                        width: 100, // Đặt chiều rộng ảnh
                        height: 100, // Đặt chiều cao ảnh
                      ),
                    ),
                    // Player(player: User(id: "1", name: "Thing", avatarIndex: 2), sizeImg: 100),
                    Padding(
                      padding: const EdgeInsets.all(8.0), // Padding giữa các ảnh
                      child: Image.asset(
                        'assets/images/avatars/avatar3.png',
                        width: 100, // Đặt chiều rộng ảnh
                        height: 100, // Đặt chiều cao ảnh
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(left: 8.0), // Padding left cho text
                        child: Text(
                          "Thinh", // Ví dụ về văn bản dài
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis, // Hiển thị ... khi văn bản quá dài
                          softWrap: false, // Không xuống dòng
                          maxLines: 1, // Giới hạn số dòng
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}