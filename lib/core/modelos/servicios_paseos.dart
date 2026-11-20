class PerfilPaseador {
  const PerfilPaseador({
    required this.uid,
    required this.nombre,
    required this.zona,
    required this.descripcion,
    required this.condiciones,
    required this.disponibilidad,
    this.duracion = 60,
    this.activo = true,
    this.revision = 0,
  });
  final String uid, nombre, zona, descripcion, condiciones, disponibilidad;
  final int duracion, revision;
  final bool activo;
  void validar() {
    if (nombre.trim().isEmpty ||
        nombre.trim().length > 120 ||
        zona.trim().isEmpty ||
        zona.trim().length > 120) {
      throw StateError('Completa nombre y zona de cobertura.');
    }
    if (descripcion.trim().isEmpty ||
        descripcion.trim().length > 1500 ||
        condiciones.trim().isEmpty ||
        condiciones.trim().length > 1500 ||
        disponibilidad.trim().isEmpty ||
        disponibilidad.trim().length > 500) {
      throw StateError(
        'Completa presentación, disponibilidad y condiciones del servicio.',
      );
    }
    if (![30, 60, 90, 120].contains(duracion)) {
      throw StateError('Elige una duración de 30, 60, 90 o 120 minutos.');
    }
  }

  Map<String, dynamic> toMap() => {
    'nombre': nombre.trim(),
    'zona': zona.trim(),
    'descripcion': descripcion.trim(),
    'condiciones': condiciones.trim(),
    'disponibilidad': disponibilidad.trim(),
    'duracion': duracion,
    'activo': activo,
    'revision': revision,
  };
  factory PerfilPaseador.fromMap(String uid, Map<String, dynamic> d) =>
      PerfilPaseador(
        uid: uid,
        nombre: d['nombre'] as String,
        zona: d['zona'] as String,
        descripcion: d['descripcion'] as String,
        condiciones: d['condiciones'] as String,
        disponibilidad: d['disponibilidad'] as String,
        duracion: d['duracion'] as int,
        activo: d['activo'] as bool,
        revision: d['revision'] as int,
      );
}

enum EstadoReservaPaseo {
  solicitada,
  aceptada,
  rechazada,
  cancelada,
  enCurso,
  finalizada,
}

class SolicitudPaseo {
  const SolicitudPaseo({
    required this.paseador,
    required this.perro,
    required this.zona,
    required this.inicio,
    this.nota = '',
  });
  final PerfilPaseador paseador;
  final String perro, zona, nota;
  final DateTime inicio;
  void validar() {
    if (perro.trim().isEmpty ||
        perro.trim().length > 80 ||
        zona.trim().isEmpty ||
        zona.trim().length > 160 ||
        nota.trim().length > 1000) {
      throw StateError('Completa el perro y la zona de encuentro.');
    }
    if (!inicio.isAfter(DateTime.now()) ||
        inicio.millisecondsSinceEpoch % 1800000 != 0) {
      throw StateError(
        'Elige una fecha futura y un horario en intervalos de 30 minutos.',
      );
    }
    if (!paseador.activo || paseador.revision < 1) {
      throw StateError('Este paseador no está recibiendo solicitudes.');
    }
  }
}

class ReservaPaseo {
  const ReservaPaseo({
    required this.id,
    required this.clienteUid,
    required this.clienteNombre,
    required this.paseadorUid,
    required this.paseadorNombre,
    required this.perro,
    required this.zona,
    required this.inicio,
    required this.duracion,
    required this.condiciones,
    required this.nota,
    required this.estado,
    this.pendiente = false,
  });
  final String id,
      clienteUid,
      clienteNombre,
      paseadorUid,
      paseadorNombre,
      perro,
      zona,
      condiciones,
      nota;
  final DateTime inicio;
  final int duracion;
  final EstadoReservaPaseo estado;
  final bool pendiente;
  List<int> get bloques => List.generate(
    duracion ~/ 30,
    (i) => inicio.millisecondsSinceEpoch ~/ 1800000 + i,
  );
  bool get cerrada => [
    EstadoReservaPaseo.rechazada,
    EstadoReservaPaseo.cancelada,
    EstadoReservaPaseo.finalizada,
  ].contains(estado);
  String get etiqueta => switch (estado) {
    EstadoReservaPaseo.enCurso => 'En curso',
    EstadoReservaPaseo.solicitada => 'Solicitada',
    EstadoReservaPaseo.aceptada => 'Aceptada',
    EstadoReservaPaseo.rechazada => 'Rechazada',
    EstadoReservaPaseo.cancelada => 'Cancelada',
    EstadoReservaPaseo.finalizada => 'Finalizada',
  };
  List<EstadoReservaPaseo> acciones(String uid) {
    if (uid != clienteUid && uid != paseadorUid) return const [];
    return switch (estado) {
      EstadoReservaPaseo.solicitada =>
        uid == paseadorUid
            ? [EstadoReservaPaseo.aceptada, EstadoReservaPaseo.rechazada]
            : [EstadoReservaPaseo.cancelada],
      EstadoReservaPaseo.aceptada => [
        EstadoReservaPaseo.cancelada,
        if (uid == paseadorUid && !inicio.isAfter(DateTime.now()))
          EstadoReservaPaseo.enCurso,
      ],
      EstadoReservaPaseo.enCurso =>
        uid == paseadorUid ? [EstadoReservaPaseo.finalizada] : [],
      _ => [],
    };
  }

  factory ReservaPaseo.fromMap(
    String id,
    Map<String, dynamic> d, {
    bool pendiente = false,
  }) => ReservaPaseo(
    id: id,
    clienteUid: d['clienteUid'] as String,
    clienteNombre: d['clienteNombre'] as String,
    paseadorUid: d['paseadorUid'] as String,
    paseadorNombre: d['paseadorNombre'] as String,
    perro: d['perro'] as String,
    zona: d['zona'] as String,
    inicio: DateTime.fromMillisecondsSinceEpoch(d['inicioMs'] as int),
    duracion: d['duracion'] as int,
    condiciones: d['condiciones'] as String,
    nota: d['nota'] as String,
    estado: EstadoReservaPaseo.values.byName(d['estado'] as String),
    pendiente: pendiente,
  );
}
