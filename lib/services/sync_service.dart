import 'dart:io';
import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:network_info_plus/network_info_plus.dart';

import 'db_service.dart';

class SyncService {
  // Puerto fijo para sincronización P2P
  static const int port = 4040;

  // IP del administrador (master)
  String? masterIp;

  // Servidor local
  ServerSocket? _server;

  // Lista de clientes conectados
  final List<Socket> _clients = [];

  // Obtener IP local para mostrar en QR
  Future<String?> getLocalIp() async {
    return await NetworkInfo().getWifiIP();
  }

  // Iniciar servidor P2P
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

  // Manejar conexión entrante
  void _handleClientConnection(Socket client) {
    _clients.add(client);
    debugPrint('Nuevo dispositivo conectado: ${client.remoteAddress.address}');

    client.listen(
      (data) async {
        final message = utf8.decode(data);
        final Map<String, dynamic> payload = jsonDecode(message);

        if (payload['type'] == 'SALE_SYNC') {
          // Guardar venta recibida
          await DBService.createSale(
            (payload['total'] as num).toDouble(),
            payload['method'],
            payload['user'],
            sessionId: payload['sessionId'],
            payments: List<Map<String, dynamic>>.from(payload['payments'] ?? []),
          );

          // Reenviar a otros dispositivos
          broadcast(message);
        }
      },
      onDone: () {
        _clients.remove(client);
      },
    );
  }

  // Enviar mensaje a todos los dispositivos conectados
  void broadcast(String message) {
    for (var client in _clients) {
      try {
        client.write(message);
      } catch (_) {}
    }
  }

  // Conectar dispositivo empleado al administrador
  Future<void> connectToMaster(String ip) async {
    masterIp = ip;

    try {
      final socket = await Socket.connect(ip, port);
      debugPrint('Conectado al Administrador en $ip');

      socket.listen((data) {
        final payload = jsonDecode(utf8.decode(data));

        if (payload['type'] == 'DB_UPDATE') {
          // Aquí puedes recargar productos, ventas, etc.
        }
      });
    } catch (e) {
      debugPrint('Error al conectar con el Master: $e');
    }
  }

  // Sincronizar venta con el administrador
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