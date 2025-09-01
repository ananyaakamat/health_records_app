import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/profile.dart';
import '../../data/repositories/profile_repository.dart';
import 'providers.dart';

// Profile state management
final profileListProvider = FutureProvider<List<Profile>>((ref) async {
  final repository = ref.watch(profileRepositoryProvider);
  return await repository.getAllProfiles();
});

final selectedProfileProvider = StateProvider<Profile?>((ref) => null);

class ProfileNotifier extends StateNotifier<AsyncValue<List<Profile>>> {
  final ProfileRepository _repository;

  ProfileNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadProfiles();
  }

  Future<void> loadProfiles() async {
    state = const AsyncValue.loading();
    try {
      final profiles = await _repository.getAllProfiles();
      state = AsyncValue.data(profiles);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<Profile> addProfile(Profile profile) async {
    try {
      final newProfile = await _repository.createProfile(profile);
      await loadProfiles(); // Refresh the list
      return newProfile;
    } catch (error) {
      rethrow;
    }
  }

  Future<Profile> updateProfile(Profile profile) async {
    try {
      final updatedProfile = await _repository.updateProfile(profile);
      await loadProfiles(); // Refresh the list
      return updatedProfile;
    } catch (error) {
      rethrow;
    }
  }

  Future<void> deleteProfile(int id) async {
    try {
      await _repository.deleteProfile(id);
      await loadProfiles(); // Refresh the list
    } catch (error) {
      rethrow;
    }
  }

  Future<bool> checkProfileNameExists(String name, {int? excludeId}) async {
    try {
      return await _repository.profileNameExists(name, excludeId: excludeId);
    } catch (error) {
      rethrow;
    }
  }
}

final profileNotifierProvider =
    StateNotifierProvider<ProfileNotifier, AsyncValue<List<Profile>>>((ref) {
  final repository = ref.watch(profileRepositoryProvider);
  return ProfileNotifier(repository);
});

// Profile by ID provider
final profileByIdProvider =
    FutureProvider.family<Profile?, int>((ref, id) async {
  final repository = ref.watch(profileRepositoryProvider);
  return await repository.getProfileById(id);
});
