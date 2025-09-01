import '../models/profile.dart';
import '../../core/database/database_helper.dart';
import '../../core/constants/app_constants.dart';

class ProfileRepository {
  final DatabaseHelper _databaseHelper;

  ProfileRepository(this._databaseHelper);

  Future<List<Profile>> getAllProfiles() async {
    try {
      final maps = await _databaseHelper.query(
        AppConstants.profilesTable,
        orderBy: 'name ASC',
      );
      return maps.map((map) => Profile.fromMap(map)).toList();
    } catch (e) {
      throw Exception('Failed to get profiles: $e');
    }
  }

  Future<Profile?> getProfileById(int id) async {
    try {
      final maps = await _databaseHelper.query(
        AppConstants.profilesTable,
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );

      if (maps.isNotEmpty) {
        return Profile.fromMap(maps.first);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get profile: $e');
    }
  }

  Future<Profile?> getProfileByName(String name) async {
    try {
      final maps = await _databaseHelper.query(
        AppConstants.profilesTable,
        where: 'name = ?',
        whereArgs: [name],
        limit: 1,
      );

      if (maps.isNotEmpty) {
        return Profile.fromMap(maps.first);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get profile by name: $e');
    }
  }

  Future<Profile> createProfile(Profile profile) async {
    try {
      // Check if profile name already exists
      final existing = await getProfileByName(profile.name);
      if (existing != null) {
        throw Exception('Profile name already exists');
      }

      final id = await _databaseHelper.insert(
        AppConstants.profilesTable,
        profile.toMap(),
      );

      return profile.copyWith(id: id);
    } catch (e) {
      throw Exception('Failed to create profile: $e');
    }
  }

  Future<Profile> updateProfile(Profile profile) async {
    try {
      if (profile.id == null) {
        throw Exception('Profile ID cannot be null for update');
      }

      // Check if new name conflicts with existing profile (excluding current one)
      final existing = await getProfileByName(profile.name);
      if (existing != null && existing.id != profile.id) {
        throw Exception('Profile name already exists');
      }

      final updatedProfile = profile.copyWith(updatedAt: DateTime.now());

      final count = await _databaseHelper.update(
        AppConstants.profilesTable,
        updatedProfile.toMap(),
        where: 'id = ?',
        whereArgs: [profile.id],
      );

      if (count == 0) {
        throw Exception('Profile not found');
      }

      return updatedProfile;
    } catch (e) {
      throw Exception('Failed to update profile: $e');
    }
  }

  Future<void> deleteProfile(int id) async {
    try {
      final count = await _databaseHelper.delete(
        AppConstants.profilesTable,
        where: 'id = ?',
        whereArgs: [id],
      );

      if (count == 0) {
        throw Exception('Profile not found');
      }
    } catch (e) {
      throw Exception('Failed to delete profile: $e');
    }
  }

  Future<int> getProfileCount() async {
    try {
      final maps = await _databaseHelper.query(
        AppConstants.profilesTable,
        columns: ['COUNT(*) as count'],
      );
      return maps.first['count'] as int;
    } catch (e) {
      throw Exception('Failed to get profile count: $e');
    }
  }

  Future<bool> profileNameExists(String name, {int? excludeId}) async {
    try {
      String whereClause = 'name = ?';
      List<dynamic> whereArgs = [name];

      if (excludeId != null) {
        whereClause += ' AND id != ?';
        whereArgs.add(excludeId);
      }

      final maps = await _databaseHelper.query(
        AppConstants.profilesTable,
        where: whereClause,
        whereArgs: whereArgs,
        limit: 1,
      );

      return maps.isNotEmpty;
    } catch (e) {
      throw Exception('Failed to check profile name existence: $e');
    }
  }
}
