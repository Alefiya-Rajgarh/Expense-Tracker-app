import 'package:flutter/material.dart';
import 'storage_helper.dart';
import 'package:expense_tracker/transaction.dart';

class AppDrawer extends StatelessWidget {
  final Function(String) onMonthSelected;
  final Function() onAddNewMonth;
  final Function(String) onDeleteMonth;
  final Map<String, List<Transaction>> monthlyTransactions;
  final String currentMonth;

  const AppDrawer({
    required this.onMonthSelected,
    required this.onAddNewMonth,
    required this.onDeleteMonth,
    required this.monthlyTransactions,
    required this.currentMonth,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(color: Colors.blueAccent),
            child: Center(
              child: Text(
                'Monthly Overview',
                style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: monthlyTransactions.keys.length,
              itemBuilder: (context, index) {
                final month = monthlyTransactions.keys.elementAt(index);
                return ListTile(
                  title: Text(month),
                  tileColor: month == currentMonth ? Colors.blue.shade100 : null,
                  onTap: () {
                    onMonthSelected(month);
                    Navigator.pop(context);
                  },
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => onDeleteMonth(month),
                  ),
                );
              },
            ),
          ),
          ListTile(
            leading: const Icon(Icons.add_circle_outline),
            title: const Text('Add New Month'),
            onTap: onAddNewMonth,
          ),
        ],
      ),
    );
  }
}
