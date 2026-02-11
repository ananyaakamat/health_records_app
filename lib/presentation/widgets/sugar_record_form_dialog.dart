import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/models/sugar_record.dart';
import '../../core/utils/decimal_input_formatter.dart';

class SugarRecordFormDialog extends StatefulWidget {
  final int profileId;
  final SugarRecord? record; // null for new record, existing record for edit
  final Function(SugarRecord) onSave;

  const SugarRecordFormDialog({
    super.key,
    required this.profileId,
    required this.onSave,
    this.record,
  });

  @override
  State<SugarRecordFormDialog> createState() => _SugarRecordFormDialogState();
}

class _SugarRecordFormDialogState extends State<SugarRecordFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _fbsController = TextEditingController();
  final _ppbsController = TextEditingController();
  final _rbsController = TextEditingController();
  final _hba1cController = TextEditingController();
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    if (widget.record != null) {
      _fbsController.text = widget.record!.fbs?.toString() ?? '';
      _ppbsController.text = widget.record!.ppbs?.toString() ?? '';
      _rbsController.text = widget.record!.rbs?.toString() ?? '';
      _hba1cController.text = widget.record!.hba1c.toString();
      _selectedDate = widget.record!.recordDate;
    }
  }

  @override
  void dispose() {
    _fbsController.dispose();
    _ppbsController.dispose();
    _rbsController.dispose();
    _hba1cController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final pickedDate = await showDatePicker(
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
      final record = SugarRecord(
        id: widget.record?.id,
        profileId: widget.profileId,
        fbs: _fbsController.text.isEmpty
            ? null
            : double.parse(_fbsController.text),
        ppbs: _ppbsController.text.isEmpty
            ? null
            : double.parse(_ppbsController.text),
        rbs: _rbsController.text.isEmpty
            ? null
            : double.parse(_rbsController.text),
        hba1c: double.parse(_hba1cController.text),
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
    double? minValue,
    double? maxValue,
    bool isOptional = false,
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
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            DecimalInputFormatter(decimalDigits: 1),
          ],
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: const Icon(Icons.bloodtype, color: Color(0xFF2E7D84)),
            isDense: true,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return isOptional ? null : validatorMessage;
            }
            final val = double.tryParse(value);
            if (val == null || val <= 0) {
              return 'Please enter a valid value';
            }
            if (minValue != null && val < minValue) {
              return 'Value should be at least $minValue';
            }
            if (maxValue != null && val > maxValue) {
              return 'Value should not exceed $maxValue';
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
                          ? 'Add Sugar Record'
                          : 'Edit Sugar Record',
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
                          fieldName: 'FBS (mg/dL)',
                          normalRange: '80-100',
                          hint: '90',
                          controller: _fbsController,
                          validatorMessage: 'Please enter FBS value',
                          minValue: 20,
                          maxValue: 500,
                          isOptional: true,
                        ),
                        const SizedBox(height: 20),
                        _buildTextField(
                          fieldName: 'PPBS (mg/dL)',
                          normalRange: '120-140',
                          hint: '130',
                          controller: _ppbsController,
                          validatorMessage: 'Please enter PPBS value',
                          minValue: 40,
                          maxValue: 500,
                          isOptional: true,
                        ),
                        const SizedBox(height: 20),
                        _buildTextField(
                          fieldName: 'RBS (mg/dL)',
                          normalRange: '<140',
                          hint: '120',
                          controller: _rbsController,
                          validatorMessage: 'Please enter RBS value',
                          minValue: 40,
                          maxValue: 500,
                          isOptional: true,
                        ),
                        const SizedBox(height: 20),
                        _buildTextField(
                          fieldName: 'HbA1c (%)',
                          normalRange: '4.0-5.6',
                          hint: '5.0',
                          controller: _hba1cController,
                          validatorMessage: 'Please enter HbA1c value',
                          minValue: 3,
                          maxValue: 20,
                          isOptional: false,
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
