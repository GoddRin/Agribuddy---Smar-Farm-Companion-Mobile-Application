const List<String> expenseCategories = [
  'Seeds', 'Fertilizer', 'Pesticides',
  'Labor', 'Transport', 'Equipment', 'Other',
];

class ExpenseItem {
  final String id;
  final String category;
  final double amount;
  final String date;   // yyyy-MM-dd
  final String note;
  bool isSynced;

  ExpenseItem({
    required this.id,
    required this.category,
    required this.amount,
    required this.date,
    required this.note,
    this.isSynced = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id, 'category': category,
    'amount': amount, 'date': date, 'note': note,
    'isSynced': isSynced,
  };

  factory ExpenseItem.fromJson(Map<String, dynamic> j) => ExpenseItem(
    id: j['id'], category: j['category'] ?? 'Other',
    amount: (j['amount'] as num).toDouble(),
    date: j['date'], note: j['note'] ?? '',
    isSynced: j['isSynced'] ?? false,
  );
}
