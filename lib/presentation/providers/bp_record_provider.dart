import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/bp_record.dart';
import '../../data/repositories/bp_record_repository.dart';
import 'providers.dart';

// BP records for a specific profile
final bpRecordsProvider =
    FutureProvider.family<List<BPRecord>, int>((ref, profileId) async {
  final repository = ref.watch(bpRecordRepositoryProvider);
  return await repository.getRecordsByProfileId(profileId);
});

class BPRecordNotifier extends StateNotifier<AsyncValue<List<BPRecord>>> {
  final BPRecordRepository _repository;
  final int _profileId;

  BPRecordNotifier(this._repository, this._profileId)
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

  Future<BPRecord> addRecord(BPRecord record) async {
    try {
      final newRecord = await _repository.createRecord(record);
      await loadRecords(); // Refresh the list
      return newRecord;
    } catch (error) {
      rethrow;
    }
  }

  Future<BPRecord> updateRecord(BPRecord record) async {
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

final bpRecordNotifierProvider = StateNotifierProvider.family<BPRecordNotifier,
    AsyncValue<List<BPRecord>>, int>((ref, profileId) {
  final repository = ref.watch(bpRecordRepositoryProvider);
  return BPRecordNotifier(repository, profileId);
});
