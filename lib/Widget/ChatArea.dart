import 'dart:async';

import 'package:draw_and_guess_promax/Widget/chat_list.dart';
import 'package:draw_and_guess_promax/provider/chat_provider.dart';
import 'package:draw_and_guess_promax/provider/user_provider.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/word_to_guess.dart';
import '../firebase.dart';

class ChatArea extends ConsumerStatefulWidget {
  const ChatArea({
    super.key,
    required this.roomId,
    required this.width,
  });

  final String roomId;
  final double width;

  @override
  createState() => _ChatAreaState();
}

class _ChatAreaState extends ConsumerState<ChatArea> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  late DatabaseReference _chatRef;
  late DatabaseReference _normalModeDataRef;
  late DatabaseReference _roomRef;
  late DatabaseReference _playerInRoomIDRef;
  late DatabaseReference _playersInRoomRef;
  late bool _isEnable;

  final ScrollController _scrollController = ScrollController();
  var wordToGuess = '';
  var _pointLeft = 0;
  var curPoint = 0;
  late String roomOwnerId;
  late StreamSubscription<bool> keyboardSubscription;

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    keyboardSubscription.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // Mở bàn phím
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(_focusNode);
    });

    // Lắng nghe sự thay đổi trạng thái bàn phím
    var keyboardVisibilityController = KeyboardVisibilityController();
    keyboardSubscription =
        keyboardVisibilityController.onChange.listen((bool visible) {
      if (visible) {
        // Cuộn xuống cuối danh sách khi bàn phím mở
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent +
                MediaQuery.of(context).viewInsets.bottom,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        });
      }
    });

    _chatRef = database.child('/normal_mode_data/${widget.roomId}/chat/');
    _normalModeDataRef = database.child('/normal_mode_data/${widget.roomId}');
    _roomRef = database.child('/rooms/${widget.roomId}');
    _playerInRoomIDRef = database.child(
        '/players_in_room/${widget.roomId}/${ref.read(userProvider).id}');
    _playersInRoomRef = database.child('/players_in_room/${widget.roomId}');

    _roomRef.get().then((value) {
      final data = Map<String, dynamic>.from(
        value.value as Map<dynamic, dynamic>,
      );
      roomOwnerId = data['roomOwner'];
    });

    _normalModeDataRef.onValue.listen((event) {
      final data = Map<String, dynamic>.from(
        event.snapshot.value as Map<dynamic, dynamic>,
      );
      wordToGuess = data['wordToDraw'];
      _pointLeft = data['point'];
    });

    _chatRef.onValue.listen((event) {
      final data = Map<String, dynamic>.from(
        event.snapshot.value as Map<dynamic, dynamic>,
      );

      final newChat = data.entries.map((e) {
        return {
          'id': e.value['id'],
          "userName": e.value['userName'],
          'avatarIndex': e.value['avatarIndex'],
          "message": e.value['message'],
          "timestamp": e.value['timestamp'],
        };
      }).toList();

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
    _isEnable = true;
  }

  @override
  Widget build(BuildContext context) {
    final width = widget.width;
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
              widget.roomId,
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
          ref.read(chatProvider.notifier).addMessage('system',
              '$userName đã đoán đúng', 'Hệ thống', widget.roomId, -1);
          _controller.clear();
          FocusScope.of(context).unfocus();
          Navigator.of(context).pop();
        }
      }
    }

    return SizedBox(
      width: width,
      child: Column(
        children: [
          Expanded(
            child: Container(
                padding: const EdgeInsets.all(15),
                width: width,
                child: ChatList(
                  scrollController: _scrollController,
                  chatMessages: chatMessages,
                )),
          ),
          Container(
            padding: const EdgeInsets.only(left: 15, right: 15, bottom: 15),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    // enabled: _isEnable,
                    controller: _controller,
                    focusNode: _focusNode,
                    decoration: InputDecoration(
                      hintText: 'Nhập đáp án',
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
                    onPressed: () {
                      onSubmitted();
                    },
                    icon: Image.asset('assets/images/send.png'),
                    iconSize: 45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
