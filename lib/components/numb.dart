import 'package:flutter/material.dart';

import 'colors.dart';

class Numbs extends StatelessWidget {
  final String numbs;

  const Numbs({
    required this.numbs,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        numbs,
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w500,
          color: B_1,
        ),
      ),
    );
  }
}
