class Usuario {
  final String uid;
  final String email;
  final String nombre;
  final String apellido;
  final String dni;
  final DateTime fechaNacimiento;

  const Usuario({
    required this.uid,
    required this.email,
    required this.nombre,
    required this.apellido,
    required this.dni,
    required this.fechaNacimiento,
  });

  factory Usuario.fromJson(Map<String, dynamic> json) => Usuario(
    uid: json['uid'],
    email: json['email'],
    nombre: json['nombre'],
    apellido: json['apellido'],
    dni: json['dni'],
    fechaNacimiento: DateTime.parse(json['fecha_nacimiento']),
  );

  String get nombreCompleto => '$nombre $apellido';

  String get iniciales =>
      '${nombre.isNotEmpty ? nombre[0] : ''}${apellido.isNotEmpty ? apellido[0] : ''}'
          .toUpperCase();
}
