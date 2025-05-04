import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}


// create function to convert the latin number to arabic number
String convertToArabic(String input) {
  String output = '';
  for (int i = 0; i < input.length; i++) {
    switch (input[i]) {
      case '0':
        output += '٠';
        break;
      case '1':
        output += '١';
        break;
      case '2':
        output += '٢';
        break;
      case '3':
        output += '٣';
        break;
      case '4':
        output += '٤';
        break;
      case '5':
        output += '٥';
        break;
      case '6':
        output += '٦';
        break;
      case '7':
        output += '٧';
        break;
      case '8':
        output += '٨';
        break;
      case '9':
        output += '٩';
        break;
      default:
        output += input[i];
    }
  }
  return output;
}


class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: CarPlate(
            plateText: 'خ7',
            arabicText: '7KH',
            serialNumberLatin: '64301',
          ),
        ),
      ),
    );
  }
}

class CarPlate extends StatelessWidget {
  final String plateText;
  final String arabicText;
  final String serialNumberLatin;

  CarPlate({
    required this.plateText,
    required this.arabicText,
    required this.serialNumberLatin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      height: 150,
      decoration: BoxDecoration(
        border: Border.all(width: 2, color: Colors.black),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Stack(
        children: [
          const Positioned(
            top: 8,
            left: 8,
            child: Text(
              'SUDAN',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const Positioned(
            top: 8,
            right: 8,
            child: Text(
              'السودان',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const Positioned(
            top: 40,
            left: 0,
            right: 0,
            child: Divider(color: Colors.black, thickness: 4),
          ),
          const VerticalDivider(color: Colors.black, thickness: 4, width: 49000),
          Positioned(
            top: 60,
            left: 8,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  plateText,
                  style: const TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  arabicText,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const Positioned(
            top: 60,
            left: 110,
            child: VerticalDivider(color: Colors.black, thickness: 40),
          ),
          Positioned(
            top: 50,
            right: 8,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  convertToArabic(serialNumberLatin),
                  style: const TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  serialNumberLatin,
                  style: const TextStyle(
                    fontSize: 30,
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
