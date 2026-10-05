import '../db/db_helper.dart';
import '../models/models.dart';

/// Thin data-access layer over sqflite. Every screen reads/writes through here.
class FinanceRepository {
  final _dbh = DbHelper.instance;

  // ---------------- Employment income ----------------

  Future<List<EmploymentIncome>> getEmploymentIncome() async {
    final db = await _dbh.database;
    final rows = await db.query('employment_income', orderBy: 'year, month');
    return rows.map(EmploymentIncome.fromMap).toList();
  }

  Future<int> addEmploymentIncome(EmploymentIncome e) async {
    final db = await _dbh.database;
    return db.insert('employment_income', e.toMap());
  }

  Future<void> updateEmploymentIncome(EmploymentIncome e) async {
    final db = await _dbh.database;
    await db.update('employment_income', e.toMap(),
        where: 'id = ?', whereArgs: [e.id]);
  }

  Future<void> deleteEmploymentIncome(int id) async {
    final db = await _dbh.database;
    await db.delete('employment_income', where: 'id = ?', whereArgs: [id]);
  }

  // ---------------- Income sources ----------------

  Future<List<IncomeSource>> getIncomeSources() async {
    final db = await _dbh.database;
    final rows = await db.query('income_sources', orderBy: 'name');
    return rows.map(IncomeSource.fromMap).toList();
  }

  Future<int> addIncomeSource(String name) async {
    final db = await _dbh.database;
    return db.insert('income_sources', {'name': name});
  }

