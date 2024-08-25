import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

Route createRouteRightToLeftTransition({
  required Widget oldPage,
  required Widget newPage,
}) {
  return PageRouteBuilder(
    pageBuilder: (context, animation, secondaryAnimation) => newPage,
    transitionsBuilder: (context, animation, secondaryAnimation, newPage) {
      const curve = Curves.easeInOutQuad;

      // animation cho trang cũ
      var tweenOldPage = Tween(begin: Offset.zero, end: const Offset(-1.0, 0.0))
          .chain(CurveTween(curve: curve));
      var offsetAnimationOldPage = animation.drive(tweenOldPage);

      // animation cho trang mới
      var tweenNewPage = Tween(begin: const Offset(1.0, 0.0), end: Offset.zero)
          .chain(CurveTween(curve: curve));
      var offsetAnimationNewPage = animation.drive(tweenNewPage);

      return Stack(
        children: [
          SlideTransition(
            position: offsetAnimationOldPage,
            child: oldPage,
          ),
          SlideTransition(
            position: offsetAnimationNewPage,
            child: newPage,
          ),
        ],
      );
    },
  );
}

Route createRouteBottomToTopTransition({
  required Widget oldPage,
  required Widget newPage,
}) {
  return PageRouteBuilder(
    pageBuilder: (context, animation, secondaryAnimation) => newPage,
    transitionsBuilder: (context, animation, secondaryAnimation, newPage) {
      const curve = Curves.easeInOutQuad;

      // animation cho trang cũ
      var tweenOldPage = Tween(begin: Offset.zero, end: const Offset(0.0, -1.0))
          .chain(CurveTween(curve: curve));
      var offsetAnimationOldPage = animation.drive(tweenOldPage);

      // animation cho trang mới
      var tweenNewPage = Tween(begin: const Offset(0.0, 1.0), end: Offset.zero)
          .chain(CurveTween(curve: curve));
      var offsetAnimationNewPage = animation.drive(tweenNewPage);

      return Stack(
        children: [
          SlideTransition(
            position: offsetAnimationOldPage,
            child: oldPage,
          ),
          SlideTransition(
            position: offsetAnimationNewPage,
            child: newPage,
          ),
        ],
      );
    },
  );
}
