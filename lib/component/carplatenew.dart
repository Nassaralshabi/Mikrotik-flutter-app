import 'package:flutter/material.dart';

class PlateView extends StatelessWidget {
  final double width;
  final double height;

  PlateView({required this.width, required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      child: Stack(
        children: [
          Image.asset(
            'assets/license_plate.png',
            width: width,
            height: height,
            fit: BoxFit.fill,
          ),
          Positioned(
            left: width * 0.1, // Adjusted position from the left
            top: height * 0.3, // Adjusted position from the top
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'خ ٤',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: height * 0.2,
                  ),
                ),
                Text(
                  '4 K H',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: height * 0.2,
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            right: width * 0.1, // Adjusted position from the right
            top: height * 00.2, // Same vertical position as above
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '٧٦٢٣٢',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: height * 0.28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '7 6 2 3 2',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: height * 0.25,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
