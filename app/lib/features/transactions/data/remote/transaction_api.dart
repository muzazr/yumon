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
}
