import 'package:flutter/material.dart';

class RoomMode extends StatefulWidget {
  const RoomMode({
    super.key,
    required this.mode,
    required this.description,
    required this.selecting,
  });

  final String mode;
  final String description;
  final ValueNotifier<String> selecting;

  @override
  State<RoomMode> createState() => _RoomModeState();
}

class _RoomModeState extends State<RoomMode> {
  late final ValueListenableBuilder<String> _valueListenableBuilder;

  @override
  void initState() {
    super.initState();
    _valueListenableBuilder = ValueListenableBuilder<String>(
        valueListenable: widget.selecting,
        builder: (context, value, child) {
          return Card(
            shape: RoundedRectangleBorder(
                borderRadius: const BorderRadius.all(Radius.circular(10)),
                side: BorderSide(
                    color: value == widget.mode
                        ? const Color.fromARGB(255, 44, 104, 44)
                        : Colors.transparent,
                    width: value == widget.mode ? 4.0 : 0.0,
                    strokeAlign: BorderSide.strokeAlignCenter)),
            child: Row(
              children: [
                SizedBox(
                  height: 110,
                  width: 110,
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Image.asset(widget.mode == 'Vẽ và đoán'
                        ? 'assets/images/thuong_mode.png'
                        : widget.mode == 'Tam sao thất bản'
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
                          widget.mode,
                          style:
                              Theme.of(context).textTheme.titleLarge!.copyWith(
                                    color: Colors.black,
                                  ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          widget.description,
                          style:
                              Theme.of(context).textTheme.bodySmall!.copyWith(
                                    color: Colors.black,
                                  ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    return _valueListenableBuilder;
  }
}
