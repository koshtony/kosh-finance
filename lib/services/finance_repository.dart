import '../models/models.dart';
import 'api_client.dart';

int _byYearMonth(int ay, String am, int by, String bm) {
  final c = ay.compareTo(by);
  return c != 0 ? c : am.compareTo(bm);
}

/// Thin data-access layer over the Kosh API. Every screen reads/writes
/// through here. Finance rows are scoped to the signed-in user's tenant
/// (set on [ApiClient] at login); `source`/`business` stay plain name
/// strings at the model layer (matching the existing UI, which only ever
/// picks from a name list) and are resolved to the API's `IncomeSource`/
/// `Business` foreign keys here, auto-creating one if a brand-new name is
/// used before Settings would otherwise have created it.
class FinanceRepository {
  final _api = ApiClient.instance;
  int get _tid => _api.tenantId!;

  List<IncomeSource> _sourcesCache = [];
  List<BusinessEntity> _businessesCache = [];

  Future<int> _resolveSourceId(String name) async {
    IncomeSource? match = _firstByName(_sourcesCache, name);
    if (match == null) {
      await getIncomeSources();
      match = _firstByName(_sourcesCache, name);
    }
    if (match != null) return match.id!;
    return addIncomeSource(name);
  }

  Future<int> _resolveBusinessId(String name) async {
    BusinessEntity? match = _firstByName(_businessesCache, name);
    if (match == null) {
      await getBusinesses();
      match = _firstByName(_businessesCache, name);
    }
    if (match != null) return match.id!;
    return addBusiness(name);
  }

  T? _firstByName<T>(List<T> items, String name) {
    for (final item in items) {
      final itemName = (item as dynamic).name as String;
      if (itemName.toLowerCase() == name.toLowerCase()) return item;
    }
    return null;
  }

  // ---------------- Employment income ----------------

  Future<List<EmploymentIncome>> getEmploymentIncome() async {
    final rows = await _api.getAllPages('/tenants/$_tid/employment-income/');
    final list = rows
        .map((r) => EmploymentIncome(
              id: r['id'] as int,
              year: r['year'] as int,
              month: r['month'] as String,
              type: r['type'] as String,
              source: (r['source_name'] as String?) ?? '',
              expected: toDoubleOrNull(r['expected']),
              actual: toDoubleOrNull(r['actual']),
            ))
        .toList();
    list.sort((a, b) => _byYearMonth(a.year, a.month, b.year, b.month));
    return list;
  }

  Future<int> addEmploymentIncome(EmploymentIncome e) async {
    final sourceId = await _resolveSourceId(e.source);
    final res = await _api.post('/tenants/$_tid/employment-income/', {
      'source': sourceId,
      'year': e.year,
      'month': e.month,
      'type': e.type,
      'expected': e.expected,
      'actual': e.actual,
    });
    return res['id'] as int;
  }

  Future<void> updateEmploymentIncome(EmploymentIncome e) async {
    final sourceId = await _resolveSourceId(e.source);
    await _api.patch('/tenants/$_tid/employment-income/${e.id}/', {
      'source': sourceId,
      'year': e.year,
      'month': e.month,
      'type': e.type,
      'expected': e.expected,
      'actual': e.actual,
    });
  }

  Future<void> deleteEmploymentIncome(int id) async {
    await _api.delete('/tenants/$_tid/employment-income/$id/');
  }

  // ---------------- Income sources ----------------

  Future<List<IncomeSource>> getIncomeSources() async {
    final rows = await _api.getAllPages('/tenants/$_tid/income-sources/');
    _sourcesCache = rows.map((r) => IncomeSource(id: r['id'] as int, name: r['name'] as String)).toList()
      ..sort((a, b) => a.name.compareTo(b.name));
    return _sourcesCache;
  }

  Future<int> addIncomeSource(String name) async {
    final res = await _api.post('/tenants/$_tid/income-sources/', {'name': name});
    return res['id'] as int;
  }

  Future<void> deleteIncomeSource(int id) async {
    await _api.delete('/tenants/$_tid/income-sources/$id/');
  }

