# Medical Records - Health Management App

A comprehensive Flutter application for managing personal and family health records with secure local storage, biometric authentication, and organized tabular data display.

## 🚀 Quick Start

### Prerequisites

- Flutter SDK 3.24.5+
- Android Studio or VS Code with Flutter extensions
- Android device (API 26+) or iOS device (iOS 11.0+)

### Installation

```bash
# Clone and navigate to project
cd health_records_app

# Install dependencies
flutter pub get

# Run the app
flutter run
```

## 📱 Features

- **🔐 Secure Authentication**: PIN + biometric authentication
- **👨‍👩‍👧‍👦 Multi-Profile Support**: Manage entire family's health records
- **🩺 Health Tracking**: Sugar/HbA1c, Blood Pressure, Lipid Profile monitoring
- **📊 Data Organization**: Structured tabular display with color-coded health indicators
- **💾 Backup & Restore**: Encrypted backup system with cross-device sync
- **🌙 Theme Support**: Light and dark mode compatibility

## 🏗️ Architecture

This app follows Clean Architecture principles with:

- **Data Layer**: SQLite database with repositories
- **Presentation Layer**: Flutter widgets with Riverpod state management
- **Core Services**: Authentication, backup, and encryption services

## 🔧 Key Dependencies

- `flutter_riverpod`: State management
- `sqflite`: Local database
- `local_auth`: Biometric authentication
- `encrypt`: Data encryption
- `workmanager`: Background tasks
- `intl`: Date formatting

## 📖 Usage

1. **Setup**: Create PIN and enable biometric authentication
2. **Profiles**: Add family member profiles
3. **Records**: Track health data across three categories
4. **Tables**: Review organized health data with status indicators
5. **Backup**: Secure your data with encrypted backups

## 📄 Documentation

For detailed documentation, see the main project README at the root level.

## 🤝 Contributing

Please refer to the main project's contributing guidelines for development workflow and code standards.
