import 'package:draw_and_guess_promax/Widget/play_mode_detail.dart';
import 'package:draw_and_guess_promax/data/play_mode_data.dart';
import 'package:flutter/material.dart';

class HowToPlay extends StatefulWidget {
  const HowToPlay({super.key});

  @override
  State<HowToPlay> createState() => _HowToPlayState();
}

class _HowToPlayState extends State<HowToPlay>
    with SingleTickerProviderStateMixin {
  void _onCloseClick(context) {
    Navigator.pop(context);
  }

  final _isExpanded = availablePlayMode.map((e) => false).toList();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
          gradient: LinearGradient(
              begin: Alignment(0.00, -1.00),
              end: Alignment(0, 1),
              colors: [Color(0xFF00C4A0), Color(0xFFD05700)])),
      child: Stack(
        children: [
          Positioned(
            top: 60,
            left: 0,
            right: 0,
            child: Center(
              child: Column(
                children: [
                  Text(
                    'CÁCH CHƠI',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge!
                        .copyWith(color: Colors.white),
                  ),
                  Text(
                    'Nhấn vào để xem chi tiết',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall!
                        .copyWith(color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: 110,
            left: 0,
            right: 0,
            bottom: 80,
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Column(
                  children: [
                    // Chế độ 1
                    for (var i = 0; i < availablePlayMode.length; i++)
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _isExpanded[i] = !_isExpanded[i];
                          });
                        },
                        child: AnimatedSize(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOutCubic,
                          alignment: Alignment.topCenter,
                          child: Center(
                            child: PlayModeDetail(
                              mode: availablePlayMode[i].mode,
                              description: availablePlayMode[i].description,
                              howToPlay: availablePlayMode[i].howToPlay,
                              isVisible: _isExpanded[i],
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 200),
                  ],
                ),
              ),
            ),
          ),
          // Nút ok
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Center(
              child: ElevatedButton(
                onPressed: () {
                  _onCloseClick(context);
                },
                style: ElevatedButton.styleFrom(
                  fixedSize: const Size(150, 150),
                  backgroundColor: const Color.fromARGB(0, 0, 0, 0),
                  shadowColor: const Color.fromARGB(0, 0, 0, 0),
                  surfaceTintColor: const Color.fromARGB(0, 0, 0, 0),
                ),
                child: Image.asset('assets/images/ok.png'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
