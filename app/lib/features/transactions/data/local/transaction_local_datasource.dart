import 'package:isar/isar.dart';

import '../../../../core/constants/transaction_constants.dart';
import '../../models/transaction_model.dart';

class TransactionLocalDatasource {
  const TransactionLocalDatasource(this._isar);

  final Isar _isar;

  Future<List<TransactionModel>> getTransactions({
    DateTime? month,
    String? type,
    String? category,
    bool includeDeleted = false,
  }) async {
    return _isar.transactionModels
        .filter()
        .optional(!includeDeleted, (q) => q.isDeletedEqualTo(false))
        .optional(month != null, (q) {
          final start = DateTime(month!.year, month.month);
          final end = DateTime(month.year, month.month + 1);
          return q.dateBetween(start, end, includeUpper: false);
        })
        .optional(
          type != null && type != TransactionTypes.all,
          (q) => q.typeEqualTo(type!),
        )
        .optional(
          category != null && category.isNotEmpty,
          (q) => q.categoryEqualTo(category!),
        )
        .sortByDateDesc()
        .findAll();
  }

  Future<List<TransactionModel>> getRecentTransactions({int limit = 5}) {
    return _isar.transactionModels
        .filter()
        .isDeletedEqualTo(false)
        .sortByDateDesc()
        .limit(limit)
        .findAll();
  }

  Future<List<TransactionModel>> getPendingTransactions() {
    return _isar.transactionModels
        .filter()
        .not()
        .syncStatusEqualTo(SyncStatusValues.synced)
        .findAll();
  }

  Future<TransactionModel?> findById(Id id) {
    return _isar.transactionModels.get(id);
  }

  Future<TransactionModel?> findByServerOrClientId({
    String? serverId,
    required String clientId,
  }) async {
    if (serverId != null && serverId.isNotEmpty) {
      final byServerId = await _isar.transactionModels
          .filter()
          .serverIdEqualTo(serverId)
          .findFirst();

      if (byServerId != null) {
        return byServerId;
      }
    }

    return _isar.transactionModels
        .filter()
        .clientIdEqualTo(clientId)
        .findFirst();
  }

  Future<Id> save(TransactionModel transaction) {
    return _isar.writeTxn(() => _isar.transactionModels.put(transaction));
  }

  Future<void> saveAll(List<TransactionModel> transactions) {
    return _isar.writeTxn(() => _isar.transactionModels.putAll(transactions));
  }

  Future<void> hardDelete(Id id) {
    return _isar.writeTxn(() async {
      await _isar.transactionModels.delete(id);
    });
  }

  Future<bool> hasPendingChanges() async {
    final count = await _isar.transactionModels
        .filter()
        .not()
        .syncStatusEqualTo(SyncStatusValues.synced)
        .count();
    return count > 0;
  }
}
