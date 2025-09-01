import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/profile.dart';
import '../../core/themes/app_theme.dart';
import '../providers/profile_provider.dart';
import '../widgets/profile_form_dialog.dart';
import 'profile_detail_screen.dart';

class ProfileListScreen extends ConsumerWidget {
  const ProfileListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profilesAsync = ref.watch(profileNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Health Profiles'),
        centerTitle: true,
      ),
      body: profilesAsync.when(
        data: (profiles) => _buildProfileList(context, ref, profiles),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _buildErrorState(context, ref, error.toString()),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddProfileDialog(context, ref),
        tooltip: 'Add Profile',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildProfileList(
      BuildContext context, WidgetRef ref, List<Profile> profiles) {
    if (profiles.isEmpty) {
      return _buildEmptyState(context, ref);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: profiles.length,
      itemBuilder: (context, index) {
        final profile = profiles[index];
        return _buildProfileCard(context, ref, profile);
      },
    );
  }

  Widget _buildEmptyState(BuildContext context, WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 100,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 24),
          Text(
            'No profiles yet',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add a profile to start tracking health records',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => _showAddProfileDialog(context, ref),
            icon: const Icon(Icons.add),
            label: const Text('Add Profile'),
            style: AppTheme.primaryButtonStyle,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, WidgetRef ref, String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 100,
            color: AppTheme.errorColor,
          ),
          const SizedBox(height: 24),
          Text(
            'Something went wrong',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppTheme.errorColor,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () =>
                ref.read(profileNotifierProvider.notifier).loadProfiles(),
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
            style: AppTheme.primaryButtonStyle,
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard(
      BuildContext context, WidgetRef ref, Profile profile) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: AppTheme.primaryColor,
          radius: 30,
          child: Text(
            profile.name.substring(0, 1).toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          profile.name,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.cake_outlined,
                  size: 16,
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
                const SizedBox(width: 4),
                Text(
                  '${profile.age} years old',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.7),
                      ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  profile.gender == 'Male'
                      ? Icons.male
                      : profile.gender == 'Female'
                          ? Icons.female
                          : Icons.person,
                  size: 16,
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
                const SizedBox(width: 4),
                Text(
                  profile.gender,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.7),
                      ),
                ),
                const SizedBox(width: 16),
                Icon(
                  Icons.bloodtype,
                  size: 16,
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
                const SizedBox(width: 4),
                Text(
                  profile.bloodGroup,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.7),
                      ),
                ),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'edit') {
              _showEditProfileDialog(context, ref, profile);
            } else if (value == 'delete') {
              _showDeleteConfirmationDialog(context, ref, profile);
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit, size: 20),
                  SizedBox(width: 8),
                  Text('Edit'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, size: 20, color: AppTheme.errorColor),
                  SizedBox(width: 8),
                  Text('Delete', style: TextStyle(color: AppTheme.errorColor)),
                ],
              ),
            ),
          ],
        ),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => ProfileDetailScreen(profile: profile),
            ),
          );
        },
      ),
    );
  }

  void _showAddProfileDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => const ProfileFormDialog(),
    );
  }

  void _showEditProfileDialog(
      BuildContext context, WidgetRef ref, Profile profile) {
    showDialog(
      context: context,
      builder: (context) => ProfileFormDialog(profile: profile),
    );
  }

  void _showDeleteConfirmationDialog(
      BuildContext context, WidgetRef ref, Profile profile) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Profile'),
        content: Text(
          'Deleting this profile will also delete all linked health records. Are you sure you want to proceed?',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              try {
                await ref
                    .read(profileNotifierProvider.notifier)
                    .deleteProfile(profile.id!);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${profile.name} deleted successfully'),
                      backgroundColor: AppTheme.successColor,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to delete profile: $e'),
                      backgroundColor: AppTheme.errorColor,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
