import 'package:flutter/material.dart';

import '../model/player_masterpiece_mode.dart';

class MasterpieceScoringStatus extends StatelessWidget {
  const MasterpieceScoringStatus({
    super.key,
    required this.timeLeft,
    required this.player,
    required this.isMyTurn,
  });

  final int timeLeft;
  final PlayerInMasterPieceMode player;
  final bool isMyTurn;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 1,
          child: Row(
            children: [
              Image.asset(
                'assets/images/avatars/avatar${player.avatarIndex}.png',
                width: 50,
                height: 50,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: isMyTurn
                    ? Text(
                        'Chờ mọi người chấm điểm cho bạn nhé!',
                        style: Theme.of(context).textTheme.titleLarge!.copyWith(
                              color: const Color(0xFF00C4A1),
                              fontSize: 20,
                            ),
                        overflow: TextOverflow.visible,
                        softWrap: true,
                      )
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Tranh của ${player.name}',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge!
                                .copyWith(color: const Color(0xFF00C4A1)),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'Hãy chấm điểm cho bức tranh này!',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall!
                                .copyWith(color: Colors.black),
                            softWrap: true,
                            overflow: TextOverflow.visible,
                          ),
                        ],
                      ),
              ),
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
