import '../models/bp_record.dart';
import '../../core/database/database_helper.dart';
import '../../core/constants/app_constants.dart';
import 'package:intl/intl.dart';

class BPRecordRepository {
  final DatabaseHelper _databaseHelper;

  BPRecordRepository(this._databaseHelper);

  Future<List<BPRecord>> getRecordsByProfileId(int profileId) async {
    try {
      final maps = await _databaseHelper.query(
        AppConstants.bpRecordsTable,
        where: 'profile_id = ?',
        whereArgs: [profileId],
        orderBy: 'record_date DESC',
      );
      return maps.map((map) => BPRecord.fromMap(map)).toList();
    } catch (e) {
      throw Exception('Failed to get BP records: $e');
    }
  }

  Future<BPRecord?> getRecordById(int id) async {
    try {
      final maps = await _databaseHelper.query(
        AppConstants.bpRecordsTable,
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );

      if (maps.isNotEmpty) {
        return BPRecord.fromMap(maps.first);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get BP record: $e');
    }
  }

  Future<BPRecord?> getRecordByProfileAndDate(
      int profileId, DateTime date) async {
    try {
      final dateString = DateFormat('yyyy-MM-dd').format(date);
      final maps = await _databaseHelper.query(
        AppConstants.bpRecordsTable,
        where: 'profile_id = ? AND record_date = ?',
        whereArgs: [profileId, dateString],
        limit: 1,
      );

      if (maps.isNotEmpty) {
        return BPRecord.fromMap(maps.first);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get BP record by date: $e');
    }
  }

  Future<BPRecord> createRecord(BPRecord record) async {
    try {
      final existing =
          await getRecordByProfileAndDate(record.profileId, record.recordDate);
      if (existing != null) {
        throw Exception('Record already exists for this date');
      }

      final id = await _databaseHelper.insert(
        AppConstants.bpRecordsTable,
        record.toMap(),
      );

      return record.copyWith(id: id);
    } catch (e) {
      throw Exception('Failed to create BP record: $e');
    }
  }

  Future<BPRecord> updateRecord(BPRecord record) async {
    try {
      if (record.id == null) {
        throw Exception('Record ID cannot be null for update');
      }

      final existing =
          await getRecordByProfileAndDate(record.profileId, record.recordDate);
      if (existing != null && existing.id != record.id) {
        throw Exception('Record already exists for this date');
      }

      final count = await _databaseHelper.update(
        AppConstants.bpRecordsTable,
        record.toMap(),
        where: 'id = ?',
        whereArgs: [record.id],
      );

      if (count == 0) {
        throw Exception('Record not found');
      }

      return record;
    } catch (e) {
      throw Exception('Failed to update BP record: $e');
    }
  }

  Future<void> deleteRecord(int id) async {
    try {
      final count = await _databaseHelper.delete(
        AppConstants.bpRecordsTable,
        where: 'id = ?',
        whereArgs: [id],
      );

      if (count == 0) {
        throw Exception('Record not found');
      }
    } catch (e) {
      throw Exception('Failed to delete BP record: $e');
    }
  }

  Future<BPRecord?> getLatestRecord(int profileId) async {
    try {
      final maps = await _databaseHelper.query(
        AppConstants.bpRecordsTable,
        where: 'profile_id = ?',
        whereArgs: [profileId],
        orderBy: 'record_date DESC',
        limit: 1,
      );

      if (maps.isNotEmpty) {
        return BPRecord.fromMap(maps.first);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get latest BP record: $e');
    }
  }
}
