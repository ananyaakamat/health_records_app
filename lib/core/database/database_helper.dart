import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../constants/app_constants.dart';

class DatabaseHelper {
  static DatabaseHelper? _instance;
  static Database? _database;

  DatabaseHelper._();

  static DatabaseHelper get instance {
    _instance ??= DatabaseHelper._();
    return _instance!;
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), AppConstants.databaseName);
    return await openDatabase(
      path,
      version: AppConstants.databaseVersion,
      onCreate: _createDatabase,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _createDatabase(Database db, int version) async {
    // Create Profiles table
    await db.execute('''
      CREATE TABLE ${AppConstants.profilesTable} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
        age INTEGER NOT NULL,
        gender TEXT NOT NULL,
        blood_group TEXT NOT NULL,
        height REAL,
        weight REAL,
        medication TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Create Sugar Records table
    await db.execute('''
      CREATE TABLE ${AppConstants.sugarRecordsTable} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        profile_id INTEGER NOT NULL,
        hba1c REAL NOT NULL,
        record_date TEXT NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY (profile_id) REFERENCES ${AppConstants.profilesTable} (id) ON DELETE CASCADE,
        UNIQUE(profile_id, record_date)
      )
    ''');

    // Create BP Records table
    await db.execute('''
      CREATE TABLE ${AppConstants.bpRecordsTable} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        profile_id INTEGER NOT NULL,
        systolic INTEGER NOT NULL,
        diastolic INTEGER NOT NULL,
        record_date TEXT NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY (profile_id) REFERENCES ${AppConstants.profilesTable} (id) ON DELETE CASCADE,
        UNIQUE(profile_id, record_date)
      )
    ''');

    // Create Lipid Records table
    await db.execute('''
      CREATE TABLE ${AppConstants.lipidRecordsTable} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        profile_id INTEGER NOT NULL,
        cholesterol_total INTEGER NOT NULL,
        triglycerides INTEGER NOT NULL,
        hdl INTEGER NOT NULL,
        non_hdl INTEGER NOT NULL,
        ldl INTEGER NOT NULL,
        vldl INTEGER NOT NULL,
        chol_hdl_ratio REAL NOT NULL,
        record_date TEXT NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY (profile_id) REFERENCES ${AppConstants.profilesTable} (id) ON DELETE CASCADE,
        UNIQUE(profile_id, record_date)
      )
    ''');

    // Create indexes for better performance
    await db.execute('''
      CREATE INDEX idx_sugar_records_profile_date ON ${AppConstants.sugarRecordsTable} (profile_id, record_date)
    ''');

    await db.execute('''
      CREATE INDEX idx_bp_records_profile_date ON ${AppConstants.bpRecordsTable} (profile_id, record_date)
    ''');

    await db.execute('''
      CREATE INDEX idx_lipid_records_profile_date ON ${AppConstants.lipidRecordsTable} (profile_id, record_date)
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Handle database upgrades here
    if (oldVersion < 2 && newVersion >= 2) {
      // Add height and weight columns to profiles table
      await db.execute('''
        ALTER TABLE ${AppConstants.profilesTable} ADD COLUMN height REAL
      ''');
      await db.execute('''
        ALTER TABLE ${AppConstants.profilesTable} ADD COLUMN weight REAL
      ''');
    }
    if (oldVersion < 3 && newVersion >= 3) {
      // Add medication column to profiles table
      await db.execute('''
        ALTER TABLE ${AppConstants.profilesTable} ADD COLUMN medication TEXT
      ''');
    }
  }

  // Generic CRUD operations
  Future<int> insert(String table, Map<String, dynamic> data) async {
    final db = await database;
    return await db.insert(table, data);
  }

  Future<List<Map<String, dynamic>>> query(
    String table, {
    bool? distinct,
    List<String>? columns,
    String? where,
    List<dynamic>? whereArgs,
    String? groupBy,
    String? having,
    String? orderBy,
    int? limit,
    int? offset,
  }) async {
    final db = await database;
    return await db.query(
      table,
      distinct: distinct,
      columns: columns,
      where: where,
      whereArgs: whereArgs,
      groupBy: groupBy,
      having: having,
      orderBy: orderBy,
      limit: limit,
      offset: offset,
    );
  }

  Future<int> update(
    String table,
    Map<String, dynamic> data, {
    String? where,
    List<dynamic>? whereArgs,
  }) async {
    final db = await database;
    return await db.update(table, data, where: where, whereArgs: whereArgs);
  }

  Future<int> delete(
    String table, {
    String? where,
    List<dynamic>? whereArgs,
  }) async {
    final db = await database;
    return await db.delete(table, where: where, whereArgs: whereArgs);
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
  }

  Future<void> deleteDatabase() async {
    String path = join(await getDatabasesPath(), AppConstants.databaseName);
    await databaseFactory.deleteDatabase(path);
    _database = null;
  }
}
