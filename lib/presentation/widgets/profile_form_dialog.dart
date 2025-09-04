import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/profile.dart';
import '../../core/constants/app_constants.dart';
import '../../core/themes/app_theme.dart';
import '../providers/profile_provider.dart';

// Custom input formatter for medication field
class MedicationInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Convert to uppercase and replace commas with new lines
    String formattedText = newValue.text.toUpperCase();

    // Replace comma followed by space with newline, or just comma with newline
    formattedText = formattedText.replaceAll(RegExp(r',\s*'), '\n');

    return TextEditingValue(
      text: formattedText,
      selection: TextSelection.collapsed(
        offset: formattedText.length.clamp(0, formattedText.length),
      ),
    );
  }
}

class ProfileFormDialog extends ConsumerStatefulWidget {
  final Profile? profile; // null for add, profile for edit

  const ProfileFormDialog({
    super.key,
    this.profile,
  });

  @override
  ConsumerState<ProfileFormDialog> createState() => _ProfileFormDialogState();
}

class _ProfileFormDialogState extends ConsumerState<ProfileFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  final _medicationController = TextEditingController();

  // Focus nodes for each field
  final _nameFocus = FocusNode();
  final _ageFocus = FocusNode();
  final _genderFocus = FocusNode();
  final _bloodGroupFocus = FocusNode();

  // Global keys for positioning
  final _nameKey = GlobalKey();
  final _ageKey = GlobalKey();
  final _genderKey = GlobalKey();
  final _bloodGroupKey = GlobalKey();

  String? _selectedGender;
  String? _selectedBloodGroup;
  bool _isLoading = false;

  bool get isEditing => widget.profile != null;

  // Method to scroll to the first field with error
  Future<void> _scrollToFirstError() async {
    await Future.delayed(const Duration(milliseconds: 100));

    // Check each field for validation errors and scroll to first one
    String? nameError;
    String? ageError;
    String? genderError;
    String? bloodGroupError;

    // Check name field
    final nameValue = _nameController.text;
    if (nameValue.trim().isEmpty) {
      nameError = 'Name is required';
    } else if (nameValue.trim().length < AppConstants.minNameLength) {
      nameError =
          'Name must be at least ${AppConstants.minNameLength} characters';
    } else if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(nameValue.trim())) {
      nameError = 'Name should only contain alphabets and spaces';
    }

    // Check age field
    final ageValue = _ageController.text;
    if (ageValue.trim().isEmpty) {
      ageError = 'Age is required';
    } else {
      final age = int.tryParse(ageValue.trim());
      if (age == null) {
        ageError = 'Please enter a valid number';
      } else if (age < AppConstants.minAge || age > AppConstants.maxAge) {
        ageError =
            'Age must be between ${AppConstants.minAge} and ${AppConstants.maxAge}';
      }
    }

    // Check gender field
    if (_selectedGender == null || _selectedGender!.isEmpty) {
      genderError = 'Gender is required';
    }

    // Check blood group field
    if (_selectedBloodGroup == null || _selectedBloodGroup!.isEmpty) {
      bloodGroupError = 'Blood group is required';
    }

    // Scroll to first error field
    if (nameError != null) {
      await Scrollable.ensureVisible(_nameKey.currentContext!,
          duration: const Duration(milliseconds: 500), curve: Curves.easeInOut);
      _nameFocus.requestFocus();
    } else if (ageError != null) {
      await Scrollable.ensureVisible(_ageKey.currentContext!,
          duration: const Duration(milliseconds: 500), curve: Curves.easeInOut);
      _ageFocus.requestFocus();
    } else if (genderError != null) {
      await Scrollable.ensureVisible(_genderKey.currentContext!,
          duration: const Duration(milliseconds: 500), curve: Curves.easeInOut);
      _genderFocus.requestFocus();
    } else if (bloodGroupError != null) {
      await Scrollable.ensureVisible(_bloodGroupKey.currentContext!,
          duration: const Duration(milliseconds: 500), curve: Curves.easeInOut);
      _bloodGroupFocus.requestFocus();
    }
  }

  @override
  void initState() {
    super.initState();
    if (isEditing) {
      _nameController.text = widget.profile!.name;
      _ageController.text = widget.profile!.age.toString();
      _selectedGender = widget.profile!.gender;
      _selectedBloodGroup = widget.profile!.bloodGroup;
      if (widget.profile!.height != null) {
        _heightController.text = widget.profile!.height.toString();
      }
      if (widget.profile!.weight != null) {
        _weightController.text = widget.profile!.weight.toString();
      }
      if (widget.profile!.medication != null) {
        _medicationController.text = widget.profile!.medication!;
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _nameController.dispose();
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _medicationController.dispose();

    _nameFocus.dispose();
    _ageFocus.dispose();
    _genderFocus.dispose();
    _bloodGroupFocus.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        isEditing ? 'Edit Profile' : 'Add Profile',
        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
      ),
      content: SingleChildScrollView(
        controller: _scrollController,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Name Field
              TextFormField(
                key: _nameKey,
                controller: _nameController,
                focusNode: _nameFocus,
                decoration: const InputDecoration(
                  labelText: 'Name *',
                  hintText: 'Enter full name',
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Name is required';
                  }
                  if (value.trim().length < AppConstants.minNameLength) {
                    return 'Name must be at least ${AppConstants.minNameLength} characters';
                  }
                  if (value.trim().length > AppConstants.maxNameLength) {
                    return 'Name must be less than ${AppConstants.maxNameLength} characters';
                  }
                  // Check if name contains only alphabets and spaces
                  final nameRegex = RegExp(r'^[a-zA-Z\s]+$');
                  if (!nameRegex.hasMatch(value.trim())) {
                    return 'Name should only contain alphabets and spaces';
                  }
                  return null;
                },
                textCapitalization: TextCapitalization.words,
                enabled: !_isLoading,
              ),

              const SizedBox(height: 16),

              // Age Field
              TextFormField(
                key: _ageKey,
                controller: _ageController,
                focusNode: _ageFocus,
                decoration: const InputDecoration(
                  labelText: 'Age *',
                  hintText: 'Enter age',
                  prefixIcon: Icon(Icons.cake),
                  suffixText: 'years',
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Age is required';
                  }
                  final age = int.tryParse(value.trim());
                  if (age == null) {
                    return 'Please enter a valid number';
                  }
                  if (age < AppConstants.minAge || age > AppConstants.maxAge) {
                    return 'Age must be between ${AppConstants.minAge} and ${AppConstants.maxAge}';
                  }
                  return null;
                },
                enabled: !_isLoading,
              ),

              const SizedBox(height: 16),

              // Gender Dropdown
              DropdownButtonFormField<String>(
                key: _genderKey,
                focusNode: _genderFocus,
                value: _selectedGender,
                decoration: const InputDecoration(
                  labelText: 'Gender *',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                items: AppConstants.genders.map((gender) {
                  return DropdownMenuItem(
                    value: gender,
                    child: Text(gender),
                  );
                }).toList(),
                onChanged: _isLoading
                    ? null
                    : (value) {
                        setState(() {
                          _selectedGender = value;
                        });
                      },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Gender is required';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Blood Group Dropdown
              DropdownButtonFormField<String>(
                key: _bloodGroupKey,
                focusNode: _bloodGroupFocus,
                value: _selectedBloodGroup,
                decoration: const InputDecoration(
                  labelText: 'Blood Group *',
                  prefixIcon: Icon(Icons.bloodtype),
                ),
                items: AppConstants.bloodGroups.map((bloodGroup) {
                  return DropdownMenuItem(
                    value: bloodGroup,
                    child: Text(bloodGroup),
                  );
                }).toList(),
                onChanged: _isLoading
                    ? null
                    : (value) {
                        setState(() {
                          _selectedBloodGroup = value;
                        });
                      },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Blood group is required';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Height Field
              TextFormField(
                controller: _heightController,
                decoration: const InputDecoration(
                  labelText: 'Height',
                  hintText: 'Enter height',
                  prefixIcon: Icon(Icons.height),
                  suffixText: 'cm',
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*$')),
                ],
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return null; // Height is optional
                  }
                  final height = double.tryParse(value.trim());
                  if (height == null) {
                    return 'Please enter a valid number';
                  }
                  if (height < AppConstants.minHeight ||
                      height > AppConstants.maxHeight) {
                    return 'Height must be between ${AppConstants.minHeight} and ${AppConstants.maxHeight} cm';
                  }
                  return null;
                },
                enabled: !_isLoading,
              ),

              const SizedBox(height: 16),

              // Weight Field
              TextFormField(
                controller: _weightController,
                decoration: const InputDecoration(
                  labelText: 'Weight',
                  hintText: 'Enter weight',
                  prefixIcon: Icon(Icons.monitor_weight),
                  suffixText: 'kg',
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*$')),
                ],
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return null; // Weight is optional
                  }
                  final weight = double.tryParse(value.trim());
                  if (weight == null) {
                    return 'Please enter a valid number';
                  }
                  if (weight < AppConstants.minWeight ||
                      weight > AppConstants.maxWeight) {
                    return 'Weight must be between ${AppConstants.minWeight} and ${AppConstants.maxWeight} kg';
                  }
                  return null;
                },
                enabled: !_isLoading,
              ),

              const SizedBox(height: 16),

              // Medication Field
              TextFormField(
                controller: _medicationController,
                decoration: const InputDecoration(
                  labelText: 'Medication',
                  hintText:
                      'Enter medication details (optional)\nUse commas to separate medications',
                  prefixIcon: Icon(Icons.medical_services),
                ),
                maxLength: AppConstants.maxMedicationLength,
                maxLines: 3,
                inputFormatters: [
                  MedicationInputFormatter(),
                ],
                validator: (value) {
                  if (value != null &&
                      value.trim().length > AppConstants.maxMedicationLength) {
                    return 'Medication details must be less than ${AppConstants.maxMedicationLength} characters';
                  }
                  return null;
                },
                enabled: !_isLoading,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _saveProfile,
          style: AppTheme.primaryButtonStyle,
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(isEditing ? 'Update' : 'Add'),
        ),
      ],
    );
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      // Scroll to first error field
      await _scrollToFirstError();
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final name = _nameController.text.trim();
      final age = int.parse(_ageController.text.trim());
      final height = _heightController.text.trim().isEmpty
          ? null
          : double.parse(_heightController.text.trim());
      final weight = _weightController.text.trim().isEmpty
          ? null
          : double.parse(_weightController.text.trim());
      final medication = _medicationController.text.trim().isEmpty
          ? null
          : _medicationController.text.trim();

      // Check for duplicate name (excluding current profile if editing)
      final nameExists = await ref
          .read(profileNotifierProvider.notifier)
          .checkProfileNameExists(name, excludeId: widget.profile?.id);

      if (nameExists) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile name already exists'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
        return;
      }

      if (isEditing) {
        // Update existing profile
        final updatedProfile = widget.profile!.copyWith(
          name: name,
          age: age,
          gender: _selectedGender!,
          bloodGroup: _selectedBloodGroup!,
          height: height,
          weight: weight,
          medication: medication,
        );

        await ref
            .read(profileNotifierProvider.notifier)
            .updateProfile(updatedProfile);

        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile updated successfully'),
              backgroundColor: AppTheme.successColor,
            ),
          );
        }
      } else {
        // Create new profile
        final newProfile = Profile(
          name: name,
          age: age,
          gender: _selectedGender!,
          bloodGroup: _selectedBloodGroup!,
          height: height,
          weight: weight,
          medication: medication,
        );

        await ref.read(profileNotifierProvider.notifier).addProfile(newProfile);

        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile saved successfully'),
              backgroundColor: AppTheme.successColor,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save profile: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
