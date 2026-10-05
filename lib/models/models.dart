class EmploymentIncome {
  final int? id;
  final int year;
  final String month;
  final String type;
  final String source;
  final double? expected;
  final double? actual;

  EmploymentIncome({
    this.id,
    required this.year,
    required this.month,
    required this.type,
    this.source = 'Employment',
    this.expected,
    this.actual,
  });

  factory EmploymentIncome.fromMap(Map<String, dynamic> m) => EmploymentIncome(
        id: m['id'] as int?,
        year: m['year'] as int,
        month: m['month'] as String,
        type: m['type'] as String,
        source: (m['source'] as String?) ?? 'Employment',
        expected: (m['expected'] as num?)?.toDouble(),
        actual: (m['actual'] as num?)?.toDouble(),
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'year': year,
        'month': month,
        'source': source,
        'type': type,
        'expected': expected,
        'actual': actual,
      };
}

class EmploymentExpense {
  final int? id;
  final int year;
  final String month;
  final String item;
  final double? estimated;
  final double? actual;

  EmploymentExpense({
    this.id,
    required this.year,
    required this.month,
    required this.item,
    this.estimated,
    this.actual,
  });

  factory EmploymentExpense.fromMap(Map<String, dynamic> m) => EmploymentExpense(
        id: m['id'] as int?,
        year: m['year'] as int,
        month: m['month'] as String,
        item: m['item'] as String,
        estimated: (m['estimated'] as num?)?.toDouble(),
        actual: (m['actual'] as num?)?.toDouble(),
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'year': year,
        'month': month,
        'item': item,
        'estimated': estimated,
        'actual': actual,
      };
}

class BusinessRevenue {
  final int? id;
  final int year;
  final String month;
  final String business;
  final double? expected;
  final double? actual;

  BusinessRevenue({
    this.id,
    required this.year,
    required this.month,
    required this.business,
    this.expected,
    this.actual,
  });

  factory BusinessRevenue.fromMap(Map<String, dynamic> m) => BusinessRevenue(
        id: m['id'] as int?,
        year: m['year'] as int,
        month: m['month'] as String,
        business: m['business'] as String,
        expected: (m['expected'] as num?)?.toDouble(),
        actual: (m['actual'] as num?)?.toDouble(),
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'year': year,
        'month': month,
        'business': business,
        'expected': expected,
        'actual': actual,
      };
}

class BusinessExpense {
  final int? id;
  final int year;
  final String month;
  final String item;
  final String business;
  final double? estimated;
  final double? actual;

  BusinessExpense({
    this.id,
    required this.year,
    required this.month,
    required this.item,
    required this.business,
    this.estimated,
    this.actual,
  });

  factory BusinessExpense.fromMap(Map<String, dynamic> m) => BusinessExpense(
        id: m['id'] as int?,
        year: m['year'] as int,
        month: m['month'] as String,
        item: m['item'] as String,
        business: m['business'] as String,
        estimated: (m['estimated'] as num?)?.toDouble(),
        actual: (m['actual'] as num?)?.toDouble(),
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'year': year,
        'month': month,
        'item': item,
        'business': business,
        'estimated': estimated,
        'actual': actual,
      };
}

class InvestmentEntry {
  final int? id;
  final int year;
  final String month;
  final double? closingValue;
  final double? totalInterest;
  final double? currentMonthIncome;

  InvestmentEntry({
    this.id,
    required this.year,
    required this.month,
    this.closingValue,
    this.totalInterest,
    this.currentMonthIncome,
  });

  factory InvestmentEntry.fromMap(Map<String, dynamic> m) => InvestmentEntry(
        id: m['id'] as int?,
        year: m['year'] as int,
        month: m['month'] as String,
        closingValue: (m['closingValue'] as num?)?.toDouble(),
        totalInterest: (m['totalInterest'] as num?)?.toDouble(),
        currentMonthIncome: (m['currentMonthIncome'] as num?)?.toDouble(),
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'year': year,
        'month': month,
        'closingValue': closingValue,
        'totalInterest': totalInterest,
        'currentMonthIncome': currentMonthIncome,
      };
}

class Customer {
  final int? id;
  final String name;
  final String? phone;
  final String? category;
  final double? avgSpending;

  Customer({
    this.id,
    required this.name,
    this.phone,
    this.category,
    this.avgSpending,
  });

