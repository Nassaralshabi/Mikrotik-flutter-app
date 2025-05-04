import 'package:flutter/material.dart';

class TextFieldDesign extends StatelessWidget {
  final String hintText;
  final IconData icon;
  final bool obscureText;
  final Color iconColor;
  final Color hintColor;
  final TextEditingController controller;

  const TextFieldDesign({
    Key? key,
    required this.hintText,
    required this.hintColor,
    required this.icon,
    required this.obscureText,
    required this.controller,
    required this.iconColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(color: hintColor),
        prefixIcon: Icon(icon, color: iconColor),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
}