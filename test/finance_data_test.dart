import 'package:flutter_test/flutter_test.dart';

import 'package:kosh_finance/models/models.dart';
import 'package:kosh_finance/services/auth_repository.dart';
import 'package:kosh_finance/services/finance_repository.dart';
import 'package:kosh_finance/services/finance_store.dart';
import 'package:kosh_finance/services/insights_engine.dart';
import 'package:kosh_finance/utils/time_range.dart';

// Runs against the live API's seeded test tenant (see backend's
// seed_test_tenant management command), not a local database — these tests
// need network access and exercise the real Kosh API end to end.
void main() {
  setUpAll(() async {
    final auth = AuthRepository();
    final session = await auth.login('test_admin', 'kosh-test-admin-1');
    if (session == null) {
      throw StateError('Could not log in as test_admin — is the seeded test tenant reachable?');
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
      business: 'Test Business ${DateTime.now().millisecondsSinceEpoch}',
      amount: 1500,
      note: 'test entry',
    ));
    expect(store.dailySales.length, before + 1);

    final added = store.dailySales.firstWhere((s) => s.note == 'test entry');
    expect(store.dailySalesTotalFor(added.business, since: '2026-10-01'), greaterThanOrEqualTo(1500));
    await store.deleteDailySale(added.id!);
    expect(store.dailySales.length, before);
  });

  test('insights engines run without throwing', () async {
    final store = FinanceStore(FinanceRepository());
    await store.load();

    dashboardInsights(store);
    employmentInsights(store);
    customerInsights(store);
    for (final b in store.distinctBusinesses) {
      businessInsights(store, b);
    }
  });

  test('test_admin can authenticate and a wrong password is rejected', () async {
    final auth = AuthRepository();
    final session = await auth.login('test_admin', 'kosh-test-admin-1');
    expect(session, isNotNull);
    expect(session!.user.isAdmin, isTrue);

    final wrongPassword = await auth.login('test_admin', 'wrong-password');
    expect(wrongPassword, isNull);
  });

  test('admin can create a restricted user with limited page access', () async {
    final auth = AuthRepository();
    final username = 'cashier_${DateTime.now().millisecondsSinceEpoch}';
    final id = await auth.createUser(
      username: username,
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
