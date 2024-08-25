import 'dart:async';

import 'package:draw_and_guess_promax/Screen/create_room.dart';
import 'package:draw_and_guess_promax/Screen/home_page.dart';
import 'package:draw_and_guess_promax/Screen/waiting_room.dart';
import 'package:draw_and_guess_promax/Widget/button.dart';
import 'package:draw_and_guess_promax/data/word_to_guess.dart';
import 'package:draw_and_guess_promax/firebase.dart';
import 'package:draw_and_guess_promax/model/room.dart';
import 'package:draw_and_guess_promax/provider/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../Widget/room_mode.dart';
import '../Widget/room_to_play.dart';
import '../data/play_mode_data.dart';
import '../model/user.dart';

class FindRoom extends ConsumerStatefulWidget {
  const FindRoom({super.key});

  @override
  ConsumerState<FindRoom> createState() => _FindRoomState();
}

class _FindRoomState extends ConsumerState<FindRoom> {
  final selecting = ValueNotifier<String>('none');
  final password = ValueNotifier<String>('');
  final TextEditingController _idController = TextEditingController();
  String dropdownValue = 'Tất cả';

  var rooms = <Room>[];
  late List<Room> filteredRoom = [];
  var _isWaiting = false;
  late int itemsToShow = 0;
  Timer? _timer;

