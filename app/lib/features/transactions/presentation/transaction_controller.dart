import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';

import '../../../core/constants/transaction_constants.dart';
import '../../../core/providers.dart';
import '../models/transaction_model.dart';

class TransactionFilter {
  const TransactionFilter({
    required this.month,
    this.type = TransactionTypes.all,
    this.category,
  });

  final DateTime month;
  final String type;
  final String? category;

  TransactionFilter copyWith({
    DateTime? month,
    String? type,
    String? category,
    bool clearCategory = false,
  }) {
    return TransactionFilter(
      month: month ?? this.month,
      type: type ?? this.type,
      category: clearCategory ? null : category ?? this.category,
    );
  }
}

final transactionFilterProvider = StateProvider<TransactionFilter>((ref) {
  final now = DateTime.now();
  return TransactionFilter(month: DateTime(now.year, now.month));
});

final transactionListProvider =
    FutureProvider.autoDispose<List<TransactionModel>>((ref) async {
      final filter = ref.watch(transactionFilterProvider);
      final repository = await ref.watch(transactionRepositoryProvider.future);
      return repository.getTransactions(
        month: filter.month,
        type: filter.type,
        category: filter.category,
      );
    });

final recentTransactionsProvider =
    FutureProvider.autoDispose<List<TransactionModel>>((ref) async {
      final repository = await ref.watch(transactionRepositoryProvider.future);
      return repository.getRecentTransactions(limit: 5);
    });

final monthlySummaryProvider = FutureProvider.autoDispose<TransactionSummary>((
  ref,
) async {
  final filter = ref.watch(transactionFilterProvider);
  final repository = await ref.watch(transactionRepositoryProvider.future);
  return repository.getMonthlySummary(filter.month);
});

final transactionByIdProvider = FutureProvider.family
    .autoDispose<TransactionModel?, Id>((ref, id) async {
      final repository = await ref.watch(transactionRepositoryProvider.future);
      return repository.findById(id);
    });
