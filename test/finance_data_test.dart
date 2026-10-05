import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:kosh_finance/models/models.dart';
import 'package:kosh_finance/services/auth_repository.dart';
import 'package:kosh_finance/services/finance_repository.dart';
import 'package:kosh_finance/services/finance_store.dart';
import 'package:kosh_finance/services/insights_engine.dart';
import 'package:kosh_finance/utils/time_range.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  test('database seeds from the Oct Kosh Budget data and loads cleanly', () async {
    final store = FinanceStore(FinanceRepository());
    await store.load();

    expect(store.employmentIncome, isNotEmpty);
    expect(store.employmentExpense, isNotEmpty);
    expect(store.businessRevenue, isNotEmpty);
    expect(store.businessExpense, isNotEmpty);
    expect(store.investments, isNotEmpty);
    expect(store.customers.length, 9);
    expect(store.revenueTargets, isNotEmpty);

    // Every seeded expense/income month name must be a real 3-letter month.
    const validMonths = {
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    };
    for (final e in store.employmentExpense) {
      expect(validMonths.contains(e.month), isTrue, reason: 'bad month: ${e.month}');
    }
    for (final e in store.businessExpense) {
      expect(validMonths.contains(e.month), isTrue, reason: 'bad month: ${e.month}');
    }
  });

  test('period aggregation produces chronologically sorted totals', () async {
    final store = FinanceStore(FinanceRepository());
    await store.load();

    final periods = store.periodTotals;
    expect(periods, isNotEmpty);
    for (var i = 1; i < periods.length; i++) {
      expect(periods[i].key, greaterThan(periods[i - 1].key));
    }

    // First tracked period should be Nov 2025 per the source spreadsheet.
    expect(periods.first.year, 2025);
    expect(periods.first.month, 'Nov');
    expect(periods.last.year, 2026);
    expect(periods.last.month, 'Oct');
  });

  test('insights engines run without throwing and produce content', () async {
    final store = FinanceStore(FinanceRepository());
    await store.load();

    expect(dashboardInsights(store), isNotEmpty);
    expect(employmentInsights(store), isNotEmpty);
    expect(customerInsights(store), isNotEmpty);
    for (final b in store.distinctBusinesses) {
      // Not all sources (e.g. "Others") necessarily have expense rows; just
      // make sure the function runs cleanly for every business key.
      businessInsights(store, b);
    }
  });

  test('CRUD round-trip: add and delete an employment expense', () async {
    final store = FinanceStore(FinanceRepository());
    await store.load();
    final before = store.employmentExpense.length;

    await store.addEmploymentExpense(EmploymentExpense(
      year: 2026,
      month: 'Nov',
      item: 'Test category',
      estimated: 1000,
      actual: 950,
    ));
    expect(store.employmentExpense.length, before + 1);

    final added = store.employmentExpense.firstWhere((e) => e.item == 'Test category');
    await store.deleteEmploymentExpense(added.id!);
    expect(store.employmentExpense.length, before);
  });

  test('daily sales CRUD round-trip and aggregation', () async {
    final store = FinanceStore(FinanceRepository());
    await store.load();
    final before = store.dailySales.length;

    await store.addDailySale(DailySale(
      date: '2026-10-04',
      business: 'Bubbles Lundry',
      amount: 1500,
      note: 'test entry',
    ));
    expect(store.dailySales.length, before + 1);
    expect(store.dailySalesTotalFor('Bubbles Lundry', since: '2026-10-01'), greaterThanOrEqualTo(1500));

    final added = store.dailySales.firstWhere((s) => s.note == 'test entry');
    await store.deleteDailySale(added.id!);
    expect(store.dailySales.length, before);
  });

  test('default admin user is seeded and can authenticate', () async {
    final auth = AuthRepository();
    final user = await auth.authenticate('admin', 'admin');
    expect(user, isNotNull);
    expect(user!.isAdmin, isTrue);

    final wrongPassword = await auth.authenticate('admin', 'wrong-password');
    expect(wrongPassword, isNull);
  });

  test('admin can create a restricted user with limited page access', () async {
    final auth = AuthRepository();
    final id = await auth.createUser(
      username: 'cashier_${DateTime.now().millisecondsSinceEpoch}',
      password: 'temp1234',
      isAdmin: false,
      allowedPages: ['dashboard', 'business'],
    );
    expect(id, greaterThan(0));

    final users = await auth.getUsers();
    final created = users.firstWhere((u) => u.id == id);
    expect(created.isAdmin, isFalse);
    expect(created.canAccess('business'), isTrue);
    expect(created.canAccess('investments'), isFalse);

    await auth.deleteUser(id);
  });

  test('default "Employment" income source is seeded and historical income carries it', () async {
    final store = FinanceStore(FinanceRepository());
    await store.load();

    expect(store.distinctIncomeSources, contains('Employment'));
    expect(store.employmentIncome, isNotEmpty);
    for (final e in store.employmentIncome) {
      expect(e.source, 'Employment');
    }
  });

  test('a new income source can be added, used, and is protected from deletion while in use', () async {
    final store = FinanceStore(FinanceRepository());
    await store.load();
    final sourceName = 'Freelance ${DateTime.now().millisecondsSinceEpoch}';

    final addErr = await store.addIncomeSource(sourceName);
    expect(addErr, isNull);
    expect(store.distinctIncomeSources, contains(sourceName));

    // Adding the same name again should be rejected.
    final dupeErr = await store.addIncomeSource(sourceName);
    expect(dupeErr, isNotNull);

    await store.addEmploymentIncome(EmploymentIncome(
      year: 2026, month: 'Nov', type: 'Contract', source: sourceName, actual: 5000,
    ));

    final created = store.incomeSources.firstWhere((s) => s.name == sourceName);
    final blockedErr = await store.deleteIncomeSource(created);
    expect(blockedErr, isNotNull);
    expect(store.distinctIncomeSources, contains(sourceName));

    // Clean up: remove the income entry, then deletion should succeed.
    final entry = store.employmentIncome.firstWhere((e) => e.source == sourceName);
    await store.deleteEmploymentIncome(entry.id!);
    final okErr = await store.deleteIncomeSource(created);
    expect(okErr, isNull);
    expect(store.distinctIncomeSources, isNot(contains(sourceName)));
  });

  test('time range filtering: all time, this year, and this month', () {
    final now = DateTime.now();
    const currentMonthNames = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final currentMonth = currentMonthNames[now.month - 1];

    expect(isPeriodInRange(now.year, currentMonth, TimeRange.allTime), isTrue);
    expect(isPeriodInRange(2000, 'Jan', TimeRange.allTime), isTrue);

    expect(isPeriodInRange(now.year, currentMonth, TimeRange.thisYear), isTrue);
    expect(isPeriodInRange(now.year - 1, currentMonth, TimeRange.thisYear), isFalse);

    expect(isPeriodInRange(now.year, currentMonth, TimeRange.thisMonth), isTrue);

    final otherMonth = currentMonthNames[(now.month) % 12]; // guaranteed different month
    expect(isPeriodInRange(now.year, otherMonth, TimeRange.thisMonth), isFalse);
  });

  test('known businesses from the spreadsheet are seeded into the managed list', () async {
    final store = FinanceStore(FinanceRepository());
    await store.load();

    expect(store.distinctBusinesses, containsAll(['Bubbles Lundry', 'Koshtech']));
  });

  test('a new business can be added, used, and is protected from deletion while in use', () async {
    final store = FinanceStore(FinanceRepository());
    await store.load();
    final name = 'Test Biz ${DateTime.now().millisecondsSinceEpoch}';

    final addErr = await store.addBusiness(name);
    expect(addErr, isNull);
    expect(store.distinctBusinesses, contains(name));

    final dupeErr = await store.addBusiness(name);
    expect(dupeErr, isNotNull);

    await store.addBusinessRevenue(BusinessRevenue(year: 2026, month: 'Nov', business: name, actual: 1000));

    final created = store.businesses.firstWhere((b) => b.name == name);
    final blockedErr = await store.deleteBusiness(created);
    expect(blockedErr, isNotNull);
    expect(store.distinctBusinesses, contains(name));

    final entry = store.businessRevenue.firstWhere((r) => r.business == name);
    await store.deleteBusinessRevenue(entry.id!);
    final okErr = await store.deleteBusiness(created);
    expect(okErr, isNull);
    expect(store.distinctBusinesses, isNot(contains(name)));
  });
}
