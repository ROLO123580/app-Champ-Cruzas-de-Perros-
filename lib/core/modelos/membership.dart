/// Un precio explícito del catálogo, conservado sin redondeos de coma flotante.
class PlanMembership {
  factory PlanMembership({
    required String id,
    required String nombre,
    required int precioMenor,
    required int decimalesMoneda,
    required String moneda,
    required String periodo,
    required List<String> beneficios,
    String descripcion = '',
    bool disponible = true,
    String? procedencia,
    bool requiereAdaptacion = false,
    int? impuestoPuntosBase,
    int ordenCatalogo = 0,
  }) {
    if (id.trim().isEmpty ||
        nombre.trim().isEmpty ||
        precioMenor < 0 ||
        decimalesMoneda < 0 ||
        decimalesMoneda > 4 ||
        !RegExp(r'^[A-Z]{3}$').hasMatch(moneda) ||
        periodo.trim().isEmpty ||
        (procedencia != null && procedencia.trim().isEmpty) ||
        (impuestoPuntosBase != null &&
            (impuestoPuntosBase < 0 || impuestoPuntosBase > 10000)) ||
        beneficios.any((valor) => valor.trim().isEmpty)) {
      throw const FormatException('El plan tiene datos o un precio inválidos.');
    }
    return PlanMembership._(
      id: id.trim(),
      nombre: nombre.trim(),
      precioMenor: precioMenor,
      decimalesMoneda: decimalesMoneda,
      moneda: moneda,
      periodo: periodo.trim(),
      beneficios: List.unmodifiable(beneficios.map((valor) => valor.trim())),
      descripcion: descripcion.trim(),
      disponible: disponible,
      procedencia: procedencia?.trim(),
      requiereAdaptacion: requiereAdaptacion,
      impuestoPuntosBase: impuestoPuntosBase,
      ordenCatalogo: ordenCatalogo,
    );
  }

  const PlanMembership._({
    required this.id,
    required this.nombre,
    required this.precioMenor,
    required this.decimalesMoneda,
    required this.moneda,
    required this.periodo,
    required this.beneficios,
    required this.descripcion,
    required this.disponible,
    required this.procedencia,
    required this.requiereAdaptacion,
    required this.impuestoPuntosBase,
    required this.ordenCatalogo,
  });

  final String id;
  final String nombre;
  final int precioMenor;
  final int decimalesMoneda;
  final String moneda;
  final String periodo;
  final List<String> beneficios;
  final String descripcion;
  final bool disponible;
  final String? procedencia;
  final bool requiereAdaptacion;
  final int? impuestoPuntosBase;
  final int ordenCatalogo;

  String importePresentado(int unidadesMenores) {
    final cifras = unidadesMenores.toString().padLeft(decimalesMoneda + 1, '0');
    final importe = decimalesMoneda == 0
        ? cifras
        : '${cifras.substring(0, cifras.length - decimalesMoneda)}'
              '.${cifras.substring(cifras.length - decimalesMoneda)}';
    return '$moneda $importe';
  }

  String get precioPresentado => '${importePresentado(precioMenor)} / $periodo';

  /// Redondeo positivo a la unidad monetaria menor, equivalente al resumen
  /// de Fénix, conservando cantidades enteras durante el cálculo.
  int? get impuestosMenor => impuestoPuntosBase == null
      ? null
      : (precioMenor * impuestoPuntosBase! + 5000) ~/ 10000;
  int get totalMenor => precioMenor + (impuestosMenor ?? 0);
  String? get porcentajeImpuesto {
    final puntos = impuestoPuntosBase;
    if (puntos == null) return null;
    final enteros = puntos ~/ 100;
    final centesimas = puntos % 100;
    return centesimas == 0
        ? '$enteros%'
        : '$enteros.${centesimas.toString().padLeft(2, '0')}%';
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'nombre': nombre,
    'precioMenor': precioMenor,
    'decimalesMoneda': decimalesMoneda,
    'moneda': moneda,
    'periodo': periodo,
    'beneficios': beneficios,
    'descripcion': descripcion,
    'disponible': disponible,
    if (procedencia != null) 'procedencia': procedencia,
    'requiereAdaptacion': requiereAdaptacion,
    if (impuestoPuntosBase != null) 'impuestoPuntosBase': impuestoPuntosBase,
    'ordenCatalogo': ordenCatalogo,
  };

