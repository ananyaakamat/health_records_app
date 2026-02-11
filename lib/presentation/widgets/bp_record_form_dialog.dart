import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/models/bp_record.dart';

class BPRecordFormDialog extends StatefulWidget {
  final int profileId;
  final BPRecord? record; // null for new record, existing record for edit
  final Function(BPRecord) onSave;

  const BPRecordFormDialog({
    super.key,
    required this.profileId,
    required this.onSave,
    this.record,
  });

  @override
  State<BPRecordFormDialog> createState() => _BPRecordFormDialogState();
}

class _BPRecordFormDialogState extends State<BPRecordFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _systolicController = TextEditingController();
  final _diastolicController = TextEditingController();
  final _bpmController = TextEditingController();
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    if (widget.record != null) {
      final record = widget.record!;
      _systolicController.text = record.systolic.toString();
      _diastolicController.text = record.diastolic.toString();
      _bpmController.text = record.bpm?.toString() ?? '';
      _selectedDate = record.recordDate;
    }
  }

  @override
  void dispose() {
    _systolicController.dispose();
    _diastolicController.dispose();
    _bpmController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: const Color(0xFF2E7D84),
                  onPrimary: Colors.white,
                ),
          ),
          child: child!,
        );
      },
    );
    if (pickedDate != null) {
      setState(() {
        _selectedDate = pickedDate;
      });
    }
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      final record = BPRecord(
        id: widget.record?.id,
        profileId: widget.profileId,
        systolic: int.parse(_systolicController.text),
        diastolic: int.parse(_diastolicController.text),
        bpm:
            _bpmController.text.isEmpty ? null : int.parse(_bpmController.text),
        recordDate: _selectedDate,
      );
      widget.onSave(record);
      Navigator.of(context).pop();
    }
  }

  Widget _buildTextField({
    required String fieldName,
    required String normalRange,
    required String hint,
    required TextEditingController controller,
    required String validatorMessage,
    int? minValue,
    int? maxValue,
    bool isOptional = false,
    String? Function(String?)? additionalValidator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Field name on one line
        Text(
          fieldName,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: const Color(0xFF2E7D84),
              ),
        ),
        const SizedBox(height: 4),
        // Normal range on second line
        Text(
          'Normal: $normalRange',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
        ),
        const SizedBox(height: 8),
        // Input field on third line
        TextFormField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: const Icon(Icons.favorite, color: Color(0xFF2E7D84)),
            isDense: true,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return isOptional ? null : validatorMessage;
            }
            final val = int.tryParse(value);
            if (val == null || val <= 0) {
              return 'Please enter a valid value';
            }
            if (minValue != null && val < minValue) {
              return 'Value should be at least $minValue';
            }
            if (maxValue != null && val > maxValue) {
              return 'Value should not exceed $maxValue';
            }

            // Run additional validator if provided
            if (additionalValidator != null) {
              return additionalValidator(value);
            }
            return null;
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.95,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Title bar
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Color(0xFF2E7D84),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.record == null
                          ? 'Add Blood Pressure Record'
                          : 'Edit Blood Pressure Record',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            // Form content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildTextField(
                          fieldName: 'Systolic (SBP) (mmHg)',
                          normalRange: '<120',
                          hint: '120',
                          controller: _systolicController,
                          validatorMessage: 'Please enter systolic value',
                          minValue: 60,
                          maxValue: 300,
                          isOptional: false,
                        ),
                        const SizedBox(height: 20),
                        _buildTextField(
                          fieldName: 'Diastolic (DBP) (mmHg)',
                          normalRange: '<80',
                          hint: '80',
                          controller: _diastolicController,
                          validatorMessage: 'Please enter diastolic value',
                          minValue: 40,
                          maxValue: 200,
                          isOptional: false,
                          additionalValidator: (value) {
                            // Check if systolic is greater than diastolic
                            final systolic =
                                int.tryParse(_systolicController.text);
                            final diastolic = int.tryParse(value!);
                            if (systolic != null &&
                                diastolic != null &&
                                diastolic >= systolic) {
                              return 'Diastolic should be less than systolic';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        _buildTextField(
                          fieldName: 'Heart Rate (BPM)',
                          normalRange: '60-80',
                          hint: '72',
                          controller: _bpmController,
                          validatorMessage: 'Please enter heart rate',
                          minValue: 30,
                          maxValue: 220,
                          isOptional: true,
                        ),
                        const SizedBox(height: 20),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Date Recorded',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF2E7D84),
                                  ),
                            ),
                            const SizedBox(height: 8),
                            InkWell(
                              onTap: _selectDate,
                              child: InputDecorator(
                                decoration: const InputDecoration(
                                  prefixIcon: Icon(Icons.calendar_today,
                                      color: Color(0xFF2E7D84)),
                                  isDense: true,
                                  contentPadding: EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 12),
                                ),
                                child: Text(DateFormat('MMM dd, yyyy')
                                    .format(_selectedDate)),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // Action buttons
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E7D84),
                      foregroundColor: Colors.white,
                    ),
                    child: Text(widget.record == null ? 'Add' : 'Update'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
