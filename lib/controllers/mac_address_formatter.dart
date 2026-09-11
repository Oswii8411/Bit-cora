import 'package:flutter/services.dart';

class MacAddressFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    // Elimina todo lo que no sea HEX
    var text = newValue.text.replaceAll(RegExp(r'[^0-9A-Fa-f]'), '').toUpperCase();
    var buffer = StringBuffer();

    for (int i = 0; i < text.length; i++) {
      buffer.write(text[i]);
      var nonZeroIndex = i + 1;
      // Inserta dos puntos cada 2 caracteres (excepto al final o si sobrepasa los 12 caracteres)
      if (nonZeroIndex % 2 == 0 && nonZeroIndex != text.length && nonZeroIndex < 12) {
        buffer.write(':');
      }
    }

    var string = buffer.toString();
    return newValue.copyWith(
        text: string,
        selection: TextSelection.collapsed(offset: string.length) // Mueve el cursor al final
    );
  }
}