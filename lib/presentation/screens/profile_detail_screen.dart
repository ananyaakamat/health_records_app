import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
        title: Text(profile.name),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Profile Summary Section
            _buildProfileSummary(context),

            const SizedBox(height: 24),

            // Health Records Tabs Section
            _buildHealthRecordsSection(context),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileSummary(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: AppTheme.cardDecoration,
      child: Column(
        children: [
          // Profile Avatar
          CircleAvatar(
            backgroundColor: AppTheme.primaryColor,
            radius: 50,
            child: Text(
              profile.name.substring(0, 1).toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 36,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Profile Name
          Text(
            profile.name,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),

          const SizedBox(height: 16),

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

  Widget _buildHealthRecordsSection(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: DefaultTabController(
        length: 3,
        child: Column(
          children: [
            // Tab Bar
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
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
              height: 400,
              decoration: BoxDecoration(
                color: Colors.white,
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
          data: (records) => _buildRecordsList(
            records: records,
            recordType: 'Sugar',
            onAddRecord: () => _showSugarRecordForm(context, ref),
            recordBuilder: (record) => _buildSugarRecordTile(record, ref),
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
          data: (records) => _buildRecordsList(
            records: records,
            recordType: 'Blood Pressure',
            onAddRecord: () => _showBPRecordForm(context, ref),
            recordBuilder: (record) => _buildBPRecordTile(record, ref),
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
          data: (records) => _buildRecordsList(
            records: records,
            recordType: 'Lipid Profile',
            onAddRecord: () => _showLipidRecordForm(context, ref),
            recordBuilder: (record) => _buildLipidRecordTile(record, ref),
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(child: Text('Error: $error')),
        );
      },
    );
  }

  Widget _buildRecordsList<T>({
    required List<T> records,
    required String recordType,
    required VoidCallback onAddRecord,
    required Widget Function(T) recordBuilder,
  }) {
    return Column(
      children: [
        // Header with Add button
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$recordType Records',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              ElevatedButton.icon(
                onPressed: onAddRecord,
                icon: const Icon(Icons.add),
                label: const Text('Add'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        // Records list
        Expanded(
          child: records.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.note_add,
                        size: 64,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No $recordType records yet',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tap the Add button to create your first record',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: records.length,
                  itemBuilder: (context, index) =>
                      recordBuilder(records[index]),
                ),
        ),
      ],
    );
  }

  Widget _buildSugarRecordTile(SugarRecord record, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: AppTheme.primaryColor,
          child: Icon(Icons.bloodtype, color: Colors.white),
        ),
        title: Text('HbA1c: ${record.hba1c.toStringAsFixed(1)}%'),
        subtitle: Text(DateFormat('MMM dd, yyyy').format(record.recordDate)),
        trailing: Builder(
          builder: (context) => PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'edit') {
                _showSugarRecordForm(context, ref, record: record);
              } else if (value == 'delete') {
                _deleteSugarRecord(context, ref, record);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'edit', child: Text('Edit')),
              const PopupMenuItem(value: 'delete', child: Text('Delete')),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBPRecordTile(BPRecord record, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: AppTheme.primaryColor,
          child: Icon(Icons.monitor_heart, color: Colors.white),
        ),
        title: Text('${record.systolic}/${record.diastolic} mmHg'),
        subtitle: Text(DateFormat('MMM dd, yyyy').format(record.recordDate)),
        trailing: Builder(
          builder: (context) => PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'edit') {
                _showBPRecordForm(context, ref, record: record);
              } else if (value == 'delete') {
                _deleteBPRecord(context, ref, record);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'edit', child: Text('Edit')),
              const PopupMenuItem(value: 'delete', child: Text('Delete')),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLipidRecordTile(LipidRecord record, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: AppTheme.primaryColor,
          child: Icon(Icons.science, color: Colors.white),
        ),
        title: Text('Total: ${record.cholesterolTotal} mg/dL'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('HDL: ${record.hdl}, LDL: ${record.ldl}'),
            Text(DateFormat('MMM dd, yyyy').format(record.recordDate)),
          ],
        ),
        isThreeLine: true,
        trailing: Builder(
          builder: (context) => PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'edit') {
                _showLipidRecordForm(context, ref, record: record);
              } else if (value == 'delete') {
                _deleteLipidRecord(context, ref, record);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'edit', child: Text('Edit')),
              const PopupMenuItem(value: 'delete', child: Text('Delete')),
            ],
          ),
        ),
      ),
    );
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
      title: 'Delete HbA1c Record',
      content:
          'Are you sure you want to delete this HbA1c record?\n\nDate: ${DateFormat('MMM d, y').format(record.recordDate)}\nHbA1c: ${record.hba1c}%',
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
          'Are you sure you want to delete this blood pressure record?\n\nDate: ${DateFormat('MMM d, y').format(record.recordDate)}\nSystolic: ${record.systolic} mmHg\nDiastolic: ${record.diastolic} mmHg',
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
          'Are you sure you want to delete this lipid profile record?\n\nDate: ${DateFormat('MMM d, y').format(record.recordDate)}\nTotal Cholesterol: ${record.cholesterolTotal} mg/dL\nLDL: ${record.ldl} mg/dL\nHDL: ${record.hdl} mg/dL',
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
