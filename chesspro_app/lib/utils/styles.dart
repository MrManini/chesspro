import 'package:flutter/material.dart';

class AppStyles {
  static final ButtonStyle darkButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: Color(0xff343a40), // Button color
    foregroundColor: Colors.white, // Text color
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
    padding: EdgeInsets.symmetric(vertical: 16),
  );

  static final ButtonStyle lightButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: Color(0xffced4da), // Button color
    foregroundColor: Colors.black, // Text color
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
    padding: EdgeInsets.symmetric(vertical: 16),
  );

  static final InputDecoration lightTextFieldStyle = InputDecoration(
    focusedBorder: UnderlineInputBorder(
      borderSide: BorderSide(color: Colors.black, width: 2), // Active color
    ),
    enabledBorder: UnderlineInputBorder(
      borderSide: BorderSide(color: Colors.grey, width: 2), // Default color
    ),
    hintStyle: TextStyle(color: Colors.grey),
  );

  static final InputDecoration darkTextFieldStyle = InputDecoration(
    focusedBorder: UnderlineInputBorder(
      borderSide: BorderSide(color: Colors.white, width: 2), // Active color
    ),
    enabledBorder: UnderlineInputBorder(
      borderSide: BorderSide(color: Colors.grey, width: 2), // Default color
    ),
    hintStyle: TextStyle(color: Colors.grey),
  );

  static ButtonStyle getPrimaryButtonStyle(BuildContext context) {
    return isDarkMode(context) ? lightButtonStyle : darkButtonStyle;
  }

  static ButtonStyle getSecondaryButtonStyle(BuildContext context) {
    return isDarkMode(context) ? darkButtonStyle : lightButtonStyle;
  }

  static InputDecoration getTextFieldStyle(BuildContext context) {
    return isDarkMode(context) ? darkTextFieldStyle : lightTextFieldStyle;
  }

  static bool isDarkMode(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark;
  }

  static Color getDefaultColor(BuildContext context) {
    return isDarkMode(context) ? Colors.white : Colors.black;
  }
}
