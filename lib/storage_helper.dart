import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'transaction.dart';

class StorageHelper {
  static const String _transactionsKey = 'transactions_data';

  static Future<void> saveTransactions(Map<String, List<Transaction>> transactions) async {
    final prefs = await SharedPreferences.getInstance();
    final transactionsJson = jsonEncode(
      transactions.map((key, value) => MapEntry(key, value.map((t) => t.toJson()).toList())),
    );
    await prefs.setString(_transactionsKey, transactionsJson);
  }

  static Future<Map<String, List<Transaction>>> loadTransactions() async {
    final prefs = await SharedPreferences.getInstance();
    final transactionsJson = prefs.getString(_transactionsKey);

    if (transactionsJson == null) return {};

    final Map<String, dynamic> decoded = jsonDecode(transactionsJson);
    return decoded.map((key, value) => MapEntry(
      key,
      (value as List).map((t) => Transaction.fromJson(t)).toList(),
    ));
  }
}
