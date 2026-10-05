import 'package:flutter/foundation.dart';

import '../models/models.dart';
import '../utils/month_utils.dart';
import 'finance_repository.dart';

/// Aggregated numbers for one calendar period (a given month/year), combining
/// every section so the dashboard can show one unified view.
class PeriodTotals {
  final int year;
  final String month;
  double empIncomeExpected = 0, empIncomeActual = 0;
  double empExpenseEstimated = 0, empExpenseActual = 0;
  double bizRevenueExpected = 0, bizRevenueActual = 0;
  double bizExpenseEstimated = 0, bizExpenseActual = 0;

  PeriodTotals(this.year, this.month);

  int get key => periodKey(year, month);
  String get label => shortPeriodLabel(year, month);

  double get totalIncomeActual => empIncomeActual + bizRevenueActual;
  double get totalIncomeExpected => empIncomeExpected + bizRevenueExpected;
  double get totalExpenseActual => empExpenseActual + bizExpenseActual;
  double get totalExpenseExpected => empExpenseEstimated + bizExpenseEstimated;
  double get netActual => totalIncomeActual - totalExpenseActual;
  double get netExpected => totalIncomeExpected - totalExpenseExpected;
}

/// Loads everything from the API once and keeps it in memory, recomputing
/// derived summaries whenever the underlying data changes. All screens read
/// from this single source of truth via [ChangeNotifier].
class FinanceStore extends ChangeNotifier {
  final FinanceRepository repo;
  FinanceStore(this.repo);

  bool loading = true;

  List<EmploymentIncome> employmentIncome = [];
  List<EmploymentExpense> employmentExpense = [];
  List<BusinessRevenue> businessRevenue = [];
  List<BusinessExpense> businessExpense = [];
  List<InvestmentEntry> investments = [];
  List<Customer> customers = [];
  List<CustomerCheckin> checkins = [];
  List<RevenueTarget> revenueTargets = [];
  List<DailySale> dailySales = [];
  List<IncomeSource> incomeSources = [];
  List<BusinessEntity> businesses = [];

  Future<void> load() async {
    loading = true;
    notifyListeners();

    final results = await Future.wait([
      repo.getEmploymentIncome(),
      repo.getEmploymentExpense(),
      repo.getBusinessRevenue(),
      repo.getBusinessExpense(),
      repo.getInvestments(),
      repo.getCustomers(),
      repo.getAllCheckins(),
      repo.getRevenueTargets(),
      repo.getDailySales(),
      repo.getIncomeSources(),
      repo.getBusinesses(),
    ]);

    employmentIncome = results[0] as List<EmploymentIncome>;
    employmentExpense = results[1] as List<EmploymentExpense>;
    businessRevenue = results[2] as List<BusinessRevenue>;
    businessExpense = results[3] as List<BusinessExpense>;
    investments = results[4] as List<InvestmentEntry>;
    customers = results[5] as List<Customer>;
    checkins = results[6] as List<CustomerCheckin>;
    revenueTargets = results[7] as List<RevenueTarget>;
    dailySales = results[8] as List<DailySale>;
    incomeSources = results[9] as List<IncomeSource>;
    businesses = results[10] as List<BusinessEntity>;

    loading = false;
    notifyListeners();
  }

  /// Named income sources, merging the Settings-managed list with any
  /// source names already present on historical entries (so data never
  /// "disappears" from the picker even if its source was deleted from the
  /// managed list).
  List<String> get distinctIncomeSources => {
        ...incomeSources.map((s) => s.name),
        ...employmentIncome.map((e) => e.source),
      }.toList()
        ..sort();

  Future<String?> addIncomeSource(String name) async {
    if (name.trim().isEmpty) return 'Name cannot be empty.';
    if (distinctIncomeSources.any((s) => s.toLowerCase() == name.trim().toLowerCase())) {
      return 'That income source already exists.';
    }
    await repo.addIncomeSource(name.trim());
    await load();
    return null;
  }

