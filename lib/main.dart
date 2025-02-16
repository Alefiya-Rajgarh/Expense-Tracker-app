import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

enum TransactionType { income, expense }

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
  final TextEditingController _amountController = TextEditingController();
  String _selectedCategory = 'Food';
  DateTime _selectedDate = DateTime.now();
  TransactionType _transactionType = TransactionType.expense;

  final List<String> _categories = [
    'Food',
    'Housing',
    'Transport',
    'Entertainment',
    'Utilities',
    'Salary',
    'Investment',
    "Other"
  ];

  Map<String, List<Transaction>> _monthlyTransactions = {};
  String _currentMonth = DateFormat('MMMM yyyy').format(DateTime.now());

  final currencyFormat =
      NumberFormat.currency(symbol: '₹', decimalDigits: 0, locale: 'en_IN');

  @override
  void initState() {
    super.initState();
    _monthlyTransactions.clear();
    _currentMonth = DateFormat('MMMM yyyy').format(DateTime.now());
    _monthlyTransactions[_currentMonth] = [];
    _calculateTotals();
  }

  void _calculateTotals() {
    double income = 0;
    double expense = 0;

    _monthlyTransactions[_currentMonth]?.forEach((transaction) {
      if (transaction.isExpense) {
        expense += transaction.amount;
      } else {
        income += transaction.amount;
      }
    });

    setState(() {
      _totalIncome = income;
      _totalExpense = expense;
    });
  }

  Map<String, double> _getSpendingData() {
    Map<String, double> spendingData = {};
    _monthlyTransactions[_currentMonth]
        ?.where((t) => t.isExpense)
        .forEach((transaction) {
      spendingData.update(
        transaction.category,
        (value) => value + transaction.amount,
        ifAbsent: () => transaction.amount,
      );
    });
    return spendingData;
  }

  List<BarChartGroupData> _getChartData() {
    final spendingData = _getSpendingData();
    final categories = spendingData.keys.toList();

    return List.generate(categories.length, (index) {
      final category = categories[index];
      final amount = spendingData[category] ?? 0;

      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: amount,
            color: _getCategoryColor(category),
            width: 25,
          ),
        ],
      );
    });
  }

  Color _getCategoryColor(String category) {
    const colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
    ];
    return colors[_categories.indexOf(category) % colors.length];
  }

  Future<void> _addNewTransaction() async {
    final result = await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add Transaction'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  items: _categories.map((category) {
                    return DropdownMenuItem(
                      value: category,
                      child: Text(category),
                    );
                  }).toList(),
                  onChanged: (value) =>
                      setState(() => _selectedCategory = value!),
                ),
                TextFormField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Amount'),
                ),
                Row(
                  children: [
                    Flexible(
                      child: RadioListTile<TransactionType>(
                        title: const Text('Income'),
                        value: TransactionType.income,
                        groupValue: _transactionType,
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        onChanged: (value) =>
                            setState(() => _transactionType = value!),
                        activeColor: Colors.green,
                      ),
                    ),
                    Flexible(
                      child: RadioListTile<TransactionType>(
                        title: const Text('Expense'),
                        value: TransactionType.expense,
                        groupValue: _transactionType,
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        onChanged: (value) =>
                            setState(() => _transactionType = value!),
                        activeColor: Colors.red,
                      ),
                    ),
                  ],
                ),
                ListTile(
                  title: Text(DateFormat.yMMMd().format(_selectedDate)),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate,
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) {
                      setState(() => _selectedDate = date);
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (_amountController.text.isEmpty ||
                    double.tryParse(_amountController.text) == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter valid amount')),
                  );
                  return;
                }
                Navigator.pop(context, true);
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );

    if (result == true) {
      final newTransaction = Transaction(
        _selectedCategory,
        double.parse(_amountController.text),
        DateTime.now(),
        _transactionType == TransactionType.expense,
      );

      setState(() {
        _monthlyTransactions[_currentMonth]!.add(newTransaction);
        _monthlyTransactions[_currentMonth]!
            .sort((a, b) => b.date.compareTo(a.date));
        _calculateTotals();
        _amountController.clear();
      });
    }
  }

  void _showWalletBalance() {
    final remaining = _totalIncome - _totalExpense;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Wallet Balance'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildBalanceRow('Total Income', _totalIncome, Colors.green),
            _buildBalanceRow('Total Expenses', _totalExpense, Colors.red),
            const Divider(),
            _buildBalanceRow('Remaining Balance', remaining,
                remaining >= 0 ? Colors.blue : Colors.orange),
            const SizedBox(height: 10),
            Text(
              remaining >= 0
                  ? 'You have ${currencyFormat.format(remaining)} left to spend'
                  : 'You overspent by ${currencyFormat.format(-remaining)}',
              style: TextStyle(
                color: remaining >= 0 ? Colors.green : Colors.red,
                fontWeight: FontWeight.bold,
              ),
            )
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceRow(String label, double amount, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            currencyFormat.format(amount),
            style: TextStyle(color: color, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Map<String, double> _getMonthlyTotals(String month) {
    double income = 0;
    double expense = 0;

    _monthlyTransactions[month]?.forEach((transaction) {
      if (transaction.isExpense) {
        expense += transaction.amount;
      } else {
        income += transaction.amount;
      }
    });

    return {'income': income, 'expense': expense};
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Expense Tracker By Alefiya",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_balance_wallet),
            onPressed: _showWalletBalance,
          ),
        ],
      ),
      drawer: _buildDrawer(),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildTopCards(),
            _buildSpendingChart(),
            _buildTransactionList(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addNewTransaction,
        tooltip: 'Add Transaction',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: Column(
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(color: Colors.blueAccent),
            child: Center(
              child: Text(
                'Monthly Overview',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView.separated(
              itemCount: _monthlyTransactions.keys.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final month = _monthlyTransactions.keys.elementAt(index);
                final totals = _getMonthlyTotals(month);
                final isCurrentMonth = month == _currentMonth;
                final isDeletable = month != _currentMonth;

                return ListTile(
                  tileColor: isCurrentMonth ? Colors.blue.shade50 : null,
                  leading: const Icon(Icons.calendar_month),
                  title: Text(
                    month,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Income: ${currencyFormat.format(totals['income'])}',
                        style: TextStyle(
                          color: Colors.green.shade600,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        'Expense: ${currencyFormat.format(totals['expense'])}',
                        style: TextStyle(
                          color: Colors.red.shade600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isDeletable)
                        IconButton(
                          icon: const Icon(Icons.delete, size: 20),
                          color: Colors.red.shade300,
                          onPressed: () => _confirmDeleteMonth(context, month),
                        ),
                      const Icon(Icons.chevron_right, size: 20),
                    ],
                  ),
                  onTap: () {
                    setState(() => _currentMonth = month);
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.add_circle_outline),
            title: const Text('Add Next Month'),
            onTap: _addNewMonth,
          ),
        ],
      ),
    );
  }

  Widget _buildTopCards() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Expanded(child: _buildDateCard()),
          Expanded(
              child: _buildFinanceCard('Income', _totalIncome, Colors.green)),
          Expanded(
              child: _buildFinanceCard('Expense', _totalExpense, Colors.red)),
        ],
      ),
    );
  }

  Widget _buildFinanceCard(String title, double amount, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              style: TextStyle(color: color, fontSize: 18),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              currencyFormat.format(amount),
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                DateFormat('EEEE').format(DateTime.now()),
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              DateFormat('dd MMM yy').format(DateTime.now()),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpendingChart() {
    return SizedBox(
      height: 200,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: (_getSpendingData().isNotEmpty
              ? _getSpendingData().values.reduce((a, b) => a > b ? a : b) * 1.2
              : 1000),
          barTouchData: BarTouchData(enabled: false),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final categories = _getSpendingData().keys.toList();
                  if (value.toInt() >= categories.length)
                    return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      categories[value.toInt()],
                      style: const TextStyle(fontSize: 12),
                    ),
                  );
                },
              ),
            ),
            leftTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          barGroups: _getChartData(),
        ),
      ),
    );
  }

  Widget _buildTransactionList() {
    final currentTransactions = _monthlyTransactions[_currentMonth] ?? [];

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Recent Transactions',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: currentTransactions.length,
            itemBuilder: (context, index) {
              final transaction = currentTransactions[index];
              final color = transaction.isExpense ? Colors.red : Colors.green;

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 4),
                color: color.shade50,
                child: ListTile(
                  leading: Icon(
                    transaction.isExpense
                        ? Icons.arrow_downward
                        : Icons.arrow_upward,
                    color: color,
                  ),
                  title: Text(
                    transaction.category,
                    style: TextStyle(color: color, fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    DateFormat('dd MMM yy • hh:mm a').format(transaction.date),
                    style: TextStyle(
                      color: color.withOpacity(0.7),
                      fontSize: 13,
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        currencyFormat.format(transaction.amount),
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.blueGrey),
                        onPressed: () {
                          setState(() {
                            currentTransactions.removeAt(index);
                            _calculateTotals();
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Transaction deleted')),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
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
    }
  }

  void _confirmDeleteMonth(BuildContext context, String month) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Month?'),
        content:
            Text('All transactions for $month will be permanently deleted'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _monthlyTransactions.remove(month);
                if (_currentMonth == month) {
                  _currentMonth = _monthlyTransactions.keys.last;
                }
              });
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.blueGrey)),
          ),
        ],
      ),
    );
  }
}

class Transaction {
  final String category;
  final double amount;
  final DateTime date;
  final bool isExpense;

  Transaction(this.category, this.amount, this.date, this.isExpense);
}