  Future<int> countIncomeEntriesForSource(String source) async {
    final match = _firstByName(_sourcesCache, source);
    if (match == null) return 0;
    final rows = await _api.getAllPages('/tenants/$_tid/employment-income/');
    return rows.where((r) => r['source'] == match.id).length;
  }

  // ---------------- Businesses ----------------

  Future<List<BusinessEntity>> getBusinesses() async {
    final rows = await _api.getAllPages('/tenants/$_tid/businesses/');
    _businessesCache = rows.map((r) => BusinessEntity(id: r['id'] as int, name: r['name'] as String)).toList()
      ..sort((a, b) => a.name.compareTo(b.name));
    return _businessesCache;
  }

  Future<int> addBusiness(String name) async {
    final res = await _api.post('/tenants/$_tid/businesses/', {'name': name});
    return res['id'] as int;
  }

  Future<void> deleteBusiness(int id) async {
    await _api.delete('/tenants/$_tid/businesses/$id/');
  }

  Future<int> countEntriesForBusiness(String name) async {
    final match = _firstByName(_businessesCache, name);
    if (match == null) return 0;
    final revenue = await _api.getAllPages('/tenants/$_tid/business-revenue/');
    final expense = await _api.getAllPages('/tenants/$_tid/business-expenses/');
    final sales = await _api.getAllPages('/tenants/$_tid/daily-sales/');
    return [revenue, expense, sales]
        .map((rows) => rows.where((r) => r['business'] == match.id).length)
        .reduce((a, b) => a + b);
  }

  // ---------------- Employment expense ----------------

  Future<List<EmploymentExpense>> getEmploymentExpense() async {
    final rows = await _api.getAllPages('/tenants/$_tid/employment-expenses/');
    final list = rows
        .map((r) => EmploymentExpense(
              id: r['id'] as int,
              year: r['year'] as int,
              month: r['month'] as String,
              item: r['item'] as String,
              estimated: toDoubleOrNull(r['estimated']),
              actual: toDoubleOrNull(r['actual']),
            ))
        .toList();
    list.sort((a, b) => _byYearMonth(a.year, a.month, b.year, b.month));
    return list;
  }

  Future<int> addEmploymentExpense(EmploymentExpense e) async {
    final res = await _api.post('/tenants/$_tid/employment-expenses/', {
      'year': e.year,
      'month': e.month,
      'item': e.item,
      'estimated': e.estimated,
      'actual': e.actual,
    });
    return res['id'] as int;
  }

  Future<void> updateEmploymentExpense(EmploymentExpense e) async {
    await _api.patch('/tenants/$_tid/employment-expenses/${e.id}/', {
      'year': e.year,
      'month': e.month,
      'item': e.item,
      'estimated': e.estimated,
      'actual': e.actual,
    });
  }

  Future<void> deleteEmploymentExpense(int id) async {
    await _api.delete('/tenants/$_tid/employment-expenses/$id/');
  }

  // ---------------- Business revenue ----------------

  Future<List<BusinessRevenue>> getBusinessRevenue() async {
    final rows = await _api.getAllPages('/tenants/$_tid/business-revenue/');
    final list = rows
        .map((r) => BusinessRevenue(
              id: r['id'] as int,
              year: r['year'] as int,
              month: r['month'] as String,
              business: (r['business_name'] as String?) ?? '',
              expected: toDoubleOrNull(r['expected']),
              actual: toDoubleOrNull(r['actual']),
            ))
        .toList();
    list.sort((a, b) => _byYearMonth(a.year, a.month, b.year, b.month));
    return list;
  }

  Future<int> addBusinessRevenue(BusinessRevenue e) async {
    final businessId = await _resolveBusinessId(e.business);
    final res = await _api.post('/tenants/$_tid/business-revenue/', {
      'business': businessId,
      'year': e.year,
      'month': e.month,
      'expected': e.expected,
      'actual': e.actual,
    });
    return res['id'] as int;
  }

  Future<void> updateBusinessRevenue(BusinessRevenue e) async {
    final businessId = await _resolveBusinessId(e.business);
    await _api.patch('/tenants/$_tid/business-revenue/${e.id}/', {
      'business': businessId,
      'year': e.year,
      'month': e.month,
      'expected': e.expected,
      'actual': e.actual,
    });
  }

