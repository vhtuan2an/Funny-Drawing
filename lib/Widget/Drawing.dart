import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:draw_and_guess_promax/Screen/knock_off_mode_album.dart';
import 'package:draw_and_guess_promax/firebase.dart';
import 'package:draw_and_guess_promax/model/room.dart';
import 'package:draw_and_guess_promax/model/user.dart';
import 'package:draw_and_guess_promax/provider/user_provider.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class Drawing extends ConsumerStatefulWidget {
  const Drawing({
    super.key,
    required this.height,
    required this.width,
    required this.selectedRoom,
  });

  final double height;
  final double width;
  final Room selectedRoom;

  @override
  ConsumerState<Drawing> createState() => _Drawing();
}

class _Drawing extends ConsumerState<Drawing> {
  late bool _isSizeMenuVisible;
  late bool _isSelectMenuVisible;
  late Color _paintColor;
  late Color _preColor;
  late bool _isErase;
  late double _paintSize;
  late IconData _selectIcon;
  late DatabaseReference _normalModeDataRef;
  bool? _isMenuBarVisible;
  final GlobalKey _sizeMenu = GlobalKey();
  final GlobalKey _selectMenu = GlobalKey();
  final GlobalKey<_PaintBoardState> _paintBoardKey = GlobalKey();
  String chose = "Draw";

  @override
  void initState() {
    super.initState();
    _isSelectMenuVisible = false;
    _paintColor = Colors.black;
    _preColor = Colors.black;
    _paintSize = 5;
    _selectIcon = Icons.draw;
    _isSizeMenuVisible = false;
    _isErase = false;

    _normalModeDataRef =
        database.child('/normal_mode_data/${widget.selectedRoom.roomId}');
    if (widget.selectedRoom.mode == 'Vẽ và đoán') {
      _normalModeDataRef.onValue.listen((event) {
        final data = Map<String, dynamic>.from(
          event.snapshot.value as Map<dynamic, dynamic>,
        );
        setState(() {
          _isMenuBarVisible = (widget.selectedRoom.mode != 'Vẽ và đoán' ||
              data['turn'] == ref.read(userProvider).id);
        });
      });
    } else if (widget.selectedRoom.mode == 'Tam sao thất bản') {
      _isMenuBarVisible = true;
    } else if (widget.selectedRoom.mode == 'Tuyệt tác') {
      _isMenuBarVisible = true;
    }
  }

  void _toggleSelectMenuVisibility(Offset position) {
    setState(() {
      _isSelectMenuVisible = !_isSelectMenuVisible;
      if (_isSelectMenuVisible) _isSizeMenuVisible = false;
    });
  }

  void _toggleSizeMenuVisibility(Offset position) {
    setState(() {
      _isSizeMenuVisible = !_isSizeMenuVisible;
      if (_isSizeMenuVisible) _isSelectMenuVisible = false;
    });
  }

  void _setColor(Color cl) {
    if (_isErase) return;
    setState(() {
      _paintColor = cl;
    });
  }

  void _setPainSize(double size) {
    setState(() {
      _paintSize = size;
    });
  }

  void _setSelectIcon(IconData ic) {
    setState(() {
      _selectIcon = ic;
    });
  }

  void _setChose(String mode) {
    setState(() {
      chose = mode;
    });
  }

  double _currentSliderValue = 10;

