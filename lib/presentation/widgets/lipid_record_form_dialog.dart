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
    required String label,
    required String hint,
    required TextEditingController controller,
    required String validatorMessage,
    double? minValue,
    double? maxValue,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: const Icon(Icons.science, color: Color(0xFF2E7D84)),
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.record == null
            ? 'Add Lipid Profile Record'
            : 'Edit Lipid Profile Record',
        style: const TextStyle(
            color: Color(0xFF2E7D84), fontWeight: FontWeight.bold),
      ),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.95,
        height: MediaQuery.of(context).size.height * 0.7,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTextField(
                  label: 'Total Cholesterol (mg/dL) - Normal: <200',
                  hint: '200',
                  controller: _cholesterolTotalController,
                  validatorMessage: 'Please enter total cholesterol',
                  minValue: 50,
                  maxValue: 500,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  label: 'HDL Cholesterol (mg/dL) - Normal: 40-60',
                  hint: '50',
                  controller: _hdlController,
                  validatorMessage: 'Please enter HDL value',
                  minValue: 10,
                  maxValue: 150,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  label: 'LDL Cholesterol (mg/dL) - Normal: 0-159',
                  hint: '120',
                  controller: _ldlController,
                  validatorMessage: 'Please enter LDL value',
                  minValue: 30,
                  maxValue: 400,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  label: 'Triglycerides (mg/dL) - Normal: <150',
                  hint: '150',
                  controller: _triglyceridesController,
                  validatorMessage: 'Please enter triglycerides value',
                  minValue: 20,
                  maxValue: 800,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  label: 'VLDL Cholesterol (mg/dL) - Normal: 0-40',
                  hint: '30',
                  controller: _vldlController,
                  validatorMessage: 'Please enter VLDL value',
                  minValue: 5,
                  maxValue: 100,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  label: 'Non-HDL Cholesterol (mg/dL) - Normal: <130',
                  hint: '150',
                  controller: _nonHdlController,
                  validatorMessage: 'Please enter Non-HDL value',
                  minValue: 40,
                  maxValue: 450,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  label: 'Cholesterol/HDL Ratio - Normal: 0-5',
                  hint: '4.0',
                  controller: _cholHdlRatioController,
                  validatorMessage: 'Please enter cholesterol/HDL ratio',
                  minValue: 1,
                  maxValue: 10,
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: _selectDate,
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Date Recorded',
                      prefixIcon:
                          Icon(Icons.calendar_today, color: Color(0xFF2E7D84)),
                    ),
                    child:
                        Text(DateFormat('MMM dd, yyyy').format(_selectedDate)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _save,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2E7D84),
            foregroundColor: Colors.white,
          ),
          child: Text(widget.record == null ? 'Add' : 'Update'),
        ),
      ],
    );
  }
}
