import 'package:flutter/material.dart';

class VoucherCard extends StatelessWidget {
  final IconData icon;
  final String name;
  final String description;
  final Color color;

  const VoucherCard({
    super.key,
    required this.icon,
    required this.name,
    required this.description,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.blue[900],
      child: Column(
        children: [
          ListTile(
            leading: Icon(icon, size: 40, color: color),
            title: Text(
              name,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontFamily: 'Tajawal',
                color: Colors.white,
              ),
            ),
            subtitle: Text(
              description,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
