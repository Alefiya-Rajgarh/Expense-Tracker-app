class Transaction {
  final String category;
  final double amount;
  final DateTime date;
  final bool isExpense;

  Transaction(this.category, this.amount, this.date, this.isExpense);

  // Convert object to JSON for saving
  Map<String, dynamic> toJson() {
    return {
      'category': category,
      'amount': amount,
      'date': date.toIso8601String(),
      'isExpense': isExpense,
    };
  }

  // Convert JSON to object when loading
  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      json['category'],
      json['amount'],
      DateTime.parse(json['date']),
      json['isExpense'],
    );
  }
}
