import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/lipid_record.dart';
import '../../data/repositories/lipid_record_repository.dart';
import 'providers.dart';

// Lipid records for a specific profile
final lipidRecordsProvider =
    FutureProvider.family<List<LipidRecord>, int>((ref, profileId) async {
  final repository = ref.watch(lipidRecordRepositoryProvider);
  return await repository.getRecordsByProfileId(profileId);
});

class LipidRecordNotifier extends StateNotifier<AsyncValue<List<LipidRecord>>> {
  final LipidRecordRepository _repository;
  final int _profileId;

  LipidRecordNotifier(this._repository, this._profileId)
      : super(const AsyncValue.loading()) {
    loadRecords();
  }

  Future<void> loadRecords() async {
    state = const AsyncValue.loading();
    try {
      final records = await _repository.getRecordsByProfileId(_profileId);
      state = AsyncValue.data(records);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<LipidRecord> addRecord(LipidRecord record) async {
    try {
      final newRecord = await _repository.createRecord(record);
      await loadRecords(); // Refresh the list
      return newRecord;
    } catch (error) {
      rethrow;
    }
  }

  Future<LipidRecord> updateRecord(LipidRecord record) async {
    try {
      final updatedRecord = await _repository.updateRecord(record);
      await loadRecords(); // Refresh the list
      return updatedRecord;
    } catch (error) {
      rethrow;
    }
  }

  Future<void> deleteRecord(int id) async {
    try {
      await _repository.deleteRecord(id);
      await loadRecords(); // Refresh the list
    } catch (error) {
      rethrow;
    }
  }
}

final lipidRecordNotifierProvider = StateNotifierProvider.family<
    LipidRecordNotifier, AsyncValue<List<LipidRecord>>, int>((ref, profileId) {
  final repository = ref.watch(lipidRecordRepositoryProvider);
  return LipidRecordNotifier(repository, profileId);
});
