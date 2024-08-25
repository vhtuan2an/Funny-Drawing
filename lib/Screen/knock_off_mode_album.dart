import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:draw_and_guess_promax/Widget/loading.dart';
import 'package:draw_and_guess_promax/model/room.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../Widget/button.dart';
import '../firebase.dart';
import '../model/user.dart';
import '../provider/user_provider.dart';
import 'home_page.dart';
import 'knock_off_mode.dart';

// milliseconds
const int timeToShowPerPicture = 3000;

class KnockoffModeAlbum extends ConsumerStatefulWidget {
  const KnockoffModeAlbum({
    super.key,
    required this.selectedRoom,
  });

  final Room selectedRoom;

  @override
  createState() => _KnockoffModeAlbumState();
}

class _KnockoffModeAlbumState extends ConsumerState<KnockoffModeAlbum> {
  late String roomOwner = widget.selectedRoom.roomOwner!;
  late final String _userId;
  late DatabaseReference _roomRef;
  late DatabaseReference _playersInRoomRef;
  late DatabaseReference _knockoffModeDataRef;
  late DatabaseReference _playerInRoomIDRef;
  late final List<User> _playersInRoom = [];
  late List<String> _playersInRoomId = [];
  late DatabaseReference _myDataRef;
  List<List<Map<String, String>>> picturesOfUsers = [];
  var _showingIndex = 0;
  var _isPlayAgain = false;
  var _isEnd = false;
  late int _curPlayer;

  Timer? _timer;
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  final ScrollController _scrollController = ScrollController();

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

    // Lấy thông tin người chơi và tranh trong phòng
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

