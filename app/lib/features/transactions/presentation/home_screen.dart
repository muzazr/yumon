import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../features/auth/presentation/auth_controller.dart';
import '../../../features/sync/sync_controller.dart';
import '../../../features/sync/sync_status.dart';
import '../../../shared/layout/main_scaffold.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/loading_view.dart';
import '../widgets/balance_card.dart';
import '../widgets/transaction_tile.dart';
import 'transaction_controller.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    final syncState = ref.watch(syncControllerProvider);
    final summary = ref.watch(monthlySummaryProvider);
    final recent = ref.watch(recentTransactionsProvider);
    final lastSync = ref.watch(lastSyncAtProvider);
    final pending = ref.watch(hasPendingSyncProvider);

    return MainScaffold(
      currentIndex: 0,
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go('/transactions/add'),
        child: const Icon(Icons.add_rounded),
      ),
      child: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(monthlySummaryProvider);
            ref.invalidate(recentTransactionsProvider);
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 110),
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.menu_rounded),
                  ),
                  const Expanded(
                    child: Center(
                      child: Text(
                        'Home',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: AppColors.iconSoft,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.person_outline_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                'Welcome,',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                auth.user?.name ?? 'Yumon User',
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 18),
              _SyncCard(
                state: syncState,
                hasPending: pending.valueOrNull ?? false,
                lastSyncLabel: lastSync.when(
                  data: (value) => value == null
                      ? 'Never synced'
                      : DateFormatter.dateTime(value),
                  loading: () => 'Checking...',
                  error: (_, _) => 'Unknown',
                ),
                onSync: () =>
                    ref.read(syncControllerProvider.notifier).syncNow(),
              ),
              const SizedBox(height: 18),
              summary.when(
                data: (data) => BalanceCard(summary: data),
                loading: () =>
                    const SizedBox(height: 190, child: LoadingView()),
                error: (error, _) => _ErrorCard(message: error.toString()),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Recent Transactions',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => context.go('/transactions'),
                    child: const Text('See All'),
                  ),
                ],
              ),
              recent.when(
                data: (items) {
                  if (items.isEmpty) {
                    return const EmptyState(
                      icon: Icons.receipt_long_outlined,
                      title: 'No transactions yet',
                      message: 'Add income or expense to start tracking.',
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
                loading: () =>
                    const SizedBox(height: 140, child: LoadingView()),
                error: (error, _) => _ErrorCard(message: error.toString()),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SyncCard extends StatelessWidget {
  const _SyncCard({
    required this.state,
    required this.hasPending,
    required this.lastSyncLabel,
    required this.onSync,
  });

  final SyncState state;
  final bool hasPending;
  final String lastSyncLabel;
  final VoidCallback onSync;

  @override
  Widget build(BuildContext context) {
    final label = hasPending && state != SyncState.loading
        ? 'Pending Sync'
        : state.label;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.iconSoft,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.sync_rounded, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 3),
                Text(
                  'Last sync: $lastSyncLabel',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: state == SyncState.loading ? null : onSync,
            icon: state == SyncState.loading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(message, style: const TextStyle(color: AppColors.expense)),
    );
  }
}