  factory Customer.fromMap(Map<String, dynamic> m) => Customer(
        id: m['id'] as int?,
        name: m['name'] as String,
        phone: m['phone'] as String?,
        category: m['category'] as String?,
        avgSpending: (m['avgSpending'] as num?)?.toDouble(),
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'name': name,
        'phone': phone,
        'category': category,
        'avgSpending': avgSpending,
      };
}

/// status: 'visited' | 'missed' | null (no data yet)
class CustomerCheckin {
  final int? id;
  final int customerId;
  final String month;
  final int week;
  final String? status;

  CustomerCheckin({
    this.id,
    required this.customerId,
    required this.month,
    required this.week,
    this.status,
  });

  factory CustomerCheckin.fromMap(Map<String, dynamic> m) => CustomerCheckin(
        id: m['id'] as int?,
        customerId: m['customerId'] as int,
        month: m['month'] as String,
        week: m['week'] as int,
        status: m['status'] as String?,
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'customerId': customerId,
        'month': month,
        'week': week,
        'status': status,
      };
}

class RevenueTarget {
  final int? id;
  final String month;
  final double? target;
  final double? actual;

  RevenueTarget({this.id, required this.month, this.target, this.actual});

  factory RevenueTarget.fromMap(Map<String, dynamic> m) => RevenueTarget(
        id: m['id'] as int?,
        month: m['month'] as String,
        target: (m['target'] as num?)?.toDouble(),
        actual: (m['actual'] as num?)?.toDouble(),
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'month': month,
        'target': target,
        'actual': actual,
      };
}

/// A named, trackable source of personal income (e.g. "Employment",
/// "Freelance", "Rental") — managed from Settings, selected when logging
/// [EmploymentIncome] entries.
class IncomeSource {
  final int? id;
  final String name;

  IncomeSource({this.id, required this.name});

  factory IncomeSource.fromMap(Map<String, dynamic> m) => IncomeSource(
        id: m['id'] as int?,
        name: m['name'] as String,
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'name': name,
      };
}

/// A named business — managed from Settings so a new business can be
/// created before it has any revenue, expense, or daily sale entries yet.
class BusinessEntity {
  final int? id;
  final String name;

  BusinessEntity({this.id, required this.name});

  factory BusinessEntity.fromMap(Map<String, dynamic> m) => BusinessEntity(
        id: m['id'] as int?,
        name: m['name'] as String,
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'name': name,
      };
}

/// A single day's sales entry for one business — the quick, frequent-entry
/// counterpart to the monthly [BusinessRevenue] budget rows.
class DailySale {
  final int? id;
  final String date; // ISO 'yyyy-MM-dd', sortable as plain text
  final String business;
  final double amount;
  final String? note;

  DailySale({
    this.id,
    required this.date,
    required this.business,
    required this.amount,
    this.note,
  });

  factory DailySale.fromMap(Map<String, dynamic> m) => DailySale(
        id: m['id'] as int?,
        date: m['date'] as String,
        business: m['business'] as String,
        amount: (m['amount'] as num).toDouble(),
        note: m['note'] as String?,
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'date': date,
        'business': business,
        'amount': amount,
        'note': note,
      };
}

/// All pages that can be independently granted to a non-admin user.
/// Settings/account is deliberately excluded: every logged-in user keeps
/// access to their own account controls regardless of this list.
const List<String> kAppPageKeys = [
  'dashboard',
  'employment',
  'business',
  'investments',
  'customers',
];

const Map<String, String> kAppPageLabels = {
  'dashboard': 'Dashboard',
  'employment': 'Sources',
  'business': 'Business',
  'investments': 'Invest',
  'customers': 'Customers',
};

class AppUser {
  final int? id;
  final String username;
  final String passwordHash;
  final String passwordSalt;
  final bool isAdmin;
  final List<String> allowedPages;

  AppUser({
    this.id,
    required this.username,
    required this.passwordHash,
    required this.passwordSalt,
    required this.isAdmin,
    required this.allowedPages,
  });

  bool canAccess(String pageKey) => isAdmin || allowedPages.contains(pageKey);

  factory AppUser.fromMap(Map<String, dynamic> m) => AppUser(
        id: m['id'] as int?,
        username: m['username'] as String,
        passwordHash: m['passwordHash'] as String,
        passwordSalt: m['passwordSalt'] as String,
        isAdmin: (m['isAdmin'] as int) == 1,
        allowedPages: ((m['allowedPages'] as String?) ?? '')
            .split(',')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList(),
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'username': username,
        'passwordHash': passwordHash,
        'passwordSalt': passwordSalt,
        'isAdmin': isAdmin ? 1 : 0,
        'allowedPages': allowedPages.join(','),
      };
}
