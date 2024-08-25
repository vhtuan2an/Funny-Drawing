import 'package:flutter/material.dart';

class MasterpieceModeStatus extends StatelessWidget {
  const MasterpieceModeStatus({
    super.key,
    required this.word,
    required this.timeLeft,
  });

  final String word;
  final int timeLeft;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 1,
          child: Row(
            children: [
                Image.asset(
                  'assets/images/color-palette.png',
                  width: 45,
                  height: 45,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                     'Hãy vẽ: $word',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge!
                        .copyWith(color: Colors.black),
                  ),
                )
            ],
          ),
        ),
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 70,
              height: 50,
              child: Container(
                //padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: timeLeft < 10 ? Colors.red : Colors.transparent,
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
        ),
      ],
    );
  }
}
