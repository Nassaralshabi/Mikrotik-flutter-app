import 'package:flutter/material.dart';

class ButtonDesign extends StatefulWidget {
  final String text;
  final Future<void> Function() onPressed;
  final Color color;
  final Color textColor;
  final Color iconColor;
  final IconData? iconData;

  const ButtonDesign({
    super.key,
    required this.text,
    required this.onPressed,
    required this.color,
    required this.textColor,
    required this.iconColor,
    this.iconData,
  });

  @override
  _ButtonDesignState createState() => _ButtonDesignState();
}

class _ButtonDesignState extends State<ButtonDesign> {
  bool _isLoading = false;

  Future<void> _handlePressed() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    await widget.onPressed();

    if (!mounted) return;
    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: _isLoading ? null : _handlePressed,
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.all(widget.color),
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
      child: _isLoading
          ? SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(widget.iconColor),
        ),
      )
          : Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (widget.iconData != null)
            Icon(
              widget.iconData,
              color: widget.iconColor,
            ),
          if (widget.iconData != null) const SizedBox(width: 10),
          Text(
            widget.text,
            style: TextStyle(
              color: widget.textColor,
              fontSize: 15,
              fontFamily: 'Tajawal',
            ),
          ),
        ],
      ),
    );
  }
}
