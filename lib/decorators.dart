import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'dart:ui';

class NeumorphicDecorator {
  static const Color baseColor = Color(0xFFE0E5EC);
  static const Color lightShadow = Color(0xFFFFFFFF);
  static const Color darkShadow = Color(0xFFA3B1C6);

  static NeumorphicStyle get standardStyle => const NeumorphicStyle(
    shape: NeumorphicShape.flat,
    boxShape: NeumorphicBoxShape.stadium(),
    depth: 8,
    lightSource: LightSource.topLeft,
    color: baseColor,
  );

  static NeumorphicStyle get recessedStyle => const NeumorphicStyle(
    depth: -10,
    intensity: 0.8,
    shape: NeumorphicShape.flat,
    boxShape: NeumorphicBoxShape.stadium(),
    color: baseColor,
  );

  static Widget withBlur({required Widget child, double sigma = 5.0}) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
        child: child,
      ),
    );
  }
}
