import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../transactions/presentation/transaction_controller.dart';
import 'sync_service.dart';
import 'sync_status.dart';

class SyncController extends StateNotifier<SyncState> {
  SyncController(this._ref) : super(SyncState.idle);

  final Ref _ref;

  Future<void> syncNow() async {
    state = SyncState.loading;
    try {
      final service = await _ref.read(syncServiceProvider.future);
      await service.syncNow();
      _ref.invalidate(transactionListProvider);
      _ref.invalidate(recentTransactionsProvider);
      _ref.invalidate(monthlySummaryProvider);
      state = SyncState.success;
    } on SyncOfflineException {
      state = SyncState.offline;
    } catch (_) {
      state = SyncState.failed;
    }
  }
}

final syncControllerProvider = StateNotifierProvider<SyncController, SyncState>(
  (ref) {
    return SyncController(ref);
  },
);

final lastSyncAtProvider = FutureProvider.autoDispose((ref) async {
  final service = await ref.watch(syncServiceProvider.future);
  return service.lastSyncAt;
});

final hasPendingSyncProvider = FutureProvider.autoDispose((ref) async {
  final service = await ref.watch(syncServiceProvider.future);
  return service.hasPendingChanges;
});
