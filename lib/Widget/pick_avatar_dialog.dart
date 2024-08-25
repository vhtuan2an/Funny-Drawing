import 'package:flutter/material.dart';

class PickAvatarDialog extends StatelessWidget {
  const PickAvatarDialog({super.key, required this.onPick});

  final void Function(int) onPick;
  final int totalAvatar = 21;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        color: const Color(0xFF00C4A0),
        borderRadius: BorderRadius.circular(25.0),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Column(
              children: [
                Text(
                  'Chọn Avatar',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge!
                      .copyWith(color: Colors.black),
                ),
                Text(
                  'Chọn nhân vật mà bạn thích',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall!
                      .copyWith(color: Colors.black),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16.0),
          Flexible(
            child: GridView.builder(
              shrinkWrap: true,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 10.0,
                mainAxisSpacing: 10.0,
              ),
              itemCount: totalAvatar,
              itemBuilder: (BuildContext _, int index) {
                return GestureDetector(
                  onTap: () {
                    onPick(index);
                  },
                  child: CircleAvatar(
                    backgroundImage:
                        AssetImage('assets/images/avatars/avatar$index.png'),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}