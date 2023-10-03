import 'package:currency_text_input_formatter/currency_text_input_formatter.dart';
import 'package:myCashBook/services/data_service.dart';
import 'package:flutter/material.dart';
import 'package:formz/formz.dart';
import 'package:intl/intl.dart';

class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({
    Key? key,
    required this.transactionType,
    required this.dataService,
  }) : super(key: key);
  static const String routeName = '/add_transaction';
  final DataService dataService;
  // ignore: prefer_typing_uninitialized_variables
  final transactionType;

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _key = GlobalKey<FormState>();
  late AddTransactionFormState _state;
  late final TextEditingController _dateController;
  late final TextEditingController _amountController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _transactionTypeController;

  void _onDateChanged() {
    setState(() {
      _state = _state.copyWith(date: Date.dirty(_dateController.text));
    });
  }

  void _onAmountChanged() {
    setState(() {
      _state = _state.copyWith(amount: Amount.dirty(_amountController.text));
    });
  }

  void _onDescriptionChanged() {
    setState(() {
      _state = _state.copyWith(
        description: Description.dirty(_descriptionController.text),
      );
    });
  }

  void _onTransactionTypeChanged() {
    setState(() {
      _state = _state.copyWith(
        transactionType: TransactionType.dirty(_transactionTypeController.text),
      );
    });
  }

  Future<void> onSubmit() async {
    if (!_key.currentState!.validate()) return;

    setState(() {
      _state = _state.copyWith(status: FormzSubmissionStatus.inProgress);
    });

    await Future.delayed(const Duration(seconds: 2));

    try {
      DateTime formattedDate =
          DateFormat('dd MMM yyyy').parse(_state.date.value);
      String amount = _state.amount.value.replaceAll('Rp. ', '');
      amount = amount.replaceAll('.', '');
      int formattedAmount = int.parse(amount);

      if (widget.transactionType == null) {
        throw Exception('Transaction type is null');
      }

      final transactionAdded = await widget.dataService.addTransaction(
        formattedDate,
        formattedAmount,
        _state.description.value,
        widget.transactionType,
      );

      if (transactionAdded) {
        _state = _state.copyWith(status: FormzSubmissionStatus.success);
      } else {
        _state = _state.copyWith(status: FormzSubmissionStatus.failure);
      }
    } catch (_) {
      _state = _state.copyWith(status: FormzSubmissionStatus.failure);
    }

    if (!mounted) return;

    setState(() {});

    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context)
        ..nextFocus()
        ..unfocus();
    });

    const successSnackBar = SnackBar(
      content: Text('Transaction added successfully! 🎉'),
    );
    const failureSnackBar = SnackBar(
      content: Text('Transaction failed to add! 😢'),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      _state.status.isSuccess ? successSnackBar : failureSnackBar,
    );

    if (_state.status.isSuccess) _resetForm();
  }

  void _resetForm() {
    _key.currentState!.reset();
    _dateController.clear();
    _amountController.clear();
    _descriptionController.clear();
    _transactionTypeController.text = widget.transactionType;
    setState(() => _state = AddTransactionFormState());
  }

  @override
  void initState() {
    super.initState();
    _state = AddTransactionFormState();
    _dateController = TextEditingController(text: _state.date.value)
      ..addListener(_onDateChanged);
    _amountController = TextEditingController(text: _state.amount.value)
      ..addListener(_onAmountChanged);
    _descriptionController =
        TextEditingController(text: _state.description.value)
          ..addListener(_onDescriptionChanged);
    _transactionTypeController =
        TextEditingController(text: widget.transactionType)
          ..addListener(_onTransactionTypeChanged);
  }

  @override
  void dispose() {
    _dateController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    _transactionTypeController.dispose();
    super.dispose();
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
        title: Text('Add ${widget.transactionType} Transaction'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Form(
            key: _key,
            child: Column(
              children: [
                const SizedBox(height: 16),
                TextFormField(
                  controller: _transactionTypeController,
                  enabled: false,
                  decoration: const InputDecoration(
                    labelText: 'Transaction Type',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) =>
                      _state.transactionType.validator(value ?? '')?.text(),
                  textInputAction: TextInputAction.done,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  key: const Key('addTransaction_dateInput'),
                  controller: _dateController,
                  decoration: const InputDecoration(
                    icon: Icon(Icons.calendar_today),
                    labelText: 'Date',
                    errorMaxLines: 3,
                  ),
                  validator: (value) =>
                      _state.date.validator(value ?? '')?.text(),
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
                      setState(() {
                        _dateController.text = formattedDate;
                      });
                    } else {
                      setState(() {
                        _dateController.text = _dateController.text;
                      });
                    }
                    setState(() {
                      FocusScope.of(context).requestFocus(FocusNode());
                    });
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  key: const Key('addTransaction_amountInput'),
                  controller: _amountController,
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
                  validator: (value) =>
                      _state.amount.validator(value ?? '')?.text(),
                  textInputAction: TextInputAction.done,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  key: const Key('addTransaction_descriptionInput'),
                  maxLines: 2,
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    icon: Icon(Icons.description),
                    labelText: 'Description',
                    errorMaxLines: 2,
                  ),
                  validator: (value) =>
                      _state.description.validator(value ?? '')?.text(),
                  textInputAction: TextInputAction.done,
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    if (_state.status.isInProgress)
                      const CircularProgressIndicator()
                    else
                      ElevatedButton(
                        key: const Key('addTransactionForm_submit'),
                        onPressed: onSubmit,
                        child: const Text(' Add '),
                      ),
                    ElevatedButton(
                      onPressed: _state.status.isInProgress ? null : _resetForm,
                      style: ButtonStyle(
                        backgroundColor: MaterialStateProperty.all<Color>(
                          Colors.redAccent,
                        ),
                      ),
                      child: const Text('Reset'),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}

enum TransactionTypeValidationError { invalid, empty }

class TransactionType extends FormzInput<String, TransactionTypeValidationError>
    with FormzInputErrorCacheMixin {
  TransactionType.pure([super.value = '']) : super.pure();

  TransactionType.dirty([super.value = '']) : super.dirty();

  @override
  TransactionTypeValidationError? validator(String value) {
    if (value.isEmpty) {
      return TransactionTypeValidationError.empty;
    }
    if (value != 'Income' && value != 'Expense') {
      return TransactionTypeValidationError.invalid;
    }

    return null;
  }
}

enum DateValidationError { invalid, empty }

class Date extends FormzInput<String, DateValidationError>
    with FormzInputErrorCacheMixin {
  Date.pure([super.value = '']) : super.pure();

  Date.dirty([super.value = '']) : super.dirty();

  @override
  DateValidationError? validator(String value) {
    if (value.isEmpty) {
      return DateValidationError.empty;
    }
    try {
      DateFormat('dd MMM yyyy').parse(value);
    } catch (e) {
      return DateValidationError.invalid;
    }

    return null;
  }
}

enum AmountValidationError { invalid, empty }

class Amount extends FormzInput<String, AmountValidationError>
    with FormzInputErrorCacheMixin {
  Amount.pure([super.value = '']) : super.pure();

  Amount.dirty([super.value = '']) : super.dirty();

  @override
  AmountValidationError? validator(String value) {
    if (value.isEmpty) {
      return AmountValidationError.empty;
    }

    try {
      value = value.replaceAll('Rp. ', '');
      value = value.replaceAll('.', '');
      double.parse(value);
    } catch (e) {
      return AmountValidationError.invalid;
    }

    return null;
  }
}

enum DescriptionValidationError { invalid, empty }

class Description extends FormzInput<String, DescriptionValidationError>
    with FormzInputErrorCacheMixin {
  Description.pure([super.value = '']) : super.pure();

  Description.dirty([super.value = '']) : super.dirty();

  @override
  DescriptionValidationError? validator(String value) {
    if (value.isEmpty) {
      return DescriptionValidationError.empty;
    } else if (value.length < 3) {
      return DescriptionValidationError.invalid;
    }

    return null;
  }
}

class AddTransactionFormState with FormzMixin {
  AddTransactionFormState({
    Date? date,
    Amount? amount,
    Description? description,
    TransactionType? transactionType,
    this.status = FormzSubmissionStatus.initial,
  })  : date = date ?? Date.pure(),
        amount = amount ?? Amount.pure(),
        description = description ?? Description.pure(),
        transactionType = transactionType ?? TransactionType.pure();

  final Date date;
  final Amount amount;
  final Description description;
  final TransactionType transactionType;
  final FormzSubmissionStatus status;

  AddTransactionFormState copyWith({
    Date? date,
    Amount? amount,
    Description? description,
    TransactionType? transactionType,
    FormzSubmissionStatus? status,
  }) {
    return AddTransactionFormState(
      date: date ?? this.date,
      amount: amount ?? this.amount,
      description: description ?? this.description,
      transactionType: transactionType ?? this.transactionType,
      status: status ?? this.status,
    );
  }

  @override
  List<FormzInput<dynamic, dynamic>> get inputs =>
      [date, amount, description, transactionType];
}

extension on DateValidationError {
  String text() {
    switch (this) {
      case DateValidationError.invalid:
        return 'Invalid date';
      case DateValidationError.empty:
        return 'Please enter a date';
    }
  }
}

extension on AmountValidationError {
  String text() {
    switch (this) {
      case AmountValidationError.invalid:
        return 'Invalid amount';
      case AmountValidationError.empty:
        return 'Please enter an amount';
    }
  }
}

extension on DescriptionValidationError {
  String text() {
    switch (this) {
      case DescriptionValidationError.invalid:
        return 'Invalid description, minimum 3 characters';
      case DescriptionValidationError.empty:
        return 'Please enter a description, minimum 3 characters';
    }
  }
}

extension on TransactionTypeValidationError {
  String text() {
    switch (this) {
      case TransactionTypeValidationError.invalid:
        return 'Invalid transaction type';
      case TransactionTypeValidationError.empty:
        return 'Please enter a transaction type';
    }
  }
}
