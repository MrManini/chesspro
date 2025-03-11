import 'package:flutter/material.dart';
import 'package:chesspro_app/utils/styles.dart';

class PasswordTextField extends StatefulWidget {
  final TextEditingController controller;
  final InputDecoration decoration;

  const PasswordTextField({
    super.key,
    required this.controller,
    required this.decoration,
  });

  @override
  PasswordTextFieldState createState() => PasswordTextFieldState();
}

class PasswordTextFieldState extends State<PasswordTextField> {
  bool isPasswordVisible = false;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller,
      obscureText: !isPasswordVisible,
      decoration: widget.decoration.copyWith(
        hintText: "Password",
        prefixIcon: Icon(Icons.lock, color: AppStyles.getDefaultColor(context)),
        suffixIcon: IconButton(
          icon: Icon(
            isPasswordVisible ? Icons.visibility : Icons.visibility_off,
            color: AppStyles.getDefaultColor(context),
          ),
          onPressed: () {
            setState(() {
              isPasswordVisible = !isPasswordVisible;
            });
          },
        ),
      ),
    );
  }
}