  Future<void> deleteBusinessRevenue(int id) async {
    await _api.delete('/tenants/$_tid/business-revenue/$id/');
  }

  // ---------------- Business expense ----------------

  Future<List<BusinessExpense>> getBusinessExpense() async {
    final rows = await _api.getAllPages('/tenants/$_tid/business-expenses/');
    final list = rows
        .map((r) => BusinessExpense(
              id: r['id'] as int,
              year: r['year'] as int,
              month: r['month'] as String,
              item: r['item'] as String,
              business: (r['business_name'] as String?) ?? '',
              estimated: toDoubleOrNull(r['estimated']),
              actual: toDoubleOrNull(r['actual']),
            ))
        .toList();
    list.sort((a, b) => _byYearMonth(a.year, a.month, b.year, b.month));
    return list;
  }

  Future<int> addBusinessExpense(BusinessExpense e) async {
    final businessId = await _resolveBusinessId(e.business);
    final res = await _api.post('/tenants/$_tid/business-expenses/', {
      'business': businessId,
      'year': e.year,
      'month': e.month,
      'item': e.item,
      'estimated': e.estimated,
      'actual': e.actual,
    });
    return res['id'] as int;
  }

  Future<void> updateBusinessExpense(BusinessExpense e) async {
    final businessId = await _resolveBusinessId(e.business);
    await _api.patch('/tenants/$_tid/business-expenses/${e.id}/', {
      'business': businessId,
      'year': e.year,
      'month': e.month,
      'item': e.item,
      'estimated': e.estimated,
      'actual': e.actual,
    });
  }

  Future<void> deleteBusinessExpense(int id) async {
    await _api.delete('/tenants/$_tid/business-expenses/$id/');
  }

  // ---------------- Investments ----------------

  Future<List<InvestmentEntry>> getInvestments() async {
    final rows = await _api.getAllPages('/tenants/$_tid/investments/');
    final list = rows
        .map((r) => InvestmentEntry(
              id: r['id'] as int,
              year: r['year'] as int,
              month: r['month'] as String,
              closingValue: toDoubleOrNull(r['closing_value']),
              totalInterest: toDoubleOrNull(r['total_interest']),
              currentMonthIncome: toDoubleOrNull(r['current_month_income']),
            ))
        .toList();
    list.sort((a, b) => _byYearMonth(a.year, a.month, b.year, b.month));
    return list;
  }

  Future<int> addInvestment(InvestmentEntry e) async {
    final res = await _api.post('/tenants/$_tid/investments/', {
      'year': e.year,
      'month': e.month,
      'closing_value': e.closingValue,
      'total_interest': e.totalInterest,
      'current_month_income': e.currentMonthIncome,
    });
    return res['id'] as int;
  }

  Future<void> updateInvestment(InvestmentEntry e) async {
    await _api.patch('/tenants/$_tid/investments/${e.id}/', {
      'year': e.year,
      'month': e.month,
      'closing_value': e.closingValue,
      'total_interest': e.totalInterest,
      'current_month_income': e.currentMonthIncome,
    });
  }

  Future<void> deleteInvestment(int id) async {
    await _api.delete('/tenants/$_tid/investments/$id/');
  }

  // ---------------- Customers ----------------

  Future<List<Customer>> getCustomers() async {
    final rows = await _api.getAllPages('/tenants/$_tid/customers/');
    final list = rows.map(_customerFromJson).toList();
    list.sort((a, b) => a.name.compareTo(b.name));
    return list;
  }

  Customer _customerFromJson(dynamic r) => Customer(
        id: r['id'] as int,
        name: r['name'] as String,
        phone: (r['phone'] as String?)?.isNotEmpty == true ? r['phone'] as String : null,
        category: (r['category'] as String?)?.isNotEmpty == true ? r['category'] as String : null,
        avgSpending: toDoubleOrNull(r['avg_spending']),
      );

  Future<int> addCustomer(Customer c) async {
    final res = await _api.post('/tenants/$_tid/customers/', {
      'name': c.name,
      'phone': c.phone ?? '',
      'category': c.category ?? '',
      'avg_spending': c.avgSpending,
    });
    return res['id'] as int;
  }

