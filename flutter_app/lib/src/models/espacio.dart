class Espacio {
  final int id;

  /// Fútbol, Tenis, Paddle, etc.
  final String tipo;

  /// Número del espacio dentro de la sede
  final int numero;
  final String nombre;
  final double precioHora;

  const Espacio({
    required this.id,
    required this.tipo,
    required this.numero,
    required this.nombre,
    required this.precioHora,
  });

  factory Espacio.fromJson(Map<String, dynamic> json) => Espacio(
    id: json['id'],
    tipo: json['tipo'],
    numero: json['numero'],
    nombre: json['nombre'],
    // La API devuelve el precio como string decimal ("3200.00")
    precioHora: double.parse(json['precio_hora'].toString()),
  );

  /// "Fútbol 1"
  String get titulo => '$tipo $numero';
}
