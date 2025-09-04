class AppConstants {
  static const String appName = 'Medical Records';
  static const String appVersion = '1.0.0';

  // Database
  static const String databaseName = 'health_records.db';
  static const int databaseVersion = 3;

  // Table Names
  static const String profilesTable = 'profiles';
  static const String sugarRecordsTable = 'sugar_records';
  static const String bpRecordsTable = 'bp_records';
  static const String lipidRecordsTable = 'lipid_records';

  // Validation Constants
  static const int minNameLength = 2;
  static const int maxNameLength = 50;
  static const int minAge = 0;
  static const int maxAge = 120;
  static const double minHeight = 50.0; // cm
  static const double maxHeight = 300.0; // cm
  static const double minWeight = 1.0; // kg
  static const double maxWeight = 500.0; // kg
  static const int maxMedicationLength = 200;

  // Health Parameter Ranges
  static const double normalHbA1cMin = 4.0;
  static const double normalHbA1cMax = 5.6;
  static const int normalSystolicMax = 120;
  static const int normalDiastolicMax = 80;
  static const int normalCholesterolMax = 200;
  static const int normalTriglyceridesMax = 150;
  static const int normalHDLMin = 40;
  static const int normalHDLMax = 60;
  static const int normalNonHDLMax = 130;
  static const int normalLDLMax = 159;
  static const int normalVLDLMax = 40;
  static const double normalCholHDLRatioMax = 5.0;

  // Blood Groups
  static const List<String> bloodGroups = [
    'A+',
    'A-',
    'B+',
    'B-',
    'AB+',
    'AB-',
    'O+',
    'O-'
  ];

  // Genders
  static const List<String> genders = ['Male', 'Female', 'Others'];

  // Graph Configuration
  static const int maxGraphPoints = 100;
  static const double graphAnimationDuration = 1.5;
}
