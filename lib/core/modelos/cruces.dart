import 'dart:convert';
import 'dart:typed_data';

class PerfilPerro {
  const PerfilPerro({
    required this.id,
    required this.nombre,
    required this.raza,
    required this.sexo,
    required this.edadMeses,
    required this.ciudad,
    required this.responsable,
    required this.descripcion,
    this.foto,
    this.imagenUrl,
    this.interesDemo = false,
  });

  final String id;
  final String nombre;
  final String raza;
  final String sexo;
  final int edadMeses;
  final String ciudad;
  final String responsable;
  final String descripcion;
  final Uint8List? foto;
  final String? imagenUrl;
  final bool interesDemo;

  String get edad => edadMeses < 12
      ? '$edadMeses meses'
      : '${edadMeses ~/ 12} años${edadMeses % 12 == 0 ? '' : ' y ${edadMeses % 12} meses'}';

  Map<String, dynamic> toJson() => {
    'id': id,
    'nombre': nombre,
    'raza': raza,
    'sexo': sexo,
    'edadMeses': edadMeses,
    'ciudad': ciudad,
    'responsable': responsable,
    'descripcion': descripcion,
    'foto': foto == null ? null : base64Encode(foto!),
    'imagenUrl': imagenUrl,
    'interesDemo': interesDemo,
  };

  factory PerfilPerro.fromJson(Map<String, dynamic> j) => PerfilPerro(
    id: j['id'] as String,
    nombre: j['nombre'] as String,
    raza: j['raza'] as String,
    sexo: j['sexo'] as String,
    edadMeses: j['edadMeses'] as int,
    ciudad: j['ciudad'] as String,
    responsable: j['responsable'] as String,
    descripcion: j['descripcion'] as String,
    foto: j['foto'] == null ? null : base64Decode(j['foto'] as String),
    imagenUrl: j['imagenUrl'] as String?,
    interesDemo: j['interesDemo'] as bool? ?? false,
  );
}

enum DecisionCruce { gusta, pasar }

class EstadoCruces {
  EstadoCruces({
    this.miPerro,
    Map<String, DecisionCruce> decisiones = const {},
    Set<String> matches = const {},
  }) : decisiones = Map.unmodifiable(decisiones),
       matches = Set.unmodifiable(matches);
  final PerfilPerro? miPerro;
  final Map<String, DecisionCruce> decisiones;
  final Set<String> matches;

  Map<String, dynamic> toJson() => {
    'miPerro': miPerro?.toJson(),
    'decisiones': decisiones.map((k, v) => MapEntry(k, v.name)),
    'matches': matches.toList(),
  };

  factory EstadoCruces.fromJson(Map<String, dynamic> j) => EstadoCruces(
    miPerro: j['miPerro'] == null
        ? null
        : PerfilPerro.fromJson(j['miPerro'] as Map<String, dynamic>),
    decisiones: (j['decisiones'] as Map<String, dynamic>).map(
      (k, v) => MapEntry(k, DecisionCruce.values.byName(v as String)),
    ),
    matches: (j['matches'] as List).cast<String>().toSet(),
  );
}