  Widget iconMenu({required Widget icon, required void Function() onPressed}) {
    return Container(
      height: 50,
      width: 50,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(7.0),
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: icon,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    const Color mainColor = Color(0xFF00C4A1);
    const double sizePickColor = 22;

    return Scaffold(
        body: Stack(
      children: [
        // ----------------------  Draw Area ----------------------
        Positioned(
          top: 0,
          left: 0,
          child: Column(
            children: [
              ClipRect(
                  child: SizedBox(
                height: widget.height,
                width: widget.width,
                child: PaintBoard(
                    key: _paintBoardKey,
                    chose: chose,
                    paintColor: _paintColor,
                    paintSize: _paintSize,
                    height: widget.height,
                    width: widget.width,
                    selectedRoom: widget.selectedRoom,
                    hideMenu: () {
                      _isSizeMenuVisible = false;
                      _isSelectMenuVisible = false;
                    },
                    toggleDrawBar: (value) {
                      _isMenuBarVisible = value;
                    }),
              ))
            ],
          ),
        ),
        // ----------------------  MenuBar ----------------------
        if (_isMenuBarVisible == true)
          Positioned(
            top: widget.height - 100,
            left: 0,
            child: Container(
                padding: const EdgeInsets.only(top: 10.0),
                height: 100,
                width: size.width,
                color: mainColor,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_selectIcon != Icons.add &&
                        _selectIcon != Icons.minimize)
                      Container(
                        height: 50,
                        width: 50,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(
                              7.0), // Bán kính cong của đường viền
                        ),
                        child: IconButton(
                          key: _selectMenu,
                          onPressed: () {
                            RenderBox buttonBox = _selectMenu.currentContext!
                                .findRenderObject() as RenderBox;
                            Offset buttonPosition =
                                buttonBox.localToGlobal(Offset.zero);
                            // Toggle the visibility of the container
                            _toggleSelectMenuVisibility(buttonPosition);
                          },
                          icon: Icon(
                            _selectIcon,
                            color: Colors.black,
                            size: 35, // Màu của biểu tượng
                          ),
                        ),
                      ),
                    if (_selectIcon == Icons.add)
                      Container(
                          height: 50,
                          width: 50,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(
                                7.0), // Bán kính cong của đường viền
                          ),
                          child: GestureDetector(
                            key: _selectMenu,
                            onTap: () {
                              _setColor(
                                  Theme.of(context).scaffoldBackgroundColor);
                              _setSelectIcon(Icons.add);
                              RenderBox buttonBox = _selectMenu.currentContext!
                                  .findRenderObject() as RenderBox;
                              Offset buttonPosition =
                                  buttonBox.localToGlobal(Offset.zero);
                              _toggleSelectMenuVisibility(buttonPosition);
                            },
                            child: Image.asset(
                              'assets/images/erase.png',
                              // Đường dẫn đến hình ảnh cục tẩy
                              width: 10,
                              height: 10,
                              color: Colors.black, // Màu của hình ảnh
                            ),
                          )),
                    if (_selectIcon == Icons.minimize)
                      Container(
                        height: 50,
                        width: 50,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(
                              7.0), // Bán kính cong của đường viền
                        ),
                        child: GestureDetector(
                          key: _selectMenu,
                          onTap: () {
                            RenderBox buttonBox = _selectMenu.currentContext!
                                .findRenderObject() as RenderBox;
                            Offset buttonPosition =
                                buttonBox.localToGlobal(Offset.zero);
                            _toggleSelectMenuVisibility(buttonPosition);
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(6.0),
                            child: Image.asset(
                              'assets/images/draw_line.png',
                              width: 20,
                              height: 20,
                            ),
                          ),
                        ),
                      ),
                    Container(
                      height: 50,
                      width: 50,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(
                            7.0), // Bán kính cong của đường viền
                      ),
                      child: IconButton(
                        padding: const EdgeInsets.all(2),
                        key: _sizeMenu,
                        onPressed: () {
                          RenderBox buttonBox = _sizeMenu.currentContext!
                              .findRenderObject() as RenderBox;
                          Offset buttonPosition =
                              buttonBox.localToGlobal(Offset.zero);
                          // Toggle the visibility of the container
                          _toggleSizeMenuVisibility(buttonPosition);
                        },
                        icon: Container(
                          width: _paintSize * 2,
                          height: _paintSize * 2,
                          decoration: BoxDecoration(
                            color: _paintColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),

                    // ----------------------  Color Picker ----------------------
                    Container(
                      height: 50,
                      width: 220,
                      decoration: BoxDecoration(
                        color: const Color.fromRGBO(255, 205, 234, 1),
                        borderRadius: BorderRadius.circular(5.0),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              for (final color in [
                                Colors.black,
                                Colors.white,
                                Colors.grey,
                                Colors.red,
                                Colors.yellow,
                                Colors.green,
                                Colors.blue
                              ])
                                SizedBox(
                                  height: sizePickColor,
                                  width: sizePickColor,
                                  child: ElevatedButton(
                                    onPressed: () {
                                      _setColor(color);
                                      _preColor = _paintColor;
                                    },
                                    style: ElevatedButton.styleFrom(
                                        padding: EdgeInsets.zero,
                                        minimumSize: const Size(
                                            sizePickColor, sizePickColor),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                              5), // Border radius là 5
                                        ),
                                        backgroundColor: color),
                                    child: const SizedBox(
                                      width: sizePickColor,
                                      // Kích thước của hình vuông
                                      height: sizePickColor,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              for (final color in [
                                Colors.pink,
                                Colors.brown,
                                Colors.cyanAccent,
                                Colors.greenAccent,
                                Colors.orange,
                                Colors.purple,
                                Colors.teal
                              ])
                                SizedBox(
                                  height: sizePickColor,
                                  width: sizePickColor,
                                  child: ElevatedButton(
                                    onPressed: () {
                                      _setColor(color);
                                      _preColor = _paintColor;
                                    },
                                    style: ElevatedButton.styleFrom(
                                        padding: EdgeInsets.zero,
                                        minimumSize: const Size(
                                            sizePickColor, sizePickColor),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                              5), // Border radius là 5
                                        ),
                                        backgroundColor: color),
                                    child: const SizedBox(
                                      width: sizePickColor,
                                      // Kích thước của hình vuông
                                      height: sizePickColor,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    )
                  ],
                )),
          ),
        if (_isSizeMenuVisible)
          Positioned(
            left: 10,
            bottom: widget.selectedRoom.mode == 'Vẽ và đoán' ? 195 : 100,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    SizedBox(
                      width: _calculateCirclePosition(
                              MediaQuery.of(context).size.width) +
                          20 -
                          0,
                    ),
                    Container(
                      alignment: Alignment.center,
                      width: _currentSliderValue * 2,
                      height: _currentSliderValue * 2,
                      decoration: BoxDecoration(
                        color: _paintColor,
                        shape: BoxShape.circle,
                      ),
                      /*child:Text(
                        _currentSliderValue.round().toString(),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                        ),
                      ),*/
                    ),
                  ],
                ),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(7.0),
                  ),
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width - 20,
                    child: Slider(
                      activeColor: _paintColor,
                      inactiveColor: _paintColor.withOpacity(0.3),
                      value: _currentSliderValue,
                      min: 5,
                      max: 30,
                      divisions: 30 - 5 + 1,
                      //label: _currentSliderValue.round().toString(),
                      onChanged: (double value) {
                        setState(() {
                          _currentSliderValue = value.roundToDouble();
                          _setPainSize(value);
                        });
                      },
                      onChangeEnd: (double value) {
                        _toggleSizeMenuVisibility(Offset.zero);
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        if (_isSelectMenuVisible)
          Positioned(
            left: 10,
            right: 10,
            bottom: widget.selectedRoom.mode == 'Vẽ và đoán' ? 200 : 105,
            child: Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: Colors.black12,
                  borderRadius: BorderRadius.circular(5.0),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    // undo
                    iconMenu(
                        icon: Image.asset('assets/images/undo.png',
                            width: 30, height: 30),
                        onPressed: () {
                          _paintBoardKey.currentState!.ctrlZ();
                        }),
                    // redo
                    iconMenu(
                        icon: Image.asset('assets/images/redo.png',
                            width: 30, height: 30),
                        onPressed: () {
                          _paintBoardKey.currentState!.ctrlY();
                        }),
                    // draw
                    iconMenu(
                        icon: const Icon(Icons.draw,
                            size: 35, color: Colors.black),
                        onPressed: () {
                          _isErase = false;
                          _setSelectIcon(Icons.draw);
                          _toggleSelectMenuVisibility(const Offset(0, 0));
                          _setColor(_preColor);
                          _setChose("Draw");
                        }),
                    // draw line
                    iconMenu(
                        icon: Image.asset('assets/images/draw_line.png',
                            width: 35, height: 35),
                        onPressed: () {
                          _isErase = false;
                          _setSelectIcon(Icons.minimize);
                          _toggleSelectMenuVisibility(const Offset(0, 0));
                          _setChose("DrawLine");
                          _setColor(_preColor);
                        }),
                    // erase
                    iconMenu(
                        icon: Image.asset('assets/images/erase.png'),
                        onPressed: () {
                          _preColor = _paintColor;
                          _setColor(Theme.of(context).scaffoldBackgroundColor);
                          _setSelectIcon(Icons.add);
                          _toggleSelectMenuVisibility(const Offset(0, 0));
                          _isErase = true;
                          _setChose("Draw");
                        }),
                    // clear
                    iconMenu(
                        icon: const Icon(Icons.delete,
                            size: 35, color: Colors.black),
                        onPressed: () {
                          _paintBoardKey.currentState!.clearPoints();
                          _isErase = false;
                        }),
                  ],
                )),
          ),
      ],
    ));
  }

  double _calculateCirclePosition(double sliderWidth) {
    double circleRadius = _currentSliderValue; // Bán kính của hình tròn
    double circleDiameter = circleRadius * 2;
    double availableWidth = sliderWidth - circleDiameter - 28;
    double position = (_currentSliderValue - 5) / (30 - 5) * availableWidth;

    print('_currentSliderValue: $_currentSliderValue');
    print('availableWidth: $availableWidth');
    print('position: $position');
    return position;
  }
}

