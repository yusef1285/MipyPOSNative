import 'dart:io';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'db_service.dart';

class ExportService {
  static Future<Directory> _getSafeWriteDirectory() async {
    try {
      final downloads = await getDownloadsDirectory();
      if (downloads != null) return downloads;
    } catch (_) {}

    try {
      final docs = await getApplicationDocumentsDirectory();
      if (docs.path.isNotEmpty) return docs;
    } catch (_) {}

    try {
      final support = await getApplicationSupportDirectory();
      if (support.path.isNotEmpty) return support;
    } catch (_) {}

    final fallback = Directory('${Directory.current.path}/mipypos_exports');
    if (!await fallback.exists()) {
      await fallback.create(recursive: true);
    }
    return fallback;
  }

  static Future<String> _getPath(String filename) async {
    final dir = await _getSafeWriteDirectory();
    return "${dir.path}/$filename";
  }

  static Future<void> _saveTxt(String filename, String content) async {
    final path = await _getPath(filename);
    final file = File(path);
    await file.writeAsString(content);
  }

  static Future<void> _saveCsv(
      String filename, List<List<dynamic>> rows) async {
    final path = await _getPath(filename);
    final file = File(path);

    final csv = rows.map((r) => r.join(",")).join("\n");
    await file.writeAsString(csv);
  }

  static Future<void> _saveExcel(
      String filename, List<List<dynamic>> rows) async {
    final excel = Excel.createExcel();
    final sheet = excel['Reporte'];

    for (var r in rows) {
      sheet.appendRow(r);
    }

    final path = await _getPath(filename);
    final file = File(path);
    await file.writeAsBytes(excel.encode()!);
  }

  // -------------------- EXPORTAR VENTAS DEL DÍA --------------------

  static Future<void> exportVentasDia() async {
    final ventas = await DBService.getSalesOfDay();
    final items = await DBService.getSaleItems();
    final productos = await DBService.getProducts();

    final rows = <List<dynamic>>[];

    rows.add([
      "ID Venta",
      "Usuario",
      "Método",
      "Total",
      "Fecha",
      "Producto",
      "Cantidad",
      "Precio",
      "Session ID"
    ]);

    for (var v in ventas) {
      final saleId = v['id'];
      final saleItems = items.where((it) => it['sale_id'] == saleId);

      for (var it in saleItems) {
        final p = productos[it['product_id']]['name'];

        rows.add([
          saleId,
          v['user'],
          v['method'],
          v['total'],
          v['date'],
          p,
          it['quantity'],
          it['price'],
          v['session_id'] ?? '',
        ]);
      }
    }

    await _saveCsv("ventas_dia.csv", rows);
    await _saveExcel("ventas_dia.xlsx", rows);
    await _saveTxt("ventas_dia.txt", rows.map((r) => r.join(" | ")).join("\n"));
  }

  // -------------------- EXPORTAR MOVIMIENTOS --------------------

  static Future<void> exportMovimientosDia() async {
    final movimientos = await DBService.getMovementsOfDay();
    final productos = await DBService.getProducts();
    final areas = await DBService.getAreas();

    final rows = <List<dynamic>>[];

    rows.add([
      "Producto",
      "Cantidad",
      "De área",
      "A área",
      "Enviado por",
      "Recibido por",
      "Confirmado",
      "Fecha"
    ]);

    for (var m in movimientos) {
      final p = productos[m['product_index']]['name'];
      final fromArea = areas[m['from_area']]['name'];
      final toArea = areas[m['to_area']]['name'];

      rows.add([
        p,
        m['qty'],
        fromArea,
        toArea,
        m['from_user'],
        m['to_user'],
        m['confirmed_by_seller'] ? "Sí" : "No",
        m['date'],
      ]);
    }

    await _saveCsv("movimientos_dia.csv", rows);
    await _saveExcel("movimientos_dia.xlsx", rows);
    await _saveTxt(
        "movimientos_dia.txt", rows.map((r) => r.join(" | ")).join("\n"));
  }

  // -------------------- EXPORTAR INVENTARIO --------------------

  static Future<void> exportInventario() async {
    final productos = await DBService.getProducts();

    final rows = <List<dynamic>>[];

    rows.add(["Producto", "Stock", "Precio Efectivo", "Precio Transferencia"]);

    for (var p in productos) {
      rows.add([
        p['name'],
        p['stock'],
        p['price_cash'],
        p['price_transfer'],
      ]);
    }

    await _saveCsv("inventario.csv", rows);
    await _saveExcel("inventario.xlsx", rows);
    await _saveTxt("inventario.txt", rows.map((r) => r.join(" | ")).join("\n"));
  }

  // -------------------- EXPORTAR PRODUCTOS VENDIDOS --------------------

  static Future<void> exportProductosVendidos() async {
    final items = await DBService.getSaleItems();
    final productos = await DBService.getProducts();

    final rows = <List<dynamic>>[];

    rows.add(["Producto", "Cantidad total vendida", "Total generado"]);

    final map = <String, Map<String, dynamic>>{};

    for (var it in items) {
      final p = productos[it['product_id']]['name'];
      final qty = it['quantity'];
      final price = it['price'];

      map[p] ??= {"qty": 0, "total": 0.0};
      map[p]!["qty"] += qty;
      map[p]!["total"] += qty * price;
    }

    for (var p in map.keys) {
      rows.add([p, map[p]!["qty"], map[p]!["total"]]);
    }

    await _saveCsv("productos_vendidos.csv", rows);
    await _saveExcel("productos_vendidos.xlsx", rows);
    await _saveTxt(
        "productos_vendidos.txt", rows.map((r) => r.join(" | ")).join("\n"));
  }

  // -------------------- EXPORTAR TODO --------------------

  static Future<void> exportTodo() async {
    await exportVentasDia();
    await exportMovimientosDia();
    await exportInventario();
    await exportProductosVendidos();
  }
}
