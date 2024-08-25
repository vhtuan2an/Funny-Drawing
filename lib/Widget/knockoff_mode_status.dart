import 'package:flutter/material.dart';

class KnockoffModeStatus extends StatelessWidget {
  const KnockoffModeStatus({
    super.key,
    required this.timeLeft,
    required this.turn,
  });

  final int timeLeft;
  final int turn;

  @override
  Widget build(BuildContext context) {
    final isFirstRound = turn == 1;
    final isDrawingRound = turn % 2 == 1;
    final isRememberRound = turn % 2 == 0;
    final isWaiting = timeLeft <= 0;
    final String text;
    final String image;
    if (isFirstRound) {
      text = 'Hãy vẽ bất cứ thứ gì bạn thích';
      image = 'assets/images/color-palette.png';
    } else if (isDrawingRound && !isFirstRound) {
      text = 'Hãy vẽ lại bức tranh vừa rồi';
      image = 'assets/images/color-palette.png';
    } else if (isRememberRound && !isFirstRound) {
      text = 'Hãy nhớ bức tranh này';
      image = 'assets/images/canvas.png';
    } else if (isWaiting) {
      text = 'Chờ người chơi khác';
      image = '';
    } else {
      text = 'Lỗi';
      image = '';
    }

    return Row(
      children: [
        // Image and text
        Expanded(
          flex: 1,
          child: Row(
            children: [
              if (image.isNotEmpty)
                Image.asset(
                  image,
                  width: 50,
                  height: 50,
                ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      text,
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge!
                          .copyWith(color: const Color(0xFF00C4A1)),
                    ),
                    if (isRememberRound && !isFirstRound)
                      Text(
                        'Bạn sẽ phải vẽ lại nó đấy',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall!
                            .copyWith(color: Colors.black),
                        softWrap: true,
                        overflow: TextOverflow.visible,
                      ),
                  ],
                ),
              )
            ],
          ),
        ),
        // Time left
        if (!isWaiting)
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 70,
                height: 50,
                child: Container(
                  decoration: BoxDecoration(
                    color: (timeLeft < 10 && !isRememberRound)
                        ? Colors.red
                        : Colors.transparent,
                    border: Border.all(
                      color: Colors.black,
                      width: 2,
                    ),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Text(
                timeLeft.toString(),
                style: Theme.of(context)
                    .textTheme
                    .titleLarge!
                    .copyWith(color: Colors.black),
              ),
            ],
          )
        else
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: SizedBox(
              width: 50,
              height: 50,
              child: Container(
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/images/finish.png'),
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
