import 'package:flutter/services.dart';

class CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    // Remove non-digits
    String newText = newValue.text.replaceAll(RegExp(r'[^\d]'), '');
    
    if (newText.isEmpty) {
      return const TextEditingValue(text: '');
    }

    // Format with thousand separator
    final number = int.parse(newText);
    final formatted = _formatNumber(number);

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  String _formatNumber(int number) {
    String result = '';
    String numStr = number.toString();
    int count = 0;
    
    for (int i = numStr.length - 1; i >= 0; i--) {
      count++;
      result = numStr[i] + result;
      if (count % 3 == 0 && i != 0) {
        result = '.$result';
      }
    }
    return result;
  }
}

String formatCurrency(double amount) {
  if (amount >= 1000000) {
    final value = amount / 1000000;
    return '${value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 1)}jt';
  } else if (amount >= 1000) {
    final value = amount / 1000;
    return '${value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 1)}rb';
  }
  return amount.toStringAsFixed(0);
}

String formatCurrencyFull(double amount) {
  String result = '';
  String numStr = amount.toInt().toString();
  int count = 0;
  
  for (int i = numStr.length - 1; i >= 0; i--) {
    count++;
    result = numStr[i] + result;
    if (count % 3 == 0 && i != 0) {
      result = '.$result';
    }
  }
  return result;
}

double parseCurrency(String text) {
  if (text.isEmpty) return 0;
  return double.tryParse(text.replaceAll('.', '')) ?? 0;
}
