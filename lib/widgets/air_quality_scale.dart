import 'package:flutter/material.dart';

class AirQualityScale extends StatelessWidget {
  final int activeLevel;

  const AirQualityScale({super.key, required this.activeLevel});

  static const labels = [
    'Good',
    'Satisfactory',
    'Moderate',
    'Poor',
    'Very Poor',
    'Severe',
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: List.generate(labels.length, (index) {
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Text(
                  labels[index],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: index == activeLevel ? FontWeight.w800 : FontWeight.w500,
                  ),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 5),
        Row(
          children: List.generate(labels.length, (index) {
            return Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 2),
                height: 9,
                color: index <= activeLevel ? Colors.green.shade700 : Colors.grey.shade300,
              ),
            );
          }),
        ),
      ],
    );
  }
}
