import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/backup_service.dart';
import '../../core/themes/app_theme.dart';
import '../dialogs/password_restore_dialog.dart';

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
      _autoBackupFrequency = settings['auto_backup_frequency'] ?? 'daily';
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
          if (shouldTryPassword) {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => PasswordRestoreDialog(
                backup: backup,
                onSuccess: () {
                  _loadBackupInfo();
                  _showSuccessDialog('Backup restored successfully!');
                },
              ),
            );
          }
        }
        return;
      }

      if (result.success) {
        _showSuccessDialog('Backup restored successfully!');
        _loadBackupInfo();
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
      // Simple file deletion approach
      final backupFile = File(backup.id); // backup.id should be the full path

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
                Icon(Icons.flash_on, color: AppTheme.primaryColor),
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
                      minimumSize: const Size(0, 48),
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
                      minimumSize: const Size(0, 48),
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
                Icon(Icons.info_outline, color: AppTheme.primaryColor),
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
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Last Backup:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade700,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _lastBackupInfo ?? 'No backup created yet',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Retention: Keeps last 3 backups',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue.shade600,
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
                Icon(Icons.schedule, color: AppTheme.primaryColor),
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
                    if (value != null) {
                      setState(() {
                        _autoBackupFrequency = value;
                      });
                    }
                  },
                  items: [
                    'daily',
                    'weekly',
                    'monthly',
                  ].map((frequency) {
                    return DropdownMenuItem(
                      value: frequency,
                      child: Text(frequency.toUpperCase()),
                    );
                  }).toList(),
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
                Icon(Icons.folder_outlined, color: AppTheme.primaryColor),
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
        leading: CircleAvatar(
          backgroundColor: AppTheme.primaryColor,
          child: const Icon(
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
