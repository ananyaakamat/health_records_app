import 'dart:convert';
import 'dart:io';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';
import '../database/database_helper.dart';

// WorkManager callback for background backup task
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      if (kDebugMode) {
        print('WorkManager task received: $task');
      }
      if (task == "auto_backup_task") {
        if (kDebugMode) {
          print('Executing auto backup task...');
        }
        final backupService = BackupService._();
        final result = await backupService.createBackup(isAutoBackup: true);

        if (kDebugMode) {
          print(
              'Auto backup result: ${result.success ? "SUCCESS" : "SKIPPED"} - ${result.message}');
        }

        // Always return true for auto backup to keep the periodic task running
        // Even if backup was skipped due to no profiles, the task should continue
        return Future.value(true);
      }
      if (kDebugMode) {
        print('Unknown task: $task');
      }
      return Future.value(false);
    } catch (e) {
      if (kDebugMode) {
        print('Auto backup failed: $e');
      }
      // Return true even on error to keep periodic task running
      return Future.value(true);
    }
  });
}

class BackupService {
  static const String _encryptionKeyKey = 'backup_encryption_key';
  static const String _backupFolderName = 'HealthRecords_Backups';
  static const String _autoBackupKey = 'auto_backup_enabled';
  static const String _autoBackupFrequencyKey = 'auto_backup_frequency';
  static const String _lastBackupKey = 'last_backup_timestamp';
  static const String _deviceIdKey = 'device_id';

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  static BackupService? _instance;
  static BackupService get instance {
    _instance ??= BackupService._();
    return _instance!;
  }

  BackupService._();

  // Initialize backup service
  Future<void> initialize() async {
    await _initializeEncryption();
    await _initializeWorkManager();
    await _generateDeviceId();
  }

  // Initialize encryption key
  Future<void> _initializeEncryption() async {
    final existingKey = await _secureStorage.read(key: _encryptionKeyKey);
    if (existingKey == null) {
      final key = encrypt.Key.fromSecureRandom(32);
      await _secureStorage.write(
        key: _encryptionKeyKey,
        value: base64.encode(key.bytes),
      );
    }
  }

  // Generate deterministic key from password for cross-device compatibility
  encrypt.Key _generateKeyFromPassword(String password) {
    const salt = 'HealthRecords_Salt_2024'; // Fixed salt for consistency
    final combined = password + salt;

    // Create a 32-byte key using repeated hashing
    final keyBytes = List<int>.filled(32, 0);
    final combinedBytes = utf8.encode(combined);

    // Fill the 32-byte key by repeating and XORing the combined bytes
    for (int i = 0; i < 32; i++) {
      keyBytes[i] = combinedBytes[i % combinedBytes.length] ^
          combinedBytes[(i * 7) % combinedBytes.length];
    }

    return encrypt.Key(Uint8List.fromList(keyBytes));
  }

