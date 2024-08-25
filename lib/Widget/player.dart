import 'package:draw_and_guess_promax/model/player_in_room.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import '../model/user.dart';

class Player extends StatelessWidget {
  const Player({
    super.key,
    required this.player,
    required this.sizeImg,
    this.roomOwner = 'null',
  });

  final double sizeImg;
  final User player;
  final String roomOwner;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: sizeImg,
          height: sizeImg,
          child: CircleAvatar(
            backgroundImage: AssetImage(
                'assets/images/avatars/avatar${player.avatarIndex}.png'), // Sử dụng AssetImage như là ImageProvider
          ),
        ),
        const SizedBox(width: 5),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              player.name,
              style: Theme.of(context).textTheme.titleSmall!.copyWith(
                  color: player.id == roomOwner ? Colors.yellow : Colors.white),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
            if (player.id!.contains('admin-')) ...[
              const SizedBox(width: 3),
              SizedBox(
                width: 15,
                height: 15,
                child: Image.asset('assets/images/admin.png'),
              )
            ]
          ],
        )
      ],
    );
  }
}
