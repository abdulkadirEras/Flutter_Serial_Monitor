// ignore_for_file: import_of_legacy_library_into_null_safe

import 'package:animated_splash_screen/animated_splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:page_transition/page_transition.dart';

import 'main.dart';

class BaslangicEkrani extends StatelessWidget {
  const BaslangicEkrani({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedSplashScreen(
      duration: 700,
      splash: Column(
        children: [
          Expanded(
            flex: 1,
            child: Image.asset(
              'assets/image/usb.png',
              width: 100,
              height: 100,
            ),
          ),
          Text(
            "Serial Terminal",
            style: const TextStyle(
                fontFamily: "Wallpoet-Regular",
                fontSize: 25,
                color: Colors.white),
          ),
        ],
      ),
      nextScreen: AnaEkran(title: "Serial Terminal"),
      splashTransition: SplashTransition.sizeTransition,
      pageTransitionType: PageTransitionType.leftToRight,
      //animasyonun oynama süresi
      animationDuration: Duration(milliseconds: 700),
      backgroundColor: Colors.indigo,
      //splashIconSize: 95,
    );
  }
}
