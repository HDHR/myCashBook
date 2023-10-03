import 'package:hive_flutter/hive_flutter.dart';
import 'package:myCashBook/models/user.dart';
import 'package:myCashBook/models/transaction.dart';
import 'package:bcrypt/bcrypt.dart';

class HiveDatabaseHelper {
  static const String _userBoxName = 'userBox';
  static const String _transactionBoxName = 'transactionBox';

  Future<void> initDatabase() async {
    await Hive.initFlutter();
    Hive.registerAdapter(UserAdapter());
    Hive.registerAdapter(TransactionAdapter());

    final box = await Hive.openBox<User>(_userBoxName);
    if (box.isEmpty) {
      const usernameFromEnv = 'user';
      const passwordFromEnv = 'user';

      final String passwordHashed = BCrypt.hashpw(
        passwordFromEnv,
        BCrypt.gensalt(),
      );

      final user = User(username: usernameFromEnv, password: passwordHashed);
      await box.add(user);
    }
  }

  Future<User?> getUser(String username) async {
    final box = await Hive.openBox<User>(_userBoxName);
    final users = box.values.where((user) => user.username == username);
    if (users.isNotEmpty) {
      return users.first;
    }
    return null;
  }

  Future<bool> updateUserPassword(
      String username, String passwordHashed) async {
    final box = await Hive.openBox<User>(_userBoxName);
    final users = box.values.where((user) => user.username == username);
    if (users.isNotEmpty) {
      final int index = box.values.toList().indexOf(users.first);
      final user = User(username: username, password: passwordHashed);
      await box.putAt(index, user);
      return true;
    }
    return false;
  }

  Future<void> addTransaction(Transaction transaction) async {
    final box = await Hive.openBox<Transaction>(_transactionBoxName);
    await box.add(transaction);
  }

  Future<List<Transaction>> getTransactions() async {
    final box = await Hive.openBox<Transaction>(_transactionBoxName);
    final transactions = box.values.toList();

    transactions.sort((a, b) => a.date.compareTo(b.date));

    return transactions;
  }

  Future<void> deleteTransaction(int id) async {
    final box = await Hive.openBox<Transaction>(_transactionBoxName);
    final transactions =
        box.values.where((transaction) => transaction.id == id);
    if (transactions.isNotEmpty) {
      final int index = box.values.toList().indexOf(transactions.first);
      await box.deleteAt(index);
    }
  }

  Future<void> updateTransaction(Transaction transaction) async {
    final box = await Hive.openBox<Transaction>(_transactionBoxName);
    final transactions =
        box.values.where((transaction) => transaction.id == transaction.id);
    if (transactions.isNotEmpty) {
      final int index = box.values.toList().indexOf(transactions.first);
      await box.putAt(index, transaction);
    }
  }

  Future<void> close() async {
    await Hive.close();
  }

  Future<void> deleteAll() async {
    await Hive.deleteBoxFromDisk(_userBoxName);
    await Hive.deleteBoxFromDisk(_transactionBoxName);
  }
}
