// lib/core/session_manager.dart
import 'package:flutter/foundation.dart';
import '../services/db_service.dart';

class SessionManager extends ChangeNotifier {
  SessionManager._internal();
  static final SessionManager _instance = SessionManager._internal();
  factory SessionManager() => _instance;

  int? _sessionId;
  bool _loading = false;

  int? get sessionId => _sessionId;
  bool get isOpen => _sessionId != null;
  bool get isLoading => _loading;

  void _setLoading(bool v) {
    _loading = v;
    notifyListeners();
  }

  /// Carga la sesión abierta desde DBService y la mantiene en memoria.
  Future<void> loadSession() async {
    _setLoading(true);
    try {
      final open = await DBService.getOpenCash();
      if (open != null) {
        _sessionId = (open['id'] is int) ? open['id'] as int : int.tryParse('${open['id']}');
      } else {
        _sessionId = null;
      }
    } finally {
      _setLoading(false);
    }
  }

  /// Abre una nueva sesión de caja y la guarda en memoria.
  Future<int> openSession(double fund) async {
    _setLoading(true);
    try {
      final id = await DBService.openCashSession(fund);
      _sessionId = id;
      notifyListeners();
      return id;
    } finally {
      _setLoading(false);
    }
  }

  /// Cierra la sesión en memoria (no ejecuta cierre completo en DBService).
  /// Para cierre definitivo usa DBService.closeCashSession desde CierreService.
  void clearSession() {
    _sessionId = null;
    notifyListeners();
  }

  /// Asegura que exista una sesión abierta; si no, lanza excepción.
  void requireSession() {
    if (_sessionId == null) {
      throw Exception('No hay caja abierta. Abre la caja antes de realizar ventas.');
    }
  }
}
