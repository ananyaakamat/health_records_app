import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/models/sugar_record.dart';

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
      if (widget.record!.fbs != null) {
        _fbsController.text = widget.record!.fbs.toString();
      }
      if (widget.record!.ppbs != null) {
        _ppbsController.text = widget.record!.ppbs.toString();
      }
      if (widget.record!.rbs != null) {
        _rbsController.text = widget.record!.rbs.toString();
      }
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
            : int.parse(_fbsController.text),
        ppbs: _ppbsController.text.isEmpty
            ? null
            : int.parse(_ppbsController.text),
        rbs: _rbsController.text.isEmpty
            ? null
            : int.parse(_rbsController.text),
        hba1c: double.parse(_hba1cController.text),
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
        widget.record == null ? 'Add Sugar Record' : 'Edit Sugar Record',
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
              TextFormField(
                controller: _fbsController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'FBS (mg/dL) - Normal: 80-100',
                  hintText: 'Enter FBS value',
                  prefixIcon: Icon(Icons.bloodtype, color: Color(0xFF2E7D84)),
                ),
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    final fbs = int.tryParse(value);
                    if (fbs == null || fbs <= 0) {
                      return 'Please enter a valid FBS value';
                    }
                    if (fbs > 500) {
                      return 'FBS value seems too high';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _ppbsController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'PPBS (mg/dL) - Normal: 120-140',
                  hintText: 'Enter PPBS value',
                  prefixIcon: Icon(Icons.bloodtype, color: Color(0xFF2E7D84)),
                ),
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    final ppbs = int.tryParse(value);
                    if (ppbs == null || ppbs <= 0) {
                      return 'Please enter a valid PPBS value';
                    }
                    if (ppbs > 500) {
                      return 'PPBS value seems too high';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _rbsController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'RBS (mg/dL) - Normal: <140',
                  hintText: 'Enter RBS value',
                  prefixIcon: Icon(Icons.bloodtype, color: Color(0xFF2E7D84)),
                ),
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    final rbs = int.tryParse(value);
                    if (rbs == null || rbs <= 0) {
                      return 'Please enter a valid RBS value';
                    }
                    if (rbs > 500) {
                      return 'RBS value seems too high';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _hba1cController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'HbA1c (%) - Normal: 4.0-5.6%',
                  hintText: 'Enter HbA1c percentage',
                  prefixIcon: Icon(Icons.bloodtype, color: Color(0xFF2E7D84)),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter HbA1c value';
                  }
                  final hba1c = double.tryParse(value);
                  if (hba1c == null || hba1c <= 0) {
                    return 'Please enter a valid HbA1c value';
                  }
                  if (hba1c > 20) {
                    return 'HbA1c value seems too high';
                  }
                  return null;
                },
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
