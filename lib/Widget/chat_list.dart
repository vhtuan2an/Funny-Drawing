import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ChatList extends ConsumerStatefulWidget {
  const ChatList({
    super.key,
    required this.scrollController,
    required this.chatMessages,
  });

  final ScrollController scrollController;
  final List<Map<String, dynamic>> chatMessages;

  @override
  ConsumerState<ChatList> createState() => _ChatList();
}

class _ChatList extends ConsumerState<ChatList> {
  final showAvatar = true;

  @override
  Widget build(BuildContext context) {
    Widget buildChat(Map<String, dynamic> chat) {
      switch (chat['id']) {
        case 'system':
          return Center(
            child: Text(
              '--${chat['message']}--',
              style: Theme.of(context).textTheme.bodySmall!.copyWith(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF00705A),
                  ),
            ),
          );
        case 'answer':
          return Center(
            child: Text(
              '--${chat['message']}--',
              style: Theme.of(context).textTheme.bodySmall!.copyWith(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFf8fc00),
                  ),
            ),
          );
        default:
          if (showAvatar == false) {
            return Row(
              children: [
                Text(
                  '${chat['userName']}: ${chat['message']}',
                  style: Theme.of(context).textTheme.bodySmall!.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            );
          } else {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Image.asset(
                  'assets/images/avatars/avatar${chat['avatarIndex']}.png',
                  width: 35,
                  height: 35,
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Text(
                            '${chat['userName']}',
                            style:
                                Theme.of(context).textTheme.bodySmall!.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                          ),
                          const SizedBox(width: 5),
                          if ((chat['id'] as String).contains('admin-'))
                            SizedBox(
                              width: 15,
                              height: 15,
                              child: Image.asset('assets/images/admin.png'),
                            )
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${chat['message']}',
                        style: Theme.of(context).textTheme.bodySmall!.copyWith(fontWeight: FontWeight.w300),
                        softWrap: true,
                        overflow: TextOverflow.visible,
                      ),
                    ],
                  ),
                ),
              ],
            );
          }
      }
    }

    return ListView.builder(
      controller: widget.scrollController,
      itemCount: widget.chatMessages.length,
      itemBuilder: (context, index) {
        final item = widget.chatMessages[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 10.0),
          child: buildChat(item),
        );
      },
    );
  }
}