  factory PlanMembership.fromJson(Map<String, dynamic> datos) {
    final beneficios = datos['beneficios'];
    if (datos['id'] is! String ||
        datos['nombre'] is! String ||
        datos['precioMenor'] is! int ||
        datos['decimalesMoneda'] is! int ||
        datos['moneda'] is! String ||
        datos['periodo'] is! String ||
        beneficios is! List ||
        beneficios.any((valor) => valor is! String) ||
        (datos['descripcion'] != null && datos['descripcion'] is! String) ||
        (datos['disponible'] != null && datos['disponible'] is! bool) ||
        (datos['procedencia'] != null && datos['procedencia'] is! String) ||
        (datos['requiereAdaptacion'] != null &&
            datos['requiereAdaptacion'] is! bool) ||
        (datos['impuestoPuntosBase'] != null &&
            datos['impuestoPuntosBase'] is! int) ||
        (datos['ordenCatalogo'] != null && datos['ordenCatalogo'] is! int)) {
      throw const FormatException('El catálogo contiene un plan inválido.');
    }
    return PlanMembership(
      id: datos['id'] as String,
      nombre: datos['nombre'] as String,
      precioMenor: datos['precioMenor'] as int,
      decimalesMoneda: datos['decimalesMoneda'] as int,
      moneda: datos['moneda'] as String,
      periodo: datos['periodo'] as String,
      beneficios: beneficios.cast<String>(),
      descripcion: datos['descripcion'] as String? ?? '',
      disponible: datos['disponible'] as bool? ?? true,
      procedencia: datos['procedencia'] as String?,
      requiereAdaptacion: datos['requiereAdaptacion'] as bool? ?? false,
      impuestoPuntosBase: datos['impuestoPuntosBase'] as int?,
      ordenCatalogo: datos['ordenCatalogo'] as int? ?? 0,
    );
  }

  bool mismasCondiciones(PlanMembership otro) =>
      id == otro.id &&
      nombre == otro.nombre &&
      precioMenor == otro.precioMenor &&
      decimalesMoneda == otro.decimalesMoneda &&
      moneda == otro.moneda &&
      periodo == otro.periodo &&
      descripcion == otro.descripcion &&
      procedencia == otro.procedencia &&
      requiereAdaptacion == otro.requiereAdaptacion &&
      impuestoPuntosBase == otro.impuestoPuntosBase &&
      beneficios.length == otro.beneficios.length &&
      List.generate(
        beneficios.length,
        (indice) => beneficios[indice] == otro.beneficios[indice],
      ).every((igual) => igual);
}

enum EstadoContratacion { sinSeleccion, seleccionado, pendiente }

/// Estado local de intención de contratación. No representa un pago.
class EstadoMembership {
  const EstadoMembership.vacio()
    : plan = null,
      contratacion = EstadoContratacion.sinSeleccion;

  const EstadoMembership.seleccionado(PlanMembership this.plan)
    : contratacion = EstadoContratacion.seleccionado;

  const EstadoMembership.pendiente(PlanMembership this.plan)
    : contratacion = EstadoContratacion.pendiente;

  final PlanMembership? plan;
  final EstadoContratacion contratacion;

  // Una autoridad de contratación/pago todavía no existe en Champ.
  // Ningún documento local ni sesión de Google concede permisos pagados.
  bool get membresiaActiva => false;

  Map<String, dynamic> toJson() => {
    'id': 'estado',
    'version': 1,
    'plan': plan?.toJson(),
    'contratacion': contratacion.name,
  };

  factory EstadoMembership.fromJson(Map<String, dynamic> datos) {
    if (datos['version'] != 1) {
      throw const FormatException('Versión de Membership no compatible.');
    }
    final estado = datos['contratacion'];
    final plan = datos['plan'];
    if (estado == EstadoContratacion.sinSeleccion.name && plan == null) {
      return const EstadoMembership.vacio();
    }
    if (plan is! Map ||
        ![
          EstadoContratacion.seleccionado.name,
          EstadoContratacion.pendiente.name,
        ].contains(estado)) {
      throw const FormatException('El estado de Membership es inválido.');
    }
    final seleccionado = PlanMembership.fromJson(
      Map<String, dynamic>.from(plan),
    );
    return estado == EstadoContratacion.pendiente.name
        ? EstadoMembership.pendiente(seleccionado)
        : EstadoMembership.seleccionado(seleccionado);
  }
}
