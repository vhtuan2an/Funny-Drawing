import 'package:flutter/material.dart';

class PlayModeDetail extends StatelessWidget {
  const PlayModeDetail({
    super.key,
    required this.mode,
    required this.description,
    required this.howToPlay,
    required this.isVisible,
  });

  final String mode;
  final String description;
  final String howToPlay;
  final bool isVisible;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          Row(
            children: [
              SizedBox(
                height: 110,
                width: 110,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Image.asset(mode == 'Vẽ và đoán'
                      ? 'assets/images/thuong_mode.png'
                      : mode == 'Tam sao thất bản'
                          ? 'assets/images/tam_sao_that_ban_mode.png'
                          : 'assets/images/tuyet_tac_mode.png'),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: SizedBox(
                  width: MediaQuery.of(context).size.width - 150,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        mode,
                        style: Theme.of(context).textTheme.titleLarge!.copyWith(
                              color: Colors.black,
                            ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        description,
                        style: Theme.of(context).textTheme.bodySmall!.copyWith(
                              color: Colors.black,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          AnimatedOpacity(
            duration: const Duration(milliseconds: 600),
            // Thời gian của hiệu ứng fade in
            opacity: isVisible ? 1.0 : 0.0,
            // Thiết lập độ mờ của widget
            curve: Curves.easeIn,
            child: Visibility(
              visible: isVisible,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cách chơi:',
                      style: Theme.of(context).textTheme.titleMedium!.copyWith(
                            color: Colors.black,
                          ),
                    ),
                    const SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 15),
                      child: Text(
                        howToPlay,
                        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                              color: Colors.black,
                            ),
                        textAlign: TextAlign.justify,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
