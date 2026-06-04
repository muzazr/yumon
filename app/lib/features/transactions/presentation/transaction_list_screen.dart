import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../shared/layout/main_scaffold.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/loading_view.dart';
import '../widgets/transaction_filter_bar.dart';
import '../widgets/transaction_tile.dart';
import 'transaction_controller.dart';

class TransactionListScreen extends ConsumerWidget {
  const TransactionListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactions = ref.watch(transactionListProvider);

    return MainScaffold(
      currentIndex: 1,
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go('/transactions/add'),
        child: const Icon(Icons.add_rounded),
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 110),
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () => context.go('/home'),
                  icon: const Icon(Icons.arrow_back_rounded),
                ),
                const Expanded(
                  child: Center(
                    child: Text(
                      'Transactions',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
                const SizedBox(width: 48),
              ],
            ),
            const SizedBox(height: 12),
            const TransactionFilterBar(),
            const SizedBox(height: 18),
            transactions.when(
              data: (items) {
                if (items.isEmpty) {
                  return const EmptyState(
                    icon: Icons.search_off_rounded,
                    title: 'No transactions found',
                    message: 'Try a different filter or add a transaction.',
                  );
                }
                return Column(
                  children: [
                    for (final item in items)
                      TransactionTile(
                        transaction: item,
                        onTap: () =>
                            context.go('/transactions/edit/${item.id}'),
                      ),
                  ],
                );
              },
              loading: () => const SizedBox(height: 220, child: LoadingView()),
              error: (error, _) => Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  error.toString(),
                  style: const TextStyle(color: AppColors.expense),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
