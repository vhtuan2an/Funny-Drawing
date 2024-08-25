import 'package:flutter/material.dart';

class Button extends StatelessWidget {
  const Button({
    super.key,
    required this.onClick,
    this.borderRadius = 10,
    this.imageAsset,
    this.title = 'Button',
    this.color = Colors.white,
    this.width,
    this.isWaiting = false,
    this.isEnable = true,
  });

  final void Function(BuildContext context) onClick;
  final double borderRadius;
  final String? imageAsset;
  final String title;
  final Color color;
  final double? width;
  final bool isWaiting;
  final bool isEnable;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: ElevatedButton(
        onPressed: () {
          if (isEnable) {
            onClick(context);
          }
        },
        style: ElevatedButton.styleFrom(
          fixedSize: width == null ? null : Size(width!, 50),
          backgroundColor: color,
          shadowColor: const Color.fromARGB(0, 0, 0, 0),
          surfaceTintColor: const Color.fromARGB(0, 0, 0, 0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(borderRadius)),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (imageAsset != null && !isWaiting) ...[
              Image.asset(
                imageAsset!,
                height: 22,
                width: 22,
              ),
              const SizedBox(width: 6)
            ],
            if (isWaiting) ...[
              const SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(
                  color: Color(0xFF3D3D3D),
                ),
              ),
              const SizedBox(width: 6)
            ],
            Text(
              title,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium!
                  .copyWith(color: Colors.black),
            ),
          ],
        ),
      ),
    );
  }
}