  Future<void> deleteIncomeSource(int id) async {
    final db = await _dbh.database;
    await db.delete('income_sources', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> countIncomeEntriesForSource(String source) async {
    final db = await _dbh.database;
    final rows = await db.query('employment_income', where: 'source = ?', whereArgs: [source]);
    return rows.length;
  }

  // ---------------- Businesses ----------------

  Future<List<BusinessEntity>> getBusinesses() async {
    final db = await _dbh.database;
    final rows = await db.query('businesses', orderBy: 'name');
    return rows.map(BusinessEntity.fromMap).toList();
  }

  Future<int> addBusiness(String name) async {
    final db = await _dbh.database;
    return db.insert('businesses', {'name': name});
  }

  Future<void> deleteBusiness(int id) async {
    final db = await _dbh.database;
    await db.delete('businesses', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> countEntriesForBusiness(String name) async {
    final db = await _dbh.database;
    final revenue = await db.query('business_revenue', where: 'business = ?', whereArgs: [name]);
    final expense = await db.query('business_expense', where: 'business = ?', whereArgs: [name]);
    final sales = await db.query('daily_sales', where: 'business = ?', whereArgs: [name]);
    return revenue.length + expense.length + sales.length;
  }

  // ---------------- Employment expense ----------------

  Future<List<EmploymentExpense>> getEmploymentExpense() async {
    final db = await _dbh.database;
    final rows = await db.query('employment_expense', orderBy: 'year, month');
    return rows.map(EmploymentExpense.fromMap).toList();
  }

  Future<int> addEmploymentExpense(EmploymentExpense e) async {
    final db = await _dbh.database;
    return db.insert('employment_expense', e.toMap());
  }

  Future<void> updateEmploymentExpense(EmploymentExpense e) async {
    final db = await _dbh.database;
    await db.update('employment_expense', e.toMap(),
        where: 'id = ?', whereArgs: [e.id]);
  }

  Future<void> deleteEmploymentExpense(int id) async {
    final db = await _dbh.database;
    await db.delete('employment_expense', where: 'id = ?', whereArgs: [id]);
  }

  // ---------------- Business revenue ----------------

  Future<List<BusinessRevenue>> getBusinessRevenue() async {
    final db = await _dbh.database;
    final rows = await db.query('business_revenue', orderBy: 'year, month');
    return rows.map(BusinessRevenue.fromMap).toList();
  }

  Future<int> addBusinessRevenue(BusinessRevenue e) async {
    final db = await _dbh.database;
    return db.insert('business_revenue', e.toMap());
  }

  Future<void> updateBusinessRevenue(BusinessRevenue e) async {
    final db = await _dbh.database;
    await db.update('business_revenue', e.toMap(),
        where: 'id = ?', whereArgs: [e.id]);
  }

  Future<void> deleteBusinessRevenue(int id) async {
    final db = await _dbh.database;
    await db.delete('business_revenue', where: 'id = ?', whereArgs: [id]);
  }

  // ---------------- Business expense ----------------

  Future<List<BusinessExpense>> getBusinessExpense() async {
    final db = await _dbh.database;
    final rows = await db.query('business_expense', orderBy: 'year, month');
    return rows.map(BusinessExpense.fromMap).toList();
  }

  Future<int> addBusinessExpense(BusinessExpense e) async {
    final db = await _dbh.database;
    return db.insert('business_expense', e.toMap());
  }

  Future<void> updateBusinessExpense(BusinessExpense e) async {
    final db = await _dbh.database;
    await db.update('business_expense', e.toMap(),
        where: 'id = ?', whereArgs: [e.id]);
  }

  Future<void> deleteBusinessExpense(int id) async {
    final db = await _dbh.database;
    await db.delete('business_expense', where: 'id = ?', whereArgs: [id]);
  }

  // ---------------- Investments ----------------

  Future<List<InvestmentEntry>> getInvestments() async {
    final db = await _dbh.database;
    final rows = await db.query('investments', orderBy: 'year, month');
    return rows.map(InvestmentEntry.fromMap).toList();
  }

  Future<int> addInvestment(InvestmentEntry e) async {
    final db = await _dbh.database;
    return db.insert('investments', e.toMap());
  }

  Future<void> updateInvestment(InvestmentEntry e) async {
    final db = await _dbh.database;
    await db.update('investments', e.toMap(), where: 'id = ?', whereArgs: [e.id]);
  }

  Future<void> deleteInvestment(int id) async {
    final db = await _dbh.database;
    await db.delete('investments', where: 'id = ?', whereArgs: [id]);
  }

  // ---------------- Customers ----------------

  Future<List<Customer>> getCustomers() async {
    final db = await _dbh.database;
    final rows = await db.query('customers', orderBy: 'name');
    return rows.map(Customer.fromMap).toList();
  }

  Future<int> addCustomer(Customer c) async {
    final db = await _dbh.database;
    return db.insert('customers', c.toMap());
  }

  Future<void> updateCustomer(Customer c) async {
    final db = await _dbh.database;
    await db.update('customers', c.toMap(), where: 'id = ?', whereArgs: [c.id]);
  }

  Future<void> deleteCustomer(int id) async {
    final db = await _dbh.database;
    await db.delete('customer_checkins', where: 'customerId = ?', whereArgs: [id]);
    await db.delete('customers', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<CustomerCheckin>> getCheckinsForCustomer(int customerId) async {
    final db = await _dbh.database;
    final rows = await db.query('customer_checkins',
        where: 'customerId = ?', whereArgs: [customerId]);
    return rows.map(CustomerCheckin.fromMap).toList();
  }

  Future<List<CustomerCheckin>> getAllCheckins() async {
    final db = await _dbh.database;
    final rows = await db.query('customer_checkins');
    return rows.map(CustomerCheckin.fromMap).toList();
  }

  /// Insert or update the checkin for (customerId, month, week).
  Future<void> setCheckin(int customerId, String month, int week, String? status) async {
    final db = await _dbh.database;
    final existing = await db.query(
      'customer_checkins',
      where: 'customerId = ? AND month = ? AND week = ?',
      whereArgs: [customerId, month, week],
    );
    if (existing.isNotEmpty) {
      await db.update(
        'customer_checkins',
        {'status': status},
        where: 'id = ?',
        whereArgs: [existing.first['id']],
      );
    } else {
      await db.insert('customer_checkins', {
        'customerId': customerId,
        'month': month,
        'week': week,
        'status': status,
      });
    }
  }

  // ---------------- Daily sales ----------------

  Future<List<DailySale>> getDailySales() async {
    final db = await _dbh.database;
    final rows = await db.query('daily_sales', orderBy: 'date DESC, id DESC');
    return rows.map(DailySale.fromMap).toList();
  }

  Future<int> addDailySale(DailySale e) async {
    final db = await _dbh.database;
    return db.insert('daily_sales', e.toMap());
  }

  Future<void> updateDailySale(DailySale e) async {
    final db = await _dbh.database;
    await db.update('daily_sales', e.toMap(), where: 'id = ?', whereArgs: [e.id]);
  }

  Future<void> deleteDailySale(int id) async {
    final db = await _dbh.database;
    await db.delete('daily_sales', where: 'id = ?', whereArgs: [id]);
  }

  // ---------------- Revenue targets ----------------

  Future<List<RevenueTarget>> getRevenueTargets() async {
    final db = await _dbh.database;
    final rows = await db.query('revenue_targets');
    return rows.map(RevenueTarget.fromMap).toList();
  }

  Future<int> addRevenueTarget(RevenueTarget t) async {
    final db = await _dbh.database;
    return db.insert('revenue_targets', t.toMap());
  }

  Future<void> updateRevenueTarget(RevenueTarget t) async {
    final db = await _dbh.database;
    await db.update('revenue_targets', t.toMap(), where: 'id = ?', whereArgs: [t.id]);
  }

  Future<void> deleteRevenueTarget(int id) async {
    final db = await _dbh.database;
    await db.delete('revenue_targets', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> resetAndReseed() => _dbh.resetAndReseed();
}