      _getPictures();
      Future.delayed(const Duration(milliseconds: 100), () {
        _animatePictures();
      });
    });

    _knockoffModeDataRef.onValue.listen((event) async {
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

      final albumShowingIndex = data['albumShowingIndex'];
      _isPlayAgain = data['playAgain'];
      if (_isPlayAgain) {
        await _myDataRef.remove();
        await _knockoffModeDataRef.update({
          'playAgain': false,
        });
        _playAgain();
      }

      // có thể chơi lại ở đây
      if (albumShowingIndex >= _playersInRoom.length &&
          _playersInRoom.isNotEmpty) {
        // Reset lại phòng
        await _knockoffModeDataRef.update({
          'turn': 1,
          'playerDone': 0,
          'albumShowingIndex': 0,
        });
        if (_userId == widget.selectedRoom.roomOwner) {
          await _knockoffModeDataRef.update({
            'playAgain': true,
          });
        }
      } else {
        _scrollController.animateTo(0,
            duration: const Duration(milliseconds: 500), curve: Curves.easeOut);
        setState(() {
          _showingIndex = albumShowingIndex;
        });
        _animatePictures();
      }
    });
  }

  Future<void> _getPictures() async {
    for (final id in _playersInRoomId) {
      List<Map<String, String>> pictures = [];
      DatabaseReference albumRef = database
          .child('/knockoff_mode_data/${widget.selectedRoom.roomId}/$id/album');
      DataSnapshot snapshot = await albumRef.get();

      final Map<String, dynamic> playerRef;
      final Map<String, dynamic> album;

      if (Platform.isIOS) {
        playerRef = Map<String, dynamic>.from(snapshot.value as Map);
        print("ZCHECK - player ref ${playerRef}");
        album = Map<String, dynamic>.from(playerRef[id]["album"] as Map);
      } else {
        album = Map<String, dynamic>.from(snapshot.value as Map);
      }

      final firstPlayerIndex =
          _playersInRoom.indexWhere((player) => player.id == id);
      var bias = 0;

      for (final picture in album.entries) {
        final color = picture.value['Color'] as String;
        final offset = picture.value['Offset'] as String;

        final player =
            _playersInRoom[(firstPlayerIndex + bias) % _playersInRoom.length];

        pictures.add({
          'avatarIndex': player.avatarIndex.toString(),
          'name': player.name,
          'id': player.id!,
          'Color': color,
          'Offset': offset,
        });
        bias++;
      }
      setState(() {
        picturesOfUsers.add(pictures);
      });
    }
  }

  void _animatePictures() {
    // Xóa tất cả các item hiện có
    final int itemCount = picturesOfUsers[_showingIndex].length;
    for (int i = itemCount - 1; i >= 0; i--) {
      _listKey.currentState!.removeItem(
        i,
        (context, animation) => SizeTransition(
          sizeFactor: animation,
          child: Container(), // Một container rỗng để animate việc xóa
        ),
        duration: const Duration(milliseconds: 300),
      );
    }

    // Thêm các item mới với độ trễ
    final int itemsToShow = picturesOfUsers[_showingIndex].length;

    for (int i = 0; i < itemsToShow; i++) {
      Timer(Duration(milliseconds: i * timeToShowPerPicture), () {
        if (_listKey.currentState != null) {
          _listKey.currentState!.insertItem(i);
          // Thêm một độ trễ nhỏ trước khi scroll để đảm bảo item đã được thêm vào danh sách
          Future.delayed(const Duration(milliseconds: 100), () {
            if (_scrollController.hasClients) {
              _scrollController.animateTo(
                _scrollController.position.maxScrollExtent,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
              );
            }
          });
        }
      });
    }
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

  _playAgain() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (ctx) => const HomePage(),
      ),
      (route) => false,
    );
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => KnockoffMode(
          selectedRoom: widget.selectedRoom,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const double widthOfPicture = 250;
    const double heightOfPicture = 430;
    const double scale = 0.6;

    if (picturesOfUsers.isEmpty || _showingIndex >= _playersInRoom.length) {
      return const Loading(
        text: 'Đang tải album...',
      );
    }
    if (_isEnd) {
      return const Loading(
        text: 'Đang chơi lại...',
      );
    }

    final int itemsToShow = picturesOfUsers[_showingIndex].length;

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
            color: const Color(0xFFE5E5E5),
          ),
          // Các bức tranh và nút
          Positioned(
              top: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                color: const Color(0xFF00C4A1),
                // Phải có width và height cố định để CustomPaint biết kích thước cần vẽ
                height: MediaQuery.of(context).size.height,
                width: MediaQuery.of(context).size.width + 1,
                child: AnimatedList(
                  key: _listKey,
                  controller: _scrollController,
                  padding: const EdgeInsets.only(top: 110, bottom: 10),
                  initialItemCount: itemsToShow,
                  itemBuilder: (context, index, animation) {
                    final id = picturesOfUsers[_showingIndex][index]['id']!;
                    final name = picturesOfUsers[_showingIndex][index]['name']!;
                    final avatarIndex =
                        picturesOfUsers[_showingIndex][index]['avatarIndex']!;
                    final paintList = decodePaintList(
                        picturesOfUsers[_showingIndex][index]['Color']!);
                    final offsetList = decodeOffsetList(
                        picturesOfUsers[_showingIndex][index]['Offset']!);
                    return FadeTransition(
                      opacity: animation,
                      child: Column(
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (index != 0) ...[
                                SizedBox(
                                  width: 50,
                                  height: 50,
                                  child: CircleAvatar(
                                    backgroundImage: AssetImage(
                                        'assets/images/avatars/avatar$avatarIndex.png'), // Sử dụng AssetImage như là ImageProvider
                                  ),
                                ),
                                const SizedBox(width: 5),
                              ],
                              Expanded(
                                flex: 1,
                                child: Column(
                                  crossAxisAlignment: index == 0
                                      ? CrossAxisAlignment.end
                                      : CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: index == 0
                                          ? MainAxisAlignment.end
                                          : MainAxisAlignment.start,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        Text(
                                          name,
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleSmall!
                                              .copyWith(
                                                color: Colors.black,
                                              ),
                                        ),
                                        if (id.contains('admin-')) ...[
                                          const SizedBox(width: 3),
                                          SizedBox(
                                            width: 15,
                                            height: 15,
                                            child: Image.asset(
                                                'assets/images/admin.png'),
                                          )
                                        ]
                                      ],
                                    ),
                                    const SizedBox(height: 5),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(15),
                                      child: Container(
                                        color: Colors.white,
                                        width: widthOfPicture,
                                        height: heightOfPicture,
                                        child: picturesOfUsers[_showingIndex]
                                                .isNotEmpty
                                            ? CustomPaint(
                                                painter: PaintCanvas(
                                                  points: scaleOffset(
                                                      offsetList,
                                                      scale: scale),
                                                  paints: scalePaint(paintList,
                                                      scale: scale),
                                                ),
                                                size: const Size(widthOfPicture,
                                                    heightOfPicture),
                                              )
                                            : Container(
                                                width: widthOfPicture,
                                                height: heightOfPicture,
                                                color: Colors
                                                    .transparent, // Placeholder while loading
                                              ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (index == 0) ...[
                                const SizedBox(width: 5),
                                SizedBox(
                                  width: 50,
                                  height: 50,
                                  child: CircleAvatar(
                                    backgroundImage: AssetImage(
                                        'assets/images/avatars/avatar$avatarIndex.png'), // Sử dụng AssetImage như là ImageProvider
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 15),
                          if (index == itemsToShow - 1) ...[
                            const SizedBox(height: 25),
                            if (_userId == widget.selectedRoom.roomOwner)
                              Column(
                                children: [
                                  Button(
                                    onClick: (ctx) {
                                      setState(() async {
                                        if (_showingIndex + 1 >=
                                            picturesOfUsers.length) {
                                          setState(() {
                                            _isEnd = true;
                                          });
                                        }
                                        // Chưa xem hết thì chuyển qua bức tiếp theo
                                        await _knockoffModeDataRef.update({
                                          'albumShowingIndex':
                                              _showingIndex + 1,
                                        });
                                      });
                                    },
                                    title: _showingIndex + 1 !=
                                            picturesOfUsers.length
                                        ? 'Tiếp tục'
                                        : 'Chơi lại',
                                    imageAsset: _showingIndex + 1 !=
                                            picturesOfUsers.length
                                        ? null
                                        : 'assets/images/play-again.png',
                                    borderRadius: 25,
                                  ),
                                  const SizedBox(height: 10),
                                  if (_showingIndex + 1 ==
                                      picturesOfUsers.length)
                                    Text('Xem hết rồi, chơi lại nhé?',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium),
                                ],
                              )
                            else
                              Text(
                                _showingIndex + 1 != picturesOfUsers.length
                                    ? 'Chờ chủ phòng tiếp tục...'
                                    : 'Xem hết rồi,\nHãy nhắc chủ phòng chơi lại nhé!',
                                style: Theme.of(context).textTheme.bodyMedium,
                                textAlign: TextAlign.center,
                              ),
                            const SizedBox(height: 30),
                          ],
                        ],
                      ),
                    );
                  },
                ),
              )),
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
                      'Album của ${picturesOfUsers[_showingIndex].first['name']}',
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

  @override
  void dispose() {
    _timer?.cancel(); // Hủy Timer khi widget bị dispose
    super.dispose();
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
