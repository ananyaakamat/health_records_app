import 'package:flutter/services.dart';

/// Custom input formatter that allows only one decimal place
class DecimalInputFormatter extends TextInputFormatter {
  final int decimalDigits;

  DecimalInputFormatter({this.decimalDigits = 1});

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // If the new value is empty, allow it
    if (newValue.text.isEmpty) {
      return newValue;
    }

    // Check if the new value is a valid number with the specified decimal places
    final RegExp regExp =
        RegExp(r'^\d*\.?\d{0,' + decimalDigits.toString() + r'}$');

    // If the new value matches the pattern, allow it
    if (regExp.hasMatch(newValue.text)) {
      return newValue;
    }

    // If it doesn't match, keep the old value
    return oldValue;
  }
}
