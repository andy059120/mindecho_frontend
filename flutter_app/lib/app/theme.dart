import 'package:flutter/cupertino.dart';

abstract final class AppColors {
  static const orange = Color.fromRGBO(227, 125, 51, 1);
  static const lightYellow = Color.fromRGBO(250, 240, 222, 1);
  static const darkBrown = Color.fromRGBO(102, 66, 33, 1);
  static const mediumBrown = Color.fromRGBO(140, 89, 51, 1);
  static const lightBrown = Color.fromRGBO(179, 140, 102, 1);
  static const title = Color.fromRGBO(102, 51, 26, 1);
  static const chatBackground = Color.fromRGBO(254, 243, 199, 1);
  static const userBubble = Color.fromRGBO(204, 102, 26, 1);
}

const appTheme = CupertinoThemeData(
  brightness: Brightness.light,
  primaryColor: AppColors.orange,
  scaffoldBackgroundColor: AppColors.lightYellow,
  textTheme: CupertinoTextThemeData(
    primaryColor: AppColors.orange,
    textStyle: TextStyle(
      fontSize: 16,
      color: AppColors.title,
      fontFamily: 'CupertinoSystemText',
      letterSpacing: -0.31,
    ),
  ),
);
