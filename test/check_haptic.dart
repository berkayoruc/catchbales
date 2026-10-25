import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';

void main() {
  test('check haptic', () {
    HapticFeedback.mediumImpact();
  });
}
