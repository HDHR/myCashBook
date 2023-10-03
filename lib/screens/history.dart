// ignore_for_file: use_build_context_synchronously

import 'package:currency_text_input_formatter/currency_text_input_formatter.dart';
import 'package:flutter/material.dart';
import 'package:myCashBook/models/transaction.dart';
import 'package:myCashBook/services/data_service.dart';
import 'package:intl/intl.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({Key? key, required this.dataService}) : super(key: key);
  static const String routeName = '/history';
  final DataService dataService;

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late List<Transaction> transactions = [];

  @override
  void initState() {
    super.initState();
    loadTransactions().whenComplete(() {
      setState(() {});
    });
  }

  Future<void> loadTransactions() async {
    try {
      final loadedTransactions = await widget.dataService.getTransactions();
      setState(() {
        transactions = loadedTransactions;
      });
    } catch (e) {
      // Handle error loading transactions
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () {
            Navigator.of(context).pushNamedAndRemoveUntil(
              '/home',
              (route) => false,
            );
          },
          icon: const Icon(Icons.home),
        ),
        title: const Text('History'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: transactions.isEmpty
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.history,
                      size: 100,
                      color: Colors.grey,
                    ),
                    SizedBox(height: 20),
                    Text(
                      'No transaction history',
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                  ],
                ),
              )
            : ListView.builder(
                itemCount: transactions.length,
                itemBuilder: (context, index) {
                  final transaction = transactions[index];

                  final amount = NumberFormat.currency(
                    locale: 'id',
                    symbol: 'Rp. ',
                    decimalDigits: 0,
                  ).format(transaction.amount);

                  return TransactionItem(
                    id: transaction.id,
                    date: DateFormat('dd MMM yyyy').format(transaction.date),
                    amount: amount,
                    description: transaction.description,
                    isIncome: transaction.type == 'Income',
                    dataService: widget.dataService,
                    transactionObj: transaction,
                  );
                },
              ),
      ),
    );
  }
}

class TransactionItem extends StatelessWidget {
  final int id;
  final String date;
  final String amount;
  final String description;
  final bool isIncome;
  final DataService dataService;
  final Transaction transactionObj;

  const TransactionItem({
    Key? key,
    required this.id,
    required this.date,
    required this.amount,
    required this.description,
    required this.isIncome,
    required this.dataService,
    required this.transactionObj,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    String selectedType = transactionObj.type;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Card(
        elevation: 2,
        margin: const EdgeInsets.symmetric(vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Dismissible(
          key: Key(id.toString()),
          background: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.red,
            ),
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.only(left: 20),
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          secondaryBackground: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.blue,
            ),
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            child: const Icon(Icons.edit, color: Colors.white),
          ),
          confirmDismiss: (direction) async {
            if (direction == DismissDirection.startToEnd) {
              return await showDialog<bool>(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    title: const Text('Delete Transaction'),
                    content: const Text(
                      'Are you sure you want to delete this transaction?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop(false);
                        },
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () async {
                          await dataService.deleteTransaction(id);
                          Navigator.of(context).pop(true);
                        },
                        child: const Text('Delete'),
                      ),
                    ],
                  );
                },
              );
            } else if (direction == DismissDirection.endToStart) {
              return _updateTransaction(context, transactionObj, selectedType);
            }
            return false;
          },
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: isIncome ? Colors.green : Colors.red,
              child: Icon(
                isIncome ? Icons.arrow_upward : Icons.arrow_downward,
                color: Colors.white,
              ),
            ),
            title:
                Text(description, maxLines: 1, overflow: TextOverflow.ellipsis),
            subtitle: Text(date),
            trailing: Text(amount),
          ),
        ),
      ),
    );
  }

  Future<bool> _updateTransaction(BuildContext context, Transaction transaction,
      String selectedType) async {
    final dateController = TextEditingController(
        text: DateFormat('dd MMM yyyy').format(transaction.date));

    final amountController = TextEditingController(
        text: NumberFormat.currency(
      locale: 'id',
      symbol: 'Rp. ',
      decimalDigits: 0,
    ).format(transaction.amount));

    final descriptionController =
        TextEditingController(text: transaction.description);

    final formKey = GlobalKey<FormState>();

    bool isProcessing = false;
    bool isDone = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                DropdownButtonFormField<String>(
                  value: selectedType,
                  onChanged: (value) {
                    selectedType = value!;
                  },
                  items: ['Income', 'Expense'].map((String type) {
                    return DropdownMenuItem<String>(
                      value: type,
                      child: Text(type),
                    );
                  }).toList(),
                  decoration: const InputDecoration(labelText: 'Type'),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  key: const Key('editTransaction_dateInput'),
                  controller: dateController,
                  decoration: const InputDecoration(
                    icon: Icon(Icons.calendar_today),
                    labelText: 'Date',
                    errorMaxLines: 3,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter date';
                    }
                    return null;
                  },
                  textInputAction: TextInputAction.done,
                  onTap: () async {
                    DateTime? pickedDate = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2015),
                      lastDate: DateTime(2100),
                    );
                    if (pickedDate != null) {
                      String formattedDate =
                          DateFormat('dd MMM yyyy').format(pickedDate);
                      dateController.text = formattedDate;
                    } else {
                      dateController.text = dateController.text;
                    }
                    FocusScope.of(context).requestFocus(FocusNode());
                  },
                ),
                const SizedBox(height: 10),
                TextFormField(
                  key: const Key('editTransaction_amountInput'),
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    CurrencyTextInputFormatter(
                      locale: 'id',
                      decimalDigits: 0,
                      symbol: 'Rp. ',
                    ),
                  ],
                  decoration: const InputDecoration(
                    icon: Icon(Icons.attach_money),
                    labelText: 'Amount',
                    errorMaxLines: 2,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter amount';
                    }
                    return null;
                  },
                  textInputAction: TextInputAction.done,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  key: const Key('editTransaction_descriptionInput'),
                  maxLines: 2,
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    icon: Icon(Icons.description),
                    labelText: 'Description',
                    errorMaxLines: 2,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter description';
                    } else if (value.length < 3) {
                      return 'Description must be at least 3 characters';
                    }
                    return null;
                  },
                  textInputAction: TextInputAction.done,
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ElevatedButton(
                      onPressed: isProcessing
                          ? null
                          : () async {
                              isProcessing = true;
                              if (formKey.currentState!.validate()) {
                                String amount = amountController.text
                                    .replaceAll('Rp. ', '');
                                amount = amount.replaceAll('.', '');
                                int formattedAmount = int.parse(amount);
                                isDone = await dataService.updateTransaction(
                                  transaction.id,
                                  DateFormat('dd MMM yyyy')
                                      .parse(dateController.text),
                                  formattedAmount,
                                  descriptionController.text,
                                  selectedType,
                                );

                                if (isDone) {
                                  Navigator.of(context).pushNamedAndRemoveUntil(
                                    '/home',
                                    (route) => false,
                                  );
                                } else {
                                  // show snackbar
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content:
                                          Text('Failed to update transaction'),
                                    ),
                                  );
                                  Navigator.pop(context, false);
                                }
                              }
                            },
                      child: const Text('Update'),
                    ),
                    ElevatedButton(
                      onPressed: isProcessing
                          ? null
                          : () {
                              Navigator.pop(context, false);
                            },
                      child: const Text('Cancel'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
    return false; // Update success
  }
}
