import 'package:flutter/material.dart';

Widget buildCategoryHeader(BuildContext context, String title) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
    child: Text(
      title,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: Colors.grey.shade700,
        letterSpacing: 1.2,
      ),
    ),
  );
}
