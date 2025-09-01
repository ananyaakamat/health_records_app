import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/sugar_record.dart';
import '../../data/repositories/sugar_record_repository.dart';
import 'providers.dart';

// Sugar records for a specific profile
final sugarRecordsProvider =
    FutureProvider.family<List<SugarRecord>, int>((ref, profileId) async {
  final repository = ref.watch(sugarRecordRepositoryProvider);
  return await repository.getRecordsByProfileId(profileId);
});

class SugarRecordNotifier extends StateNotifier<AsyncValue<List<SugarRecord>>> {
  final SugarRecordRepository _repository;
  final int _profileId;

  SugarRecordNotifier(this._repository, this._profileId)
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

  Future<SugarRecord> addRecord(SugarRecord record) async {
    try {
      final newRecord = await _repository.createRecord(record);
      await loadRecords(); // Refresh the list
      return newRecord;
    } catch (error) {
      rethrow;
    }
  }

  Future<SugarRecord> updateRecord(SugarRecord record) async {
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

final sugarRecordNotifierProvider = StateNotifierProvider.family<
    SugarRecordNotifier, AsyncValue<List<SugarRecord>>, int>((ref, profileId) {
  final repository = ref.watch(sugarRecordRepositoryProvider);
  return SugarRecordNotifier(repository, profileId);
});