class PaintBoard extends ConsumerStatefulWidget {
  //final GlobalKey<_PaintBoardState> key;
  final String chose;
  final Color paintColor;
  final double paintSize;
  final double height;
  final double width;
  final Room selectedRoom;
  final void Function() hideMenu;
  final void Function(bool) toggleDrawBar;

  const PaintBoard({
    super.key,
    required this.chose,
    required this.height,
    required this.width,
    required this.paintColor,
    required this.paintSize,
    required this.selectedRoom,
    required this.hideMenu,
    required this.toggleDrawBar,
  });

  @override
  createState() => _PaintBoardState();
}

class _PaintBoardState extends ConsumerState<PaintBoard> {
  late List<List<Offset>> points = [];
  late List<Paint> paints = [];
  late List<Offset> tmp = [];
  late Queue<List<Offset>> Qpn = Queue<List<Offset>>();
  late Queue<Paint> Qpt = Queue<Paint>();
  late bool isDrawLine = false;
  late DatabaseReference _drawingRef;
  late DatabaseReference _playersInRoomRef;
  late DatabaseReference _normalModeDataRef;
  late DatabaseReference _knockoffModeDataRef;
  late DatabaseReference _masterpieceModeDataRef;
  late DatabaseReference _myDataRef;
  late final List<User> _playersInRoom = [];
  late List<String> _playersInRoomId = [];
  late int _countTurn = 1;
  late int _indexCurrent = 0;
  late int _currentTurn = 1;
  late int _playerDone = 0;
  late bool _canEdit = true;
  var userTurn = "";
  var _timeLeft = -1;

