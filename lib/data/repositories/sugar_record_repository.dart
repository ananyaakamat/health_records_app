import '../models/sugar_record.dart';
import '../../core/database/database_helper.dart';
import '../../core/constants/app_constants.dart';
import 'package:intl/intl.dart';

class SugarRecordRepository {
  final DatabaseHelper _databaseHelper;

  SugarRecordRepository(this._databaseHelper);

  Future<List<SugarRecord>> getRecordsByProfileId(int profileId) async {
    try {
      final maps = await _databaseHelper.query(
        AppConstants.sugarRecordsTable,
        where: 'profile_id = ?',
        whereArgs: [profileId],
        orderBy: 'record_date DESC',
      );
      return maps.map((map) => SugarRecord.fromMap(map)).toList();
    } catch (e) {
      throw Exception('Failed to get sugar records: $e');
    }
  }

  Future<SugarRecord?> getRecordById(int id) async {
    try {
      final maps = await _databaseHelper.query(
        AppConstants.sugarRecordsTable,
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );

      if (maps.isNotEmpty) {
        return SugarRecord.fromMap(maps.first);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get sugar record: $e');
    }
  }

  Future<SugarRecord?> getRecordByProfileAndDate(
      int profileId, DateTime date) async {
    try {
      final dateString = DateFormat('yyyy-MM-dd').format(date);
      final maps = await _databaseHelper.query(
        AppConstants.sugarRecordsTable,
        where: 'profile_id = ? AND record_date = ?',
        whereArgs: [profileId, dateString],
        limit: 1,
      );

      if (maps.isNotEmpty) {
        return SugarRecord.fromMap(maps.first);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get sugar record by date: $e');
    }
  }

  Future<SugarRecord> createRecord(SugarRecord record) async {
    try {
      // Check if record already exists for this date
      final existing =
          await getRecordByProfileAndDate(record.profileId, record.recordDate);
      if (existing != null) {
        throw Exception('Record already exists for this date');
      }

      final id = await _databaseHelper.insert(
        AppConstants.sugarRecordsTable,
        record.toMap(),
      );

      return record.copyWith(id: id);
    } catch (e) {
      throw Exception('Failed to create sugar record: $e');
    }
  }

  Future<SugarRecord> updateRecord(SugarRecord record) async {
    try {
      if (record.id == null) {
        throw Exception('Record ID cannot be null for update');
      }

      // Check if new date conflicts with existing record (excluding current one)
      final existing =
          await getRecordByProfileAndDate(record.profileId, record.recordDate);
      if (existing != null && existing.id != record.id) {
        throw Exception('Record already exists for this date');
      }

      final count = await _databaseHelper.update(
        AppConstants.sugarRecordsTable,
        record.toMap(),
        where: 'id = ?',
        whereArgs: [record.id],
      );

      if (count == 0) {
        throw Exception('Record not found');
      }

      return record;
    } catch (e) {
      throw Exception('Failed to update sugar record: $e');
    }
  }

  Future<void> deleteRecord(int id) async {
    try {
      final count = await _databaseHelper.delete(
        AppConstants.sugarRecordsTable,
        where: 'id = ?',
        whereArgs: [id],
      );

      if (count == 0) {
        throw Exception('Record not found');
      }
    } catch (e) {
      throw Exception('Failed to delete sugar record: $e');
    }
  }

  Future<void> deleteRecordsByProfileId(int profileId) async {
    try {
      await _databaseHelper.delete(
        AppConstants.sugarRecordsTable,
        where: 'profile_id = ?',
        whereArgs: [profileId],
      );
    } catch (e) {
      throw Exception('Failed to delete sugar records: $e');
    }
  }

  Future<int> getRecordCount(int profileId) async {
    try {
      final maps = await _databaseHelper.query(
        AppConstants.sugarRecordsTable,
        columns: ['COUNT(*) as count'],
        where: 'profile_id = ?',
        whereArgs: [profileId],
      );
      return maps.first['count'] as int;
    } catch (e) {
      throw Exception('Failed to get record count: $e');
    }
  }

  Future<SugarRecord?> getLatestRecord(int profileId) async {
    try {
      final maps = await _databaseHelper.query(
        AppConstants.sugarRecordsTable,
        where: 'profile_id = ?',
        whereArgs: [profileId],
        orderBy: 'record_date DESC',
        limit: 1,
      );

      if (maps.isNotEmpty) {
        return SugarRecord.fromMap(maps.first);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get latest sugar record: $e');
    }
  }

  Future<List<SugarRecord>> getRecordsInDateRange(
    int profileId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final startDateString = DateFormat('yyyy-MM-dd').format(startDate);
      final endDateString = DateFormat('yyyy-MM-dd').format(endDate);

      final maps = await _databaseHelper.query(
        AppConstants.sugarRecordsTable,
        where: 'profile_id = ? AND record_date >= ? AND record_date <= ?',
        whereArgs: [profileId, startDateString, endDateString],
        orderBy: 'record_date DESC',
      );

      return maps.map((map) => SugarRecord.fromMap(map)).toList();
    } catch (e) {
      throw Exception('Failed to get sugar records in date range: $e');
    }
  }
}
