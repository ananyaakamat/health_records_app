import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/database/database_helper.dart';
import '../../core/services/backup_service.dart';
import '../../data/repositories/profile_repository.dart';
import '../../data/repositories/sugar_record_repository.dart';
import '../../data/repositories/bp_record_repository.dart';
import '../../data/repositories/lipid_record_repository.dart';

// Database provider
final databaseHelperProvider = Provider<DatabaseHelper>((ref) {
  return DatabaseHelper.instance;
});

// Backup service provider
final backupServiceProvider = Provider<BackupService>((ref) {
  return BackupService.instance;
});

// Repository providers
final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  final databaseHelper = ref.watch(databaseHelperProvider);
  return ProfileRepository(databaseHelper);
});

final sugarRecordRepositoryProvider = Provider<SugarRecordRepository>((ref) {
  final databaseHelper = ref.watch(databaseHelperProvider);
  return SugarRecordRepository(databaseHelper);
});

final bpRecordRepositoryProvider = Provider<BPRecordRepository>((ref) {
  final databaseHelper = ref.watch(databaseHelperProvider);
  return BPRecordRepository(databaseHelper);
});

final lipidRecordRepositoryProvider = Provider<LipidRecordRepository>((ref) {
  final databaseHelper = ref.watch(databaseHelperProvider);
  return LipidRecordRepository(databaseHelper);
});
