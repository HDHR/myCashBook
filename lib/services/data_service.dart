import 'package:myCashBook/db/database.dart';
import 'package:myCashBook/models/transaction.dart';

class DataService {
  final HiveDatabaseHelper _databaseHelper;

  DataService(this._databaseHelper);

  Future<bool> addTransaction(
      DateTime date, int amount, String description, String type) async {
    final transaction = Transaction(
      id: DateTime.now().millisecondsSinceEpoch,
      date: date,
      amount: amount,
      description: description,
      type: type,
    );
    await _databaseHelper.addTransaction(transaction);
    return true;
  }

  Future<List<Transaction>> getTransactions() async {
    return await _databaseHelper.getTransactions();
  }

  Future<bool> deleteTransaction(int id) async {
    try {
      await _databaseHelper.deleteTransaction(id);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateTransaction(int id, DateTime date, int amount,
      String description, String type) async {
    try {
      final transaction = Transaction(
        id: id,
        date: date,
        amount: amount,
        description: description,
        type: type,
      );
      await _databaseHelper.updateTransaction(transaction);
      return true;
    } catch (e) {
      return false;
    }
  }
}