  Future<void> updateCustomer(Customer c) async {
    await _api.patch('/tenants/$_tid/customers/${c.id}/', {
      'name': c.name,
      'phone': c.phone ?? '',
      'category': c.category ?? '',
      'avg_spending': c.avgSpending,
    });
  }

  Future<void> deleteCustomer(int id) async {
    await _api.delete('/tenants/$_tid/customers/$id/');
  }

  Future<List<CustomerCheckin>> getAllCheckins() async {
    final rows = await _api.getAllPages('/tenants/$_tid/customer-checkins/');
    return rows.map(_checkinFromJson).toList();
  }

  CustomerCheckin _checkinFromJson(dynamic r) => CustomerCheckin(
        id: r['id'] as int,
        customerId: r['customer'] as int,
        month: r['month'] as String,
        week: r['week'] as int,
        status: r['status'] as String?,
      );

  /// Insert or update the checkin for (customerId, month, week).
  Future<void> setCheckin(int customerId, String month, int week, String? status) async {
    final rows = await _api.getAllPages('/tenants/$_tid/customer-checkins/');
    final existing = rows.where(
      (r) => r['customer'] == customerId && r['month'] == month && r['week'] == week,
    );
    if (existing.isNotEmpty) {
      await _api.patch('/tenants/$_tid/customer-checkins/${existing.first['id']}/', {'status': status});
    } else {
      await _api.post('/tenants/$_tid/customer-checkins/', {
        'customer': customerId,
        'month': month,
        'week': week,
        'status': status,
      });
    }
  }

  // ---------------- Daily sales ----------------

  Future<List<DailySale>> getDailySales() async {
    final rows = await _api.getAllPages('/tenants/$_tid/daily-sales/');
    final list = rows
        .map((r) => DailySale(
              id: r['id'] as int,
              date: r['date'] as String,
              business: (r['business_name'] as String?) ?? '',
              amount: toDoubleOrNull(r['amount']) ?? 0,
              note: (r['note'] as String?)?.isNotEmpty == true ? r['note'] as String : null,
            ))
        .toList();
    list.sort((a, b) {
      final c = b.date.compareTo(a.date);
      return c != 0 ? c : (b.id ?? 0).compareTo(a.id ?? 0);
    });
    return list;
  }

  Future<int> addDailySale(DailySale e) async {
    final businessId = await _resolveBusinessId(e.business);
    final res = await _api.post('/tenants/$_tid/daily-sales/', {
      'business': businessId,
      'date': e.date,
      'amount': e.amount,
      'note': e.note ?? '',
    });
    return res['id'] as int;
  }

  Future<void> updateDailySale(DailySale e) async {
    final businessId = await _resolveBusinessId(e.business);
    await _api.patch('/tenants/$_tid/daily-sales/${e.id}/', {
      'business': businessId,
      'date': e.date,
      'amount': e.amount,
      'note': e.note ?? '',
    });
  }

  Future<void> deleteDailySale(int id) async {
    await _api.delete('/tenants/$_tid/daily-sales/$id/');
  }

  // ---------------- Revenue targets ----------------

  Future<List<RevenueTarget>> getRevenueTargets() async {
    final rows = await _api.getAllPages('/tenants/$_tid/revenue-targets/');
    return rows
        .map((r) => RevenueTarget(
              id: r['id'] as int,
              month: r['month'] as String,
              target: toDoubleOrNull(r['target']),
              actual: toDoubleOrNull(r['actual']),
            ))
        .toList();
  }

  Future<int> addRevenueTarget(RevenueTarget t) async {
    final res = await _api.post('/tenants/$_tid/revenue-targets/', {
      'month': t.month,
      'target': t.target,
      'actual': t.actual,
    });
    return res['id'] as int;
  }

  Future<void> updateRevenueTarget(RevenueTarget t) async {
    await _api.patch('/tenants/$_tid/revenue-targets/${t.id}/', {
      'month': t.month,
      'target': t.target,
      'actual': t.actual,
    });
  }

  Future<void> deleteRevenueTarget(int id) async {
    await _api.delete('/tenants/$_tid/revenue-targets/$id/');
  }
}
