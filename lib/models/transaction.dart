import 'package:hive/hive.dart';

class Transaction {
  final int id;
  final DateTime date;
  final int amount;
  final String description;
  final String type;

  Transaction({
    required this.id,
    required this.date,
    required this.amount,
    required this.description,
    required this.type,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'] as int,
      date: json['date'] as DateTime,
      amount: json['amount'] as int,
      description: json['description'] as String,
      type: json['type'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date,
      'amount': amount,
      'description': description,
      'type': type,
    };
  }
}

class TransactionAdapter extends TypeAdapter<Transaction> {
  @override
  int get typeId => 1;

  @override
  Transaction read(BinaryReader reader) {
    return Transaction(
      id: reader.read(),
      date: reader.read(),
      amount: reader.read(),
      description: reader.read(),
      type: reader.read(),
    );
  }

  @override
  void write(BinaryWriter writer, Transaction obj) {
    writer.write(obj.id);
    writer.write(obj.date);
    writer.write(obj.amount);
    writer.write(obj.description);
    writer.write(obj.type);
  }
}
