import 'transaction.dart';

class MoneyCalculator {
  static double calculateTotalIncome(List<Transaction> transactions) {
    return transactions
        .where((transaction) => !transaction.isExpense)
        .fold(0, (sum, item) => sum + item.amount);
  }

  static double calculateTotalExpense(List<Transaction> transactions) {
    return transactions
        .where((transaction) => transaction.isExpense)
        .fold(0, (sum, item) => sum + item.amount);
  }
}