  Future<String?> deleteIncomeSource(IncomeSource source) async {
    final count = await repo.countIncomeEntriesForSource(source.name);
    if (count > 0) {
      return 'Cannot delete "${source.name}" — it still has $count income entr${count == 1 ? 'y' : 'ies'}.';
    }
    await repo.deleteIncomeSource(source.id!);
    await load();
    return null;
  }

  /// Drops everything cached in memory (e.g. on logout, so the next login's
  /// first frame doesn't briefly show the previous tenant's data).
  void clear() {
    loading = true;
    employmentIncome = [];
    employmentExpense = [];
    businessRevenue = [];
    businessExpense = [];
    investments = [];
    customers = [];
    checkins = [];
    revenueTargets = [];
    dailySales = [];
    incomeSources = [];
    businesses = [];
    notifyListeners();
  }

  // ---------------- cross-cutting aggregation ----------------

  /// Named businesses, merging the Settings-managed list with any business
  /// names already present on revenue/expense/daily-sale entries (so data
  /// never "disappears" from the picker even if deleted from the managed
  /// list elsewhere).
  List<String> get distinctBusinesses => {
        ...businesses.map((b) => b.name),
        ...businessRevenue.map((e) => e.business),
        ...businessExpense.map((e) => e.business),
        ...dailySales.map((e) => e.business),
      }.toList()
        ..sort();

  Future<String?> addBusiness(String name) async {
    if (name.trim().isEmpty) return 'Name cannot be empty.';
    if (distinctBusinesses.any((b) => b.toLowerCase() == name.trim().toLowerCase())) {
      return 'That business already exists.';
    }
    await repo.addBusiness(name.trim());
    await load();
    return null;
  }

  Future<String?> deleteBusiness(BusinessEntity business) async {
    final count = await repo.countEntriesForBusiness(business.name);
    if (count > 0) {
      return 'Cannot delete "${business.name}" — it still has $count record${count == 1 ? '' : 's'}.';
    }
    await repo.deleteBusiness(business.id!);
    await load();
    return null;
  }

  /// All periods present across every section, sorted chronologically.
  List<MapEntry<int, String>> get allPeriods {
    final seen = <int, MapEntry<int, String>>{};
    void add(int y, String m) => seen[periodKey(y, m)] = MapEntry(y, m);
    for (final e in employmentIncome) add(e.year, e.month);
    for (final e in employmentExpense) add(e.year, e.month);
    for (final e in businessRevenue) add(e.year, e.month);
    for (final e in businessExpense) add(e.year, e.month);
    for (final e in investments) add(e.year, e.month);
    final keys = seen.keys.toList()..sort();
    return keys.map((k) => seen[k]!).toList();
  }

  /// Unified per-month totals across employment + business, ready for charts.
  List<PeriodTotals> get periodTotals {
    final map = <int, PeriodTotals>{};
    PeriodTotals get(int y, String m) =>
        map.putIfAbsent(periodKey(y, m), () => PeriodTotals(y, m));

    for (final e in employmentIncome) {
      final t = get(e.year, e.month);
      t.empIncomeExpected += e.expected ?? 0;
      t.empIncomeActual += e.actual ?? 0;
    }
    for (final e in employmentExpense) {
      final t = get(e.year, e.month);
      t.empExpenseEstimated += e.estimated ?? 0;
      t.empExpenseActual += e.actual ?? 0;
    }
    for (final e in businessRevenue) {
      final t = get(e.year, e.month);
      t.bizRevenueExpected += e.expected ?? 0;
      t.bizRevenueActual += e.actual ?? 0;
    }
    for (final e in businessExpense) {
      final t = get(e.year, e.month);
      t.bizExpenseEstimated += e.estimated ?? 0;
      t.bizExpenseActual += e.actual ?? 0;
    }

    final list = map.values.toList()..sort((a, b) => a.key.compareTo(b.key));
    return list;
  }

  PeriodTotals? get latestPeriod =>
      periodTotals.isEmpty ? null : periodTotals.last;

