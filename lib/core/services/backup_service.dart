import 'dart:convert';
import 'dart:io';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';
import '../database/database_helper.dart';

// WorkManager callback for background backup task
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      if (task == "autoBackupTask") {
        final backupService = BackupService._();
        await backupService.createBackup();
        return Future.value(true);
      }
      return Future.value(false);
    } catch (e) {
      if (kDebugMode) {
        print('Auto backup failed: $e');
      }
      return Future.value(false);
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
      final backupFileName = 'backup_$formattedDate.db.enc';

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
      final backupDir = await _createBackupFolder();
      final files = await backupDir.list().toList();

      final backups = <BackupInfo>[];

      for (final file in files) {
        if (file is File && file.path.endsWith('.db.enc')) {
          final fileName = file.path.split('/').last;
          final stat = await file.stat();

          backups.add(BackupInfo(
            id: fileName,
            displayName: fileName.replaceAll('.db.enc', ''),
            createdTime: stat.modified,
            size: stat.size,
          ));
        }
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
    return {
      'auto_backup_enabled': prefs.getBool(_autoBackupKey) ?? false,
      'auto_backup_frequency':
          prefs.getString(_autoBackupFrequencyKey) ?? 'daily',
      'last_backup': prefs.getString(_lastBackupKey),
    };
  }

  // Get last backup info
  Future<String?> getLastBackupInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final lastBackupStr = prefs.getString(_lastBackupKey);

    if (lastBackupStr != null) {
      final lastBackup = DateTime.parse(lastBackupStr);
      final now = DateTime.now();
      final difference = now.difference(lastBackup);

      if (difference.inDays > 0) {
        return 'Last backup: ${difference.inDays} days ago';
      } else if (difference.inHours > 0) {
        return 'Last backup: ${difference.inHours} hours ago';
      } else {
        return 'Last backup: ${difference.inMinutes} minutes ago';
      }
    }

    return null;
  }

  // Auto-backup settings
  Future<void> setAutoBackup(bool enabled, String frequency) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_autoBackupKey, enabled);
    await prefs.setString(_autoBackupFrequencyKey, frequency);

    if (enabled) {
      await _scheduleAutoBackup(frequency);
    } else {
      await Workmanager().cancelByUniqueName('auto_backup');
    }
  }

  // Schedule auto-backup
  Future<void> _scheduleAutoBackup(String frequency) async {
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

    await Workmanager().registerPeriodicTask(
      'auto_backup',
      'auto_backup_task',
      frequency: interval,
      constraints: Constraints(
        networkType: NetworkType.not_required,
      ),
    );
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
