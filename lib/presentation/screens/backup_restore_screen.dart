import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/backup_service.dart';
import '../../core/themes/app_theme.dart';
import '../../core/database/database_helper.dart';
import '../dialogs/password_restore_dialog.dart';
import '../providers/profile_provider.dart';
import '../providers/providers.dart';

class BackupRestoreScreen extends ConsumerStatefulWidget {
  const BackupRestoreScreen({super.key});

  @override
  ConsumerState<BackupRestoreScreen> createState() =>
      _BackupRestoreScreenState();
}

class _BackupRestoreScreenState extends ConsumerState<BackupRestoreScreen> {
  bool _isLoading = false;
  bool _autoBackupEnabled = false;
  String _autoBackupFrequency = 'daily';
  String? _lastBackupInfo;
  List<BackupInfo> _availableBackups = [];
  bool _backupsLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _loadBackupInfo();
    _loadAvailableBackups(); // Load backups immediately
  }

  Future<void> _loadSettings() async {
    final backupService = BackupService.instance;
    final settings = await backupService.getBackupSettings();

    setState(() {
      _autoBackupEnabled = settings['auto_backup_enabled'] ?? false;
      // Ensure the frequency is one of the valid options
      final frequency = settings['auto_backup_frequency'] ?? 'daily';
      _autoBackupFrequency = (frequency == 'daily' || frequency == 'weekly')
          ? frequency
          : 'daily'; // Default to daily if invalid
    });
  }

  Future<void> _loadBackupInfo() async {
    final backupService = BackupService.instance;
    final lastBackup = await backupService.getLastBackupInfo();

    setState(() {
      _lastBackupInfo = lastBackup;
    });
  }

  Future<void> _loadAvailableBackups() async {
    if (_backupsLoaded) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final backupService = BackupService.instance;
      final backups = await backupService.getAvailableBackups();

      setState(() {
        _availableBackups = backups;
        _backupsLoaded = true;
      });
    } catch (e) {
      _showErrorDialog('Failed to load backups: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _createBackup() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final backupService = BackupService.instance;
      final result = await backupService.createBackup();

      if (result.success) {
        _showSuccessDialog('Backup created successfully!');
        _loadBackupInfo();
        _refreshBackups();
      } else {
        _showErrorDialog(result.message);
      }
    } catch (e) {
      _showErrorDialog('Failed to create backup: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshBackups() async {
    setState(() {
      _backupsLoaded = false;
      _availableBackups.clear();
    });
    await _loadAvailableBackups();
  }

  void _triggerAppRefresh() {
    // Force database reinitialization and provider refresh
    try {
      // Invalidate providers to force fresh data reload
      ref.invalidate(profileNotifierProvider);
      ref.invalidate(databaseHelperProvider);

      // Force database helper to reinitialize
      DatabaseHelper.instance.reinitializeDatabase().then((_) {
        debugPrint('Database reinitialized after restore');
      }).catchError((error) {
        debugPrint('Database reinitialize error: $error');
      });
    } catch (e) {
      debugPrint('Provider invalidation error: $e');
    }

    // Show immediate feedback
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Restore complete! All data has been refreshed.',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.green.shade600,
          duration: const Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          action: SnackBarAction(
            label: 'View Data',
            textColor: Colors.white,
            onPressed: () {
              // Navigate back to home and trigger a rebuild
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
          ),
        ),
      );
    }
  }

  Future<void> _restoreBackup(BackupInfo backup) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final backupService = BackupService.instance;

      // First, try with device key
      var result = await backupService.restoreBackup(backup.id);

      if (!result.success &&
          (result.message.contains('decryption') ||
              result.message.contains('encryption') ||
              result.message.contains('key') ||
              result.message.contains('CROSS_DEVICE_BACKUP') ||
              result.message.contains('Invalid argument') ||
              result.message.contains('corrupted pad') ||
              result.message.contains('pad block'))) {
        // Device key failed, ask user if they want to try password restore
        setState(() {
          _isLoading = false;
        });

        if (mounted) {
          final shouldTryPassword = await _showPasswordPromptDialog();
          if (shouldTryPassword && mounted) {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => PasswordRestoreDialog(
                backup: backup,
                onSuccess: () {
                  _loadBackupInfo();
                  _refreshBackups();
                  _showSuccessDialog(
                      'Backup restored successfully! All data has been updated.');
                  // Trigger app-wide refresh by popping to root and refreshing
                  _triggerAppRefresh();
                },
              ),
            );
          }
        }
        return;
      }

      if (result.success) {
        _showSuccessDialog(
            'Backup restored successfully! All data has been updated.');
        _loadBackupInfo();
        _refreshBackups();
        // Trigger app-wide refresh
        _triggerAppRefresh();
      } else {
        _showErrorDialog(result.message);
      }
    } catch (e) {
      _showErrorDialog('Failed to restore backup: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteBackup(BackupInfo backup) async {
    final confirmed = await _showConfirmDialog(
      'Delete Backup',
      'Are you sure you want to delete this backup? This action cannot be undone.',
    );

    if (!confirmed) return;

    try {
      // Get the backup service to access the backup directory
      final backupService = BackupService.instance;

      // Find the backup file in the actual backup directory
      final backupDir = await backupService.getBackupDirectory();
      final backupFile = File('${backupDir.path}/${backup.id}');

      if (await backupFile.exists()) {
        await backupFile.delete();
        _showSuccessDialog('Backup deleted successfully!');
        _refreshBackups();
      } else {
        _showErrorDialog('Backup file not found');
      }
    } catch (e) {
      _showErrorDialog('Failed to delete backup: $e');
    }
  }

  Future<void> _saveSettings() async {
    try {
      final backupService = BackupService.instance;
      await backupService.setAutoBackup(
          _autoBackupEnabled, _autoBackupFrequency);

      _showSuccessDialog('Settings saved successfully!');
    } catch (e) {
      _showErrorDialog('Failed to save settings: $e');
    }
  }

  Future<bool> _showPasswordPromptDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.lock, color: Colors.orange.shade600),
            const SizedBox(width: 8),
            const Text('Cross-Device Restore'),
          ],
        ),
        content: const Text(
          'This backup appears to be from another device or app installation. '
          'Would you like to try restoring it using a password?\n\n'
          'Note: Only backups created with password protection can be restored across devices.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Try Password'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green.shade600),
            const SizedBox(width: 8),
            const Text('Success'),
          ],
        ),
        content: Text(message),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.error, color: Colors.red.shade600),
            const SizedBox(width: 8),
            const Text('Error'),
          ],
        ),
        content: Text(message),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<bool> _showConfirmDialog(String title, String message) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Backup & Restore'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildQuickActionsCard(),
            const SizedBox(height: 12),
            _buildBackupInfoCard(),
            const SizedBox(height: 12),
            _buildAutoBackupCard(),
            const SizedBox(height: 12),
            _buildAvailableBackupsCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionsCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.flash_on, color: AppTheme.primaryColor),
                const SizedBox(width: 8),
                const Text(
                  'Quick Actions',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _createBackup,
                    icon: const Icon(Icons.backup),
                    label: const Text('Create Backup'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(0, 50),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _refreshBackups,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Refresh List'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade600,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(0, 50),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackupInfoCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.info_outline, color: AppTheme.primaryColor),
                const SizedBox(width: 8),
                const Text(
                  'Backup Information',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Last Backup Section
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.shade200,
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.access_time,
                          color: Colors.blue.shade600,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Last Backup',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue.shade800,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _lastBackupInfo ?? 'No backup created yet',
                                style: TextStyle(
                                  fontSize: 14,
                                  height: 1.4,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Retention Policy Section
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.policy,
                          color: Colors.green.shade600,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Retention Policy',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green.shade800,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Automatically keeps the last 3 backups and removes older ones',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.green.shade700,
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAutoBackupCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.schedule, color: AppTheme.primaryColor),
                const SizedBox(width: 8),
                const Text(
                  'Auto Backup Settings',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Enable Auto Backup'),
              subtitle: const Text('Automatically create backups'),
              value: _autoBackupEnabled,
              onChanged: (value) {
                setState(() {
                  _autoBackupEnabled = value;
                });
              },
              activeColor: AppTheme.primaryColor,
            ),
            if (_autoBackupEnabled) ...[
              const SizedBox(height: 8),
              ListTile(
                title: const Text('Backup Frequency'),
                subtitle: Text('Current: $_autoBackupFrequency'),
                trailing: DropdownButton<String>(
                  value: _autoBackupFrequency,
                  onChanged: (value) {
                    if (value != null &&
                        (value == 'daily' || value == 'weekly')) {
                      setState(() {
                        _autoBackupFrequency = value;
                      });
                    }
                  },
                  items: const [
                    DropdownMenuItem(
                      value: 'daily',
                      child: Text('Daily'),
                    ),
                    DropdownMenuItem(
                      value: 'weekly',
                      child: Text('Weekly'),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveSettings,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Save Settings'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvailableBackupsCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.folder_outlined, color: AppTheme.primaryColor),
                const SizedBox(width: 8),
                const Text(
                  'Available Backups',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (_isLoading)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            if (_availableBackups.isEmpty && !_isLoading)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.folder_open,
                      size: 48,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No backups found',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Create your first backup to get started',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _availableBackups.length,
                separatorBuilder: (context, index) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final backup = _availableBackups[index];
                  return _buildBackupItem(backup);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackupItem(BackupInfo backup) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: AppTheme.primaryColor,
          child: Icon(
            Icons.backup,
            color: Colors.white,
            size: 20,
          ),
        ),
        title: Text(
          backup.displayName,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              'Size: ${(backup.size / 1024).toStringAsFixed(1)} KB',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
            Text(
              'Created: ${backup.createdTime.day}/${backup.createdTime.month}/${backup.createdTime.year} ${backup.createdTime.hour > 12 ? backup.createdTime.hour - 12 : backup.createdTime.hour}:${backup.createdTime.minute.toString().padLeft(2, '0')} ${backup.createdTime.hour >= 12 ? 'PM' : 'AM'}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: _isLoading ? null : () => _restoreBackup(backup),
              icon: Icon(
                Icons.restore,
                color: Colors.green.shade600,
              ),
              tooltip: 'Restore',
            ),
            IconButton(
              onPressed: _isLoading ? null : () => _deleteBackup(backup),
              icon: Icon(
                Icons.delete,
                color: Colors.red.shade600,
              ),
              tooltip: 'Delete',
            ),
          ],
        ),
      ),
    );
  }
}
