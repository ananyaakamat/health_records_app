import 'package:flutter/material.dart';
import '../../core/themes/app_theme.dart';

class UserGuideScreen extends StatelessWidget {
  final String? currentPage;

  const UserGuideScreen({super.key, this.currentPage});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Guide'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (currentPage != null) ...[
              _buildPageSpecificGuide(context, currentPage!),
              const SizedBox(height: 32),
              const Divider(),
              const SizedBox(height: 16),
            ],
            _buildGeneralGuide(context),
          ],
        ),
      ),
    );
  }

  Widget _buildPageSpecificGuide(BuildContext context, String page) {
    Widget content;

    switch (page.toLowerCase()) {
      case 'health profiles':
        content = _buildProfilesGuide(context);
        break;
      case 'profile detail':
        content = _buildProfileDetailGuide(context);
        break;
      case 'backup & restore':
        content = _buildBackupRestoreGuide(context);
        break;
      default:
        content = _buildHomeGuide(context);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Help for: $page',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        content,
      ],
    );
  }

  Widget _buildHomeGuide(BuildContext context) {
    return _buildGuideSection(
      context,
      'Home Screen',
      [
        _buildGuideItem(
          context,
          'Welcome Screen',
          'This is your starting point to access all features of the Health Records app.',
        ),
        _buildGuideItem(
          context,
          'Get Started',
          'Tap the "Get Started" button to begin managing health profiles.',
        ),
        _buildGuideItem(
          context,
          'Settings Menu',
          'Use the menu (☰) to access profiles, change PIN, backup & restore, and other settings.',
        ),
        _buildGuideItem(
          context,
          'Theme Toggle',
          'Switch between light and dark themes using the theme button (🌙/☀️) in the top right.',
        ),
      ],
    );
  }

  Widget _buildProfilesGuide(BuildContext context) {
    return _buildGuideSection(
      context,
      'Health Profiles',
      [
        _buildGuideItem(
          context,
          'Add New Profile',
          'Tap the + button to create a new health profile for family members.',
        ),
        _buildGuideItem(
          context,
          'View Profile Details',
          'Tap on any profile card to view detailed health records and charts.',
        ),
        _buildGuideItem(
          context,
          'Edit Profile',
          'Use the three-dot menu (⋮) on each profile to edit or delete.',
        ),
        _buildGuideItem(
          context,
          'Profile Information',
          'Each profile shows name, age, gender, and blood group for quick reference.',
        ),
      ],
    );
  }

  Widget _buildProfileDetailGuide(BuildContext context) {
    return _buildGuideSection(
      context,
      'Profile Details',
      [
        _buildGuideItem(
          context,
          'Health Records Tabs',
          'Switch between Sugar, BP (Blood Pressure), and Lipids tabs to view different health metrics.',
        ),
        _buildGuideItem(
          context,
          'Add New Records',
          'Use the + button in each tab to add new health measurements.',
        ),
        _buildGuideItem(
          context,
          'Edit Records',
          'Use the three-dot menu (⋮) next to each record to edit or delete.',
        ),
        _buildGuideItem(
          context,
          'BMI Information',
          'BMI is automatically calculated from height and weight when available.',
        ),
        _buildGuideItem(
          context,
          'Color Coding',
          'Health values are color-coded: Green (Normal), Orange (Caution), Red (High Risk).',
        ),
      ],
    );
  }

  Widget _buildBackupRestoreGuide(BuildContext context) {
    return _buildGuideSection(
      context,
      'Backup & Restore',
      [
        _buildGuideItem(
          context,
          'Create Backup',
          'Tap "Create New Backup" to save all your health data securely. Backups are automatically encrypted.',
        ),
        _buildGuideItem(
          context,
          'Automatic Encryption',
          'Backups are encrypted automatically using device-specific keys for security.',
        ),
        _buildGuideItem(
          context,
          'Backup Actions',
          'Each backup shows three action icons below the timestamp: Restore (🔄), Share (📤), and Delete (🗑️). These icons are properly spaced for easy access.',
        ),
        _buildGuideItem(
          context,
          'Restore Backup',
          'Tap the Restore icon (🔄) to restore data from a backup. This will replace your current data with the backup data.',
        ),
        _buildGuideItem(
          context,
          'Share Backup',
          'Tap the Share icon (📤) to share backup files via WhatsApp, email, cloud storage, or other apps. Perfect for backing up to multiple locations.',
        ),
        _buildGuideItem(
          context,
          'Delete Backup',
          'Tap the Delete icon (🗑️) to permanently remove a backup file. Use with caution as this cannot be undone.',
        ),
        _buildGuideItem(
          context,
          'Cross-Device Restore',
          'When restoring on a different device, you may be prompted to enter a recovery password if the automatic restore fails.',
        ),
        _buildGuideItem(
          context,
          'Backup Management',
          'The app keeps your last 3 backups automatically. Older backups are deleted to save space.',
        ),
        _buildGuideItem(
          context,
          'Auto Backup',
          'Backups are automatically created when profiles exist. Empty databases won\'t create backup files.',
        ),
      ],
    );
  }

  Widget _buildGeneralGuide(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'General Help',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        _buildGuideSection(
          context,
          'Navigation',
          [
            _buildGuideItem(
              context,
              'Home Icon (🏠)',
              'Tap to return to the main home screen from anywhere in the app.',
            ),
            _buildGuideItem(
              context,
              'Help Icon (❓)',
              'Tap to view context-specific help for the current screen.',
            ),
            _buildGuideItem(
              context,
              'Back Button (←)',
              'Use to go back to the previous screen.',
            ),
          ],
        ),
        const SizedBox(height: 24),
        _buildGuideSection(
          context,
          'Data Management',
          [
            _buildGuideItem(
              context,
              'Backup & Restore',
              'Regularly backup your data and restore when switching devices.',
            ),
            _buildGuideItem(
              context,
              'Security',
              'The app is protected with a PIN. Change it regularly for security.',
            ),
            _buildGuideItem(
              context,
              'Data Privacy',
              'All data is stored locally on your device and encrypted for security.',
            ),
          ],
        ),
        const SizedBox(height: 24),
        _buildGuideSection(
          context,
          'Health Metrics',
          [
            _buildGuideItem(
              context,
              'Sugar (HbA1c)',
              'Normal: 4.0-5.6%, Pre-diabetes: 5.7-6.4%, Diabetes: ≥6.5%',
            ),
            _buildGuideItem(
              context,
              'Blood Pressure',
              'Normal: <120/80 mmHg, High: ≥140/90 mmHg',
            ),
            _buildGuideItem(
              context,
              'Lipid Profile',
              'Includes Total Cholesterol, HDL, LDL, Triglycerides, VLDL, Non-HDL, and Cholesterol/HDL ratio.',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildGuideSection(
      BuildContext context, String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryColor,
              ),
        ),
        const SizedBox(height: 12),
        ...items,
      ],
    );
  }

  Widget _buildGuideItem(
      BuildContext context, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: AppTheme.primaryColor.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryColor,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.8),
                    height: 1.4,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
