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
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    if (widget.record != null) {
      _systolicController.text = widget.record!.systolic.toString();
      _diastolicController.text = widget.record!.diastolic.toString();
      _selectedDate = widget.record!.recordDate;
    }
  }

  @override
  void dispose() {
    _systolicController.dispose();
    _diastolicController.dispose();
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
      final record = BPRecord(
        id: widget.record?.id,
        profileId: widget.profileId,
        systolic: int.parse(_systolicController.text),
        diastolic: int.parse(_diastolicController.text),
        recordDate: _selectedDate,
      );
      widget.onSave(record);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.record == null
            ? 'Add Blood Pressure Record'
            : 'Edit Blood Pressure Record',
        style: const TextStyle(
            color: Color(0xFF2E7D84), fontWeight: FontWeight.bold),
      ),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.9,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _systolicController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Systolic (mmHg)',
                        hintText: '120',
                        prefixIcon:
                            Icon(Icons.favorite, color: Color(0xFF2E7D84)),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter systolic value';
                        }
                        final systolic = int.tryParse(value);
                        if (systolic == null || systolic <= 0) {
                          return 'Please enter a valid systolic value';
                        }
                        if (systolic < 60 || systolic > 300) {
                          return 'Systolic value should be between 60-300';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _diastolicController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Diastolic (mmHg)',
                        hintText: '80',
                        prefixIcon:
                            Icon(Icons.monitor_heart, color: Color(0xFF2E7D84)),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter diastolic value';
                        }
                        final diastolic = int.tryParse(value);
                        if (diastolic == null || diastolic <= 0) {
                          return 'Please enter a valid diastolic value';
                        }
                        if (diastolic < 40 || diastolic > 200) {
                          return 'Diastolic value should be between 40-200';
                        }

                        // Check if systolic is greater than diastolic
                        final systolic = int.tryParse(_systolicController.text);
                        if (systolic != null && diastolic >= systolic) {
                          return 'Diastolic should be less than systolic';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
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
                  child: Text(DateFormat('MMM dd, yyyy').format(_selectedDate)),
                ),
              ),
            ],
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
