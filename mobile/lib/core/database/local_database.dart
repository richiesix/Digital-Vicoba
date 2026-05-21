import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path/path.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';

class LocalDatabase {
  static Database? _db;
  static const _dbName = 'digital_vicoba.db';
  static const _passphrase = 'vicoba_secure_key_change_in_prod';

  static Future<Database> get instance async {
    if (kIsWeb) {
      throw UnsupportedError(
        'SQLCipher is not available on web. Use SyncLocalStore instead.',
      );
    }
    if (_db != null) return _db!;
    final dir = await getDatabasesPath();
    final path = join(dir, _dbName);
    _db = await openDatabase(
      path,
      password: _passphrase,
      version: 1,
      onCreate: _onCreate,
    );
    return _db!;
  }

  static Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE sync_queue (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        client_id TEXT UNIQUE NOT NULL,
        entity_type TEXT NOT NULL,
        operation TEXT NOT NULL,
        payload TEXT NOT NULL,
        client_timestamp TEXT NOT NULL,
        status TEXT DEFAULT 'pending',
        retry_count INTEGER DEFAULT 0,
        error_message TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE sync_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        direction TEXT NOT NULL,
        records_count INTEGER DEFAULT 0,
        status TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE groups_cache (
        id INTEGER PRIMARY KEY,
        uuid TEXT,
        name TEXT,
        share_price REAL,
        status TEXT,
        data_json TEXT,
        updated_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE members_cache (
        id INTEGER PRIMARY KEY,
        group_id INTEGER,
        uuid TEXT,
        first_name TEXT,
        last_name TEXT,
        phone_number TEXT,
        savings_balance REAL,
        loan_balance REAL,
        total_shares INTEGER,
        data_json TEXT,
        updated_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE shares_local (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        client_id TEXT UNIQUE,
        group_id INTEGER,
        member_id INTEGER,
        quantity INTEGER,
        total_amount REAL,
        payment_method TEXT,
        recorded_at TEXT,
        synced INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE contributions_local (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        client_id TEXT UNIQUE,
        group_id INTEGER,
        member_id INTEGER,
        type TEXT,
        amount REAL,
        payment_method TEXT,
        recorded_at TEXT,
        synced INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE loans_local (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        client_id TEXT UNIQUE,
        group_id INTEGER,
        member_id INTEGER,
        principal_amount REAL,
        status TEXT,
        data_json TEXT,
        synced INTEGER DEFAULT 0
      )
    ''');
  }

  static Future<void> close() async {
    await _db?.close();
    _db = null;
  }
}
