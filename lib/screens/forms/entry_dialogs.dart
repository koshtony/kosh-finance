import 'package:flutter/material.dart';

import '../../models/models.dart';
import '../../services/finance_store.dart';
import '../../utils/month_utils.dart';

class _FormScaffold extends StatefulWidget {
  final String title;
  final List<Widget> Function(BuildContext context, StateSetter setState) buildFields;
  final Future<void> Function() onSave;
  final Future<void> Function()? onDelete;

  const _FormScaffold({
    required this.title,
    required this.buildFields,
    required this.onSave,
    this.onDelete,
  });

  @override
  State<_FormScaffold> createState() => _FormScaffoldState();
}

class _FormScaffoldState extends State<_FormScaffold> {
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: widget.buildFields(context, setState),
        ),
      ),
      actions: [
        if (widget.onDelete != null)
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: _saving
                ? null
                : () async {
                    setState(() => _saving = true);
                    await widget.onDelete!();
                    if (context.mounted) Navigator.pop(context);
                  },
            child: const Text('Delete'),
          ),
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _saving
              ? null
              : () async {
                  setState(() => _saving = true);
                  await widget.onSave();
                  if (context.mounted) Navigator.pop(context);
                },
          child: _saving
              ? const SizedBox(
                  width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Save'),
        ),
      ],
    );
  }
}

Widget monthYearRow({
  required int year,
  required String month,
  required ValueChanged<int> onYear,
  required ValueChanged<String> onMonth,
}) {
  return Row(
    children: [
      Expanded(
        child: DropdownButtonFormField<String>(
          initialValue: month,
          decoration: const InputDecoration(labelText: 'Month'),
          items: monthOrder
              .map((m) => DropdownMenuItem(value: m, child: Text(m)))
              .toList(),
          onChanged: (v) => onMonth(v ?? month),
        ),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: TextFormField(
          initialValue: year.toString(),
          decoration: const InputDecoration(labelText: 'Year'),
          keyboardType: TextInputType.number,
          onChanged: (v) => onYear(int.tryParse(v) ?? year),
        ),
      ),
    ],
  );
}

Widget moneyField({
  required String label,
  required double? initial,
  required ValueChanged<double?> onChanged,
}) {
  return Padding(
    padding: const EdgeInsets.only(top: 10),
    child: TextFormField(
      initialValue: initial?.toString() ?? '',
      decoration: InputDecoration(labelText: label),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      onChanged: (v) => onChanged(double.tryParse(v)),
    ),
  );
}

// ---------------- Employment income ----------------

void showEmploymentIncomeDialog(BuildContext context, FinanceStore store,
    {EmploymentIncome? existing, String? defaultSource}) {
  int year = existing?.year ?? DateTime.now().year;
  String month = existing?.month ?? monthOrder[DateTime.now().month - 1];
  String type = existing?.type ?? '';
  final sources = store.distinctIncomeSources;
  String source = existing?.source ?? defaultSource ?? (sources.isNotEmpty ? sources.first : 'Employment');
  double? expected = existing?.expected;
  double? actual = existing?.actual;

  showDialog(
    context: context,
    builder: (_) => _FormScaffold(
      title: existing == null ? 'Add income' : 'Edit income',
      buildFields: (ctx, setState) => [
        DropdownButtonFormField<String>(
          initialValue: sources.contains(source) ? source : null,
          decoration: const InputDecoration(labelText: 'Income source'),
          items: sources.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
          onChanged: (v) => setState(() => source = v ?? source),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 10),
          child: monthYearRow(
            year: year, month: month,
            onYear: (v) => setState(() => year = v),
            onMonth: (v) => setState(() => month = v),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 10),
          child: TextFormField(
            initialValue: type,
            decoration: const InputDecoration(labelText: 'Income type (e.g. Salary, Bonus)'),
            onChanged: (v) => type = v,
          ),
        ),
        moneyField(label: 'Expected', initial: expected, onChanged: (v) => expected = v),
        moneyField(label: 'Actual', initial: actual, onChanged: (v) => actual = v),
      ],
      onSave: () async {
        if (type.trim().isEmpty) return;
        final entry = EmploymentIncome(
          id: existing?.id, year: year, month: month, type: type.trim(),
          source: source, expected: expected, actual: actual,
        );
        if (existing == null) {
          await store.addEmploymentIncome(entry);
        } else {
          await store.updateEmploymentIncome(entry);
        }
      },
      onDelete: existing == null ? null : () => store.deleteEmploymentIncome(existing.id!),
    ),
  );
}

// ---------------- Employment expense ----------------

