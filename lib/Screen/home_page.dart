import 'dart:async';
import 'dart:math';

import 'package:draw_and_guess_promax/Screen/master_piece_mode_rank.dart';
import 'package:draw_and_guess_promax/Widget/pick_avatar_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../Widget/button.dart';
import '../animation.dart';
import '../firebase.dart';
import '../model/room.dart';
import '../provider/user_provider.dart'; // Đảm bảo bạn import user_provider đúng cách
import 'create_room.dart';
import 'find_room.dart';
import 'how_to_play.dart';
import 'more_drawer.dart';

Random random = Random();

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  final TextEditingController _textEditingController = TextEditingController();
  var _avatarIndex = random.nextInt(13);
  var _isWaitingFindRoom = false;
  var _isWaitingCreateRoom = false;

  // Tạo một GlobalKey cho Scaffold
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  Timer? _timer;
  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  // Lấy dữ liệu từ SharedPreferences
  Future<void> _loadUser() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool hasData = prefs.getBool('hasData') ?? false;
    if (hasData) {
      String? id = prefs.getString('id');
      String? name = prefs.getString('name');
      int? avatarIndex = prefs.getInt('avatarIndex');

      if (id != null && name != null && avatarIndex != null) {
        ref
            .watch(userProvider.notifier)
            .updateUser(id: id, name: name, avatarIndex: avatarIndex);
        _textEditingController.text = name;
        setState(() {
          _avatarIndex = avatarIndex;
        });
      }
    }
  }

  Future<void> _setUser({bool secret = false}) async {
    final user = ref.watch(userProvider);
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool('hasData', true);
    if (secret) {
      var newId = 'admin-${await _getRandomId()}';
      while (newId.substring(0, 12) == 'admin-admin-') {
        newId = newId.substring(6, newId.length);
      }
      prefs.setString('id', newId);
    } else {
      prefs.setString('id', user.id ?? await _getRandomId());
    }
    prefs.setInt('avatarIndex', _avatarIndex);
    prefs.setString('name', user.name);
  }

  Future<String> _getRandomId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? id = prefs.getString('id');
    if (id == null) {
      id = uuid.v4();
      prefs.setString('id', id);
    }
    return id;
  }

  void _onMoreClick(context) {
    _scaffoldKey.currentState?.openDrawer();
  }

  void _onInformationClick(context) {
    Navigator.of(context).push(
      createRouteRightToLeftTransition(
        oldPage: widget,
        newPage: const HowToPlay(),
      ),
    );
  }

  void _findRoomClick(context) async {
    String name = _textEditingController.text;
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng nhập tên của bạn'),
        ),
      );
      return;
    }
    setState(() {
      _isWaitingFindRoom = true;
    });

    final userNotifier = ref.watch(userProvider.notifier);
    userNotifier.updateUser(
        id: await _getRandomId(), name: name, avatarIndex: _avatarIndex);
    await _setUser();

    final user = ref.watch(userProvider);
    final usersRef = database.child('/users/${user.id}');
    await usersRef.update({'name': name, 'avatarIndex': _avatarIndex});

    //Navigator.of(context).push(createRouteBottomToTopTransition(oldPage: widget, newPage: const FindRoom()));
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (ctx) => const FindRoom()));
    setState(() {
      _isWaitingFindRoom = false;
    });
  }

  void _createRoomClick(context) async {
    String name = _textEditingController.text;
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng nhập tên của bạn'),
        ),
      );
      return;
    }
    setState(() {
      _isWaitingCreateRoom = true;
    });

    final userNotifier = ref.watch(userProvider.notifier);
    userNotifier.updateUser(
        id: await _getRandomId(), name: name, avatarIndex: _avatarIndex);
    await _setUser();

    final user = ref.watch(userProvider);
    final usersRef = database.child('/users/${user.id}');
    await usersRef.update({'name': name, 'avatarIndex': _avatarIndex});

    Navigator.of(context)
        .push(MaterialPageRoute(builder: (ctx) => const CreateRoom()));
    setState(() {
      _isWaitingCreateRoom = false;
    });
  }

  void _pickAvatar(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final width = MediaQuery.of(context).size.width * 0.1;
        final height = MediaQuery.of(context).size.height * 0.15;
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: width, vertical: height),
          child: PickAvatarDialog(onPick: (index) {
            setState(() {
              _avatarIndex = index;
              _setUser();
            });
            Navigator.of(context).pop();
          }),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: Drawer(
        surfaceTintColor: Colors.transparent,
        child: MoreDrawer(
          onHowToPlayClick: () {
            Navigator.of(context).pop();
            Future.delayed(const Duration(milliseconds: 250), () {
              Navigator.of(context).push(
                createRouteRightToLeftTransition(
                  oldPage: widget,
                  newPage: const HowToPlay(),
                ),
              );
            });
          },
        ),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment(0.00, -1.00),
            end: Alignment(0, 1),
            colors: [Color(0xFF00C4A0), Color(0xFFD05700)],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: 100,
              left: 0,
              right: 0,
              child: Center(
                child: SizedBox(
                  height: 120,
                  child: Image.asset('assets/images/new_logo.png'),
                ),
              ),
            ),
            Positioned(
              top: 35,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      if (!_isWaitingFindRoom && !_isWaitingCreateRoom) {
                        _onMoreClick(context);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      fixedSize: const Size(90, 90),
                      backgroundColor: const Color.fromARGB(0, 0, 0, 0),
                      shadowColor: const Color.fromARGB(0, 0, 0, 0),
                      surfaceTintColor: const Color.fromARGB(0, 0, 0, 0),
                    ),
                    child: Image.asset('assets/images/more.png'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      if (!_isWaitingFindRoom && !_isWaitingCreateRoom) {
                        _onInformationClick(context);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      fixedSize: const Size(90, 90),
                      backgroundColor: const Color.fromARGB(0, 0, 0, 0),
                      shadowColor: const Color.fromARGB(0, 0, 0, 0),
                      surfaceTintColor: const Color.fromARGB(0, 0, 0, 0),
                    ),
                    child: Image.asset('assets/images/information.png'),
                  ),
                ],
              ),
            ),
            Positioned(
              top: 220,
              left: 20,
              right: 20,
              child: Container(
                width: 310,
                height: 250,
                decoration: ShapeDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment(0.00, -1.00),
                    end: Alignment(0, 1),
                    colors: [Color(0xFFD6FFBE), Color(0xFFC29191)],
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 5),
                    InkWell(
                      onTap: () {
                        if (!_isWaitingFindRoom && !_isWaitingCreateRoom) {
                          _pickAvatar(context);
                        }
                      },
                      onTapDown: (details) {
                        _timer = Timer(const Duration(seconds: 5), () async {
                          await _setUser(secret: true);
                          const snackBar = SnackBar(
                            content: Text('Đã là admin'),
                            duration: Duration(seconds: 1),
                          );
                          ScaffoldMessenger.of(context).showSnackBar(snackBar);
                        });
                      },
                      onTapUp: (details) {
                        _timer?.cancel();
                      },
                      onTapCancel: () {
                        _timer?.cancel();
                      },
                      child: Container(
                        width: 123.20,
                        height: 123.20,
                        decoration: ShapeDecoration(
                          image: DecorationImage(
                            image: AssetImage(
                                'assets/images/avatars/avatar$_avatarIndex.png'),
                            fit: BoxFit.fill,
                          ),
                          shape: const CircleBorder(),
                        ),
                        child: Stack(
                          children: [
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: SizedBox(
                                width: 40,
                                height: 40,
                                child: IconButton(
                                  icon: Image.asset('assets/images/edit.png'),
                                  onPressed: () {
                                    if (!_isWaitingFindRoom &&
                                        !_isWaitingCreateRoom) {
                                      _pickAvatar(context);
                                    }
                                  },
                                  padding: const EdgeInsets.all(0),
                                ),
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: TextField(
                        enabled: !_isWaitingFindRoom && !_isWaitingCreateRoom,
                        controller: _textEditingController,
                        decoration: InputDecoration(
                          hintText: 'Tên của bạn',
                          hintStyle: const TextStyle(color: Colors.white),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: Colors.white),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: Colors.white),
                          ),
                        ),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 470 +
                  (MediaQuery.of(context).size.height - 470) / 2 -
                  120 / 2,
              left: 0,
              right: 0,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Hero(
                    tag: 'find_room',
                    child: Button(
                      onClick: _findRoomClick,
                      imageAsset: 'assets/images/search.png',
                      title: 'Tìm phòng',
                      isWaiting: _isWaitingFindRoom,
                      isEnable: !_isWaitingFindRoom && !_isWaitingCreateRoom,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Hero(
                    tag: 'create_room',
                    child: Button(
                      onClick: _createRoomClick,
                      imageAsset: 'assets/images/plus.png',
                      title: 'Tạo phòng',
                      isWaiting: _isWaitingCreateRoom,
                      isEnable: !_isWaitingFindRoom && !_isWaitingCreateRoom,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
