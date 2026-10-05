import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/models.dart';
import '../utils/password_utils.dart';
import 'seed_data.dart';

class DbHelper {
  DbHelper._internal();
  static final DbHelper instance = DbHelper._internal();

  static const _dbName = 'kosh_finance.db';
  static const _dbVersion = 4;

  // Cache the in-flight Future (not just the resolved Database) so that
  // concurrent first-access callers — e.g. FinanceStore.load() and
  // AuthStore.login() both firing on app start — await the same
  // initialization instead of racing to open/create the db twice.
  Future<Database>? _dbFuture;

  Future<Database> get database {
    return _dbFuture ??= _initDb();
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);
    return openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _createV2Tables(db);
      await _seedDefaultAdmin(db);
    }
    if (oldVersion < 3) {
      await _createV3Tables(db);
      await db.execute(
          "ALTER TABLE employment_income ADD COLUMN source TEXT NOT NULL DEFAULT 'Employment'");
      await _seedDefaultIncomeSource(db);
    }
    if (oldVersion < 4) {
      await _createV4Tables(db);
      await _seedKnownBusinesses(db);
    }
  }

  Future<void> _createV4Tables(Database db) async {
    await db.execute('''
      CREATE TABLE businesses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE
      );
    ''');
  }

  Future<void> _seedKnownBusinesses(Database db) async {
    final existing = await db.query('businesses', limit: 1);
    if (existing.isNotEmpty) return;
    final names = <String>{};
    for (final row in await db.query('business_revenue', columns: ['business'], distinct: true)) {
      names.add(row['business'] as String);
    }
    for (final row in await db.query('business_expense', columns: ['business'], distinct: true)) {
      names.add(row['business'] as String);
    }
    for (final name in names) {
      await db.insert('businesses', {'name': name});
    }
  }

  Future<void> _createV3Tables(Database db) async {
    await db.execute('''
      CREATE TABLE income_sources (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE
      );
    ''');
  }

  Future<void> _seedDefaultIncomeSource(Database db) async {
    final existing = await db.query('income_sources', limit: 1);
    if (existing.isNotEmpty) return;
    await db.insert('income_sources', {'name': 'Employment'});
  }

  Future<void> _createV2Tables(Database db) async {
    await db.execute('''
      CREATE TABLE daily_sales (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        business TEXT NOT NULL,
        amount REAL NOT NULL,
        note TEXT
      );
    ''');

    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT NOT NULL UNIQUE,
        passwordHash TEXT NOT NULL,
        passwordSalt TEXT NOT NULL,
        isAdmin INTEGER NOT NULL DEFAULT 0,
        allowedPages TEXT NOT NULL DEFAULT ''
      );
    ''');
  }

  Future<void> _seedDefaultAdmin(Database db) async {
    final existing = await db.query('users', limit: 1);
    if (existing.isNotEmpty) return;
    final salt = generateSalt();
    await db.insert('users', {
      'username': 'admin',
      'passwordHash': hashPassword('admin', salt),
      'passwordSalt': salt,
      'isAdmin': 1,
      'allowedPages': kAppPageKeys.join(','),
    });
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE employment_income (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        year INTEGER NOT NULL,
        month TEXT NOT NULL,
        type TEXT NOT NULL,
        source TEXT NOT NULL DEFAULT 'Employment',
        expected REAL,
        actual REAL
      );
    ''');

    await db.execute('''
      CREATE TABLE employment_expense (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        year INTEGER NOT NULL,
        month TEXT NOT NULL,
        item TEXT NOT NULL,
        estimated REAL,
        actual REAL
      );
    ''');

    await db.execute('''
      CREATE TABLE business_revenue (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        year INTEGER NOT NULL,
        month TEXT NOT NULL,
        business TEXT NOT NULL,
        expected REAL,
        actual REAL
      );
    ''');

    await db.execute('''
      CREATE TABLE business_expense (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        year INTEGER NOT NULL,
        month TEXT NOT NULL,
        item TEXT NOT NULL,
        business TEXT NOT NULL,
        estimated REAL,
        actual REAL
      );
    ''');

    await db.execute('''
      CREATE TABLE investments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        year INTEGER NOT NULL,
        month TEXT NOT NULL,
        closingValue REAL,
        totalInterest REAL,
        currentMonthIncome REAL
      );
    ''');

    await db.execute('''
      CREATE TABLE customers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        phone TEXT,
        category TEXT,
        avgSpending REAL
      );
    ''');

    await db.execute('''
      CREATE TABLE customer_checkins (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        customerId INTEGER NOT NULL,
        month TEXT NOT NULL,
        week INTEGER NOT NULL,
        status TEXT,
        FOREIGN KEY (customerId) REFERENCES customers (id) ON DELETE CASCADE
      );
    ''');

    await db.execute('''
      CREATE TABLE revenue_targets (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        month TEXT NOT NULL,
        target REAL,
        actual REAL
      );
    ''');

    await _createV2Tables(db);
    await _createV3Tables(db);
    await _createV4Tables(db);
    await _seed(db);
    await _seedDefaultAdmin(db);
    await _seedDefaultIncomeSource(db);
    await _seedKnownBusinesses(db);
  }

  Future<void> _seed(Database db) async {
    final batch = db.batch();

    for (final row in seedEmploymentIncome) {
      batch.insert('employment_income', {...row, 'source': 'Employment'});
    }
    for (final row in seedEmploymentExpense) {
      batch.insert('employment_expense', row);
    }
    for (final row in seedBusinessRevenue) {
      batch.insert('business_revenue', row);
    }
    for (final row in seedBusinessExpense) {
      batch.insert('business_expense', row);
    }
    for (final row in seedInvestments) {
      batch.insert('investments', row);
    }
    for (final row in seedRevenueTargets) {
      batch.insert('revenue_targets', row);
    }

    for (final c in seedCustomers) {
      final customerId = await db.insert('customers', {
        'name': c['name'],
        'phone': c['phone'],
        'category': c['category'],
        'avgSpending': c['avgSpending'],
      });
      for (final chk in (c['checkins'] as List)) {
        batch.insert('customer_checkins', {
          'customerId': customerId,
          'month': chk['month'],
          'week': chk['week'],
          'status': chk['status'],
        });
      }
    }

    await batch.commit(noResult: true);
  }

  Future<void> resetAndReseed() async {
    final db = await database;
    await db.transaction((txn) async {
      for (final t in [
        'employment_income',
        'employment_expense',
        'business_revenue',
        'business_expense',
        'investments',
        'customer_checkins',
        'customers',
        'revenue_targets',
      ]) {
        await txn.delete(t);
      }
    });
    await _seed(db);
  }
}
