import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math' as math;
import '../../data/models/profile.dart';
import '../../core/themes/app_theme.dart';
import '../providers/sugar_record_provider.dart';
import '../providers/bp_record_provider.dart';
import '../providers/lipid_record_provider.dart';
import '../widgets/sugar_record_form_dialog.dart';
import '../widgets/bp_record_form_dialog.dart';
import '../widgets/lipid_record_form_dialog.dart';
import '../../data/models/sugar_record.dart';
import '../../data/models/bp_record.dart';
import '../../data/models/lipid_record.dart';
import 'package:intl/intl.dart';
import 'home_screen.dart';
import 'user_guide_screen.dart';

enum GraphType { sugar, bloodPressure, lipidProfile }

class ProfileDetailScreen extends ConsumerWidget {
  final Profile profile;

  const ProfileDetailScreen({
    super.key,
    required this.profile,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.home),
          onPressed: () {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => const HomeScreen()),
              (route) => false,
            );
          },
          tooltip: 'Home',
        ),
        title: Text(profile.name),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) =>
                      const UserGuideScreen(currentPage: 'Profile Detail'),
                ),
              );
            },
            tooltip: 'Help',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Profile Summary Section
            _buildProfileSummary(context),

            const SizedBox(height: 6), // Further reduced by 50% (from 12 to 6)

            // Health Records Tabs Section
            _buildHealthRecordsSection(context, ref),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileSummary(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Profile Details
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildInfoCard(
                context,
                icon: Icons.cake_outlined,
                label: 'Age',
                value: '${profile.age} years',
              ),
              _buildInfoCard(
                context,
                icon: profile.gender == 'Male'
                    ? Icons.male
                    : profile.gender == 'Female'
                        ? Icons.female
                        : Icons.person,
                label: 'Gender',
                value: profile.gender,
              ),
              _buildInfoCard(
                context,
                icon: Icons.bloodtype,
                label: 'Blood Group',
                value: profile.bloodGroup,
              ),
            ],
          ),

          // BMI Card (if height and weight are available)
          if (profile.bmi != null) ...[
            const SizedBox(height: 20),
            _buildBMICard(context),
          ],

          // Medication Card (if medication is available)
          if (profile.medication != null && profile.medication!.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildMedicationCard(context),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          size: 24,
          color: AppTheme.primaryColor,
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                fontWeight: FontWeight.w500,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }

  Widget _buildBMICard(BuildContext context) {
    final bmi = profile.bmi!;
    final category = profile.bmiCategory;

    Color categoryColor;
    if (bmi < 18.5) {
      categoryColor = Colors.blue;
    } else if (bmi < 25.0) {
      categoryColor = Colors.green;
    } else if (bmi < 30.0) {
      categoryColor = Colors.orange;
    } else {
      categoryColor = Colors.red;
    }

    return Container(
      padding: const EdgeInsets.all(
          12), // Reduced from 16 to 12 (25% reduction for 20% height reduction)
      decoration: BoxDecoration(
        color: categoryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: categoryColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.monitor_weight,
            size: 28, // Reduced from 32 to 28
            color: categoryColor,
          ),
          const SizedBox(width: 12), // Reduced from 16 to 12
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'BMI: ${bmi.toStringAsFixed(1)}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: categoryColor,
                      ),
                ),
                Text(
                  'Category: $category',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: categoryColor,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                if (profile.height != null && profile.weight != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Height: ${profile.height!.toStringAsFixed(0)} cm | Weight: ${profile.weight!.toStringAsFixed(1)} kg',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.7),
                        ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMedicationCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.primaryColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.medical_services,
            size: 28,
            color: AppTheme.primaryColor,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Medication',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  profile.medication!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHealthRecordsSection(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: DefaultTabController(
        length: 3,
        child: Column(
          children: [
            // Tab Bar
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(12)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TabBar(
                labelColor: AppTheme.primaryColor,
                unselectedLabelColor:
                    Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                indicatorColor: AppTheme.primaryColor,
                tabs: const [
                  Tab(
                    icon: Icon(Icons.favorite, size: 20),
                    text: 'Sugar',
                  ),
                  Tab(
                    icon: Icon(Icons.monitor_heart, size: 20),
                    text: 'BP',
                  ),
                  Tab(
                    icon: Icon(Icons.science, size: 20),
                    text: 'Lipids',
                  ),
                ],
              ),
            ),

            // Tab Views
            Container(
              height: 600, // Increased height to accommodate graphs
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius:
                    const BorderRadius.vertical(bottom: Radius.circular(12)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TabBarView(
                children: [
                  _buildSugarRecordsTab(),
                  _buildBPRecordsTab(),
                  _buildLipidRecordsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSugarRecordsTab() {
    return Consumer(
      builder: (context, ref, child) {
        final sugarRecordsAsync =
            ref.watch(sugarRecordNotifierProvider(profile.id!));

        return sugarRecordsAsync.when(
          data: (records) => Column(
            children: [
              // Table Section for Sugar Records
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.table_chart,
                                  color: AppTheme.primaryColor),
                              const SizedBox(width: 8),
                              Text(
                                'HbA1c ${records.length} record${records.length != 1 ? 's' : ''}',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ],
                          ),
                          ElevatedButton.icon(
                            onPressed: () => _showSugarRecordForm(context, ref),
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('Add Record'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: _buildSugarTable(
                          context,
                          records.cast<SugarRecord>(),
                          ref,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(child: Text('Error: $error')),
        );
      },
    );
  }

  Widget _buildBPRecordsTab() {
    return Consumer(
      builder: (context, ref, child) {
        final bpRecordsAsync = ref.watch(bpRecordNotifierProvider(profile.id!));

        return bpRecordsAsync.when(
          data: (records) => Column(
            children: [
              // Table Section for BP Records
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.table_chart,
                                  color: AppTheme.primaryColor),
                              const SizedBox(width: 8),
                              Text(
                                'BP ${records.length} record${records.length != 1 ? 's' : ''}',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ],
                          ),
                          ElevatedButton.icon(
                            onPressed: () => _showBPRecordForm(context, ref),
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('Add Record'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: _buildBPTable(
                          context,
                          records.cast<BPRecord>(),
                          ref,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(child: Text('Error: $error')),
        );
      },
    );
  }

  Widget _buildLipidRecordsTab() {
    return Consumer(
      builder: (context, ref, child) {
        final lipidRecordsAsync =
            ref.watch(lipidRecordNotifierProvider(profile.id!));

        return lipidRecordsAsync.when(
          data: (records) => Column(
            children: [
              // Table Section for Lipid Records
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.table_chart,
                                  color: AppTheme.primaryColor),
                              const SizedBox(width: 8),
                              Text(
                                'Lipids ${records.length} record${records.length != 1 ? 's' : ''}',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ],
                          ),
                          ElevatedButton.icon(
                            onPressed: () => _showLipidRecordForm(context, ref),
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('Add Record'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: _buildLipidTable(
                          context,
                          records.cast<LipidRecord>(),
                          ref,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(child: Text('Error: $error')),
        );
      },
    );
  }

  Widget _buildSugarTable(
      BuildContext context, List<SugarRecord> records, WidgetRef ref) {
    // Sort records by date descending (latest first)
    final sortedRecords = List<SugarRecord>.from(records)
      ..sort((a, b) => b.recordDate.compareTo(a.recordDate));

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? Theme.of(context).cardColor : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.grey.shade600 : Colors.grey.shade300,
        ),
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.black : Colors.black).withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: _SimpleSugarTable(
        sortedRecords: sortedRecords,
        isDark: isDark,
        getSugarColor: _getSugarColor,
        onEdit: (record) => _showSugarRecordForm(context, ref, record: record),
        onDelete: (record) => _deleteSugarRecord(context, ref, record),
      ),
    );
  }

  // Helper method to get color based on sugar levels
  Color _getSugarColor(num? value, String type, {bool isDark = false}) {
    if (value == null) {
      return isDark ? Colors.grey.shade400 : Colors.grey.shade600;
    }

    switch (type) {
      case 'fbs': // FBS (80-100)
        if (value >= 80 && value <= 100) {
          return isDark ? Colors.green.shade300 : Colors.green.shade700;
        } else if ((value >= 70 && value < 80) ||
            (value > 100 && value <= 125)) {
          return isDark ? Colors.orange.shade300 : Colors.orange.shade700;
        } else {
          return isDark ? Colors.red.shade300 : Colors.red.shade700;
        }
      case 'ppbs': // PPBS (120-140)
        if (value >= 120 && value <= 140) {
          return isDark ? Colors.green.shade300 : Colors.green.shade700;
        } else if ((value >= 110 && value < 120) ||
            (value > 140 && value <= 160)) {
          return isDark ? Colors.orange.shade300 : Colors.orange.shade700;
        } else {
          return isDark ? Colors.red.shade300 : Colors.red.shade700;
        }
      case 'rbs': // RBS (<140)
        if (value < 140) {
          return isDark ? Colors.green.shade300 : Colors.green.shade700;
        } else if (value >= 140 && value <= 180) {
          return isDark ? Colors.orange.shade300 : Colors.orange.shade700;
        } else {
          return isDark ? Colors.red.shade300 : Colors.red.shade700;
        }
      case 'hba1c': // HbA1c (4-5.6)
        if (value >= 4.0 && value <= 5.6) {
          return isDark ? Colors.green.shade300 : Colors.green.shade700;
        } else if (value > 5.6 && value <= 6.4) {
          return isDark ? Colors.orange.shade300 : Colors.orange.shade700;
        } else {
          return isDark ? Colors.red.shade300 : Colors.red.shade700;
        }
      default:
        return isDark
            ? Colors.white.withOpacity(0.87)
            : Colors.black.withOpacity(0.87);
    }
  }

  Widget _buildBPTable(
      BuildContext context, List<BPRecord> records, WidgetRef ref) {
    // Sort records by date descending (latest first)
    final sortedRecords = List<BPRecord>.from(records)
      ..sort((a, b) => b.recordDate.compareTo(a.recordDate));

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? Theme.of(context).cardColor : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.grey.shade600 : Colors.grey.shade300,
        ),
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.black : Colors.black).withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: _SimpleBPTable(
        sortedRecords: sortedRecords,
        isDark: isDark,
        getBPColor: _getBPColor,
        onEdit: (record) => _showBPRecordForm(context, ref, record: record),
        onDelete: (record) => _deleteBPRecord(context, ref, record),
      ),
    );
  }

  // Helper method to get color based on BP levels
  Color _getBPColor(int value, String type, {bool isDark = false}) {
    if (type == 'systolic') {
      if (value < 120) {
        return isDark ? Colors.green.shade300 : Colors.green.shade700;
      } else if (value < 140) {
        return isDark ? Colors.orange.shade300 : Colors.orange.shade700;
      } else {
        return isDark ? Colors.red.shade300 : Colors.red.shade700;
      }
    } else if (type == 'diastolic') {
      if (value < 80) {
        return isDark ? Colors.green.shade300 : Colors.green.shade700;
      } else if (value < 90) {
        return isDark ? Colors.orange.shade300 : Colors.orange.shade700;
      } else {
        return isDark ? Colors.red.shade300 : Colors.red.shade700;
      }
    } else if (type == 'bpm') {
      // BPM: 60-80 is normal (green), otherwise yellow/orange
      if (value >= 60 && value <= 80) {
        return isDark ? Colors.green.shade300 : Colors.green.shade700;
      } else {
        return isDark ? Colors.orange.shade300 : Colors.orange.shade700;
      }
    }
    // Default color for unknown type
    return isDark
        ? Colors.white.withOpacity(0.87)
        : Colors.black.withOpacity(0.87);
  }

  Widget _buildLipidTable(
      BuildContext context, List<LipidRecord> records, WidgetRef ref) {
    // Sort records by date descending (latest first)
    final sortedRecords = List<LipidRecord>.from(records)
      ..sort((a, b) => b.recordDate.compareTo(a.recordDate));

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? Theme.of(context).cardColor : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.grey.shade600 : Colors.grey.shade300,
        ),
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.black : Colors.black).withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: _SimpleLipidTable(
        sortedRecords: sortedRecords,
        isDark: isDark,
        getLipidColor: _getLipidColor,
        onEdit: (record) => _showLipidRecordForm(context, ref, record: record),
        onDelete: (record) => _deleteLipidRecord(context, ref, record),
      ),
    );
  }

  // Helper method to get color based on lipid levels
  Color _getLipidColor(num value, String type, {bool isDark = false}) {
    switch (type) {
      case 'tc': // Total Cholesterol (<200)
        if (value < 200) {
          return isDark ? Colors.green.shade300 : Colors.green.shade700;
        } else if (value < 240) {
          return isDark ? Colors.orange.shade300 : Colors.orange.shade700;
        } else {
          return isDark ? Colors.red.shade300 : Colors.red.shade700;
        }
      case 'tg': // Triglycerides (<150)
        if (value < 150) {
          return isDark ? Colors.green.shade300 : Colors.green.shade700;
        } else if (value < 200) {
          return isDark ? Colors.orange.shade300 : Colors.orange.shade700;
        } else {
          return isDark ? Colors.red.shade300 : Colors.red.shade700;
        }
      case 'hdl': // HDL-C (40-60)
        if (value >= 40 && value <= 60) {
          return isDark ? Colors.green.shade300 : Colors.green.shade700;
        } else if (value >= 35 && value < 40) {
          return isDark ? Colors.orange.shade300 : Colors.orange.shade700;
        } else {
          return isDark ? Colors.red.shade300 : Colors.red.shade700;
        }
      case 'nonhdl': // Non-HDL-C (<130)
        if (value < 130) {
          return isDark ? Colors.green.shade300 : Colors.green.shade700;
        } else if (value < 160) {
          return isDark ? Colors.orange.shade300 : Colors.orange.shade700;
        } else {
          return isDark ? Colors.red.shade300 : Colors.red.shade700;
        }
      case 'ldl': // LDL-C (0-159)
        if (value <= 100) {
          return isDark ? Colors.green.shade300 : Colors.green.shade700;
        } else if (value <= 159) {
          return isDark ? Colors.orange.shade300 : Colors.orange.shade700;
        } else {
          return isDark ? Colors.red.shade300 : Colors.red.shade700;
        }
      case 'vldl': // VLDL-C (0-40)
        if (value <= 30) {
          return isDark ? Colors.green.shade300 : Colors.green.shade700;
        } else if (value <= 40) {
          return isDark ? Colors.orange.shade300 : Colors.orange.shade700;
        } else {
          return isDark ? Colors.red.shade300 : Colors.red.shade700;
        }
      case 'ratio': // TC/HDL Ratio (0-5)
        if (value <= 3.5) {
          return isDark ? Colors.green.shade300 : Colors.green.shade700;
        } else if (value <= 5.0) {
          return isDark ? Colors.orange.shade300 : Colors.orange.shade700;
        } else {
          return isDark ? Colors.red.shade300 : Colors.red.shade700;
        }
      default:
        return isDark
            ? Colors.white.withOpacity(0.87)
            : Colors.black.withOpacity(0.87);
    }
  }

  void _showSugarRecordForm(BuildContext context, WidgetRef ref,
      {SugarRecord? record}) {
    showDialog(
      context: context,
      builder: (context) => SugarRecordFormDialog(
        profileId: profile.id!,
        record: record,
        onSave: (sugarRecord) async {
          final notifier =
              ref.read(sugarRecordNotifierProvider(profile.id!).notifier);
          try {
            if (record == null) {
              await notifier.addRecord(sugarRecord);
            } else {
              await notifier.updateRecord(sugarRecord);
            }
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    record == null
                        ? 'Sugar record added successfully'
                        : 'Sugar record updated successfully',
                  ),
                  backgroundColor: AppTheme.primaryColor,
                ),
              );
            }
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error: $e'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        },
      ),
    );
  }

  void _showBPRecordForm(BuildContext context, WidgetRef ref,
      {BPRecord? record}) {
    showDialog(
      context: context,
      builder: (context) => BPRecordFormDialog(
        profileId: profile.id!,
        record: record,
        onSave: (bpRecord) async {
          final notifier =
              ref.read(bpRecordNotifierProvider(profile.id!).notifier);
          try {
            if (record == null) {
              await notifier.addRecord(bpRecord);
            } else {
              await notifier.updateRecord(bpRecord);
            }
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    record == null
                        ? 'BP record added successfully'
                        : 'BP record updated successfully',
                  ),
                  backgroundColor: AppTheme.primaryColor,
                ),
              );
            }
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error: $e'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        },
      ),
    );
  }

  void _showLipidRecordForm(BuildContext context, WidgetRef ref,
      {LipidRecord? record}) {
    showDialog(
      context: context,
      builder: (context) => LipidRecordFormDialog(
        profileId: profile.id!,
        record: record,
        onSave: (lipidRecord) async {
          final notifier =
              ref.read(lipidRecordNotifierProvider(profile.id!).notifier);
          try {
            if (record == null) {
              await notifier.addRecord(lipidRecord);
            } else {
              await notifier.updateRecord(lipidRecord);
            }
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    record == null
                        ? 'Lipid record added successfully'
                        : 'Lipid record updated successfully',
                  ),
                  backgroundColor: AppTheme.primaryColor,
                ),
              );
            }
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error: $e'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        },
      ),
    );
  }

  void _deleteSugarRecord(
      BuildContext context, WidgetRef ref, SugarRecord record) {
    _showDeleteConfirmationDialog(
      context: context,
      title: 'Delete Record',
      content:
          'Delete record dated ${DateFormat('dd-MMM-yyyy').format(record.recordDate)}?',
      onConfirm: () {
        final notifier =
            ref.read(sugarRecordNotifierProvider(profile.id!).notifier);
        notifier.deleteRecord(record.id!);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('HbA1c record deleted successfully')),
        );
      },
    );
  }

  void _deleteBPRecord(BuildContext context, WidgetRef ref, BPRecord record) {
    _showDeleteConfirmationDialog(
      context: context,
      title: 'Delete Blood Pressure Record',
      content:
          'Are you sure you want to delete this blood pressure record?\n\nDate: ${DateFormat('MMM d, y').format(record.recordDate)}',
      onConfirm: () {
        final notifier =
            ref.read(bpRecordNotifierProvider(profile.id!).notifier);
        notifier.deleteRecord(record.id!);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Blood pressure record deleted successfully')),
        );
      },
    );
  }

  void _deleteLipidRecord(
      BuildContext context, WidgetRef ref, LipidRecord record) {
    _showDeleteConfirmationDialog(
      context: context,
      title: 'Delete Lipid Profile Record',
      content:
          'Are you sure you want to delete this lipid profile record?\n\nDate: ${DateFormat('MMM d, y').format(record.recordDate)}',
      onConfirm: () {
        final notifier =
            ref.read(lipidRecordNotifierProvider(profile.id!).notifier);
        notifier.deleteRecord(record.id!);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Lipid profile record deleted successfully')),
        );
      },
    );
  }

  void _showDeleteConfirmationDialog({
    required BuildContext context,
    required String title,
    required String content,
    required VoidCallback onConfirm,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              onConfirm();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class FullScreenGraphScreen extends ConsumerStatefulWidget {
  final Profile profile;
  final GraphType graphType;
  final String title;
  final List<dynamic> records;

  const FullScreenGraphScreen({
    super.key,
    required this.profile,
    required this.graphType,
    required this.title,
    required this.records,
  });

  @override
  ConsumerState<FullScreenGraphScreen> createState() =>
      _FullScreenGraphScreenState();
}

class _FullScreenGraphScreenState extends ConsumerState<FullScreenGraphScreen> {
  @override
  void initState() {
    super.initState();
    // Switch to landscape mode
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  @override
  void dispose() {
    // Switch back to portrait mode when leaving the screen
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            // Full screen graph with minimal padding for true 80% coverage
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: _buildFullScreenGraph(),
            ),
            // Close button overlay - moved to bottom right
            Positioned(
              bottom: 8,
              right: 8,
              child: Material(
                color: Colors.black54,
                shape: const CircleBorder(),
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
            // Title overlay - moved to bottom left
            Positioned(
              bottom: 8,
              left: 8,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${widget.title} - ${widget.profile.name}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFullScreenGraph() {
    switch (widget.graphType) {
      case GraphType.sugar:
        return _buildFullScreenSugarGraph();
      case GraphType.bloodPressure:
        return _buildFullScreenBPGraph();
      case GraphType.lipidProfile:
        return _buildFullScreenLipidGraph();
    }
  }

  Widget _buildFullScreenSugarGraph() {
    final records = widget.records.cast<SugarRecord>();

    if (records.isEmpty) {
      return const Center(
        child: Text('No HbA1c data available', style: TextStyle(fontSize: 18)),
      );
    }

    // Sort records by date
    final sortedRecords = List<SugarRecord>.from(records)
      ..sort((a, b) => a.recordDate.compareTo(b.recordDate));

    final spots = sortedRecords.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.hba1c);
    }).toList();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        width: math.max(
            400,
            sortedRecords.length * 80.0 +
                80), // Added extra 80px padding for last date
        child: Stack(
          children: [
            // Main LineChart
            LineChart(
              LineChartData(
                lineTouchData: LineTouchData(
                  enabled: true,
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
                      return touchedBarSpots.map((barSpot) {
                        return LineTooltipItem(
                          '${barSpot.y.toStringAsFixed(1)}%',
                          const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),
                gridData: const FlGridData(
                  show: true,
                  drawVerticalLine: true,
                  horizontalInterval: 0.5,
                  verticalInterval: 1,
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 60,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '${value.toStringAsFixed(1)}%',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize:
                          120, // Further increased to prevent date truncation
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index >= 0 && index < sortedRecords.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Transform.rotate(
                              angle: -0.2,
                              child: Text(
                                DateFormat('MM/dd/yy')
                                    .format(sortedRecords[index].recordDate),
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: true),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: AppTheme.primaryColor,
                    barWidth: 4,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) =>
                          FlDotCirclePainter(
                        radius: 3, // Reduced dot size as requested
                        color: AppTheme.primaryColor,
                        strokeWidth: 1,
                        strokeColor: Colors.white,
                      ),
                    ),
                    showingIndicators:
                        List.generate(spots.length, (index) => index),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppTheme.primaryColor.withOpacity(0.2),
                    ),
                  ),
                ],
              ),
            ),
            // Permanently visible data value labels
            ...spots.asMap().entries.map((entry) {
              final index = entry.key;
              final spot = entry.value;

              // Calculate accurate position accounting for left axis reserved size
              final xOffset = 60 +
                  (index * 80.0) +
                  40; // 60px left axis + index spacing + centering

              // Calculate Y position based on the actual data value
              // Assuming chart area is ~300px high, starting at ~100px from top
              final minValue =
                  records.map((r) => r.hba1c).reduce((a, b) => a < b ? a : b) -
                      0.2;
              final maxValue =
                  records.map((r) => r.hba1c).reduce((a, b) => a > b ? a : b) +
                      0.2;
              const chartAreaTop = 100.0;
              const chartAreaHeight = 300.0;
              final normalizedValue =
                  (spot.y - minValue) / (maxValue - minValue);
              final yOffset = chartAreaTop +
                  (chartAreaHeight * (1 - normalizedValue)) -
                  30; // -30 to position above the dot

              return Positioned(
                left: xOffset,
                top: yOffset,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        offset: Offset(0, 2),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: Text(
                    '${spot.y.toStringAsFixed(1)}%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildFullScreenBPGraph() {
    final records = widget.records.cast<BPRecord>();

    if (records.isEmpty) {
      return const Center(
        child: Text('No Blood Pressure data available',
            style: TextStyle(fontSize: 18)),
      );
    }

    // Sort records by date
    final sortedRecords = List<BPRecord>.from(records)
      ..sort((a, b) => a.recordDate.compareTo(b.recordDate));

    final systolicSpots = sortedRecords.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.systolic.toDouble());
    }).toList();

    final diastolicSpots = sortedRecords.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.diastolic.toDouble());
    }).toList();

    return Column(
      children: [
        // Legend
        Container(
          height: 50,
          padding: const EdgeInsets.all(8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendItem('Systolic', Colors.red),
              const SizedBox(width: 30),
              _buildLegendItem('Diastolic', Colors.blue),
            ],
          ),
        ),
        // Chart
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: math.max(
                  400,
                  sortedRecords.length * 80.0 +
                      80), // Added extra 80px padding for last date
              child: Stack(
                children: [
                  // Main LineChart
                  LineChart(
                    LineChartData(
                      lineTouchData: LineTouchData(
                        enabled: true,
                        touchTooltipData: LineTouchTooltipData(
                          getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
                            return touchedBarSpots.map((barSpot) {
                              final isSystemic = barSpot.barIndex == 0;
                              return LineTooltipItem(
                                '${isSystemic ? "Sys" : "Dia"}: ${barSpot.y.toInt()}',
                                const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              );
                            }).toList();
                          },
                        ),
                      ),
                      gridData: const FlGridData(
                        show: true,
                        drawVerticalLine: true,
                        horizontalInterval: 10,
                        verticalInterval: 1,
                      ),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 60,
                            getTitlesWidget: (value, meta) {
                              return Text(
                                '${value.toInt()}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              );
                            },
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize:
                                120, // Further increased to prevent date truncation
                            interval: 1,
                            getTitlesWidget: (value, meta) {
                              final index = value.toInt();
                              if (index >= 0 && index < sortedRecords.length) {
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Transform.rotate(
                                    angle: -0.2,
                                    child: Text(
                                      DateFormat('MM/dd/yy').format(
                                          sortedRecords[index].recordDate),
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ),
                                );
                              }
                              return const Text('');
                            },
                          ),
                        ),
                        rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                      ),
                      borderData: FlBorderData(show: true),
                      lineBarsData: [
                        LineChartBarData(
                          spots: systolicSpots,
                          isCurved: true,
                          color: Colors.red,
                          barWidth: 4,
                          dotData: FlDotData(
                            show: true,
                            getDotPainter: (spot, percent, barData, index) =>
                                FlDotCirclePainter(
                              radius: 3, // Reduced dot size as requested
                              color: Colors.red,
                              strokeWidth: 1,
                              strokeColor: Colors.white,
                            ),
                          ),
                        ),
                        LineChartBarData(
                          spots: diastolicSpots,
                          isCurved: true,
                          color: Colors.blue,
                          barWidth: 4,
                          dotData: FlDotData(
                            show: true,
                            getDotPainter: (spot, percent, barData, index) =>
                                FlDotCirclePainter(
                              radius: 3, // Reduced dot size as requested
                              color: Colors.blue,
                              strokeWidth: 1,
                              strokeColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Permanently visible systolic data value labels
                  ...systolicSpots.asMap().entries.map((entry) {
                    final index = entry.key;
                    final spot = entry.value;

                    // Calculate accurate position accounting for left axis reserved size
                    final xOffset = 60 +
                        (index * 80.0) +
                        30; // 60px left axis + index spacing + centering

                    // Calculate Y position based on the actual systolic data value
                    final minSystolic = records
                            .map((r) => r.systolic)
                            .reduce((a, b) => a < b ? a : b) -
                        10;
                    final maxSystolic = records
                            .map((r) => r.systolic)
                            .reduce((a, b) => a > b ? a : b) +
                        10;
                    const chartAreaTop = 100.0;
                    const chartAreaHeight = 300.0;
                    final normalizedValue =
                        (spot.y - minSystolic) / (maxSystolic - minSystolic);
                    final yOffset = chartAreaTop +
                        (chartAreaHeight * (1 - normalizedValue)) -
                        30; // Position above the dot

                    return Positioned(
                      left: xOffset,
                      top: yOffset,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(6),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black26,
                              offset: Offset(0, 2),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: Text(
                          '${spot.y.toInt()}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  }),
                  // Permanently visible diastolic data value labels
                  ...diastolicSpots.asMap().entries.map((entry) {
                    final index = entry.key;
                    final spot = entry.value;

                    // Calculate accurate position accounting for left axis reserved size
                    final xOffset = 60 +
                        (index * 80.0) +
                        35; // 60px left axis + index spacing + centering

                    // Calculate Y position based on the actual diastolic data value
                    final minDiastolic = records
                            .map((r) => r.diastolic)
                            .reduce((a, b) => a < b ? a : b) -
                        10;
                    final maxDiastolic = records
                            .map((r) => r.diastolic)
                            .reduce((a, b) => a > b ? a : b) +
                        10;
                    const chartAreaTop = 100.0;
                    const chartAreaHeight = 300.0;
                    final normalizedValue =
                        (spot.y - minDiastolic) / (maxDiastolic - minDiastolic);
                    final yOffset = chartAreaTop +
                        (chartAreaHeight * (1 - normalizedValue)) -
                        30; // Position above the dot

                    return Positioned(
                      left: xOffset,
                      top: yOffset,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(6),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black26,
                              offset: Offset(0, 2),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: Text(
                          '${spot.y.toInt()}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFullScreenLipidGraph() {
    final records = widget.records.cast<LipidRecord>();

    if (records.isEmpty) {
      return const Center(
        child: Text('No Lipid Profile data available',
            style: TextStyle(fontSize: 18)),
      );
    }

    // Sort records by date
    final sortedRecords = List<LipidRecord>.from(records)
      ..sort((a, b) => a.recordDate.compareTo(b.recordDate));

    final totalCholesterolSpots = sortedRecords.asMap().entries.map((entry) {
      return FlSpot(
          entry.key.toDouble(), entry.value.cholesterolTotal.toDouble());
    }).toList();

    final hdlSpots = sortedRecords.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.hdl.toDouble());
    }).toList();

    final ldlSpots = sortedRecords.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.ldl.toDouble());
    }).toList();

    final triglyceridesSpots = sortedRecords.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.triglycerides.toDouble());
    }).toList();

    final vldlSpots = sortedRecords.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.vldl.toDouble());
    }).toList();

    final nonHdlSpots = sortedRecords
        .asMap()
        .entries
        .where((entry) => entry.value.nonHdl != null)
        .map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.nonHdl!.toDouble());
    }).toList();

    final cholHdlRatioSpots = sortedRecords.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.cholHdlRatio);
    }).toList();

    return Column(
      children: [
        // Legend for all 7 parameters - optimized for landscape
        Container(
          height: 80,
          padding: const EdgeInsets.all(8),
          child: Column(
            children: [
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 20,
                children: [
                  _buildLegendItem('Total Chol', Colors.orange),
                  _buildLegendItem('HDL', Colors.green),
                  _buildLegendItem('LDL', Colors.red),
                  _buildLegendItem('Triglycerides', Colors.purple),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 20,
                children: [
                  _buildLegendItem('VLDL', Colors.teal),
                  _buildLegendItem('Non-HDL', Colors.brown),
                  _buildLegendItem('Chol/HDL Ratio', Colors.pink),
                ],
              ),
            ],
          ),
        ),
        // Chart
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: math.max(
                  400,
                  sortedRecords.length * 80.0 +
                      80), // Added extra 80px padding for last date
              child: Stack(
                children: [
                  // Main LineChart
                  LineChart(
                    LineChartData(
                      lineTouchData: LineTouchData(
                        enabled: true,
                        touchTooltipData: LineTouchTooltipData(
                          getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
                            final labels = [
                              'Total Chol',
                              'HDL',
                              'LDL',
                              'Triglycerides',
                              'VLDL',
                              'Non-HDL',
                              'Chol/HDL'
                            ];
                            return touchedBarSpots.map((barSpot) {
                              final labelIndex = barSpot.barIndex;
                              return LineTooltipItem(
                                '${labels[labelIndex]}: ${barSpot.y.toInt()}',
                                const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              );
                            }).toList();
                          },
                        ),
                      ),
                      gridData: const FlGridData(
                        show: true,
                        drawVerticalLine: true,
                        horizontalInterval: 20,
                        verticalInterval: 1,
                      ),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 60,
                            getTitlesWidget: (value, meta) {
                              return Text(
                                '${value.toInt()}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              );
                            },
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize:
                                120, // Further increased to prevent date truncation
                            interval: 1,
                            getTitlesWidget: (value, meta) {
                              final index = value.toInt();
                              if (index >= 0 && index < sortedRecords.length) {
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Transform.rotate(
                                    angle: -0.2,
                                    child: Text(
                                      DateFormat('MM/dd/yy').format(
                                          sortedRecords[index].recordDate),
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ),
                                );
                              }
                              return const Text('');
                            },
                          ),
                        ),
                        rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                      ),
                      borderData: FlBorderData(show: true),
                      lineBarsData: [
                        LineChartBarData(
                          spots: totalCholesterolSpots,
                          isCurved: true,
                          color: Colors.orange,
                          barWidth: 3,
                          dotData: FlDotData(
                            show: true,
                            getDotPainter: (spot, percent, barData, index) =>
                                FlDotCirclePainter(
                              radius: 3, // Reduced dot size as requested
                              color: Colors.orange,
                              strokeWidth: 1,
                              strokeColor: Colors.white,
                            ),
                          ),
                        ),
                        LineChartBarData(
                          spots: hdlSpots,
                          isCurved: true,
                          color: Colors.green,
                          barWidth: 3,
                          dotData: FlDotData(
                            show: true,
                            getDotPainter: (spot, percent, barData, index) =>
                                FlDotCirclePainter(
                              radius: 3, // Reduced dot size as requested
                              color: Colors.green,
                              strokeWidth: 1,
                              strokeColor: Colors.white,
                            ),
                          ),
                        ),
                        LineChartBarData(
                          spots: ldlSpots,
                          isCurved: true,
                          color: Colors.red,
                          barWidth: 3,
                          dotData: FlDotData(
                            show: true,
                            getDotPainter: (spot, percent, barData, index) =>
                                FlDotCirclePainter(
                              radius: 3, // Reduced dot size as requested
                              color: Colors.red,
                              strokeWidth: 1,
                              strokeColor: Colors.white,
                            ),
                          ),
                        ),
                        LineChartBarData(
                          spots: triglyceridesSpots,
                          isCurved: true,
                          color: Colors.purple,
                          barWidth: 3,
                          dotData: FlDotData(
                            show: true,
                            getDotPainter: (spot, percent, barData, index) =>
                                FlDotCirclePainter(
                              radius: 3, // Reduced dot size as requested
                              color: Colors.purple,
                              strokeWidth: 1,
                              strokeColor: Colors.white,
                            ),
                          ),
                        ),
                        LineChartBarData(
                          spots: vldlSpots,
                          isCurved: true,
                          color: Colors.teal,
                          barWidth: 3,
                          dotData: FlDotData(
                            show: true,
                            getDotPainter: (spot, percent, barData, index) =>
                                FlDotCirclePainter(
                              radius: 3, // Reduced dot size as requested
                              color: Colors.teal,
                              strokeWidth: 1,
                              strokeColor: Colors.white,
                            ),
                          ),
                        ),
                        LineChartBarData(
                          spots: nonHdlSpots,
                          isCurved: true,
                          color: Colors.brown,
                          barWidth: 3,
                          dotData: FlDotData(
                            show: true,
                            getDotPainter: (spot, percent, barData, index) =>
                                FlDotCirclePainter(
                              radius: 3, // Reduced dot size as requested
                              color: Colors.brown,
                              strokeWidth: 1,
                              strokeColor: Colors.white,
                            ),
                          ),
                        ),
                        LineChartBarData(
                          spots: cholHdlRatioSpots,
                          isCurved: true,
                          color: Colors.pink,
                          barWidth: 3,
                          dotData: FlDotData(
                            show: true,
                            getDotPainter: (spot, percent, barData, index) =>
                                FlDotCirclePainter(
                              radius: 3, // Reduced dot size as requested
                              color: Colors.pink,
                              strokeWidth: 1,
                              strokeColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Permanently visible data value labels for all 7 lipid values
                  // Total Cholesterol
                  ...totalCholesterolSpots.asMap().entries.map((entry) {
                    final index = entry.key;
                    final spot = entry.value;

                    final xOffset = 60 +
                        (index * 80.0) +
                        25; // 60px left axis + index spacing + centering
                    const yOffset =
                        120.0; // Total Cholesterol - positioned in chart area

                    return Positioned(
                      left: xOffset,
                      top: yOffset,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '${spot.y.toInt()}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  }),
                  // HDL
                  ...hdlSpots.asMap().entries.map((entry) {
                    final index = entry.key;
                    final spot = entry.value;

                    final xOffset = 60 +
                        (index * 80.0) +
                        35; // 60px left axis + index spacing + centering
                    const yOffset = 140.0; // HDL - positioned in chart area

                    return Positioned(
                      left: xOffset,
                      top: yOffset,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '${spot.y.toInt()}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  }),
                  // LDL
                  ...ldlSpots.asMap().entries.map((entry) {
                    final index = entry.key;
                    final spot = entry.value;

                    final xOffset = 60 +
                        (index * 80.0) +
                        15; // 60px left axis + index spacing + centering
                    const yOffset =
                        160.0; // LDL - positioned closer to data points

                    return Positioned(
                      left: xOffset,
                      top: yOffset,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '${spot.y.toInt()}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  }),
                  // Triglycerides
                  ...triglyceridesSpots.asMap().entries.map((entry) {
                    final index = entry.key;
                    final spot = entry.value;

                    final xOffset = 60 +
                        (index * 80.0) +
                        5; // 60px left axis + index spacing + centering
                    const yOffset =
                        180.0; // Triglycerides - positioned in chart area

                    return Positioned(
                      left: xOffset,
                      top: yOffset,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.purple.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '${spot.y.toInt()}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  }),
                  // VLDL
                  ...vldlSpots.asMap().entries.map((entry) {
                    final index = entry.key;
                    final spot = entry.value;

                    final xOffset = 60 +
                        (index * 80.0) +
                        25; // 60px left axis + index spacing + centering
                    const yOffset = 200.0; // VLDL - positioned in chart area

                    return Positioned(
                      left: xOffset,
                      top: yOffset,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.teal.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '${spot.y.toInt()}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  }),
                  // Non-HDL
                  ...nonHdlSpots.asMap().entries.map((entry) {
                    final index = entry.key;
                    final spot = entry.value;

                    final xOffset = 60 +
                        (index * 80.0) +
                        15; // 60px left axis + index spacing + centering
                    const yOffset = 220.0; // Non-HDL - positioned in chart area

                    return Positioned(
                      left: xOffset,
                      top: yOffset,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.brown.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '${spot.y.toInt()}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  }),
                  // Chol/HDL Ratio
                  ...cholHdlRatioSpots.asMap().entries.map((entry) {
                    final index = entry.key;
                    final spot = entry.value;

                    final xOffset = 60 +
                        (index * 80.0) +
                        15; // 60px left axis + index spacing + centering
                    const yOffset =
                        240.0; // Chol/HDL Ratio - positioned in chart area

                    return Positioned(
                      left: xOffset,
                      top: yOffset,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.pink.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          spot.y.toStringAsFixed(1),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }
}

// Simple Sugar Table Widget with synchronized scrolling
class _SimpleSugarTable extends StatefulWidget {
  final List<SugarRecord> sortedRecords;
  final bool isDark;
  final Color Function(num?, String, {bool isDark}) getSugarColor;
  final void Function(SugarRecord) onEdit;
  final void Function(SugarRecord) onDelete;

  const _SimpleSugarTable({
    required this.sortedRecords,
    required this.isDark,
    required this.getSugarColor,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<_SimpleSugarTable> createState() => _SimpleSugarTableState();
}

class _SimpleSugarTableState extends State<_SimpleSugarTable> {
  late ScrollController _headerScrollController;
  late List<ScrollController> _rowScrollControllers;
  bool _syncing = false;

  @override
  void initState() {
    super.initState();
    _headerScrollController = ScrollController();
    _rowScrollControllers = List.generate(
      widget.sortedRecords.length,
      (index) => ScrollController(),
    );

    // Add listener to header scroll controller
    _headerScrollController.addListener(_onHeaderScroll);

    // Add listeners to all row scroll controllers
    for (int i = 0; i < _rowScrollControllers.length; i++) {
      final controller = _rowScrollControllers[i];
      controller.addListener(() => _onRowScroll(i));
    }
  }

  @override
  void dispose() {
    _headerScrollController.dispose();
    for (final controller in _rowScrollControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _onHeaderScroll() {
    if (_syncing) return;
    _syncing = true;
    final offset = _headerScrollController.offset;
    for (final controller in _rowScrollControllers) {
      if (controller.hasClients && controller.offset != offset) {
        controller.jumpTo(offset);
      }
    }
    _syncing = false;
  }

  void _onRowScroll(int index) {
    if (_syncing) return;
    _syncing = true;
    final offset = _rowScrollControllers[index].offset;

    // Sync header
    if (_headerScrollController.hasClients &&
        _headerScrollController.offset != offset) {
      _headerScrollController.jumpTo(offset);
    }

    // Sync all other rows
    for (int i = 0; i < _rowScrollControllers.length; i++) {
      if (i != index) {
        final controller = _rowScrollControllers[i];
        if (controller.hasClients && controller.offset != offset) {
          controller.jumpTo(offset);
        }
      }
    }
    _syncing = false;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Fixed Header with Frozen Date Column
        Container(
          decoration: BoxDecoration(
            color: widget.isDark
                ? AppTheme.primaryColor.withOpacity(0.2)
                : AppTheme.primaryColor.withOpacity(0.1),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            border: Border(
              bottom: BorderSide(
                color:
                    widget.isDark ? Colors.grey.shade600 : Colors.grey.shade300,
              ),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                // Frozen Date column header
                SizedBox(
                  width: 80,
                  child: Text(
                    'Date',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: widget.isDark
                              ? Colors.white
                              : AppTheme.primaryColor,
                          fontSize: 12,
                        ),
                  ),
                ),
                // Scrollable headers section
                Expanded(
                  child: SingleChildScrollView(
                    controller: _headerScrollController,
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildHeaderColumn('FBS\n(mg/dL)\n(80–100)', 80),
                        _buildHeaderColumn('PPBS\n(mg/dL)\n(120–140)', 80),
                        _buildHeaderColumn('RBS\n(mg/dL)\n(<140)', 80),
                        _buildHeaderColumn('HbA1c\n(4–5.6)', 80),
                        const SizedBox(width: 40), // Actions column
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        // Scrollable Content
        Expanded(
          child: widget.sortedRecords.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  itemCount: widget.sortedRecords.length,
                  itemBuilder: (context, index) => _buildDataRow(index),
                ),
        ),
      ],
    );
  }

  Widget _buildHeaderColumn(String title, double width) {
    return SizedBox(
      width: width,
      child: Text(
        title,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: widget.isDark ? Colors.white : AppTheme.primaryColor,
              fontSize: 12,
            ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.table_chart,
            size: 48,
            color: widget.isDark ? Colors.grey.shade400 : Colors.grey.shade400,
          ),
          const SizedBox(height: 12),
          Text(
            'No sugar records yet—add one above to get started.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color:
                  widget.isDark ? Colors.grey.shade300 : Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataRow(int index) {
    final record = widget.sortedRecords[index];
    final isLastItem = index == widget.sortedRecords.length - 1;

    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: isLastItem
              ? BorderSide.none
              : BorderSide(
                  color: widget.isDark
                      ? Colors.grey.shade700
                      : Colors.grey.shade200,
                ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        child: Row(
          children: [
            // Frozen Date column
            SizedBox(
              width: 80,
              child: Text(
                DateFormat('dd-MMM-yy').format(record.recordDate),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: widget.isDark
                      ? Colors.white.withOpacity(0.87)
                      : Colors.black.withOpacity(0.87),
                ),
              ),
            ),
            // Scrollable data columns
            Expanded(
              child: SingleChildScrollView(
                controller: _rowScrollControllers[index],
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildDataColumn(
                        record.fbs?.toStringAsFixed(0) ?? 'N/A',
                        80,
                        widget.getSugarColor(record.fbs, 'fbs',
                            isDark: widget.isDark)),
                    _buildDataColumn(
                        record.ppbs?.toStringAsFixed(0) ?? 'N/A',
                        80,
                        widget.getSugarColor(record.ppbs, 'ppbs',
                            isDark: widget.isDark)),
                    _buildDataColumn(
                        record.rbs?.toStringAsFixed(0) ?? 'N/A',
                        80,
                        widget.getSugarColor(record.rbs, 'rbs',
                            isDark: widget.isDark)),
                    _buildDataColumn(
                        record.hba1c.toStringAsFixed(1),
                        80,
                        widget.getSugarColor(record.hba1c, 'hba1c',
                            isDark: widget.isDark)),
                    _buildActionsColumn(record),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataColumn(String text, double width, Color color) {
    return SizedBox(
      width: width,
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
    );
  }

  Widget _buildActionsColumn(SugarRecord record) {
    return SizedBox(
      width: 40,
      child: PopupMenuButton<String>(
        icon: Icon(
          Icons.more_vert,
          color: widget.isDark ? Colors.grey.shade400 : Colors.grey.shade600,
          size: 20,
        ),
        onSelected: (value) {
          if (value == 'edit') {
            widget.onEdit(record);
          } else if (value == 'delete') {
            widget.onDelete(record);
          }
        },
        itemBuilder: (context) => [
          const PopupMenuItem(
            value: 'edit',
            child: Row(
              children: [
                Icon(Icons.edit, size: 20),
                SizedBox(width: 8),
                Text('Edit'),
              ],
            ),
          ),
          const PopupMenuItem(
            value: 'delete',
            child: Row(
              children: [
                Icon(Icons.delete, size: 20, color: Colors.red),
                SizedBox(width: 8),
                Text('Delete', style: TextStyle(color: Colors.red)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Simple Lipid Table Widget with synchronized scrolling
class _SimpleLipidTable extends StatefulWidget {
  final List<LipidRecord> sortedRecords;
  final bool isDark;
  final Color Function(num, String, {bool isDark}) getLipidColor;
  final void Function(LipidRecord) onEdit;
  final void Function(LipidRecord) onDelete;

  const _SimpleLipidTable({
    required this.sortedRecords,
    required this.isDark,
    required this.getLipidColor,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<_SimpleLipidTable> createState() => _SimpleLipidTableState();
}

class _SimpleLipidTableState extends State<_SimpleLipidTable> {
  late ScrollController _headerScrollController;
  late List<ScrollController> _rowScrollControllers;
  bool _syncing = false;

  @override
  void initState() {
    super.initState();
    _headerScrollController = ScrollController();
    _rowScrollControllers = List.generate(
      widget.sortedRecords.length,
      (index) => ScrollController(),
    );

    // Add listener to header scroll controller
    _headerScrollController.addListener(_onHeaderScroll);

    // Add listeners to all row scroll controllers
    for (int i = 0; i < _rowScrollControllers.length; i++) {
      final controller = _rowScrollControllers[i];
      controller.addListener(() => _onRowScroll(i));
    }
  }

  @override
  void dispose() {
    _headerScrollController.dispose();
    for (final controller in _rowScrollControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _onHeaderScroll() {
    if (_syncing) return;
    _syncing = true;
    final offset = _headerScrollController.offset;
    for (final controller in _rowScrollControllers) {
      if (controller.hasClients && controller.offset != offset) {
        controller.jumpTo(offset);
      }
    }
    _syncing = false;
  }

  void _onRowScroll(int index) {
    if (_syncing) return;
    _syncing = true;
    final offset = _rowScrollControllers[index].offset;

    // Sync header
    if (_headerScrollController.hasClients &&
        _headerScrollController.offset != offset) {
      _headerScrollController.jumpTo(offset);
    }

    // Sync all other rows
    for (int i = 0; i < _rowScrollControllers.length; i++) {
      if (i != index) {
        final controller = _rowScrollControllers[i];
        if (controller.hasClients && controller.offset != offset) {
          controller.jumpTo(offset);
        }
      }
    }
    _syncing = false;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Fixed Header with Frozen Date Column
        Container(
          decoration: BoxDecoration(
            color: widget.isDark
                ? AppTheme.primaryColor.withOpacity(0.2)
                : AppTheme.primaryColor.withOpacity(0.1),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            border: Border(
              bottom: BorderSide(
                color:
                    widget.isDark ? Colors.grey.shade600 : Colors.grey.shade300,
              ),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                // Frozen Date column header
                SizedBox(
                  width: 80,
                  child: Text(
                    'Date',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: widget.isDark
                              ? Colors.white
                              : AppTheme.primaryColor,
                          fontSize: 12,
                        ),
                  ),
                ),
                // Scrollable headers section
                Expanded(
                  child: SingleChildScrollView(
                    controller: _headerScrollController,
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildHeaderColumn('TC\n(<200)', 80),
                        _buildHeaderColumn('TG\n(<150)', 80),
                        _buildHeaderColumn('HDL-C\n(40–60)', 80),
                        _buildHeaderColumn('Non-HDL-C\n(<130)', 90),
                        _buildHeaderColumn('LDL-C\n(0–159)', 80),
                        _buildHeaderColumn('VLDL-C\n(0–40)', 80),
                        _buildHeaderColumn('TC/HDL\nRatio (0–5)', 90),
                        const SizedBox(width: 40), // Actions column
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        // Scrollable Content
        Expanded(
          child: widget.sortedRecords.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  itemCount: widget.sortedRecords.length,
                  itemBuilder: (context, index) => _buildDataRow(index),
                ),
        ),
      ],
    );
  }

  Widget _buildHeaderColumn(String title, double width) {
    return SizedBox(
      width: width,
      child: Text(
        title,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: widget.isDark ? Colors.white : AppTheme.primaryColor,
              fontSize: 12,
            ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.table_chart,
            size: 48,
            color: widget.isDark ? Colors.grey.shade400 : Colors.grey.shade400,
          ),
          const SizedBox(height: 12),
          Text(
            'No lipid records yet—add one above to get started.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color:
                  widget.isDark ? Colors.grey.shade300 : Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataRow(int index) {
    final record = widget.sortedRecords[index];
    final isLastItem = index == widget.sortedRecords.length - 1;

    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: isLastItem
              ? BorderSide.none
              : BorderSide(
                  color: widget.isDark
                      ? Colors.grey.shade700
                      : Colors.grey.shade200,
                ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        child: Row(
          children: [
            // Frozen Date column
            SizedBox(
              width: 80,
              child: Text(
                DateFormat('dd-MMM-yy').format(record.recordDate),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: widget.isDark
                      ? Colors.white.withOpacity(0.87)
                      : Colors.black.withOpacity(0.87),
                ),
              ),
            ),
            // Scrollable data columns
            Expanded(
              child: SingleChildScrollView(
                controller: _rowScrollControllers[index],
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildDataColumn(
                        record.cholesterolTotal.toString(),
                        80,
                        widget.getLipidColor(record.cholesterolTotal, 'tc',
                            isDark: widget.isDark)),
                    _buildDataColumn(
                        record.triglycerides.toString(),
                        80,
                        widget.getLipidColor(record.triglycerides, 'tg',
                            isDark: widget.isDark)),
                    _buildDataColumn(
                        record.hdl.toString(),
                        80,
                        widget.getLipidColor(record.hdl, 'hdl',
                            isDark: widget.isDark)),
                    _buildDataColumn(
                        record.nonHdl?.toString() ?? 'N/A',
                        90,
                        record.nonHdl != null
                            ? widget.getLipidColor(record.nonHdl!, 'nonhdl',
                                isDark: widget.isDark)
                            : Colors.grey),
                    _buildDataColumn(
                        record.ldl.toString(),
                        80,
                        widget.getLipidColor(record.ldl, 'ldl',
                            isDark: widget.isDark)),
                    _buildDataColumn(
                        record.vldl.toString(),
                        80,
                        widget.getLipidColor(record.vldl, 'vldl',
                            isDark: widget.isDark)),
                    _buildDataColumn(
                        record.cholHdlRatio.toStringAsFixed(1),
                        90,
                        widget.getLipidColor(record.cholHdlRatio, 'ratio',
                            isDark: widget.isDark)),
                    _buildActionsColumn(record),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataColumn(String text, double width, Color color) {
    return SizedBox(
      width: width,
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
    );
  }

  Widget _buildActionsColumn(LipidRecord record) {
    return SizedBox(
      width: 40,
      child: PopupMenuButton<String>(
        icon: Icon(
          Icons.more_vert,
          color: widget.isDark ? Colors.grey.shade400 : Colors.grey.shade600,
          size: 20,
        ),
        onSelected: (value) {
          if (value == 'edit') {
            widget.onEdit(record);
          } else if (value == 'delete') {
            widget.onDelete(record);
          }
        },
        itemBuilder: (context) => [
          const PopupMenuItem(
            value: 'edit',
            child: Row(
              children: [
                Icon(Icons.edit, size: 20),
                SizedBox(width: 8),
                Text('Edit'),
              ],
            ),
          ),
          const PopupMenuItem(
            value: 'delete',
            child: Row(
              children: [
                Icon(Icons.delete, size: 20, color: Colors.red),
                SizedBox(width: 8),
                Text('Delete', style: TextStyle(color: Colors.red)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// _SimpleBPTable - Stateful widget for BP table with frozen Date column
class _SimpleBPTable extends StatefulWidget {
  final List<BPRecord> sortedRecords;
  final bool isDark;
  final Color Function(int, String, {bool isDark}) getBPColor;
  final void Function(BPRecord) onEdit;
  final void Function(BPRecord) onDelete;

  const _SimpleBPTable({
    required this.sortedRecords,
    required this.isDark,
    required this.getBPColor,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<_SimpleBPTable> createState() => _SimpleBPTableState();
}

class _SimpleBPTableState extends State<_SimpleBPTable> {
  late ScrollController _headerScrollController;
  late List<ScrollController> _rowScrollControllers;
  bool _syncing = false;

  @override
  void initState() {
    super.initState();
    _headerScrollController = ScrollController();
    _rowScrollControllers = List.generate(
      widget.sortedRecords.length,
      (index) => ScrollController(),
    );

    // Add listener to header scroll controller
    _headerScrollController.addListener(_onHeaderScroll);

    // Add listeners to all row scroll controllers
    for (int i = 0; i < _rowScrollControllers.length; i++) {
      final controller = _rowScrollControllers[i];
      controller.addListener(() => _onRowScroll(i));
    }
  }

  @override
  void dispose() {
    _headerScrollController.dispose();
    for (final controller in _rowScrollControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _onHeaderScroll() {
    if (_syncing) return;
    _syncing = true;
    final offset = _headerScrollController.offset;
    for (final controller in _rowScrollControllers) {
      if (controller.hasClients && controller.offset != offset) {
        controller.jumpTo(offset);
      }
    }
    _syncing = false;
  }

  void _onRowScroll(int index) {
    if (_syncing) return;
    _syncing = true;
    final offset = _rowScrollControllers[index].offset;

    // Sync header
    if (_headerScrollController.hasClients &&
        _headerScrollController.offset != offset) {
      _headerScrollController.jumpTo(offset);
    }

    // Sync all other rows
    for (int i = 0; i < _rowScrollControllers.length; i++) {
      if (i != index) {
        final controller = _rowScrollControllers[i];
        if (controller.hasClients && controller.offset != offset) {
          controller.jumpTo(offset);
        }
      }
    }
    _syncing = false;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Fixed Header with Frozen Date Column
        Container(
          decoration: BoxDecoration(
            color: widget.isDark
                ? AppTheme.primaryColor.withOpacity(0.2)
                : AppTheme.primaryColor.withOpacity(0.1),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            border: Border(
              bottom: BorderSide(
                color:
                    widget.isDark ? Colors.grey.shade600 : Colors.grey.shade300,
              ),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                // Frozen Date column header
                SizedBox(
                  width: 80,
                  child: Text(
                    'Date',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: widget.isDark
                              ? Colors.white
                              : AppTheme.primaryColor,
                          fontSize: 12,
                        ),
                  ),
                ),
                // Scrollable headers section
                Expanded(
                  child: SingleChildScrollView(
                    controller: _headerScrollController,
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildHeaderColumn('SBP\n(mmHg)\n(<120)', 80),
                        _buildHeaderColumn('DBP\n(mmHg)\n(<80)', 80),
                        _buildHeaderColumn('BPM\n(60-80)', 80),
                        const SizedBox(width: 40), // Actions column
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        // Scrollable Content
        Expanded(
          child: widget.sortedRecords.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  itemCount: widget.sortedRecords.length,
                  itemBuilder: (context, index) => _buildDataRow(index),
                ),
        ),
      ],
    );
  }

  Widget _buildHeaderColumn(String title, double width) {
    return SizedBox(
      width: width,
      child: Text(
        title,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: widget.isDark ? Colors.white : AppTheme.primaryColor,
              fontSize: 12,
            ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.table_chart,
            size: 48,
            color: widget.isDark ? Colors.grey.shade400 : Colors.grey.shade400,
          ),
          const SizedBox(height: 12),
          Text(
            'No BP records yet—add one above to get started.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color:
                  widget.isDark ? Colors.grey.shade300 : Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataRow(int index) {
    final record = widget.sortedRecords[index];
    final isLastItem = index == widget.sortedRecords.length - 1;

    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: isLastItem
              ? BorderSide.none
              : BorderSide(
                  color: widget.isDark
                      ? Colors.grey.shade700
                      : Colors.grey.shade200,
                ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        child: Row(
          children: [
            // Frozen Date column
            SizedBox(
              width: 80,
              child: Text(
                DateFormat('dd-MMM-yy').format(record.recordDate),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: widget.isDark
                      ? Colors.white.withOpacity(0.87)
                      : Colors.black.withOpacity(0.87),
                ),
              ),
            ),
            // Scrollable data columns
            Expanded(
              child: SingleChildScrollView(
                controller: _rowScrollControllers[index],
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildDataColumn(
                        record.systolic.toString(),
                        80,
                        widget.getBPColor(record.systolic, 'systolic',
                            isDark: widget.isDark)),
                    _buildDataColumn(
                        record.diastolic.toString(),
                        80,
                        widget.getBPColor(record.diastolic, 'diastolic',
                            isDark: widget.isDark)),
                    _buildDataColumn(
                        record.bpm?.toString() ?? 'N/A',
                        80,
                        record.bpm != null
                            ? widget.getBPColor(record.bpm!, 'bpm',
                                isDark: widget.isDark)
                            : Colors.grey),
                    _buildActionsColumn(record),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataColumn(String text, double width, Color color) {
    return SizedBox(
      width: width,
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
    );
  }

  Widget _buildActionsColumn(BPRecord record) {
    return SizedBox(
      width: 40,
      child: PopupMenuButton<String>(
        icon: Icon(
          Icons.more_vert,
          color: widget.isDark ? Colors.grey.shade400 : Colors.grey.shade600,
          size: 20,
        ),
        onSelected: (value) {
          if (value == 'edit') {
            widget.onEdit(record);
          } else if (value == 'delete') {
            widget.onDelete(record);
          }
        },
        itemBuilder: (context) => [
          const PopupMenuItem(
            value: 'edit',
            child: Row(
              children: [
                Icon(Icons.edit, size: 20),
                SizedBox(width: 8),
                Text('Edit'),
              ],
            ),
          ),
          const PopupMenuItem(
            value: 'delete',
            child: Row(
              children: [
                Icon(Icons.delete, size: 20, color: Colors.red),
                SizedBox(width: 8),
                Text('Delete', style: TextStyle(color: Colors.red)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
