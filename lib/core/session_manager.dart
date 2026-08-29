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

  /// Inicia el proceso de cierre. Cualquier usuario (cajero) puede proponerlo.
  /// Devuelve true si se requiere autorización del administrador.
  bool requestClose() {
    return true; // Siempre requiere confirmación final
  }

  /// Ejecuta el cierre definitivo. SOLO permitido si el usuario que confirma es admin.
  Future<void> confirmFinalClose({
    required Map<String, dynamic> adminUser,
    required double finalCash,
    required double expectedCash,
  }) async {
    if (adminUser['role'] != 'admin') {
      throw Exception('Autorización denegada: Solo un administrador puede certificar el cierre final.');
    }

    if (_sessionId != null) {
      await DBService.closeCash(_sessionId!, finalCash, expectedCash);
      _sessionId = null;
      notifyListeners();
    }
  }

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
