import '../../../../core/network/dio_client.dart';
import '../../models/transaction_model.dart';

class TransactionApi {
  const TransactionApi(this._client);

  final DioClient _client;

  Future<List<TransactionModel>> getTransactions() async {
    try {
      final response = await _client.dio.get('/transactions');
      final list = _extractList(response.data);
      return list
          .whereType<Map<String, dynamic>>()
          .map(TransactionModel.fromApiJson)
          .toList();
    } catch (error) {
      throw _client.readableError(error);
    }
  }

  Future<TransactionModel> create(TransactionModel transaction) async {
    try {
      final response = await _client.dio.post(
        '/transactions',
        data: transaction.toCreateApiJson(),
      );
      return TransactionModel.fromApiJson(_extractTransaction(response.data));
    } catch (error) {
      throw _client.readableError(error);
    }
  }

  Future<TransactionModel> update(TransactionModel transaction) async {
    try {
      final response = await _client.dio.put(
        '/transactions/${transaction.serverId}',
        data: transaction.toUpdateApiJson(),
      );
      return TransactionModel.fromApiJson(_extractTransaction(response.data));
    } catch (error) {
      throw _client.readableError(error);
    }
  }

  Future<void> delete(String serverId) async {
    try {
      await _client.dio.delete('/transactions/$serverId');
    } catch (error) {
      throw _client.readableError(error);
    }
  }

  Future<List<SyncPushResult>> pushSync(List<TransactionModel> changes) async {
    try {
      final response = await _client.dio.post(
        '/sync/push',
        data: {
          'changes': changes
              .map(
                (transaction) =>
                    transaction.toSyncPushJson(_syncOperation(transaction)),
              )
              .toList(),
        },
      );
      return _extractSyncResults(
        response.data,
      ).whereType<Map<String, dynamic>>().map(SyncPushResult.fromJson).toList();
    } catch (error) {
      throw _client.readableError(error);
    }
  }

  List<dynamic> _extractList(dynamic body) {
    if (body is List) return body;
    if (body is Map<String, dynamic>) {
      final data = body['data'];
      if (data is Map<String, dynamic> && data['transactions'] is List) {
        return data['transactions'] as List;
      }
      if (data is List) return data;
      if (body['transactions'] is List) return body['transactions'] as List;
    }
    return const [];
  }

  Map<String, dynamic> _extractTransaction(dynamic body) {
    if (body is Map<String, dynamic>) {
      final data = body['data'];
      if (data is Map<String, dynamic> &&
          data['transaction'] is Map<String, dynamic>) {
        return data['transaction'] as Map<String, dynamic>;
      }
      if (body['transaction'] is Map<String, dynamic>) {
        return body['transaction'] as Map<String, dynamic>;
      }
      return body;
    }
    return <String, dynamic>{};
  }

  List<dynamic> _extractSyncResults(dynamic body) {
    if (body is Map<String, dynamic>) {
      final data = body['data'];
      if (data is Map<String, dynamic> && data['results'] is List) {
        return data['results'] as List;
      }
      if (body['results'] is List) return body['results'] as List;
    }
    return const [];
  }

  String _syncOperation(TransactionModel transaction) {
    switch (transaction.syncStatus) {
      case 'pendingUpdate':
        return 'update';
      case 'pendingDelete':
        return 'delete';
      case 'pendingCreate':
        return 'create';
      case 'failed':
      default:
        if (transaction.isDeleted) return 'delete';
        if (transaction.serverId != null && transaction.serverId!.isNotEmpty) {
          return 'update';
        }
        return 'create';
    }
  }
}

class SyncPushResult {
  const SyncPushResult({
    required this.clientId,
    required this.status,
    required this.operation,
    this.serverId,
  });

  final String clientId;
  final String? serverId;
  final String status;
  final String operation;

  bool get isSynced => status == 'synced';

  factory SyncPushResult.fromJson(Map<String, dynamic> json) {
    return SyncPushResult(
      clientId: (json['clientId'] ?? '').toString(),
      serverId: json['serverId']?.toString(),
      status: (json['status'] ?? '').toString(),
      operation: (json['operation'] ?? '').toString(),
    );
  }
}
