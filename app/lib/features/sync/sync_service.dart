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
    for (final transaction in pending) {
      try {
        if (transaction.syncStatus == SyncStatusValues.pendingCreate ||
            transaction.syncStatus == SyncStatusValues.failed) {
          if (transaction.isDeleted) {
            await _local.hardDelete(transaction.id);
            continue;
          }
          final server = await _api.create(transaction);
          transaction
            ..serverId = server.serverId
            ..syncStatus = SyncStatusValues.synced
            ..updatedAt = server.updatedAt;
          await _local.save(transaction);
        } else if (transaction.syncStatus == SyncStatusValues.pendingUpdate) {
          if (transaction.serverId == null || transaction.serverId!.isEmpty) {
            transaction.syncStatus = SyncStatusValues.pendingCreate;
            await _local.save(transaction);
            continue;
          }
          final server = await _api.update(transaction);
          transaction
            ..syncStatus = SyncStatusValues.synced
            ..updatedAt = server.updatedAt;
          await _local.save(transaction);
        } else if (transaction.syncStatus == SyncStatusValues.pendingDelete) {
          final serverId = transaction.serverId;
          if (serverId != null && serverId.isNotEmpty) {
            await _api.delete(serverId);
          }
          await _local.hardDelete(transaction.id);
        }
      } catch (_) {
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
