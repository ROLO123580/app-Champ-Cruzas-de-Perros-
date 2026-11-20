class BorradorEvento {
  const BorradorEvento({
    required this.titulo,
    required this.descripcion,
    required this.lugar,
    required this.zona,
    required this.inicio,
    required this.cupos,
    this.duracionMinutos = 60,
    this.esPaseo = false,
  });
  final String titulo, descripcion, lugar, zona;
  final DateTime inicio;
  final int cupos, duracionMinutos;
  final bool esPaseo;

  void validar([DateTime? ahora]) {
    for (final campo in [titulo, lugar, zona]) {
      if (campo.trim().isEmpty || campo.trim().length > 120) {
        throw StateError(
          'Completa título, lugar y zona (hasta 120 caracteres).',
        );
      }
    }
    if (descripcion.trim().isEmpty || descripcion.trim().length > 2000) {
      throw StateError('Escribe una descripción de hasta 2000 caracteres.');
    }
    if (!inicio.isAfter(ahora ?? DateTime.now())) {
      throw StateError('Elige una fecha y hora futuras.');
    }
    if (cupos < 2 || cupos > 100) {
      throw StateError('Elige entre 2 y 100 cupos, incluyendo al organizador.');
    }
    if (duracionMinutos < 15 || duracionMinutos > 720) {
      throw StateError('La duración debe estar entre 15 y 720 minutos.');
    }
  }
}

class EventoChamp {
  const EventoChamp({
    required this.id,
    required this.autorUid,
    required this.autorNombre,
    required this.datos,
    required this.participantes,
    this.cancelado = false,
    this.pendiente = false,
  });
  final String id, autorUid, autorNombre;
  final BorradorEvento datos;
  final Map<String, String> participantes;
  final bool cancelado, pendiente;
  int get disponibles => datos.cupos - participantes.length;
  DateTime get fin =>
      datos.inicio.add(Duration(minutes: datos.duracionMinutos));
  bool get finalizado => !fin.isAfter(DateTime.now());
  bool get inscripcionesAbiertas =>
      !cancelado && datos.inicio.isAfter(DateTime.now());
  bool get chatAbierto => !cancelado && !finalizado;
}

class PublicacionChamp {
  const PublicacionChamp({
    required this.id,
    required this.autorNombre,
    required this.texto,
    required this.fecha,
    this.pendiente = false,
  });
  final String id, autorNombre, texto;
  final DateTime fecha;
  final bool pendiente;
}

class MensajeEvento {
  const MensajeEvento({
    required this.id,
    required this.uid,
    required this.nombre,
    required this.texto,
    required this.fecha,
    this.pendiente = false,
  });
  final String id, uid, nombre, texto;
  final DateTime fecha;
  final bool pendiente;
}
