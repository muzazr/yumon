import 'package:isar/isar.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/transaction_constants.dart';
import '../models/transaction_model.dart';
import 'local/transaction_local_datasource.dart';

class TransactionRepository {
  TransactionRepository(this._local);

  final TransactionLocalDatasource _local;
  final _uuid = const Uuid();

  Future<List<TransactionModel>> getTransactions({
    DateTime? month,
    String? type,
    String? category,
  }) {
    return _local.getTransactions(month: month, type: type, category: category);
  }

  Future<TransactionModel?> findById(Id id) => _local.findById(id);

  Future<List<TransactionModel>> getRecentTransactions({int limit = 5}) {
    return _local.getRecentTransactions(limit: limit);
  }

  Future<Id> createTransaction(TransactionInput input) {
    final now = DateTime.now();
    final transaction = TransactionModel()
      ..clientId = _uuid.v4()
      ..title = input.title
      ..amount = input.amount
      ..type = input.type
      ..category = input.category
      ..date = input.date
      ..note = input.note
      ..syncStatus = SyncStatusValues.pendingCreate
      ..createdAt = now
      ..updatedAt = now;
    return _local.save(transaction);
  }

  Future<void> updateTransaction(Id localId, TransactionInput input) async {
    final transaction = await _local.findById(localId);
    if (transaction == null) return;
    transaction
      ..title = input.title
      ..amount = input.amount
      ..type = input.type
      ..category = input.category
      ..date = input.date
      ..note = input.note
      ..updatedAt = DateTime.now();
    if (transaction.syncStatus != SyncStatusValues.pendingCreate) {
      transaction.syncStatus = SyncStatusValues.pendingUpdate;
    }
    await _local.save(transaction);
  }

  Future<void> deleteTransaction(Id localId) async {
    final transaction = await _local.findById(localId);
    if (transaction == null) return;
    if (transaction.serverId == null || transaction.serverId!.isEmpty) {
      await _local.hardDelete(localId);
      return;
    }
    transaction
      ..isDeleted = true
      ..deletedAt = DateTime.now()
      ..updatedAt = DateTime.now()
      ..syncStatus = SyncStatusValues.pendingDelete;
    await _local.save(transaction);
  }

  Future<TransactionSummary> getMonthlySummary(DateTime month) async {
    final transactions = await _local.getTransactions(month: month);
    double income = 0;
    double expense = 0;
    for (final transaction in transactions) {
      if (transaction.type == TransactionTypes.income) {
        income += transaction.amount;
      } else if (transaction.type == TransactionTypes.expense) {
        expense += transaction.amount;
      }
    }
    return TransactionSummary(totalIncome: income, totalExpense: expense);
  }
}
