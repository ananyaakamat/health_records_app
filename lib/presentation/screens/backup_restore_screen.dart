import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/services/backup_service.dart';
import '../../core/themes/app_theme.dart';
import '../../core/database/database_helper.dart';
import '../dialogs/password_restore_dialog.dart';
import '../providers/profile_provider.dart';
import '../providers/providers.dart';
import 'home_screen.dart';
import 'user_guide_screen.dart';

class BackupRestoreScreen extends ConsumerStatefulWidget {
  const BackupRestoreScreen({super.key});

  @override
  ConsumerState<BackupRestoreScreen> createState() =>
      _BackupRestoreScreenState();
}

class _BackupRestoreScreenState extends ConsumerState<BackupRestoreScreen>
    with WidgetsBindingObserver {
  bool _isLoading = false;
  bool _autoBackupEnabled = false;
  String _autoBackupFrequency = 'daily';
  String? _lastBackupInfo;
  List<BackupInfo> _availableBackups = [];
  bool _backupsLoaded = false;
  Timer? _refreshTimer;
  Timer? _backupListRefreshTimer;
  Set<String> _lastBackupFileNames = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadSettings();
    _loadBackupInfo();
    _requestPermissionsAndLoadBackups(); // Check permissions first

    // Start timer to refresh backup info every minute
    _refreshTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _loadBackupInfo();
    });

    // Start timer to check for new backup files every 5 seconds
    // This detects files copied while app is in foreground (e.g., split-screen file manager)
    _backupListRefreshTimer =
        Timer.periodic(const Duration(seconds: 5), (timer) {
      _checkForNewBackups();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _refreshTimer?.cancel();
    _backupListRefreshTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Refresh backups when app comes to foreground
    // This detects files copied when app was in background
    // AND checks if permission was granted while in background
    if (state == AppLifecycleState.resumed) {
      if (kDebugMode) {
        print('App resumed, checking for new backup files');
      }
      // Re-check permissions and load backups
      _requestPermissionsAndLoadBackups();
    }
  }

  // Lightweight check for new backups without showing loading indicator
  Future<void> _checkForNewBackups() async {
    try {
      final backupService = BackupService.instance;
      final backups = await backupService.getAvailableBackups();

      // Compare actual file names, not just count
      final currentFileNames = backups.map((b) => b.id).toSet();

      // Check if there are any differences in the file sets
      if (!_setEquals(_lastBackupFileNames, currentFileNames)) {
        if (kDebugMode) {
          print('Backup list changed. Old: $_lastBackupFileNames');
          print('New: $currentFileNames');
        }
        _lastBackupFileNames = currentFileNames;
        setState(() {
          _availableBackups = backups;
          _backupsLoaded = true;
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error checking for new backups: $e');
      }
    }
  }

  // Helper to compare two sets for equality
  bool _setEquals(Set<String> set1, Set<String> set2) {
    if (set1.length != set2.length) return false;
    return set1.containsAll(set2);
  }

  Future<void> _loadSettings() async {
    final backupService = BackupService.instance;
    final settings = await backupService.getBackupSettings();

    final originalFrequency = settings['auto_backup_frequency'] ?? 'daily';
    final wasLegacyFrequency = originalFrequency == '2min';

    setState(() {
      _autoBackupEnabled = settings['auto_backup_enabled'] ?? false;
      // Ensure the frequency is one of the valid options
      _autoBackupFrequency =
          (originalFrequency == 'daily' || originalFrequency == 'weekly')
              ? originalFrequency
              : 'daily'; // Default to daily if invalid or was 2min
    });

    // If we had a legacy frequency and auto backup is enabled, restart with new settings
    if (wasLegacyFrequency && _autoBackupEnabled) {
      if (kDebugMode) {
        print(
            'Detected legacy 2min frequency, restarting auto backup with daily');
      }
      await backupService.forceResetAutoBackup();
      await backupService.setAutoBackup(
          _autoBackupEnabled, _autoBackupFrequency);
    }
  }

  Future<void> _loadBackupInfo() async {
    final backupService = BackupService.instance;
    final lastBackup = await backupService.getLastBackupInfo();

    setState(() {
      _lastBackupInfo = lastBackup;
    });
  }

  Future<void> _requestPermissionsAndLoadBackups() async {
    if (kDebugMode) {
      print('_requestPermissionsAndLoadBackups called');
    }

    if (!Platform.isAndroid) {
      if (kDebugMode) {
        print('Not Android, loading backups directly');
      }
      await _loadAvailableBackups();
      return;
    }

    // Check if we already have permission
    final manageGranted = await Permission.manageExternalStorage.isGranted;
    final storageGranted = await Permission.storage.isGranted;

    if (kDebugMode) {
      print('MANAGE_EXTERNAL_STORAGE granted: $manageGranted');
      print('STORAGE granted: $storageGranted');
    }

    if (manageGranted || storageGranted) {
      if (kDebugMode) {
        print('Storage permission already granted');
      }
      await _loadAvailableBackups();
      return;
    }

    // For Android 11+, MANAGE_EXTERNAL_STORAGE cannot be requested via dialog
    // User must manually enable it in Settings
    if (kDebugMode) {
      print('Storage permission not granted - showing settings prompt');
      print('mounted: $mounted');
    }

    if (mounted) {
      _showStoragePermissionDialog();
    }
  }

  Future<void> _loadAvailableBackups() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final backupService = BackupService.instance;
      final backups = await backupService.getAvailableBackups();

      _lastBackupFileNames = backups.map((b) => b.id).toSet();

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
    // Small delay to allow Android file system to sync
    await Future.delayed(const Duration(milliseconds: 300));
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

  Future<void> _shareBackup(BackupInfo backup) async {
    try {
      final backupService = BackupService.instance;
      final backupDir = await backupService.getBackupDirectory();
      final backupFile = File('${backupDir.path}/${backup.id}');

      if (!await backupFile.exists()) {
        _showErrorDialog('Backup file not found');
        return;
      }

      final result = await Share.shareXFiles(
        [XFile(backupFile.path)],
        text: 'Health Records Backup - ${backup.displayName}\n\n'
            'Created: ${backup.createdTime.day}/${backup.createdTime.month}/${backup.createdTime.year}\n'
            'Size: ${(backup.size / 1024).toStringAsFixed(1)} KB\n\n'
            'Important: Keep this backup file safe. You may need to enter a recovery password when restoring on a different device.',
        subject: 'Health Records Backup - ${backup.displayName}',
      );

      if (result.status == ShareResultStatus.success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 8),
                  Text('Backup shared successfully!'),
                ],
              ),
              backgroundColor: Colors.green.shade600,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      _showErrorDialog('Failed to share backup: $e');
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

  void _showStoragePermissionDialog() {
    if (kDebugMode) {
      print('_showStoragePermissionDialog called');
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Storage Permission Required'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'To access backup files (including those copied from other devices), this app needs storage permission.',
              style: TextStyle(fontSize: 14),
            ),
            SizedBox(height: 16),
            Text(
              'Steps:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            SizedBox(height: 8),
            Text(
              '1. Tap "Open Settings" below\n'
              '2. Find and tap "Permissions"\n'
              '3. Enable "Files and media" or "Storage"\n'
              '4. Choose "Allow" or "Allow all files"',
              style: TextStyle(fontSize: 13),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Load with whatever permission we have
              _loadAvailableBackups();
            },
            child: const Text('Skip'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final opened = await openAppSettings();
              if (kDebugMode) {
                print('Settings opened: $opened');
              }
              // Wait a bit and try loading again
              await Future.delayed(const Duration(seconds: 1));
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'After granting permission, tap the refresh button to reload backups',
                    ),
                    duration: Duration(seconds: 4),
                  ),
                );
              }
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
        title: const Text('Backup & Restore'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) =>
                      const UserGuideScreen(currentPage: 'Backup & Restore'),
                ),
              );
            },
            tooltip: 'Help',
          ),
        ],
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
            const Row(
              children: [
                Icon(Icons.flash_on, color: AppTheme.primaryColor),
                SizedBox(width: 8),
                Text(
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
            const Row(
              children: [
                Icon(Icons.info_outline, color: AppTheme.primaryColor),
                SizedBox(width: 8),
                Text(
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
            const Row(
              children: [
                Icon(Icons.schedule, color: AppTheme.primaryColor),
                SizedBox(width: 8),
                Text(
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
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          children: [
            // Top row with icon and backup info
            Row(
              children: [
                // Leading icon
                const CircleAvatar(
                  backgroundColor: AppTheme.primaryColor,
                  radius: 18,
                  child: Icon(
                    Icons.backup,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                // Content (backup name and details)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Backup name
                      Text(
                        backup.displayName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      // Size and timestamp info
                      Text(
                        '${(backup.size / 1024).toStringAsFixed(1)} KB • ${backup.createdTime.day}/${backup.createdTime.month}/${backup.createdTime.year} ${backup.createdTime.hour > 12 ? backup.createdTime.hour - 12 : (backup.createdTime.hour == 0 ? 12 : backup.createdTime.hour)}:${backup.createdTime.minute.toString().padLeft(2, '0')} ${backup.createdTime.hour >= 12 ? 'PM' : 'AM'}',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Bottom row with action icons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Restore icon
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: _isLoading ? null : () => _restoreBackup(backup),
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Icon(
                        Icons.restore,
                        color: Colors.green.shade600,
                        size: 20,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Share icon
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: _isLoading ? null : () => _shareBackup(backup),
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Icon(
                        Icons.share,
                        color: Colors.blue.shade600,
                        size: 20,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Delete icon
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: _isLoading ? null : () => _deleteBackup(backup),
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Icon(
                        Icons.delete,
                        color: Colors.red.shade600,
                        size: 20,
                      ),
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
}