  @override
  initState() {
    super.initState();

    // setup cho chế độ thường
    if (widget.selectedRoom.mode == 'Vẽ và đoán') {
      _drawingRef = database
          .child('/normal_mode_data/${widget.selectedRoom.roomId}/draw');
      _normalModeDataRef =
          database.child('/normal_mode_data/${widget.selectedRoom.roomId}');

      _knockoffModeDataRef =
          database.child('/knockoff_mode_data/${widget.selectedRoom.roomId}');

      _normalModeDataRef.onValue.listen((event) {
        final data = Map<String, dynamic>.from(
          event.snapshot.value as Map<dynamic, dynamic>,
        );
        setState(() {
          userTurn = data['turn'];
        });

        // Xóa bảng và Ẩn menu khi có người đoán đúng
        _timeLeft = data['timeLeft'];
        if (_timeLeft == widget.selectedRoom.timePerRound) {
          clearPoints();
          widget.hideMenu();
        }
      });

      _drawingRef.onValue.listen((event) async {
        // Khi có sự thay đổi dữ liệu trên Firebase
        if (event.snapshot.value == null) {
          clearPoints();
        }

        if (userTurn != ref.read(userProvider).id) {
          if (event.snapshot.value is Map) {
            final data = (event.snapshot.value as Map).map((key, value) {
              return MapEntry(key.toString(), value.toString());
            });
            setState(() {
              points = decodeOffsetList(data["Offset"]!);
              paints = decodePaintList(data["Color"]!);
            });
          }
        }
      });
    }

    // Setup cho chế độ tam sao thất bản
    if (widget.selectedRoom.mode == 'Tam sao thất bản') {
      _playersInRoomRef =
          database.child('/players_in_room/${widget.selectedRoom.roomId}');
      _myDataRef = database.child(
          '/knockoff_mode_data/${widget.selectedRoom.roomId}/${ref.read(userProvider).id}');
      _knockoffModeDataRef =
          database.child('/knockoff_mode_data/${widget.selectedRoom.roomId}');

      _playersInRoomRef.onValue.listen((event) {
        final data = Map<String, dynamic>.from(
          event.snapshot.value as Map<dynamic, dynamic>,
        );
        _playersInRoom.clear();
        var index = 0;
        for (final player in data.entries) {
          if (player.key == ref.read(userProvider).id) {
            _indexCurrent = index;
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

      _knockoffModeDataRef.onValue.listen((event) async {
        final data = Map<String, dynamic>.from(
          event.snapshot.value as Map<dynamic, dynamic>,
        );
        setState(() {
          _countTurn = data['turn'] as int;
          _playerDone = data['playerDone'] as int;
        });
        bool isNextTurn = (_currentTurn == _countTurn);

        for (var player in _playersInRoomId) {
          if (data[player]["timeLeft"] > 0) {
            isNextTurn = false;
            break;
          }
        }

        // Giai đoạn vẽ
        if (_currentTurn % 2 == 0 && _countTurn != _currentTurn) {
          await _myDataRef.update({
            "timeLeft": widget.selectedRoom.timePerRound,
          });
          widget.toggleDrawBar(true);
          _currentTurn = _countTurn;
          clearPoints();
          _canEdit = (_currentTurn % 2 != 0);
          if (!_canEdit) {
            showPicture();
          }
        }

        // Giai đoạn xem
        if (_currentTurn % 2 == 1 && _countTurn != _currentTurn) {
          await _myDataRef.update({
            "timeLeft": 10,
          });
          _currentTurn = _countTurn;
          clearPoints();
          _canEdit = (_currentTurn % 2 != 0);
          if (!_canEdit) {
            showPicture();
          }
        }

        // Chủ phòng chuyển turn khi tất cả người chơi đã vẽ xong
        if (_currentTurn == _countTurn && isNextTurn) {
          if (ref.read(userProvider).id == widget.selectedRoom.roomOwner) {
            await _knockoffModeDataRef.update({
              'turn': _currentTurn + 1,
              "playerDone": 0,
            });
          }
        }
      });

      _myDataRef.onValue.listen((event) async {
        final data = Map<String, dynamic>.from(
          event.snapshot.value as Map<dynamic, dynamic>,
        );
        _timeLeft = data['timeLeft'];
        // Hết thời gian vẽ
        if (_timeLeft == 0) {
          if (_currentTurn % 2 == 1) {
            updatePointsKnockoffMode(
              _knockoffModeDataRef.child(
                  '/${_playersInRoom[(_indexCurrent + (_currentTurn ~/ 2)) % _playersInRoom.length].id}/album/'),
            );
          }
          await _myDataRef.update({
            'timeLeft': -1,
          });

          await _knockoffModeDataRef.update({
            'playerDone': _playerDone + 1,
          });
        }
        // đã vẽ xong và gửi lên firebase hoàn tất thì:
        if (_timeLeft == -1) {
          widget.hideMenu();
          widget.toggleDrawBar(false);
        }
      });
    }

    // setup cho chế độ tuyệt tác
    if (widget.selectedRoom.mode == 'Tuyệt tác') {
      _playersInRoomRef =
          database.child('/players_in_room/${widget.selectedRoom.roomId}');
      _myDataRef = database.child(
          '/knockoff_mode_data/${widget.selectedRoom.roomId}/${ref.read(userProvider).id}');
      _masterpieceModeDataRef = database
          .child('/masterpiece_mode_data/${widget.selectedRoom.roomId}');
      _masterpieceModeDataRef.onValue.listen((event) async {
        final data = Map<String, dynamic>.from(
          event.snapshot.value as Map<dynamic, dynamic>,
        );
        _timeLeft = data['timeLeft'];

        // Hết thời gian vẽ
        if (_timeLeft == 0) {
          updatePointsMasterPieceMode(ref.read(userProvider).id!);
        }
      });
    }
  }

  Future<void> showPicture() async {
    // Hết lượt vẽ, xem album
    if (_currentTurn >= _playersInRoom.length * 2) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
            builder: (context) => KnockoffModeAlbum(
                  selectedRoom: widget.selectedRoom,
                )),
        (route) => false,
      );
      return;
    }

    try {
      DatabaseReference drawTurn = _knockoffModeDataRef.child(
          '${_playersInRoom[(_indexCurrent + (_currentTurn ~/ 2)) % _playersInRoom.length].id}');

      DataSnapshot snapshot = await drawTurn.get();
      if (snapshot.exists) {
        final Map<String, dynamic> data;
        final Map<String, dynamic> album;
        final Map<String, dynamic> picture;
        if (Platform.isIOS) {
          data = Map<String, dynamic>.from(snapshot.value as Map);
          album = Map<String, dynamic>.from(data[_playersInRoom[
                  (_indexCurrent + (_currentTurn ~/ 2)) % _playersInRoom.length]
              .id]["album"] as Map);
          picture = Map<String, dynamic>.from(
              album["Turn ${_currentTurn - 1}"] as Map);
        } else {
          data = Map<String, dynamic>.from(snapshot.value as Map);
          album = Map<String, dynamic>.from(data["album"] as Map);
          picture = Map<String, dynamic>.from(
              album["Turn ${_currentTurn - 1}"] as Map);
        }
        points = decodeOffsetList(picture["Offset"]!);
        paints = decodePaintList(picture["Color"]!);
      } else {
        print('No data available.');
      }
    } catch (error) {
      print('Lỗi: $error');
    }
  }

  bool isInBox(Offset point) {
    return point.dx >= 0 &&
        point.dy >= 0 &&
        point.dx <= widget.width &&
        point.dy <= widget.height;
  }

  Offset setValid(Offset point) {
    double x = point.dx, y = point.dy;
    if (point.dx < 0) x = 0;
    if (point.dy < 0) y = 0;
    if (point.dx > widget.width - 2) x = widget.width - 2;
    if (point.dy > widget.height - 2) y = widget.height - 2;
    Offset res = Offset(x, y);
    return res;
  }

  void clearPoints() {
    setState(() {
      points.clear();
      tmp.clear();
      paints.clear();
      updatePointsNormalMode();
    });
  }

  void ctrlZ() {
    setState(() {
      if (points.isEmpty) return;
      if (paints.isEmpty) return;
      Qpn.add(points[points.length - 1]);
      Qpt.add(paints[paints.length - 1]);
      points.removeLast();
      paints.removeLast();

      updatePointsNormalMode();
    });
  }

  void ctrlY() {
    setState(() {
      if (Qpt.isEmpty || Qpt.isEmpty) return;
      if (Qpn.isEmpty || Qpn.isEmpty) return;
      points.add(Qpn.last);
      paints.add(Qpt.last);
      Qpn.removeLast();
      Qpt.removeLast();

      updatePointsNormalMode();
    });
  }

  String encodeOffsetList(List<List<Offset>> offsetList) {
    List<List<double>> encodedList = [];
    for (var innerList in offsetList) {
      List<double> tempList = [];
      for (var offset in innerList) {
        tempList.add(offset.dx);
        tempList.add(offset.dy);
      }
      encodedList.add(tempList);
    }
    return json.encode(encodedList);
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

  // Hàm encode List<Paint> thành chuỗi JSON
  String encodePaintList(List<Paint> paintList) {
    List<Map<String, dynamic>> encodedList = paintList.map((paint) {
      return {
        'color': paint.color.value,
        'strokeWidth': paint.strokeWidth,
        'strokeCap': paint.strokeCap
            .toString()
            .split('.')
            .last, // Convert StrokeCap to string
        // Add other properties if needed
      };
    }).toList();
    return json.encode(encodedList);
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

  void updatePointsNormalMode() async {
    List<List<Offset>> fbpush = points;
    if (tmp.isNotEmpty) fbpush.add(tmp);

    await _drawingRef.update(
        {'Offset': encodeOffsetList(fbpush), 'Color': encodePaintList(paints)});
  }

  void updatePointsKnockoffMode(DatabaseReference ref) async {
    List<List<Offset>> fbpush = points;
    if (tmp.isNotEmpty) fbpush.add(tmp);

    await ref.update({
      "Turn $_currentTurn": {
        'Offset': encodeOffsetList(fbpush),
        'Color': encodePaintList(paints)
      }
    });
  }

  void updatePointsMasterPieceMode(String id) async {
    List<List<Offset>> fbpush = points;
    if (tmp.isNotEmpty) fbpush.add(tmp);

    await _masterpieceModeDataRef.child('/album/$id').update(
        {'Offset': encodeOffsetList(fbpush), 'Color': encodePaintList(paints)});
    await _masterpieceModeDataRef.update({
      'uploadDone': true,
    });
  }

  @override
  Widget build(BuildContext context) {
    String chose = widget.chose;

    bool canEdit() {
      switch (widget.selectedRoom.mode) {
        case 'Vẽ và đoán':
          if (userTurn != ref.read(userProvider).id) return false;
          break;
        case 'Tam sao thất bản':
          if (_currentTurn % 2 == 0) return false;
          break;
        case 'Tuyệt tác':
          break;
      }
      return true;
    }

    return GestureDetector(
      onPanDown: (DragDownDetails details) {
        // Kiểm tra xem có thể vẽ không
        if (!canEdit()) return;

        // Ẩn menu khi bắt đầu vẽ
        widget.hideMenu();

        setState(() {
          if (chose == "Fill") {
            RenderBox renderBox = context.findRenderObject() as RenderBox;
          } else {
            Paint paint = Paint()
              ..color = widget.paintColor
              ..strokeCap = StrokeCap.round
              ..strokeWidth = widget.paintSize;
            paints.add(paint);
            RenderBox renderBox = context.findRenderObject() as RenderBox;
            Offset pos = renderBox.globalToLocal(details.globalPosition);
            // points[cnt].add(setValid(pos));
            tmp.add(setValid(pos));
            //updatePointsNormalMode();

            Qpn.clear();
            Qpt.clear();
          }
        });
      },
      onPanUpdate: (DragUpdateDetails details) {
        // Kiểm tra xem có thể vẽ không
        if (!canEdit()) return;

        setState(() {
          if (chose == "Draw") {
            RenderBox renderBox = context.findRenderObject() as RenderBox;
            Offset pos = renderBox.globalToLocal(details.globalPosition);
            tmp.add(setValid(pos));
            //updatePointsNormalMode();
            // points[cnt].add(setValid(pos));
          } else if (chose == "DrawLine") {
            if (tmp.length > 1) tmp.removeLast();
            RenderBox renderBox = context.findRenderObject() as RenderBox;
            Offset pos = renderBox.globalToLocal(details.globalPosition);
            tmp.add(setValid(pos));
            //updatePointsNormalMode();
          }
        });
      },
      onPanEnd: (DragEndDetails details) {
        // Kiểm tra xem có thể vẽ không
        if (!canEdit()) return;

        // if(chose == "Draw")
        setState(() {
          tmp.add(const Offset(-1, -1));
          points.add(List.of(tmp));
          tmp.clear();
          updatePointsNormalMode();
        });

        // points[cnt].add(Offset(-1, -1));
      },
      child: CustomPaint(
        painter: PaintCanvas(points: points, tmp: tmp, paints: paints),
        size: Size.infinite,
      ),
    );
  }
}

class PaintCanvas extends CustomPainter {
  final List<List<Offset>> points;
  final List<Offset> tmp;
  final List<Paint> paints;

  PaintCanvas({required this.points, required this.tmp, required this.paints});

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..color = Colors.black
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 5.0;
    for (int i = 0; i < points.length; i++) {
      for (int j = 0; j < points[i].length - 1; j++) {
        if (points[i][j].dx != -1 && points[i][j + 1].dx != -1) {
          canvas.drawLine(points[i][j], points[i][j + 1], paints[i]);
        }
      }
    }
    Paint paint2 = Paint()
      ..color = Colors.blue
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 8.0;
    for (int j = 0; j < tmp.length - 1; j++) {
      if (tmp[j].dx != -1 && tmp[j + 1].dx != -1) {
        canvas.drawLine(tmp[j], tmp[j + 1], paints[paints.length - 1]);
      }
    }
  }

  @override
  bool shouldRepaint(PaintCanvas oldDelegate) => true;
}
