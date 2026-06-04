import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/auth/data/auth_api.dart';
import '../features/auth/data/auth_repository.dart';
import '../features/sync/sync_service.dart';
import '../features/transactions/data/local/isar_service.dart';
import '../features/transactions/data/local/transaction_local_datasource.dart';
import '../features/transactions/data/remote/transaction_api.dart';
import '../features/transactions/data/transaction_repository.dart';
import 'network/dio_client.dart';
import 'storage/secure_storage_service.dart';

final secureStorageProvider = Provider((ref) => SecureStorageService());

final dioClientProvider = Provider((ref) {
  return DioClient(ref.watch(secureStorageProvider));
});

final authApiProvider = Provider((ref) {
  return AuthApi(ref.watch(dioClientProvider));
});

final authRepositoryProvider = Provider((ref) {
  return AuthRepository(
    ref.watch(authApiProvider),
    ref.watch(secureStorageProvider),
  );
});

final isarProvider = FutureProvider((ref) => IsarService.open());

final transactionLocalDatasourceProvider = FutureProvider((ref) async {
  final isar = await ref.watch(isarProvider.future);
  return TransactionLocalDatasource(isar);
});

final transactionApiProvider = Provider((ref) {
  return TransactionApi(ref.watch(dioClientProvider));
});

final transactionRepositoryProvider = FutureProvider((ref) async {
  final local = await ref.watch(transactionLocalDatasourceProvider.future);
  return TransactionRepository(local);
});

final syncServiceProvider = FutureProvider((ref) async {
  final local = await ref.watch(transactionLocalDatasourceProvider.future);
  return SyncService(
    local,
    ref.watch(transactionApiProvider),
    ref.watch(secureStorageProvider),
  );
});