  // GlobalKey để tham chiếu đến AnimatedList
  final GlobalKey<AnimatedListState> _listKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    database.child('/rooms').onValue.listen((event) {
      _onRefresh();
    });
  }

  Future<void> _onRefresh() async {
    print('Refresh triggered'); // Debugging statement
    final snapshot = await database.child('/rooms').get();

    // Ensure snapshot has data
    if (snapshot.value != null) {
      final data =
          Map<String, dynamic>.from(snapshot.value as Map<dynamic, dynamic>);

      rooms = [];

      for (final room in data.entries) {
        final nextRoom = Room(
          roomId: room.key,
          roomOwner: room.value['roomOwner'],
          mode: room.value['mode'],
          curPlayer: room.value['curPlayer'],
          maxPlayer: room.value['maxPlayer'],
          isPrivate: room.value['isPrivate'],
          password: room.value['password'],
          isPlayed: room.value['isPlayed'],
          timePerRound: room.value['timePerRound'],
        );
        rooms.add(nextRoom);
      }

      setState(() {
        filteredRoom = rooms
            .where((room) =>
                room.curPlayer < room.maxPlayer &&
                ((room.mode == 'Vẽ và đoán') ||
                    (room.mode == 'Tam sao thất bản' &&
                        room.isPlayed == false) ||
                    (room.mode == 'Tuyệt tác' && room.isPlayed == false)))
            .toList();
        itemsToShow = filteredRoom.length;
        print(
            'Filtered rooms count: ${filteredRoom.length}'); // Debugging statement
      });
    } else {
      setState(() {
        filteredRoom = [];
        itemsToShow = 0;
      });
      print('No data found'); // Debugging statement
    }
  }

  // Chắc khỏi làm quá
  void _animateRooms() {
    // Xóa các item cũ
    _listKey.currentState?.removeAllItems(
      (context, animation) => SizeTransition(
        sizeFactor: animation,
        child: Container(), // Một container rỗng để animate việc xóa
      ),
      duration: const Duration(milliseconds: 300),
    );

    // Thêm các item mới
    for (int i = 0; i < itemsToShow; i++) {
      Timer(Duration(milliseconds: i * 200), () {
        if (_listKey.currentState != null) {
          _listKey.currentState?.insertItem(i);
        }
      });
    }
  }

  Future<void> _onStartClick(BuildContext context) async {
    ScaffoldMessenger.of(context).clearSnackBars();
    if (selecting.value == 'none') {
      // Hiển thị thông báo khi chưa chọn phòng
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(filteredRoom.isEmpty
              ? 'Hãy tạo phòng mới'
              : 'Vui lòng chọn phòng!'),
          action: filteredRoom.isEmpty
              ? SnackBarAction(
                  label: 'Tạo phòng',
                  onPressed: () {
                    ScaffoldMessenger.of(context).clearSnackBars();
                    Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (ctx) => const HomePage()),
                        (route) => false);
                    Navigator.of(context).push(MaterialPageRoute(
                        builder: (ctx) => const CreateRoom()));
                  },
                )
              : null,
        ),
      );
      return;
    }
    setState(() {
      _isWaiting = true;
    });

    print(selecting.value);
    print(password.value);
    final selectedRoom =
        rooms.firstWhere((room) => room.roomId == selecting.value);
    print('Password của phòng: ${selectedRoom.password}');
    if (selectedRoom.isPrivate && password.value != selectedRoom.password) {
      print('Sai mật khẩu');

      // Hiển thị thông báo khi nhập sai mật khẩu
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sai mật khẩu!'),
        ),
      );
    } else {
      print('Đúng mật khẩu');

      // Cập nhật thông tin người chơi trong phòng
      final User player = ref.read(userProvider);

      final playersInRoomRef =
          database.child('/players_in_room/${selectedRoom.roomId}');
      await playersInRoomRef.update({
        player.id!: {
          'name': player.name,
          'avatarIndex': player.avatarIndex,
          'point': 0,
          'isCorrect': false,
        },
      });

      // Cập nhật thông tin phòng
      final roomsRef = database.child('/rooms/${selectedRoom.roomId}');
      await roomsRef.update({
        'curPlayer': selectedRoom.curPlayer + 1,
      });

      Navigator.of(context).push(MaterialPageRoute(
          builder: (ctx) => WaitingRoom(
                selectedRoom: selectedRoom,
                isGuest: true,
              )));
    }
    setState(() {
      _isWaiting = false;
    });
  }

  void _onFilterRoom() {
    final roomId = _idController.text;
    final filter = dropdownValue;

    if (roomId.isEmpty && filter == 'Tất cả') {
      filteredRoom = rooms;
    } else if (roomId.isEmpty && filter != 'Tất cả') {
      filteredRoom = rooms.where((room) => room.mode == filter).toList();
    } else if (roomId.isNotEmpty && filter == 'Tất cả') {
      filteredRoom =
          rooms.where((room) => room.roomId.contains(roomId)).toList();
    } else {
      filteredRoom = rooms
          .where((room) => room.roomId.contains(roomId) && room.mode == filter)
          .toList();
    }
    setState(() {});
  }

  // Hàm xây dựng mỗi item trong dropdown menu
  Widget _buildDropdownMenuItem(String value) {
    return InkWell(
      onTap: () {
        setState(() {
          dropdownValue = value;
        });
        //_onCompleteFilter(value);
        _onFilterRoom();
        Navigator.pop(context); // Đóng dropdown menu khi chọn một item
      },
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(
          value,
          style: Theme.of(context)
              .textTheme
              .bodyMedium!
              .copyWith(color: Colors.black),
        ),
      ),
    );
  }

  // Hàm hiển thị dropdown menu
  void _showDropdownMenu(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final width = MediaQuery.of(context).size.width * 0.15;
        final height = (MediaQuery.of(context).size.height - 250) / 2;
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: width, vertical: height),
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: 250,
              decoration: BoxDecoration(
                color: const Color(0xFF00C4A0),
                borderRadius: BorderRadius.circular(25),
              ),
              child: Center(
                child: ListView(
                  padding: const EdgeInsets.all(8),
                  children: [
                    Center(child: _buildDropdownMenuItem('Tất cả')),
                    Center(child: _buildDropdownMenuItem('Vẽ và đoán')),
                    Center(child: _buildDropdownMenuItem('Tam sao thất bản')),
                    Center(child: _buildDropdownMenuItem('Tuyệt tác')),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(children: [
        // Nền
        Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(color: Color(0xFF00C4A0))),
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
                    'Tìm phòng',
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
        // Thanh lọc phòng
        Positioned(
          top: 120,
          left: 0,
          right: 0,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: SizedBox(
              height: 35,
              child: Row(
                children: [
                  // Ô tìm id phòng
                  Expanded(
                    flex: 4,
                    child: TextField(
                      enabled: !_isWaiting,
                      controller: _idController,
                      // Gán TextEditingController cho trường nhập văn bản
                      decoration: InputDecoration(
                        hintText: 'Id phòng',
                        hintStyle: Theme.of(context)
                            .textTheme
                            .bodySmall!
                            .copyWith(color: Colors.black),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.0),
                          // Điều chỉnh độ cong của viền
                          borderSide: const BorderSide(
                              color: Colors.transparent), // Màu của viền
                        ),
                        filled: true,
                        // Đánh dấu để hiển thị nền
                        fillColor: Colors.white,
                        // Màu của nền
                        prefixIcon: SizedBox(
                          height: 24, // Điều chỉnh chiều cao của icon
                          width: 24, // Điều chỉnh chiều rộng của icon
                          child: Image.asset(
                              'assets/images/search.png'), // Thêm biểu tượng bên trái
                        ),
                      ),
                      style: const TextStyle(color: Colors.black),
                      keyboardType: TextInputType.number,
                      onChanged: (roomId) {
                        _onFilterRoom();
                      },
                      maxLines: 1,
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Ô lọc chế độ
                  Expanded(
                    flex: 6,
                    child: InkWell(
                      onTap: () {
                        if (_isWaiting) return;
                        _showDropdownMenu(context);
                      },
                      child: TextField(
                        enabled: false,
                        decoration: InputDecoration(
                          hintText: dropdownValue,
                          hintStyle: Theme.of(context)
                              .textTheme
                              .bodySmall!
                              .copyWith(
                                  color: Colors.black,
                                  fontWeight: FontWeight.w300),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10.0),
                            // Điều chỉnh độ cong của viền
                            borderSide: const BorderSide(
                                color: Colors.transparent), // Màu của viền
                          ),
                          filled: true,
                          // Đánh dấu để hiển thị nền
                          fillColor: Colors.white,
                          // Màu của nền
                          prefixIcon: SizedBox(
                            height: 24, // Điều chỉnh chiều cao của icon
                            width: 24, // Điều chỉnh chiều rộng của icon
                            child: Image.asset(
                                'assets/images/filter.png'), // Thêm biểu tượng bên trái
                          ),
                        ),
                        style: const TextStyle(color: Colors.black),
                        keyboardType: TextInputType.number,
                        maxLines: 1,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        // Danh sách các phòng
        if (filteredRoom.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 165),
            child: RefreshIndicator(
              onRefresh: () async {
                _onRefresh();
                _animateRooms();
              },
              color: const Color(0xFF00C4A0),
              child: SizedBox(
                width: double.infinity,
                height: double.infinity,
                child: ListView(
                  children: [
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Text(
                          'Hiện không có phòng nào\nHãy làm mới hoặc tạo phòng!',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium!
                              .copyWith(color: Colors.black),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ),
          )
        else
          // Widget sử dụng AnimatedList
          Padding(
            padding: const EdgeInsets.only(top: 165),
            child: RefreshIndicator(
              onRefresh: () async {
                _onRefresh();
                _animateRooms();
              },
              color: const Color(0xFF00C4A0),
              child: AnimatedList(
                key: _listKey,
                padding: EdgeInsets.zero,
                initialItemCount: itemsToShow,
                itemBuilder: (ctx, index, animation) {
                  final isLastItem = index == itemsToShow - 1;
                  // Sử dụng SizeTransition để thực hiện animation xuất hiện
                  try {
                    return FadeTransition(
                      key: ValueKey(filteredRoom[index]),
                      opacity: animation,
                      child: Padding(
                        padding: EdgeInsets.only(
                            left: 8, right: 8, bottom: isLastItem ? 120 : 8),
                        child: InkWell(
                          onTap: () {
                            if (_isWaiting) return;
                            setState(() {
                              selecting.value = filteredRoom[index].roomId;
                            });
                          },
                          child: Hero(
                            tag: filteredRoom[index].roomId,
                            child: RoomToPlay(
                              mode: filteredRoom[index].mode,
                              curPlayer: filteredRoom[index].curPlayer,
                              maxPlayer: filteredRoom[index].maxPlayer,
                              roomId: filteredRoom[index].roomId,
                              isPrivate: filteredRoom[index].isPrivate,
                              selecting: selecting,
                              password: password,
                            ),
                          ),
                        ),
                      ),
                    );
                  } catch (e) {
                    print('[Lỗi từ AnimatedList] $e');
                    return Container();
                  }
                },
              ),
            ),
          ),

        if (filteredRoom.isEmpty)
          Positioned(
              bottom: 120,
              right: 50,
              child: SizedBox(
                height: 150,
                width: 150,
                child: Image.asset(
                  'assets/images/arrow.png',
                ),
              )),
        // Nút
        Positioned(
            bottom: 50,
            left: 0,
            right: 0,
            child: Align(
              alignment: Alignment.center,
              child: filteredRoom.isNotEmpty
                  ? Hero(
                      tag: 'find_room',
                      child: Button(
                        onClick: (ctx) {
                          _onStartClick(ctx);
                        },
                        title: 'Vào phòng',
                        imageAsset: 'assets/images/play.png',
                        isWaiting: _isWaiting,
                        isEnable: !(_isWaiting),
                      ),
                    )
                  : Hero(
                      tag: 'find_room',
                      child: Button(
                        onClick: (ctx) {
                          Navigator.of(context).push(MaterialPageRoute(
                              builder: (ctx) => const CreateRoom()));
                        },
                        title: 'Tạo phòng',
                        imageAsset: 'assets/images/plus.png',
                        isWaiting: _isWaiting,
                        isEnable: !(_isWaiting),
                      ),
                    ),
            )),
      ]),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();

    super.dispose();
  }
}
