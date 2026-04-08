import 'package:flutter/material.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import '../decorators.dart';

class HapticRingComponent extends StatelessWidget {
  final double progress;
  final String text;

  const HapticRingComponent({
    super.key,
    required this.progress,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.blueAccent.withOpacity(0.3),
            blurRadius: 40,
            spreadRadius: 5,
          ),
        ],
      ),
      child: CircularPercentIndicator(
        radius: 120.0,
        lineWidth: 15.0,
        percent: progress.clamp(0.0, 1.0),
        center: Text(
          text,
          style: const TextStyle(
            fontSize: 48.0,
            fontWeight: FontWeight.bold,
            color: Colors.blueAccent,
            fontFamily: 'Courier', // Cyberpunk/Timer feel
          ),
        ),
        circularStrokeCap: CircularStrokeCap.round,
        backgroundColor: NeumorphicDecorator.baseColor,
        progressColor: Colors.blueAccent,
        animation: true,
        animateFromLastPercent: true,
      ),
    );
  }
}
