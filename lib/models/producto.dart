class Producto {
  int? id;
  String codigo;
  String nombre;
  double precio;
  double costo;
  double stock;
  String categoria;
  String? foto;

  Producto({
    this.id,
    required this.codigo,
    required this.nombre,
    required this.precio,
    required this.costo,
    required this.stock,
    required this.categoria,
    this.foto,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'codigo': codigo,
      'nombre': nombre,
      'precio': precio,
      'costo': costo,
      'stock': stock,
      'categoria': categoria,
      'foto': foto,
    };
  }

  factory Producto.fromMap(Map<String, dynamic> map) {
    return Producto(
      id: map['id'],
      codigo: map['codigo'],
      nombre: map['nombre'],
      precio: map['precio'],
      costo: map['costo'],
      stock: map['stock'],
      categoria: map['categoria'],
      foto: map['foto'],
    );
  }
}
