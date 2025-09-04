import 'package:flutter_test/flutter_test.dart';
import 'package:medical_records_app/presentation/widgets/profile_form_dialog.dart';

void main() {
  group('MedicationInputFormatter Tests', () {
    late MedicationInputFormatter formatter;

    setUp(() {
      formatter = MedicationInputFormatter();
    });

    test('should convert text to uppercase', () {
      const oldValue = TextEditingValue(text: '');
      const newValue = TextEditingValue(text: 'aspirin');

      final result = formatter.formatEditUpdate(oldValue, newValue);

      expect(result.text, equals('ASPIRIN'));
    });

    test('should replace comma with newline', () {
      const oldValue = TextEditingValue(text: 'ASPIRIN');
      const newValue = TextEditingValue(text: 'ASPIRIN,paracetamol');

      final result = formatter.formatEditUpdate(oldValue, newValue);

      expect(result.text, equals('ASPIRIN\nPARACETAMOL'));
    });

    test('should replace comma with space with newline', () {
      const oldValue = TextEditingValue(text: 'ASPIRIN');
      const newValue = TextEditingValue(text: 'ASPIRIN, paracetamol');

      final result = formatter.formatEditUpdate(oldValue, newValue);

      expect(result.text, equals('ASPIRIN\nPARACETAMOL'));
    });

    test('should handle multiple commas', () {
      const oldValue = TextEditingValue(text: '');
      const newValue =
          TextEditingValue(text: 'aspirin, paracetamol, ibuprofen');

      final result = formatter.formatEditUpdate(oldValue, newValue);

      expect(result.text, equals('ASPIRIN\nPARACETAMOL\nIBUPROFEN'));
    });

    test('should maintain cursor position at end', () {
      const oldValue = TextEditingValue(text: 'ASPIRIN');
      const newValue = TextEditingValue(text: 'ASPIRIN,paracetamol');

      final result = formatter.formatEditUpdate(oldValue, newValue);

      expect(result.selection.baseOffset, equals(result.text.length));
      expect(result.selection.extentOffset, equals(result.text.length));
    });
  });
}