  // Initialize WorkManager for auto-backup
  Future<void> _initializeWorkManager() async {
    await Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: kDebugMode,
    );
  }

  // Generate unique device ID
  Future<void> _generateDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey(_deviceIdKey)) {
      final deviceId = DateTime.now().millisecondsSinceEpoch.toString();
      await prefs.setString(_deviceIdKey, deviceId);
    }
  }

  // Get encryption key
  Future<encrypt.Key> _getEncryptionKey() async {
    // Use a simpler approach: generate key from app-specific string
    // This makes backups portable across devices for the same app
    const appKey = 'HealthRecordsApp2024SecureBackup';
    final keyBytes = utf8.encode(appKey).take(32).toList();
    // Pad to 32 bytes if needed
    while (keyBytes.length < 32) {
      keyBytes.add(0);
    }
    return encrypt.Key(Uint8List.fromList(keyBytes));
  }

  // Get Downloads folder path
  Future<Directory> _getDownloadsDirectory() async {
    if (Platform.isAndroid) {
      // Ensure we have storage permission
      await checkStoragePermission();

      // For Android, use the Downloads directory
      final directory = await getExternalStorageDirectory();
      if (directory != null) {
        // Navigate to the Downloads folder
        const downloadsPath = '/storage/emulated/0/Download';
        final downloadsDir = Directory(downloadsPath);
        if (await downloadsDir.exists()) {
          return downloadsDir;
        }
      }
      // Fallback to external storage directory
      return directory ?? await getApplicationDocumentsDirectory();
    } else {
      // For other platforms, use documents directory
      return await getApplicationDocumentsDirectory();
    }
  }

  // Create backup folder in Downloads
  Future<Directory> _createBackupFolder() async {
    final downloadsDir = await _getDownloadsDirectory();
    final backupDir = Directory('${downloadsDir.path}/$_backupFolderName');

    if (!await backupDir.exists()) {
      await backupDir.create(recursive: true);
    }

    return backupDir;
  }

  // Public method to get backup directory for external access
  Future<Directory> getBackupDirectory() async {
    return await _createBackupFolder();
  }

  // Check and request storage permissions
  Future<bool> checkStoragePermission() async {
    if (!Platform.isAndroid) {
      return true; // No permission needed on other platforms
    }

    // Check Android version
    if (await Permission.manageExternalStorage.isGranted) {
      return true;
    }

    // For Android 11+ (API 30+), we need MANAGE_EXTERNAL_STORAGE
    if (await Permission.manageExternalStorage.request().isGranted) {
      return true;
    }

    // Fallback to legacy storage permissions
    if (await Permission.storage.isGranted) {
      return true;
    }

    final status = await Permission.storage.request();
    return status.isGranted;
  }

  // Create backup
  Future<BackupResult> createBackup({bool isAutoBackup = false}) async {
    try {
      // Get database file
      final dbHelper = DatabaseHelper.instance;
      final db = await dbHelper.database;

      // Check if at least one profile exists before creating backup
      final profileCount =
          await db.rawQuery('SELECT COUNT(*) as count FROM profiles');
      final count = profileCount.isNotEmpty
          ? (profileCount.first['count'] as int?) ?? 0
          : 0;

      if (count == 0) {
        return BackupResult(
          success: false,
          message: isAutoBackup
              ? 'Auto-backup skipped: No profiles to backup'
              : 'No profiles found. Create a profile first before backing up.',
        );
      }

      final dbPath = db.path;

      // Create backup filename with 12-hour format
      final timestamp = DateTime.now();
      final hour12 = timestamp.hour > 12
          ? timestamp.hour - 12
          : (timestamp.hour == 0 ? 12 : timestamp.hour);
      final amPm = timestamp.hour >= 12 ? 'PM' : 'AM';
      final formattedDate =
          "${timestamp.day}${_getMonthName(timestamp.month)}${timestamp.year.toString().substring(2)}_${hour12.toString().padLeft(2, '0')}${timestamp.minute.toString().padLeft(2, '0')}$amPm";
      final backupFileName = 'medical_records$formattedDate.db.enc';

      // Get backup folder
      final backupDir = await _createBackupFolder();
      final backupPath = '${backupDir.path}/$backupFileName';

      // Encrypt database file
      final encryptedData = await _encryptFile(dbPath);

      // Write encrypted backup
      final backupFile = File(backupPath);
      await backupFile.writeAsBytes(encryptedData);

      // Clean old backups (keep only latest 3)
      await _cleanOldBackups(backupDir);

      // Update last backup timestamp
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_lastBackupKey, timestamp.toIso8601String());

      return BackupResult(
        success: true,
        message: isAutoBackup
            ? 'Auto-backup completed successfully'
            : 'Backup saved to Downloads folder',
        timestamp: timestamp,
      );
    } catch (e) {
      debugPrint('Backup error: $e');
      return BackupResult(success: false, message: 'Backup failed: $e');
    }
  }

  // Encrypt file
  Future<List<int>> _encryptFile(String filePath) async {
    final file = File(filePath);
    final fileData = await file.readAsBytes();
    return await _encryptData(base64.encode(fileData));
  }

  // Encrypt data
  Future<List<int>> _encryptData(String data) async {
    final key = await _getEncryptionKey();
    final iv = encrypt.IV.fromSecureRandom(16);
    final encrypter = encrypt.Encrypter(encrypt.AES(key));
    final encrypted = encrypter.encrypt(data, iv: iv);

    // Combine IV and encrypted data
    final combined = <int>[];
    combined.addAll(iv.bytes);
    combined.addAll(encrypted.bytes);

    return combined;
  }

  // Decrypt data with better error handling
  Future<String> _decryptData(List<int> encryptedData) async {
    try {
      final key = await _getEncryptionKey();

      // Validate input data
      if (encryptedData.length < 16) {
        throw Exception('Backup file is too small or corrupted (missing IV)');
      }

      // Extract IV and encrypted content
      final iv = encrypt.IV(Uint8List.fromList(encryptedData.sublist(0, 16)));
      final encryptedContent = Uint8List.fromList(encryptedData.sublist(16));

      if (encryptedContent.isEmpty) {
        throw Exception('Backup file contains no encrypted data');
      }

      final encrypter = encrypt.Encrypter(encrypt.AES(key));

      try {
        final decrypted =
            encrypter.decrypt(encrypt.Encrypted(encryptedContent), iv: iv);

        if (decrypted.isEmpty) {
          throw Exception('Backup file decryption resulted in empty data');
        }

        return decrypted;
      } catch (e) {
        if (e.toString().contains('pad block') ||
            e.toString().contains('Invalid argument') ||
            e.toString().contains('corrupted') ||
            e.toString().contains('padding')) {
          throw Exception(
              'CROSS_DEVICE_ERROR'); // Special marker for cross-device error
        }
        throw Exception('Unable to decrypt backup file: ${e.toString()}');
      }
    } catch (e) {
      debugPrint('Decryption error: $e');
      rethrow;
    }
  }

  // Decrypt data using password for cross-device compatibility
  Future<String> _decryptDataWithPassword(
      List<int> encryptedData, String password) async {
    try {
      final key = _generateKeyFromPassword(password);

      // Validate input data
      if (encryptedData.length < 16) {
        throw Exception('Backup file is too small or corrupted (missing IV)');
      }

      // Extract IV and encrypted content
      final iv = encrypt.IV(Uint8List.fromList(encryptedData.sublist(0, 16)));
      final encryptedContent = Uint8List.fromList(encryptedData.sublist(16));

      if (encryptedContent.isEmpty) {
        throw Exception('Backup file contains no encrypted data');
      }

      final encrypter = encrypt.Encrypter(encrypt.AES(key));

      final decrypted =
          encrypter.decrypt(encrypt.Encrypted(encryptedContent), iv: iv);

      if (decrypted.isEmpty) {
        throw Exception('Backup file decryption resulted in empty data');
      }

      return decrypted;
    } catch (e) {
      debugPrint('Password decryption error: $e');
      throw Exception('Invalid password or corrupted backup file');
    }
  }

  // Get available backups
  Future<List<BackupInfo>> getAvailableBackups() async {
    try {
      // Check storage permission before accessing files
      final hasPermission = await checkStoragePermission();
      if (!hasPermission) {
        if (kDebugMode) {
          print(
              'BackupService: Storage permission denied, returning empty list');
        }
        return [];
      }

      final backupDir = await _createBackupFolder();

      // Create fresh directory instance to avoid caching issues
      final freshDir = Directory(backupDir.path);

      if (kDebugMode) {
        print('BackupService: Scanning directory: ${freshDir.path}');
      }

      final files =
          await freshDir.list(recursive: false, followLinks: false).toList();

      if (kDebugMode) {
        print(
            'BackupService: Found ${files.length} total items in backup directory');
      }

      final backups = <BackupInfo>[];

      for (final entity in files) {
        if (entity is File) {
          // Create fresh file instance to avoid caching
          final freshFile = File(entity.path);

          // Check if file exists and is readable
          if (!await freshFile.exists()) {
            if (kDebugMode) {
              print('BackupService: File does not exist: ${entity.path}');
            }
            continue;
          }

          final fileName = entity.path.split('/').last;

          // Case-insensitive filter: accept files containing 'medical_record' OR 'backup_'
          // This handles:
          // - App-created files: medical_records30Dec25_1218PM.db.enc or backup_30Dec25_1218PM.db.enc
          // - Shared files with extension: Health Records Backup - medical_records30Dec25_1218PM.db.enc
          // - Shared files without extension: Health Records Backup - backup_29Dec25_0206PM
          final lowerFileName = fileName.toLowerCase();
          if (lowerFileName.contains('medical_record') ||
              lowerFileName.contains('backup_')) {
            if (kDebugMode) {
              print('BackupService: Valid backup file found: $fileName');
            }

            try {
              final stat = await freshFile.stat();

              backups.add(BackupInfo(
                id: fileName,
                displayName: fileName.replaceAll('.db.enc', ''),
                createdTime: stat.modified,
                size: stat.size,
              ));
            } catch (e) {
              if (kDebugMode) {
                print(
                    'BackupService: Error reading file stats for $fileName: $e');
              }
            }
          } else {
            if (kDebugMode) {
              print(
                  'BackupService: Skipping file (does not match pattern): $fileName');
            }
          }
        }
      }

      if (kDebugMode) {
        print('BackupService: Total valid backups detected: ${backups.length}');
      }

      // Sort by creation time (newest first)
      backups.sort((a, b) => b.createdTime.compareTo(a.createdTime));

      return backups;
    } catch (e) {
      debugPrint('Error loading backups: $e');
      return [];
    }
  }

  // Restore from backup
  Future<BackupResult> restoreBackup(String backupId) async {
    try {
      final backupDir = await _createBackupFolder();
      final backupFile = File('${backupDir.path}/$backupId');

      if (!await backupFile.exists()) {
        throw Exception('Backup file not found');
      }

      // Validate backup file size
      final fileSize = await backupFile.length();
      if (fileSize < 32) {
        // At least IV (16 bytes) + minimal encrypted data
        throw Exception('Backup file appears to be corrupted (too small)');
      }

      // Read and decrypt backup
      final encryptedData = await backupFile.readAsBytes();

      // Validate encrypted data structure
      if (encryptedData.length < 16) {
        throw Exception('Invalid backup file format (missing IV)');
      }

      String decryptedData;
      try {
        decryptedData = await _decryptData(encryptedData);
      } catch (e) {
        if (e.toString().contains('CROSS_DEVICE_ERROR')) {
          // This backup was created on a different device/installation
          throw Exception('CROSS_DEVICE_BACKUP');
        }
        rethrow;
      }

      // Validate decrypted data is valid base64
      if (decryptedData.isEmpty) {
        throw Exception('Decryption failed - backup file may be corrupted');
      }

      List<int> decodedData;
      try {
        decodedData = base64.decode(decryptedData);
      } catch (e) {
        throw Exception(
            'Invalid backup format - base64 decode failed: ${e.toString()}');
      }

      // Validate decoded data size
      if (decodedData.isEmpty) {
        throw Exception('Backup file contains no valid database data');
      }

      // Get database path and close current connection
      final dbHelper = DatabaseHelper.instance;
      final db = await dbHelper.database;
      final dbPath = db.path;
      await db.close();

      // Create backup of current database before restore
      final currentDbFile = File(dbPath);
      final tempBackupPath = '$dbPath.temp_backup';
      final tempBackupFile = File(tempBackupPath);

      if (await currentDbFile.exists()) {
        await currentDbFile.copy(tempBackupPath);
      }

      try {
        // Replace database file
        await currentDbFile.writeAsBytes(decodedData);

        // Test if restored database is valid by trying to open it
        await dbHelper.reinitializeDatabase();
        final testDb = await dbHelper.database;

        // Simple validation query to ensure database integrity
        try {
          await testDb
              .rawQuery('SELECT name FROM sqlite_master WHERE type="table"');
          // Don't close the database as the app needs to continue using it
          // await testDb.close();
        } catch (e) {
          throw Exception('Restored database is corrupted: ${e.toString()}');
        }

        // If we reach here, restore was successful
        if (await tempBackupFile.exists()) {
          await tempBackupFile.delete();
        }

        return BackupResult(
          success: true,
          message: 'Backup restored successfully',
          timestamp: DateTime.now(),
        );
      } catch (e) {
        // Restore failed, revert to original database
        if (await tempBackupFile.exists()) {
          await tempBackupFile.copy(dbPath);
          await tempBackupFile.delete();
          await dbHelper.reinitializeDatabase();
        }
        rethrow;
      }
    } catch (e) {
      debugPrint('Restore error: $e');
      return BackupResult(
          success: false,
          message:
              'Restore failed: ${e.toString().replaceAll('Exception: ', '')}');
    }
  }

  // Restore from backup using password (for cross-device compatibility)
  Future<BackupResult> restoreBackupWithPassword(
      String backupId, String password) async {
    try {
      final backupDir = await _createBackupFolder();
      final backupFile = File('${backupDir.path}/$backupId');

      if (!await backupFile.exists()) {
        throw Exception('Backup file not found');
      }

      // Validate backup file size
      final fileSize = await backupFile.length();
      if (fileSize < 32) {
        throw Exception('Backup file appears to be corrupted (too small)');
      }

      // Read and decrypt backup using password
      final encryptedData = await backupFile.readAsBytes();

      if (encryptedData.length < 16) {
        throw Exception('Invalid backup file format (missing IV)');
      }

      final decryptedData =
          await _decryptDataWithPassword(encryptedData, password);

      if (decryptedData.isEmpty) {
        throw Exception(
            'Decryption failed - incorrect password or corrupted file');
      }

      List<int> decodedData;
      try {
        decodedData = base64.decode(decryptedData);
      } catch (e) {
        throw Exception(
            'Invalid backup format - base64 decode failed: ${e.toString()}');
      }

      if (decodedData.isEmpty) {
        throw Exception('Backup file contains no valid database data');
      }

      // Get database path and close current connection
      final dbHelper = DatabaseHelper.instance;
      final db = await dbHelper.database;
      final dbPath = db.path;
      await db.close();

      // Create backup of current database before restore
      final currentDbFile = File(dbPath);
      final tempBackupPath = '$dbPath.temp_backup';
      final tempBackupFile = File(tempBackupPath);

      if (await currentDbFile.exists()) {
        await currentDbFile.copy(tempBackupPath);
      }

      try {
        // Replace database file
        await currentDbFile.writeAsBytes(decodedData);

        // Test if restored database is valid by trying to open it
        await dbHelper.reinitializeDatabase();
        final testDb = await dbHelper.database;

        // Simple validation query to ensure database integrity
        try {
          await testDb
              .rawQuery('SELECT name FROM sqlite_master WHERE type="table"');
          // Don't close the database as the app needs to continue using it
          // await testDb.close();
        } catch (e) {
          throw Exception('Restored database is corrupted: ${e.toString()}');
        }

        // If we reach here, restore was successful
        if (await tempBackupFile.exists()) {
          await tempBackupFile.delete();
        }

        return BackupResult(
          success: true,
          message: 'Cross-device backup restored successfully',
          timestamp: DateTime.now(),
        );
      } catch (e) {
        // Restore failed, revert to original database
        if (await tempBackupFile.exists()) {
          await tempBackupFile.copy(dbPath);
          await tempBackupFile.delete();
          await dbHelper.reinitializeDatabase();
        }
        rethrow;
      }
    } catch (e) {
      debugPrint('Cross-device restore error: $e');
      return BackupResult(
          success: false,
          message:
              'Cross-device restore failed: ${e.toString().replaceAll('Exception: ', '')}');
    }
  }

  // Get backup settings
  Future<Map<String, dynamic>> getBackupSettings() async {
    final prefs = await SharedPreferences.getInstance();
    var frequency = prefs.getString(_autoBackupFrequencyKey) ?? 'daily';

    // Clean up legacy 2min frequency setting
    if (frequency == '2min') {
      frequency = 'daily';
      await prefs.setString(_autoBackupFrequencyKey, frequency);
      if (kDebugMode) {
        print('Cleaned up legacy 2min frequency setting to daily');
      }
    }

    return {
      'auto_backup_enabled': prefs.getBool(_autoBackupKey) ?? false,
      'auto_backup_frequency': frequency,
      'last_backup': prefs.getString(_lastBackupKey),
    };
  }

  // Get last backup info
  Future<String?> getLastBackupInfo() async {
    try {
      // Get backup directory
      final backupDir = await _createBackupFolder();

      // Get all backup files
      final files = await backupDir.list().toList();
      final backupFiles = files
          .where((file) => file is File && file.path.endsWith('.db.enc'))
          .cast<File>()
          .toList();

      if (backupFiles.isEmpty) {
        return null;
      }

      // Sort files by modification time (newest first)
      backupFiles
          .sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));

      // Get the most recent backup file
      final lastBackupFile = backupFiles.first;
      final lastModified = lastBackupFile.lastModifiedSync();
      final now = DateTime.now();
      final difference = now.difference(lastModified);

      String timeAgo;
      if (difference.inDays > 0) {
        timeAgo =
            '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
      } else if (difference.inHours > 0) {
        timeAgo =
            '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
      } else if (difference.inMinutes > 0) {
        timeAgo =
            '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
      } else {
        timeAgo = 'Just now';
      }

      return 'Last backup: $timeAgo';
    } catch (e) {
      if (kDebugMode) {
        print('Error getting last backup info: $e');
      }
      // Fallback to SharedPreferences method if file checking fails
      final prefs = await SharedPreferences.getInstance();
      final lastBackupStr = prefs.getString(_lastBackupKey);

      if (lastBackupStr != null) {
        final lastBackup = DateTime.parse(lastBackupStr);
        final now = DateTime.now();
        final difference = now.difference(lastBackup);

        if (difference.inDays > 0) {
          return 'Last backup: ${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
        } else if (difference.inHours > 0) {
          return 'Last backup: ${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
        } else {
          return 'Last backup: ${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
        }
      }

      return null;
    }
  }

  // Auto-backup settings
  Future<void> setAutoBackup(bool enabled, String frequency) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_autoBackupKey, enabled);

    // Clean up legacy 2min frequency setting
    if (frequency == '2min') {
      frequency = 'daily';
      if (kDebugMode) {
        print('Converting legacy 2min frequency to daily');
      }
    }

    await prefs.setString(_autoBackupFrequencyKey, frequency);

    // Always cancel existing tasks first
    await Workmanager().cancelByUniqueName('auto_backup');

    if (enabled) {
      await _scheduleAutoBackup(frequency);
    }
  }

  // Schedule auto-backup
  Future<void> _scheduleAutoBackup(String frequency) async {
    if (kDebugMode) {
      print('Scheduling auto backup with frequency: $frequency');
    }

    Duration interval;
    switch (frequency) {
      case 'hourly':
        interval = const Duration(hours: 1);
        break;
      case 'daily':
        interval = const Duration(days: 1);
        break;
      case 'weekly':
        interval = const Duration(days: 7);
        break;
      default:
        interval = const Duration(days: 1);
    }

    if (kDebugMode) {
      print(
          'Registering periodic task with interval: ${interval.inMinutes} minutes');
    }

    await Workmanager().registerPeriodicTask(
      'auto_backup',
      'auto_backup_task',
      frequency: interval,
      constraints: Constraints(
        networkType: NetworkType.not_required,
        requiresBatteryNotLow: false,
        requiresCharging: false,
        requiresDeviceIdle: false,
        requiresStorageNotLow: false,
      ),
    );

    if (kDebugMode) {
      print('Auto backup task registered successfully');
    }
  }

  // Clean old backups (keep only latest 10)
  Future<void> _cleanOldBackups(Directory backupDir) async {
    try {
      final files = await backupDir.list().toList();

      // Clean up any existing JSON files (legacy from previous versions)
      final jsonFiles = files
          .where((file) => file is File && file.path.endsWith('.json.enc'))
          .cast<File>()
          .toList();

      for (final jsonFile in jsonFiles) {
        await jsonFile.delete();
        debugPrint('Removed legacy JSON backup file: ${jsonFile.path}');
      }

      final backupFiles = files
          .where((file) => file is File && file.path.endsWith('.db.enc'))
          .cast<File>()
          .toList();

      if (backupFiles.length > 3) {
        // Sort by modification time (oldest first)
        backupFiles.sort(
            (a, b) => a.statSync().modified.compareTo(b.statSync().modified));

        // Delete oldest files, keep only latest 3
        final filesToDelete = backupFiles.take(backupFiles.length - 3);
        for (final file in filesToDelete) {
          await file.delete();
        }
      }
    } catch (e) {
      debugPrint('Error cleaning old backups: $e');
    }
  }

  // Helper method to get month name
  String _getMonthName(int month) {
    const months = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return months[month];
  }

  // Update backup settings
  Future<void> updateBackupSettings(Map<String, dynamic> settings) async {
    final prefs = await SharedPreferences.getInstance();

    if (settings.containsKey('auto_backup_enabled')) {
      await prefs.setBool(_autoBackupKey, settings['auto_backup_enabled']);
    }

    if (settings.containsKey('auto_backup_frequency')) {
      await prefs.setString(
          _autoBackupFrequencyKey, settings['auto_backup_frequency']);
    }

    // Re-schedule work manager with new settings
    if (settings['auto_backup_enabled'] == true) {
      await _scheduleAutoBackup(settings['auto_backup_frequency'] ?? 'daily');
    } else {
      await Workmanager().cancelByUniqueName('auto_backup');
    }
  }

  // Delete a backup file
  Future<BackupResult> deleteBackup(String backupId) async {
    try {
      final downloadsDir = await _getDownloadsDirectory();
      final backupFolder =
          Directory('${downloadsDir.path}/HealthRecordsBackups');

      if (!await backupFolder.exists()) {
        return BackupResult(
          success: false,
          message: 'Backup folder not found',
        );
      }

      final backupFile = File('${backupFolder.path}/$backupId.hrbak');

      if (!await backupFile.exists()) {
        return BackupResult(
          success: false,
          message: 'Backup file not found',
        );
      }

      await backupFile.delete();

      return BackupResult(
        success: true,
        message: 'Backup deleted successfully',
      );
    } catch (e) {
      return BackupResult(
        success: false,
        message: 'Failed to delete backup: $e',
      );
    }
  }

  // Force reset auto backup system - cancel all tasks and clear settings
  Future<void> forceResetAutoBackup() async {
    try {
      // Cancel all WorkManager tasks
      await Workmanager().cancelAll();

      // Also specifically cancel by unique name
      await Workmanager().cancelByUniqueName('auto_backup');

      if (kDebugMode) {
        print('All auto backup tasks cancelled and reset');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error during force reset: $e');
      }
    }
  }
}

// Backup result class
class BackupResult {
  final bool success;
  final String message;
  final DateTime? timestamp;

  BackupResult({
    required this.success,
    required this.message,
    this.timestamp,
  });
}

// Backup info class
class BackupInfo {
  final String id;
  final String displayName;
  final DateTime createdTime;
  final int size;

  BackupInfo({
    required this.id,
    required this.displayName,
    required this.createdTime,
    required this.size,
  });
}