void showEmploymentExpenseDialog(BuildContext context, FinanceStore store,
    {EmploymentExpense? existing}) {
  int year = existing?.year ?? DateTime.now().year;
  String month = existing?.month ?? monthOrder[DateTime.now().month - 1];
  String item = existing?.item ?? '';
  double? estimated = existing?.estimated;
  double? actual = existing?.actual;

  showDialog(
    context: context,
    builder: (_) => _FormScaffold(
      title: existing == null ? 'Add expense' : 'Edit expense',
      buildFields: (ctx, setState) => [
        monthYearRow(
          year: year, month: month,
          onYear: (v) => setState(() => year = v),
          onMonth: (v) => setState(() => month = v),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 10),
          child: TextFormField(
            initialValue: item,
            decoration: const InputDecoration(labelText: 'Category (e.g. Rent, Food)'),
            onChanged: (v) => item = v,
          ),
        ),
        moneyField(label: 'Estimated', initial: estimated, onChanged: (v) => estimated = v),
        moneyField(label: 'Actual', initial: actual, onChanged: (v) => actual = v),
      ],
      onSave: () async {
        if (item.trim().isEmpty) return;
        final entry = EmploymentExpense(
          id: existing?.id, year: year, month: month, item: item.trim(),
          estimated: estimated, actual: actual,
        );
        if (existing == null) {
          await store.addEmploymentExpense(entry);
        } else {
          await store.updateEmploymentExpense(entry);
        }
      },
      onDelete: existing == null ? null : () => store.deleteEmploymentExpense(existing.id!),
    ),
  );
}

// ---------------- Business revenue ----------------

void showBusinessRevenueDialog(BuildContext context, FinanceStore store,
    {BusinessRevenue? existing, String? defaultBusiness}) {
  int year = existing?.year ?? DateTime.now().year;
  String month = existing?.month ?? monthOrder[DateTime.now().month - 1];
  String business = existing?.business ?? defaultBusiness ?? '';
  double? expected = existing?.expected;
  double? actual = existing?.actual;

  showDialog(
    context: context,
    builder: (_) => _FormScaffold(
      title: existing == null ? 'Add revenue' : 'Edit revenue',
      buildFields: (ctx, setState) => [
        monthYearRow(
          year: year, month: month,
          onYear: (v) => setState(() => year = v),
          onMonth: (v) => setState(() => month = v),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 10),
          child: TextFormField(
            initialValue: business,
            decoration: const InputDecoration(labelText: 'Business / source'),
            onChanged: (v) => business = v,
          ),
        ),
        moneyField(label: 'Expected', initial: expected, onChanged: (v) => expected = v),
        moneyField(label: 'Actual', initial: actual, onChanged: (v) => actual = v),
      ],
      onSave: () async {
        if (business.trim().isEmpty) return;
        final entry = BusinessRevenue(
          id: existing?.id, year: year, month: month, business: business.trim(),
          expected: expected, actual: actual,
        );
        if (existing == null) {
          await store.addBusinessRevenue(entry);
        } else {
          await store.updateBusinessRevenue(entry);
        }
      },
      onDelete: existing == null ? null : () => store.deleteBusinessRevenue(existing.id!),
    ),
  );
}

// ---------------- Business expense ----------------

void showBusinessExpenseDialog(BuildContext context, FinanceStore store,
    {BusinessExpense? existing, String? defaultBusiness}) {
  int year = existing?.year ?? DateTime.now().year;
  String month = existing?.month ?? monthOrder[DateTime.now().month - 1];
  String item = existing?.item ?? '';
  String business = existing?.business ?? defaultBusiness ?? '';
  double? estimated = existing?.estimated;
  double? actual = existing?.actual;

  showDialog(
    context: context,
    builder: (_) => _FormScaffold(
      title: existing == null ? 'Add expense' : 'Edit expense',
      buildFields: (ctx, setState) => [
        monthYearRow(
          year: year, month: month,
          onYear: (v) => setState(() => year = v),
          onMonth: (v) => setState(() => month = v),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 10),
          child: TextFormField(
            initialValue: business,
            decoration: const InputDecoration(labelText: 'Business'),
            onChanged: (v) => business = v,
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 10),
          child: TextFormField(
            initialValue: item,
            decoration: const InputDecoration(labelText: 'Category (e.g. Rent, Marketing)'),
            onChanged: (v) => item = v,
          ),
        ),
        moneyField(label: 'Estimated', initial: estimated, onChanged: (v) => estimated = v),
        moneyField(label: 'Actual', initial: actual, onChanged: (v) => actual = v),
      ],
      onSave: () async {
        if (item.trim().isEmpty || business.trim().isEmpty) return;
        final entry = BusinessExpense(
          id: existing?.id, year: year, month: month, item: item.trim(),
          business: business.trim(), estimated: estimated, actual: actual,
        );
        if (existing == null) {
          await store.addBusinessExpense(entry);
        } else {
          await store.updateBusinessExpense(entry);
        }
      },
      onDelete: existing == null ? null : () => store.deleteBusinessExpense(existing.id!),
    ),
  );
}

// ---------------- Investments ----------------

