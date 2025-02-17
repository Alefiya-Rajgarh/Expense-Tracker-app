import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'storage_helper.dart';
import 'money_calculator.dart';
import 'drawer.dart';
import 'transaction.dart';

void main() {
  runApp(const FinanceApp());
}

class FinanceApp extends StatelessWidget {
  const FinanceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Expense Tracker by Alefiya',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.blueAccent,
          foregroundColor: Colors.white,
        ),
      ),
      home: const FinanceHomePage(),
    );
  }
}

class FinanceHomePage extends StatefulWidget {
  const FinanceHomePage({super.key});

  @override
  State<FinanceHomePage> createState() => _FinanceHomePageState();
}

class _FinanceHomePageState extends State<FinanceHomePage> {
  double _totalIncome = 0;
  double _totalExpense = 0;
  String _currentMonth = DateFormat('MMMM yyyy').format(DateTime.now());
  Map<String, List<Transaction>> _monthlyTransactions = {};

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    final transactions = await StorageHelper.loadTransactions();
    setState(() {
      _monthlyTransactions = transactions;
      if (!_monthlyTransactions.containsKey(_currentMonth)) {
        _monthlyTransactions[_currentMonth] = [];
      }
      _calculateTotals();
    });
  }

  Future<void> _saveTransactions() async {
    await StorageHelper.saveTransactions(_monthlyTransactions);
  }

  void _calculateTotals() {
    setState(() {
      _totalIncome = MoneyCalculator.calculateTotalIncome(_monthlyTransactions[_currentMonth] ?? []);
      _totalExpense = MoneyCalculator.calculateTotalExpense(_monthlyTransactions[_currentMonth] ?? []);
    });
  }

  void _addNewMonth() {
    final lastDate = DateFormat('MMMM yyyy').parse(_currentMonth);
    final newDate = DateTime(lastDate.year, lastDate.month + 1);
    final newMonth = DateFormat('MMMM yyyy').format(newDate);

    if (!_monthlyTransactions.containsKey(newMonth)) {
      setState(() {
        _monthlyTransactions[newMonth] = [];
        _currentMonth = newMonth;
      });
      _saveTransactions();
    }
  }

  void _deleteMonth(String month) {
    if (month != _currentMonth) {
      setState(() {
        _monthlyTransactions.remove(month);
      });
      _saveTransactions();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Expense Tracker")),
      drawer: AppDrawer(
        onMonthSelected: (month) {
          setState(() {
            _currentMonth = month;
            _calculateTotals();
          });
        },
        onAddNewMonth: _addNewMonth,
        onDeleteMonth: _deleteMonth,
        monthlyTransactions: _monthlyTransactions,
        currentMonth: _currentMonth,
      ),
      body: Center(child: Text("Dashboard here...")),
    );
  }
}