  double get netWorthProxy {
    final investedValue =
        investments.isEmpty ? 0.0 : investments.last.closingValue ?? 0.0;
    final cumulativeNet =
        periodTotals.fold<double>(0, (sum, p) => sum + p.netActual);
    return investedValue + cumulativeNet;
  }

  // -------- CRUD passthrough (mutate local cache + persist + notify) --------

  Future<void> addEmploymentIncome(EmploymentIncome e) async {
    await repo.addEmploymentIncome(e);
    await load();
  }

  Future<void> updateEmploymentIncome(EmploymentIncome e) async {
    await repo.updateEmploymentIncome(e);
    await load();
  }

  Future<void> deleteEmploymentIncome(int id) async {
    await repo.deleteEmploymentIncome(id);
    await load();
  }

  Future<void> addEmploymentExpense(EmploymentExpense e) async {
    await repo.addEmploymentExpense(e);
    await load();
  }

  Future<void> updateEmploymentExpense(EmploymentExpense e) async {
    await repo.updateEmploymentExpense(e);
    await load();
  }

  Future<void> deleteEmploymentExpense(int id) async {
    await repo.deleteEmploymentExpense(id);
    await load();
  }

  Future<void> addBusinessRevenue(BusinessRevenue e) async {
    await repo.addBusinessRevenue(e);
    await load();
  }

  Future<void> updateBusinessRevenue(BusinessRevenue e) async {
    await repo.updateBusinessRevenue(e);
    await load();
  }

  Future<void> deleteBusinessRevenue(int id) async {
    await repo.deleteBusinessRevenue(id);
    await load();
  }

  Future<void> addBusinessExpense(BusinessExpense e) async {
    await repo.addBusinessExpense(e);
    await load();
  }

  Future<void> updateBusinessExpense(BusinessExpense e) async {
    await repo.updateBusinessExpense(e);
    await load();
  }

  Future<void> deleteBusinessExpense(int id) async {
    await repo.deleteBusinessExpense(id);
    await load();
  }

  Future<void> addInvestment(InvestmentEntry e) async {
    await repo.addInvestment(e);
    await load();
  }

  Future<void> updateInvestment(InvestmentEntry e) async {
    await repo.updateInvestment(e);
    await load();
  }

  Future<void> deleteInvestment(int id) async {
    await repo.deleteInvestment(id);
    await load();
  }

  Future<void> addCustomer(Customer c) async {
    await repo.addCustomer(c);
    await load();
  }

  Future<void> updateCustomer(Customer c) async {
    await repo.updateCustomer(c);
    await load();
  }

  Future<void> deleteCustomer(int id) async {
    await repo.deleteCustomer(id);
    await load();
  }

  Future<void> setCheckin(int customerId, String month, int week, String? status) async {
    await repo.setCheckin(customerId, month, week, status);
    await load();
  }

  Future<void> addRevenueTarget(RevenueTarget t) async {
    await repo.addRevenueTarget(t);
    await load();
  }

  Future<void> updateRevenueTarget(RevenueTarget t) async {
    await repo.updateRevenueTarget(t);
    await load();
  }

  Future<void> deleteRevenueTarget(int id) async {
    await repo.deleteRevenueTarget(id);
    await load();
  }

  Future<void> addDailySale(DailySale s) async {
    await repo.addDailySale(s);
    await load();
  }

  Future<void> updateDailySale(DailySale s) async {
    await repo.updateDailySale(s);
    await load();
  }

  Future<void> deleteDailySale(int id) async {
    await repo.deleteDailySale(id);
    await load();
  }

  // ---------------- daily sales aggregation ----------------

  List<DailySale> dailySalesFor(String business) =>
      dailySales.where((s) => s.business == business).toList();

  double dailySalesTotalFor(String business, {required String since}) =>
      dailySalesFor(business)
          .where((s) => s.date.compareTo(since) >= 0)
          .fold<double>(0, (a, s) => a + s.amount);
}
