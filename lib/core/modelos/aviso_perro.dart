import 'dart:convert';
import 'dart:typed_data';

enum TipoAvisoPerro { perdido, encontrado }

class DatosAvisoPerro {
  const DatosAvisoPerro({
    required this.tipo,
    required this.nombre,
    required this.raza,
    required this.zona,
    required this.lugar,
    required this.descripcion,
    required this.fechaVista,
    this.chip = 'desconocido',
    this.chipUltimos = '',
    this.fotoBase64 = '',
  });
  final TipoAvisoPerro tipo;
  final String nombre,
      raza,
      zona,
      lugar,
      descripcion,
      chip,
      chipUltimos,
      fotoBase64;
  final DateTime fechaVista;
  void validar() {
    if (nombre.trim().length > 80 || raza.trim().length > 80) {
      throw StateError('Nombre y raza admiten hasta 80 caracteres.');
    }
    if (zona.trim().isEmpty ||
        zona.trim().length > 120 ||
        lugar.trim().isEmpty ||
        lugar.trim().length > 160) {
      throw StateError('Indica una zona y un lugar de referencia.');
    }
    if (descripcion.trim().isEmpty || descripcion.trim().length > 2000) {
      throw StateError('Describe al perro en hasta 2000 caracteres.');
    }
    if (fechaVista.isAfter(DateTime.now()) || fechaVista.year < 2000) {
      throw StateError('La fecha del avistamiento no puede ser futura.');
    }
    if (!['si', 'no', 'desconocido'].contains(chip) ||
        (chipUltimos.isNotEmpty &&
            (chip != 'si' || !RegExp(r'^\d{4}$').hasMatch(chipUltimos)))) {
      throw StateError(
        'Indica solo los últimos cuatro dígitos del chip, si los conoces.',
      );
    }
    if (fotoBase64.length > 120000 ||
        (fotoBase64.isNotEmpty && !fotoBase64.startsWith('iVBORw0KGgo'))) {
      throw StateError('Selecciona una foto desde el botón de imagen.');
    }
  }

  Uint8List? get foto {
    if (fotoBase64.isEmpty) return null;
    try {
      return base64Decode(fotoBase64);
    } on FormatException {
      return null;
    }
  }

  Map<String, dynamic> toMap() => {
    'tipo': tipo.name,
    'nombre': nombre.trim(),
    'raza': raza.trim(),
    'zona': zona.trim(),
    'lugar': lugar.trim(),
    'descripcion': descripcion.trim(),
    'fechaVistaMs': fechaVista.millisecondsSinceEpoch,
    'chip': chip,
    'chipUltimos': chipUltimos,
    'foto': fotoBase64,
  };
  factory DatosAvisoPerro.fromMap(Map<String, dynamic> d) => DatosAvisoPerro(
    tipo: TipoAvisoPerro.values.byName(d['tipo'] as String),
    nombre: d['nombre'] as String,
    raza: d['raza'] as String,
    zona: d['zona'] as String,
    lugar: d['lugar'] as String,
    descripcion: d['descripcion'] as String,
    fechaVista: DateTime.fromMillisecondsSinceEpoch(d['fechaVistaMs'] as int),
    chip: d['chip'] as String,
    chipUltimos: d['chipUltimos'] as String,
    fotoBase64: d['foto'] as String,
  );
}

class AvisoPerro {
  const AvisoPerro({
    required this.id,
    required this.autorUid,
    required this.autorNombre,
    required this.datos,
    this.resuelto = false,
    this.notaCierre = '',
    this.pendiente = false,
  });
  final String id, autorUid, autorNombre, notaCierre;
  final DatosAvisoPerro datos;
  final bool resuelto, pendiente;
  String get titulo =>
      datos.nombre.isEmpty ? 'Perro sin identificar' : datos.nombre;
}
