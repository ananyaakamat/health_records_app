import '../models/lipid_record.dart';
import '../../core/database/database_helper.dart';
import '../../core/constants/app_constants.dart';
import 'package:intl/intl.dart';

class LipidRecordRepository {
  final DatabaseHelper _databaseHelper;

  LipidRecordRepository(this._databaseHelper);

  Future<List<LipidRecord>> getRecordsByProfileId(int profileId) async {
    try {
      final maps = await _databaseHelper.query(
        AppConstants.lipidRecordsTable,
        where: 'profile_id = ?',
        whereArgs: [profileId],
        orderBy: 'record_date DESC',
      );
      return maps.map((map) => LipidRecord.fromMap(map)).toList();
    } catch (e) {
      throw Exception('Failed to get lipid records: $e');
    }
  }

  Future<LipidRecord?> getRecordById(int id) async {
    try {
      final maps = await _databaseHelper.query(
        AppConstants.lipidRecordsTable,
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );

      if (maps.isNotEmpty) {
        return LipidRecord.fromMap(maps.first);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get lipid record: $e');
    }
  }

  Future<LipidRecord?> getRecordByProfileAndDate(
      int profileId, DateTime date) async {
    try {
      final dateString = DateFormat('yyyy-MM-dd').format(date);
      final maps = await _databaseHelper.query(
        AppConstants.lipidRecordsTable,
        where: 'profile_id = ? AND record_date = ?',
        whereArgs: [profileId, dateString],
        limit: 1,
      );

      if (maps.isNotEmpty) {
        return LipidRecord.fromMap(maps.first);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get lipid record by date: $e');
    }
  }

  Future<LipidRecord> createRecord(LipidRecord record) async {
    try {
      final existing =
          await getRecordByProfileAndDate(record.profileId, record.recordDate);
      if (existing != null) {
        throw Exception('Record already exists for this date');
      }

      final id = await _databaseHelper.insert(
        AppConstants.lipidRecordsTable,
        record.toMap(),
      );

      return record.copyWith(id: id);
    } catch (e) {
      throw Exception('Failed to create lipid record: $e');
    }
  }

  Future<LipidRecord> updateRecord(LipidRecord record) async {
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
        AppConstants.lipidRecordsTable,
        record.toMap(),
        where: 'id = ?',
        whereArgs: [record.id],
      );

      if (count == 0) {
        throw Exception('Record not found');
      }

      return record;
    } catch (e) {
      throw Exception('Failed to update lipid record: $e');
    }
  }

  Future<void> deleteRecord(int id) async {
    try {
      final count = await _databaseHelper.delete(
        AppConstants.lipidRecordsTable,
        where: 'id = ?',
        whereArgs: [id],
      );

      if (count == 0) {
        throw Exception('Record not found');
      }
    } catch (e) {
      throw Exception('Failed to delete lipid record: $e');
    }
  }

  Future<LipidRecord?> getLatestRecord(int profileId) async {
    try {
      final maps = await _databaseHelper.query(
        AppConstants.lipidRecordsTable,
        where: 'profile_id = ?',
        whereArgs: [profileId],
        orderBy: 'record_date DESC',
        limit: 1,
      );

      if (maps.isNotEmpty) {
        return LipidRecord.fromMap(maps.first);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get latest lipid record: $e');
    }
  }
}
