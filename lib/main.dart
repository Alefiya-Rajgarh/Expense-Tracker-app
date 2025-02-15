import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

// Move this to the top of the file after imports
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

  // Create a currency formatter
  final currencyFormat = NumberFormat.currency(
      symbol: '₹', decimalDigits: 0, locale: 'en_IN' // Indian locale formatting
      );

  @override
  void initState() {
    super.initState();

    // Initialize with sample data for current month
    _monthlyTransactions[_currentMonth] = [
      Transaction('Salary', 4500, DateTime.now(), false),
      Transaction('Rent', 1000, DateTime.now(), true),
      Transaction('Groceries', 200, DateTime.now(), true),
    ];
    _calculateTotals();
  }

  void _calculateTotals() {
    double income = 0;
    double expense = 0;

    // Use current month's transactions
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

    // Use current month's transactions
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
                  validator: (value) {
                    if (value == null || double.tryParse(value) == null) {
                      return 'Please enter valid Transaction';
                    }
                    return null;
                  },
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
                    SnackBar(content: Text('Please enter a valid Transaction')),
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
        // Add the transaction to the current month's list
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
                  fontWeight: FontWeight.bold),
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
      drawer: Drawer(
        child: ListView(
          children: [
            DrawerHeader(
              child: Text('Select Month'),
            ),
            ..._monthlyTransactions.keys.map((month) {
              return ListTile(
                title: Text(month),
                onTap: () {
                  setState(() {
                    _currentMonth = month;
                  });
                  Navigator.pop(context);
                },
              );
            }).toList(),
            ListTile(
              title: const Text('Add New Month'),
              onTap: () {
                setState(() {
                  _currentMonth = DateFormat('MMMM yyyy')
                      .format(DateTime.now().add(Duration(days: 30)));
                  _monthlyTransactions[_currentMonth] = [];
                });
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
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

  Widget _buildTopCards() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Expanded(
            flex: 1,
            child: _buildDateCard(),
          ),
          Expanded(
            flex: 1,
            child: _buildFinanceCard('Income', _totalIncome, Colors.green),
          ),
          Expanded(
            flex: 1,
            child: _buildFinanceCard('Expense', _totalExpense, Colors.red),
          ),
        ],
      ),
    );
  }

  Widget _buildFinanceCard(String title, double amount, Color color) {
    return Expanded(
      child: Card(
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
                  if (value.toInt() >= categories.length) {
                    return const SizedBox.shrink();
                  }
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
            leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
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
                    DateFormat('dd MMM yy • hh:mm a')
                        .format(transaction.date),
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
                            fontSize: 16),
                      ),
                      IconButton(
                        icon: Icon(Icons.delete, color: Colors.blueGrey),
                        onPressed: () {
                          setState(() {
                            currentTransactions.removeAt(index);
                            _calculateTotals();
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Transaction deleted')),
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
}

class Transaction {
  final String category;
  final double amount;
  final DateTime date;
  final bool isExpense;

  Transaction(this.category, this.amount, this.date, this.isExpense);
}