void showInvestmentDialog(BuildContext context, FinanceStore store,
    {InvestmentEntry? existing}) {
  int year = existing?.year ?? DateTime.now().year;
  String month = existing?.month ?? monthOrder[DateTime.now().month - 1];
  double? closingValue = existing?.closingValue;
  double? totalInterest = existing?.totalInterest;
  double? currentMonthIncome = existing?.currentMonthIncome;

  showDialog(
    context: context,
    builder: (_) => _FormScaffold(
      title: existing == null ? 'Add investment update' : 'Edit investment update',
      buildFields: (ctx, setState) => [
        monthYearRow(
          year: year, month: month,
          onYear: (v) => setState(() => year = v),
          onMonth: (v) => setState(() => month = v),
        ),
        moneyField(label: 'Closing value', initial: closingValue, onChanged: (v) => closingValue = v),
        moneyField(label: 'Total interest (cumulative)', initial: totalInterest, onChanged: (v) => totalInterest = v),
        moneyField(label: 'This month\'s income', initial: currentMonthIncome, onChanged: (v) => currentMonthIncome = v),
      ],
      onSave: () async {
        final entry = InvestmentEntry(
          id: existing?.id, year: year, month: month,
          closingValue: closingValue, totalInterest: totalInterest,
          currentMonthIncome: currentMonthIncome,
        );
        if (existing == null) {
          await store.addInvestment(entry);
        } else {
          await store.updateInvestment(entry);
        }
      },
      onDelete: existing == null ? null : () => store.deleteInvestment(existing.id!),
    ),
  );
}

// ---------------- Customers ----------------

void showCustomerDialog(BuildContext context, FinanceStore store, {Customer? existing}) {
  String name = existing?.name ?? '';
  String phone = existing?.phone ?? '';
  String category = existing?.category ?? '';
  double? avgSpending = existing?.avgSpending;

  showDialog(
    context: context,
    builder: (_) => _FormScaffold(
      title: existing == null ? 'Add customer' : 'Edit customer',
      buildFields: (ctx, setState) => [
        TextFormField(
          initialValue: name,
          decoration: const InputDecoration(labelText: 'Name'),
          onChanged: (v) => name = v,
        ),
        Padding(
          padding: const EdgeInsets.only(top: 10),
          child: TextFormField(
            initialValue: phone,
            decoration: const InputDecoration(labelText: 'Phone (optional)'),
            onChanged: (v) => phone = v,
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 10),
          child: TextFormField(
            initialValue: category,
            decoration: const InputDecoration(labelText: 'Category (optional)'),
            onChanged: (v) => category = v,
          ),
        ),
        moneyField(label: 'Average spending', initial: avgSpending, onChanged: (v) => avgSpending = v),
      ],
      onSave: () async {
        if (name.trim().isEmpty) return;
        final entry = Customer(
          id: existing?.id, name: name.trim(),
          phone: phone.trim().isEmpty ? null : phone.trim(),
          category: category.trim().isEmpty ? null : category.trim(),
          avgSpending: avgSpending,
        );
        if (existing == null) {
          await store.addCustomer(entry);
        } else {
          await store.updateCustomer(entry);
        }
      },
      onDelete: existing == null ? null : () => store.deleteCustomer(existing.id!),
    ),
  );
}

// ---------------- Daily sales ----------------

String formatIsoDate(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

DateTime parseIsoDate(String s) => DateTime.parse(s);

void showDailySaleDialog(BuildContext context, FinanceStore store,
    {DailySale? existing, String? defaultBusiness}) {
  DateTime date = existing != null ? parseIsoDate(existing.date) : DateTime.now();
  String business = existing?.business ?? defaultBusiness ?? '';
  double? amount = existing?.amount;
  String note = existing?.note ?? '';

  showDialog(
    context: context,
    builder: (_) => _FormScaffold(
      title: existing == null ? 'Add daily sale' : 'Edit daily sale',
      buildFields: (ctx, setState) => [
        InkWell(
          onTap: () async {
            final picked = await showDatePicker(
              context: ctx,
              initialDate: date,
              firstDate: DateTime(2020),
              lastDate: DateTime(2100),
            );
            if (picked != null) setState(() => date = picked);
          },
          child: InputDecorator(
            decoration: const InputDecoration(labelText: 'Date'),
            child: Text(formatIsoDate(date)),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 10),
          child: TextFormField(
            initialValue: business,
            decoration: const InputDecoration(labelText: 'Business name'),
            onChanged: (v) => business = v,
          ),
        ),
        moneyField(label: 'Amount sold', initial: amount, onChanged: (v) => amount = v),
        Padding(
          padding: const EdgeInsets.only(top: 10),
          child: TextFormField(
            initialValue: note,
            decoration: const InputDecoration(labelText: 'Note (optional)'),
            onChanged: (v) => note = v,
          ),
        ),
      ],
      onSave: () async {
        if (business.trim().isEmpty || amount == null) return;
        final entry = DailySale(
          id: existing?.id,
          date: formatIsoDate(date),
          business: business.trim(),
          amount: amount!,
          note: note.trim().isEmpty ? null : note.trim(),
        );
        if (existing == null) {
          await store.addDailySale(entry);
        } else {
          await store.updateDailySale(entry);
        }
      },
      onDelete: existing == null ? null : () => store.deleteDailySale(existing.id!),
    ),
  );
}
