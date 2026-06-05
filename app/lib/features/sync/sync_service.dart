import 'package:connectivity_plus/connectivity_plus.dart';

import '../../core/constants/transaction_constants.dart';
import '../../core/storage/secure_storage_service.dart';
import '../transactions/data/local/transaction_local_datasource.dart';
import '../transactions/data/remote/transaction_api.dart';

class SyncService {
  const SyncService(this._local, this._api, this._storage);

  final TransactionLocalDatasource _local;
  final TransactionApi _api;
  final SecureStorageService _storage;

  Future<bool> get isOnline async {
    final Object result = await Connectivity().checkConnectivity();
    if (result is List<ConnectivityResult>) {
      return result.any((item) => item != ConnectivityResult.none);
    }
    return result != ConnectivityResult.none;
  }

  Future<bool> get hasPendingChanges => _local.hasPendingChanges();

  Future<DateTime?> get lastSyncAt => _storage.readLastSyncAt();

  Future<void> syncNow() async {
    if (!await isOnline) {
      throw const SyncOfflineException();
    }
    final token = await _storage.readToken();
    if (token == null || token.isEmpty) {
      throw const SyncAuthException();
    }
    await pushPendingTransactions();
    await pullServerTransactions();
    await _storage.saveLastSyncAt(DateTime.now());
  }

  Future<void> pushPendingTransactions() async {
    final pending = await _local.getPendingTransactions();
    if (pending.isEmpty) return;

    try {
      final results = await _api.pushSync(pending);
      for (final transaction in pending) {
        SyncPushResult? result;
        for (final item in results) {
          if (item.clientId == transaction.clientId) {
            result = item;
            break;
          }
        }

        if (result == null || !result.isSynced) {
          transaction.syncStatus = SyncStatusValues.failed;
          await _local.save(transaction);
          continue;
        }

        if (result.operation == 'delete') {
          await _local.hardDelete(transaction.id);
          continue;
        }

        transaction
          ..serverId = result.serverId ?? transaction.serverId
          ..syncStatus = SyncStatusValues.synced;
        await _local.save(transaction);
      }
    } catch (_) {
      for (final transaction in pending) {
        transaction.syncStatus = SyncStatusValues.failed;
        await _local.save(transaction);
      }
    }
  }

  Future<void> pullServerTransactions() async {
    final serverTransactions = await _api.getTransactions();
    for (final server in serverTransactions) {
      final local = await _local.findByServerOrClientId(
        serverId: server.serverId,
        clientId: server.clientId,
      );
      if (local == null) {
        await _local.save(server);
        continue;
      }
      if (local.syncStatus != SyncStatusValues.synced) {
        continue;
      }
      local
        ..serverId = server.serverId
        ..title = server.title
        ..amount = server.amount
        ..type = server.type
        ..category = server.category
        ..date = server.date
        ..note = server.note
        ..isDeleted = server.isDeleted
        ..createdAt = server.createdAt
        ..updatedAt = server.updatedAt
        ..syncStatus = SyncStatusValues.synced;
      await _local.save(local);
    }
  }
}

class SyncOfflineException implements Exception {
  const SyncOfflineException();
}

class SyncAuthException implements Exception {
  const SyncAuthException();
}
