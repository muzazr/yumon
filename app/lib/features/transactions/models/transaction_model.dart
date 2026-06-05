import 'package:isar/isar.dart';

part 'transaction_model.g.dart';

@collection
class TransactionModel {
  Id id = Isar.autoIncrement;

  late String clientId;
  String? serverId;

  late String title;
  late double amount;

  /// income | expense
  late String type;

  late String category;
  DateTime date = DateTime.now();
  String? note;

  /// synced | pendingCreate | pendingUpdate | pendingDelete | failed
  late String syncStatus;

  bool isDeleted = false;

  DateTime createdAt = DateTime.now();
  DateTime updatedAt = DateTime.now();
  DateTime? deletedAt;

  Map<String, dynamic> toCreateApiJson() {
    return {
      'clientId': clientId,
      'title': title,
      'amount': amount,
      'type': type,
      'category': category,
      'date': _formatApiDate(date),
      'note': note ?? '',
    };
  }

  Map<String, dynamic> toUpdateApiJson() {
    return {
      'title': title,
      'amount': amount,
      'type': type,
      'category': category,
      'date': _formatApiDate(date),
      'note': note ?? '',
    };
  }

  Map<String, dynamic> toSyncPushJson(String operation) {
    final data = <String, dynamic>{
      'operation': operation,
      'clientId': clientId,
      'serverId': serverId,
      'updatedAt': updatedAt.toIso8601String(),
    };

    if (operation != 'delete') {
      data.addAll({
        'title': title,
        'amount': amount,
        'type': type,
        'category': category,
        'date': _formatApiDate(date),
        'note': note,
        'createdAt': createdAt.toIso8601String(),
      });
    }

    return data;
  }

  static TransactionModel fromApiJson(Map<String, dynamic> json) {
    final model = TransactionModel()
      ..clientId = (json['clientId'] ?? '').toString()
      ..serverId = (json['id'] ?? json['serverId'])?.toString()
      ..title = (json['title'] ?? '').toString()
      ..amount = double.tryParse((json['amount'] ?? '0').toString()) ?? 0
      ..type = (json['type'] ?? '').toString()
      ..category = (json['category'] ?? '').toString()
      ..date =
          DateTime.tryParse((json['date'] ?? '').toString()) ?? DateTime.now()
      ..note = json['note']?.toString()
      ..syncStatus = 'synced'
      ..isDeleted = json['isDeleted'] == true
      ..createdAt =
          DateTime.tryParse((json['createdAt'] ?? '').toString()) ??
          DateTime.now()
      ..updatedAt =
          DateTime.tryParse((json['updatedAt'] ?? '').toString()) ??
          DateTime.now();

    return model;
  }
}

class TransactionInput {
  const TransactionInput({
    required this.title,
    required this.amount,
    required this.type,
    required this.category,
    required this.date,
    this.note,
  });

  final String title;
  final double amount;
  final String type;
  final String category;
  final DateTime date;
  final String? note;
}

class TransactionSummary {
  const TransactionSummary({
    required this.totalIncome,
    required this.totalExpense,
  });

  final double totalIncome;
  final double totalExpense;

  double get balance => totalIncome - totalExpense;
}

String _formatApiDate(DateTime date) {
  final year = date.year.toString().padLeft(4, '0');
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');

  return '$year-$month-$day';
}
