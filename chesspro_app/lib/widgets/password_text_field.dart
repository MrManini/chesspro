import 'package:flutter/material.dart';
import 'package:chesspro_app/utils/styles.dart';

class PasswordTextField extends StatefulWidget {
  final TextEditingController controller;
  final InputDecoration decoration;
  final ValueNotifier<bool>? isPasswordVisibleNotifier;

  const PasswordTextField({
    super.key,
    required this.controller,
    required this.decoration,
    this.isPasswordVisibleNotifier,
  });

  @override
  PasswordTextFieldState createState() => PasswordTextFieldState();
}

class PasswordTextFieldState extends State<PasswordTextField> {
  late bool isPasswordVisible;

  @override
  void initState() {
    super.initState();
    isPasswordVisible = widget.isPasswordVisibleNotifier?.value ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller,
      obscureText: !isPasswordVisible,
      decoration: widget.decoration.copyWith(
        hintText: "Password",
        prefixIcon: Icon(Icons.lock, color: AppStyles.getDefaultColor(context)),
        suffixIcon: widget.isPasswordVisibleNotifier != null
            ? IconButton(
                icon: Icon(
                  isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                  color: AppStyles.getDefaultColor(context),
                ),
                onPressed: () {
                  setState(() {
                    isPasswordVisible = !isPasswordVisible;
                  });
                  widget.isPasswordVisibleNotifier?.value = isPasswordVisible;
                },
              )
            : null,
      ),
    );
  }
}

class ConfirmPasswordField extends StatelessWidget {
  final TextEditingController controller;
  final InputDecoration decoration;
  final ValueNotifier<bool> isPasswordVisibleNotifier;

  const ConfirmPasswordField({
    super.key,
    required this.controller,
    required this.decoration,
    required this.isPasswordVisibleNotifier,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: isPasswordVisibleNotifier,
      builder: (context, isPasswordVisible, child) {
        return TextField(
          controller: controller,
          obscureText: !isPasswordVisible,
          decoration: decoration.copyWith(
            hintText: "Confirm Password",
            prefixIcon: Icon(Icons.lock, color: AppStyles.getDefaultColor(context)),
          ),
        );
      },
    );
  }
}
