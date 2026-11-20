import 'dart:convert';
import 'dart:typed_data';

class Mensaje {
  Mensaje({
    required this.id,
    required this.fecha,
    this.texto,
    this.foto,
    this.remitenteId,
    this.pendiente = false,
  });
  final String? remitenteId;
  final bool pendiente;
  final String id;
  final DateTime fecha;
  final String? texto;
  final Uint8List? foto;
  Map<String, dynamic> toJson() => {
    'id': id,
    'fecha': fecha.toIso8601String(),
    'texto': texto,
    if (remitenteId != null) 'remitenteId': remitenteId,
    'foto': foto == null ? null : base64Encode(foto!),
  };
  factory Mensaje.fromJson(Map<String, dynamic> j) => Mensaje(
    id: j['id'] as String,
    fecha: DateTime.parse(j['fecha'] as String),
    texto: j['texto'] as String?,
    remitenteId: j['remitenteId'] as String?,
    foto: j['foto'] == null ? null : base64Decode(j['foto'] as String),
  );
}

class Conversacion {
  Conversacion({
    required this.id,
    required this.nombre,
    required this.fecha,
    List<Mensaje> mensajes = const [],
    List<String> participantes = const [],
    this.ultimaActividad,
    this.ultimoTexto,
  }) : mensajes = List.unmodifiable(mensajes),
       participantes = List.unmodifiable(participantes);
  final List<String> participantes;
  final DateTime? ultimaActividad;
  final String? ultimoTexto;
  bool get entreUsuarios => participantes.isNotEmpty;
  final String id;
  final String nombre;
  final DateTime fecha;
  final List<Mensaje> mensajes;
  DateTime get actualizada =>
      ultimaActividad ?? (mensajes.isEmpty ? fecha : mensajes.last.fecha);
  Conversacion agregar(Mensaje mensaje) => Conversacion(
    id: id,
    nombre: nombre,
    fecha: fecha,
    mensajes: [...mensajes, mensaje],
    participantes: participantes,
  );
  Map<String, dynamic> toJson() => {
    'id': id,
    'nombre': nombre,
    'fecha': fecha.toIso8601String(),
    'mensajes': mensajes.map((m) => m.toJson()).toList(),
  };
  factory Conversacion.fromJson(Map<String, dynamic> j) => Conversacion(
    id: j['id'] as String,
    nombre: j['nombre'] as String,
    fecha: DateTime.parse(j['fecha'] as String),
    mensajes: (j['mensajes'] as List)
        .map((m) => Mensaje.fromJson(m as Map<String, dynamic>))
        .toList(),
  );
}
