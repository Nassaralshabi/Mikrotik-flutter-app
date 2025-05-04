import 'package:flutter/material.dart';

class CircleIndicator extends StatelessWidget {
  final Color color;
  final double width;
  final double height;
  final double progress;
  final String title;
  final String value;

  CircleIndicator({
    required this.color,
    required this.width,
    required this.height,
    required this.progress,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: progress,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            backgroundColor: color.withOpacity(0.2),
            strokeWidth: 15, // زيادة حجم الخط
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14, // ضبط حجم النص ليكون متناسب مع الحجم الأكبر
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize:14, // ضبط حجم النص ليكون متناسب مع الحجم الأكبر
                  color: color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
