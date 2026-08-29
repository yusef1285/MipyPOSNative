import 'dart:io';
import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'db_service.dart';

import 'package:network_info_plus/network_info_plus.dart';

class SyncService {
  // ... (instancia y variables existentes)

  Future<String?> getLocalIp() async {
    return await NetworkInfo().getWifiIP();
  }

  /// Inicia el servidor y devuelve la IP local para el QR
  Future<String?> startServer() async {
    try {
      final ip = await getLocalIp();
      _server = await ServerSocket.bind(InternetAddress.anyIPv4, port);
      debugPrint('Sync Server iniciado en $ip:$port');
      
      _server!.listen((client) {
        _handleClientConnection(client);
      });
      return ip;
    } catch (e) {
      debugPrint('Error al iniciar Sync Server: $e');
      return null;
    }
  }

  void _handleClientConnection(Socket client) {
    _clients.add(client);
    debugPrint('Nuevo dispositivo conectado: ${client.remoteAddress.address}');

    client.listen((data) async {
      final message = utf8.decode(data);
      final Map<String, dynamic> payload = jsonDecode(message);

      if (payload['type'] == 'SALE_SYNC') {
        // Recibir venta de otro dispositivo y guardarla en la base central
        await DBService.createSale(
          (payload['total'] as num).toDouble(),
          payload['method'],
          payload['user'],
          sessionId: payload['sessionId'],
          payments: List<Map<String, dynamic>>.from(payload['payments'] ?? []),
        );
        // Notificar a otros clientes (Broadcast)
        broadcast(message);
      }
    }, onDone: () => _clients.remove(client));
  }

  /// Envía datos a todos los dispositivos conectados
  void broadcast(String message) {
    for (var client in _clients) {
      client.write(message);
    }
  }

  /// Conectar un dispositivo empleado al Administrador
  Future<void> connectToMaster(String ip) async {
    masterIp = ip;
    try {
      final socket = await Socket.connect(ip, port);
      debugPrint('Conectado al Administrador en $ip');
      
      socket.listen((data) {
        final payload = jsonDecode(utf8.decode(data));
        // Si el master envía una actualización, refrescar base local
        if (payload['type'] == 'DB_UPDATE') {
          // Lógica para recargar productos o ventas
        }
      });
    } catch (e) {
      debugPrint('Error al conectar con el Master: $e');
    }
  }

  /// Sincronizar una venta recién hecha con el Master
  Future<void> syncSale(Map<String, dynamic> saleData) async {
    if (masterIp == null) return;
    try {
      final socket = await Socket.connect(masterIp!, port);
      saleData['type'] = 'SALE_SYNC';
      socket.write(jsonEncode(saleData));
      await socket.flush();
      await socket.close();
    } catch (e) {
      debugPrint('Error al sincronizar venta: $e');
    }
  }
}
