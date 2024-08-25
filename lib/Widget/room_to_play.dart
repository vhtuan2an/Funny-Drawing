import 'package:flutter/material.dart';

class RoomToPlay extends StatefulWidget {
  RoomToPlay({
    super.key,
    required this.mode,
    required this.roomId,
    this.isPrivate = false,
    required this.selecting,
    required this.curPlayer,
    required this.maxPlayer,
    required this.password,
  });

  final String mode;
  final String roomId;
  final bool isPrivate;
  final int curPlayer;
  final int maxPlayer;
  final ValueNotifier<String> selecting;
  final ValueNotifier<String> password;

  @override
  State<RoomToPlay> createState() => _RoomToPlayState();
}

class _RoomToPlayState extends State<RoomToPlay> {
  late final ValueListenableBuilder<String> _valueListenableBuilder;
  final TextEditingController _passwordController = TextEditingController();

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
                    color: (value == widget.roomId)
                        ? const Color.fromARGB(255, 44, 104, 44)
                        : Colors.transparent,
                    width: value == widget.roomId ? 4.0 : 0.0,
                    strokeAlign: BorderSide.strokeAlignCenter)),
            child: Column(
              children: [
                Row(
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
                        width: 180,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.mode,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge!
                                  .copyWith(
                                    color: Colors.black,
                                  ),
                            ),
                            Text(
                              'Số người: ${widget.curPlayer}/${widget.maxPlayer}',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium!
                                  .copyWith(
                                    color: Colors.black,
                                  ),
                            ),
                            Text(
                              'ID phòng: ${widget.roomId}',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium!
                                  .copyWith(
                                    color: Colors.black,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (widget.isPrivate)
                      SizedBox(
                        height: 40,
                        child: Image.asset('assets/images/lock.png'),
                      ),
                  ],
                ),
                if (widget.isPrivate)
                  Padding(
                    padding:
                        const EdgeInsets.only(left: 20, right: 20, bottom: 20),
                    child: TextField(
                      controller: _passwordController,
                      decoration: InputDecoration(
                        hintText: 'Mật khẩu',
                        hintStyle: Theme.of(context)
                            .textTheme
                            .bodySmall!
                            .copyWith(color: Colors.black),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Colors.black),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                              color: Color.fromARGB(255, 21, 48, 21)),
                        ),
                      ),
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium!
                          .copyWith(color: Colors.black),
                      onTap: () {
                        widget.selecting.value = widget.roomId;
                      },
                      /*onTapOutside: (pointer) {
                          _passwordController.text = '';
                        },*/
                      onChanged: (value) {
                        widget.password.value = _passwordController.text;
                      },
                      cursorColor: Colors.black,
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
