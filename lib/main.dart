import 'dart:io';

import 'package:draw_and_guess_promax/Screen/Ranking.dart';
import 'package:draw_and_guess_promax/Screen/home_page.dart';
import 'package:draw_and_guess_promax/Screen/waiting_room.dart';
import 'package:draw_and_guess_promax/model/room.dart';
import 'package:draw_and_guess_promax/theme.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';


void main() async {
  // Kết nối Firebase
  WidgetsFlutterBinding.ensureInitialized();
  if (Platform.isAndroid) {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: 'AIzaSyAN5w4LhO_J86gaM530epJOtprZ0QAOjdc',
        appId: '1:289465409378:android:348e2044d1f7d800de163b',
        messagingSenderId: '289465409378',
        projectId: 'draw-and-guest',
        storageBucket: 'draw-and-guest.appspot.com',
        databaseURL: 'https://draw-and-guest-default-rtdb.asia-southeast1.firebasedatabase.app',
      ),
    );
  } else if (Platform.isIOS) {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: 'AIzaSyAN5w4LhO_J86gaM530epJOtprZ0QAOjdc',
        appId: '1:289465409378:ios:e201c7f592add358de163b',
        messagingSenderId: '289465409378',
        projectId: 'draw-and-guest',
        storageBucket: 'draw-and-guest.appspot.com',
        databaseURL: 'https://draw-and-guest-default-rtdb.asia-southeast1.firebasedatabase.app',
        iosBundleId: 'com.your.bundle.id',  // Thêm iosBundleId nếu cần
      ),
    );
  }
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(const ProviderScope(child: DrawAndGuestApp()));
}

class DrawAndGuestApp extends StatefulWidget {
  const DrawAndGuestApp({super.key});

  @override
  State<DrawAndGuestApp> createState() => _DrawAndGuestAppState();
}

class _DrawAndGuestAppState extends State<DrawAndGuestApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    print('=====================${state.toString()}================');

    if (state == AppLifecycleState.detached ||
        state == AppLifecycleState.inactive) {
      _performCleanup();
    }
  }

  void _performCleanup() {
    // Thực hiện các hành động cần thiết khi ứng dụng đóng
    print('[Fake] Ứng dụng đang đóng, thực hiện callback...');
    // Ví dụ: Lưu trạng thái, gửi dữ liệu lên server, v.v.
  }

  @override
  Widget build(BuildContext context) {
    Widget content = const HomePage();

    return MaterialApp(
      theme: AppTheme.lightTheme,
      home: Scaffold(body: content),
      routes: {
        '/ranking': (context) => Ranking(selectedRoom: ModalRoute.of(context)?.settings.arguments as Room),
        '/waiting': (context) => WaitingRoom(selectedRoom: ModalRoute.of(context)?.settings.arguments as Room)
      },
    );
  }
}
