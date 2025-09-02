import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/models/lipid_record.dart';

class LipidRecordFormDialog extends StatefulWidget {
  final int profileId;
  final LipidRecord? record; // null for new record, existing record for edit
  final Function(LipidRecord) onSave;

  const LipidRecordFormDialog({
    super.key,
    required this.profileId,
    required this.onSave,
    this.record,
  });

  @override
  State<LipidRecordFormDialog> createState() => _LipidRecordFormDialogState();
}

class _LipidRecordFormDialogState extends State<LipidRecordFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _cholesterolTotalController = TextEditingController();
  final _hdlController = TextEditingController();
  final _ldlController = TextEditingController();
  final _triglyceridesController = TextEditingController();
  final _vldlController = TextEditingController();
  final _nonHdlController = TextEditingController();
  final _cholHdlRatioController = TextEditingController();
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    if (widget.record != null) {
      final record = widget.record!;
      _cholesterolTotalController.text = record.cholesterolTotal.toString();
      _hdlController.text = record.hdl.toString();
      _ldlController.text = record.ldl.toString();
      _triglyceridesController.text = record.triglycerides.toString();
      _vldlController.text = record.vldl.toString();
      _nonHdlController.text = record.nonHdl.toString();
      _cholHdlRatioController.text = record.cholHdlRatio.toString();
      _selectedDate = record.recordDate;
    }
  }

  @override
  void dispose() {
    _cholesterolTotalController.dispose();
    _hdlController.dispose();
    _ldlController.dispose();
    _triglyceridesController.dispose();
    _vldlController.dispose();
    _nonHdlController.dispose();
    _cholHdlRatioController.dispose();
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
      final record = LipidRecord(
        id: widget.record?.id,
        profileId: widget.profileId,
        cholesterolTotal: int.parse(_cholesterolTotalController.text),
        hdl: int.parse(_hdlController.text),
        ldl: int.parse(_ldlController.text),
        triglycerides: int.parse(_triglyceridesController.text),
        vldl: int.parse(_vldlController.text),
        nonHdl: int.parse(_nonHdlController.text),
        cholHdlRatio: double.parse(_cholHdlRatioController.text),
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
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: const Icon(Icons.science, color: Color(0xFF2E7D84)),
            isDense: true,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return validatorMessage;
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
                          ? 'Add Lipid Profile Record'
                          : 'Edit Lipid Profile Record',
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
                          fieldName: 'Total Cholesterol (mg/dL)',
                          normalRange: '<200',
                          hint: '200',
                          controller: _cholesterolTotalController,
                          validatorMessage: 'Please enter total cholesterol',
                          minValue: 50,
                          maxValue: 500,
                        ),
                        const SizedBox(height: 20),
                        _buildTextField(
                          fieldName: 'HDL Cholesterol (mg/dL)',
                          normalRange: '40-60',
                          hint: '50',
                          controller: _hdlController,
                          validatorMessage: 'Please enter HDL value',
                          minValue: 10,
                          maxValue: 150,
                        ),
                        const SizedBox(height: 20),
                        _buildTextField(
                          fieldName: 'LDL Cholesterol (mg/dL)',
                          normalRange: '0-159',
                          hint: '120',
                          controller: _ldlController,
                          validatorMessage: 'Please enter LDL value',
                          minValue: 30,
                          maxValue: 400,
                        ),
                        const SizedBox(height: 20),
                        _buildTextField(
                          fieldName: 'Triglycerides (mg/dL)',
                          normalRange: '<150',
                          hint: '150',
                          controller: _triglyceridesController,
                          validatorMessage: 'Please enter triglycerides value',
                          minValue: 20,
                          maxValue: 800,
                        ),
                        const SizedBox(height: 20),
                        _buildTextField(
                          fieldName: 'VLDL Cholesterol (mg/dL)',
                          normalRange: '0-40',
                          hint: '30',
                          controller: _vldlController,
                          validatorMessage: 'Please enter VLDL value',
                          minValue: 5,
                          maxValue: 100,
                        ),
                        const SizedBox(height: 20),
                        _buildTextField(
                          fieldName: 'Non-HDL Cholesterol (mg/dL)',
                          normalRange: '<130',
                          hint: '150',
                          controller: _nonHdlController,
                          validatorMessage: 'Please enter Non-HDL value',
                          minValue: 40,
                          maxValue: 450,
                        ),
                        const SizedBox(height: 20),
                        _buildTextField(
                          fieldName: 'Cholesterol/HDL Ratio',
                          normalRange: '0-5',
                          hint: '4.0',
                          controller: _cholHdlRatioController,
                          validatorMessage:
                              'Please enter cholesterol/HDL ratio',
                          minValue: 1,
                          maxValue: 10,
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
