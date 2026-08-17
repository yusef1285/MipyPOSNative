// lib/controllers/cierre_service.dart
import 'package:flutter/foundation.dart';
import '../services/db_service.dart';
import '../controllers/product_repository.dart';

class CierreService extends ChangeNotifier {
  static final CierreService _instance = CierreService._internal();
  factory CierreService() => _instance;
  CierreService._internal();

  bool _loading = false;
  bool get isLoading => _loading;

  void _setLoading(bool v) {
    _loading = v;
    notifyListeners();
  }

  Future<void> saveProvisionalClose({
    required int sessionId,
    required Map<String, dynamic> productsStart,
    required Map<String, dynamic> productsEnd,
    required Map<String, int> cashCount,
    required Map<String, dynamic> transferCount,
    required double fund,
    required double finalCash,
    required double expectedCash,
    String? notes,
  }) async {
    _setLoading(true);
    try {
      final session = await DBService.getOpenCash();
      if (session == null || session['id'] != sessionId) {
        throw Exception('No hay sesión abierta con ese ID');
      }

      final provisional = {
        'saved_at': DateTime.now().toIso8601String(),
        'products_start': productsStart,
        'products_end': productsEnd,
        'cash_count': cashCount,
        'transfer_count': transferCount,
        'fund': fund,
        'final_cash': finalCash,
        'expected_cash': expectedCash,
        'notes': notes ?? '',
        'confirmed_by_manager': false,
        'confirmed_at': null,
      };

      final key = 'provisional_close_$sessionId';
      await DBService.putConfig(key, provisional);

      _setLoading(false);
    } catch (e) {
      _setLoading(false);
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> getProvisionalClose(int sessionId) async {
    final key = 'provisional_close_$sessionId';
    final p = await DBService.getConfig(key);
    if (p == null) return null;
    return Map<String, dynamic>.from(p);
  }

  Future<void> confirmProvisionalCloseLocally(int sessionId) async {
    _setLoading(true);
    try {
      final provisional = await getProvisionalClose(sessionId);
      if (provisional == null) {
        throw Exception('No existe cierre provisional para esta sesión');
      }

      provisional['confirmed_by_manager'] = true;
      provisional['confirmed_at'] = DateTime.now().toIso8601String();

      final key = 'provisional_close_$sessionId';
      await DBService.putConfig(key, provisional);

      await DBService.closeCashSession(
        sessionId,
        productsStart: Map<String, dynamic>.from(provisional['products_start'] ?? {}),
        productsEnd: Map<String, dynamic>.from(provisional['products_end'] ?? {}),
        cashCount: Map<String, int>.from(provisional['cash_count'] ?? {}),
        transferCount: Map<String, dynamic>.from(provisional['transfer_count'] ?? {}),
        fund: (provisional['fund'] ?? 0.0) is num ? (provisional['fund'] as num).toDouble() : double.tryParse('${provisional['fund']}') ?? 0.0,
        finalCash: (provisional['final_cash'] ?? 0.0) is num ? (provisional['final_cash'] as num).toDouble() : double.tryParse('${provisional['final_cash']}') ?? 0.0,
        expectedCash: (provisional['expected_cash'] ?? 0.0) is num ? (provisional['expected_cash'] as num).toDouble() : double.tryParse('${provisional['expected_cash']}') ?? 0.0,
      );

      await DBService.deleteConfig(key);

      _setLoading(false);
    } catch (e) {
      _setLoading(false);
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> reopenWithSample(int sessionId) async {
    final sessions = await DBService.getCashSessions();
    final session = sessions.firstWhere((s) => s['id'] == sessionId, orElse: () => {});
    if (session.isEmpty) {
      throw Exception('Sesión no encontrada');
    }

    final sample = await ProductRepository.getRandomSample10();

    final key = 'reopen_sample_$sessionId';
    await DBService.putConfig(key, {
      'requested_at': DateTime.now().toIso8601String(),
      'sample': sample.map((p) => {'id': p['id'], 'name': p['name'], 'stock': p['stock']}).toList(),
    });

    return sample;
  }

  Future<Map<String, dynamic>?> getReopenSample(int sessionId) async {
    final key = 'reopen_sample_$sessionId';
    final v = await DBService.getConfig(key);
    if (v == null) return null;
    return Map<String, dynamic>.from(v);
  }
}
