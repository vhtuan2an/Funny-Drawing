import 'package:draw_and_guess_promax/Screen/how_to_play.dart';
import 'package:draw_and_guess_promax/animation.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:url_launcher/url_launcher.dart';

class MoreDrawer extends StatelessWidget {
  const MoreDrawer({
    super.key,
    required this.onHowToPlayClick,
  });

  final void Function() onHowToPlayClick;
  final buttonSize = const Size(100, 100);

  void _onCloseClick(context) {
    // Xử lý khi nút Close được nhấn
    Navigator.pop(context);
  }

  _launchURL(String link) async {
    final uri = Uri.parse(link);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      // can't launch url
    }
  }

  final String youtubeLink = "https://www.youtube.com/watch?v=tiM2ZWLXKT4";
  final String discordLink = "https://discord.gg/wNg6dnuEXV";
  final String githubLink =
      "https://github.com/BeIchTuan/SE346_DrawNGuess_Promax";
  final String feedbackLink =
      "https://docs.google.com/forms/d/e/1FAIpQLSeZGcU2gKAx-kC5a1EMJShbKoKFQVElw87Sk4NipiJpm1vVEw/viewform?usp=sf_link";

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
          gradient: LinearGradient(
              begin: Alignment(0.00, -1.00),
              end: Alignment(0, 1),
              colors: [Color(0xFF00C4A0), Color(0xFFD05700)])),
      child: Stack(
        children: [
          // App bar
          Positioned(
            top: 35,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton(
                  onPressed: () {
                    _onCloseClick(context);
                  },
                  style: ElevatedButton.styleFrom(
                    fixedSize: const Size(90, 90),
                    backgroundColor: const Color.fromARGB(0, 0, 0, 0),
                    shadowColor: const Color.fromARGB(0, 0, 0, 0),
                    surfaceTintColor: const Color.fromARGB(0, 0, 0, 0),
                  ),
                  child: Image.asset('assets/images/close.png'),
                ),
              ],
            ),
          ),
          // Logo + nút
          Positioned(
            top: 135,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Center(
                  child: SizedBox(
                    height: 100,
                    child: Image.asset('assets/images/new_logo.png'),
                  ),
                ),
                const SizedBox(height: 10),
                TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: Text(
                      'TRANG CHỦ',
                      style: Theme.of(context).textTheme.titleLarge,
                    )),
                const SizedBox(height: 5),
                TextButton(
                    onPressed: onHowToPlayClick,
                    child: Text(
                      'CÁCH CHƠI',
                      style: Theme.of(context).textTheme.titleLarge,
                    )),
                const SizedBox(height: 5),
                TextButton(
                    onPressed: () {
                      _launchURL(feedbackLink);
                      Navigator.of(context).pop();
                    },
                    child: Text(
                      'GÓP Ý',
                      style: Theme.of(context).textTheme.titleLarge,
                    )),
              ],
            ),
          ),

          // Nút liên hệ
          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /*Padding(
                  padding: const EdgeInsets.only(left: 20),
                  child: Text(
                    'Liên kết ngoài:',
                    style: Theme.of(context).textTheme.bodySmall!.copyWith(
                        fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.start,
                  ),
                ),*/
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        _launchURL(discordLink);
                      },
                      style: ElevatedButton.styleFrom(
                        fixedSize: buttonSize,
                        backgroundColor: const Color.fromARGB(0, 0, 0, 0),
                        shadowColor: const Color.fromARGB(0, 0, 0, 0),
                        surfaceTintColor: const Color.fromARGB(0, 0, 0, 0),
                      ),
                      child: Image.asset('assets/images/discord.png'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        _launchURL(youtubeLink);
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.all(14),
                        fixedSize: buttonSize,
                        backgroundColor: const Color.fromARGB(0, 0, 0, 0),
                        shadowColor: const Color.fromARGB(0, 0, 0, 0),
                        surfaceTintColor: const Color.fromARGB(0, 0, 0, 0),
                      ),
                      child: Image.asset('assets/images/youtube.png'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        _launchURL(githubLink);
                      },
                      style: ElevatedButton.styleFrom(
                        fixedSize: buttonSize,
                        backgroundColor: const Color.fromARGB(0, 0, 0, 0),
                        shadowColor: const Color.fromARGB(0, 0, 0, 0),
                        surfaceTintColor: const Color.fromARGB(0, 0, 0, 0),
                        padding: const EdgeInsets.all(20),
                      ),
                      child: Image.asset('assets/images/github.png'),
                    ),
                  ],
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
