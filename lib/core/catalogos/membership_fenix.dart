import '../modelos/membership.dart';
import '../persistencia/base_local.dart';

/// Traslado literal del catálogo de la implementación funcional de referencia:
/// /home/rolo/flutter_projects/fenix_fitness/lib/membership/app_memb.dart.
/// USD procede de membership_service.dart; mes y 19% de app_memb/app_carro.
/// Los beneficios de Fitness quedan señalados como pendientes en Champ.
List<PlanMembership> planesReferenciaFenix() => [
  PlanMembership(
    id: 'fenix_free',
    nombre: 'Free',
    descripcion: 'Comienza tu camino',
    precioMenor: 0,
    decimalesMoneda: 2,
    moneda: 'USD',
    periodo: 'mes',
    beneficios: const [
      'Registro de consumos',
      'Gastos energéticos',
      'Seguimiento básico',
    ],
    procedencia: 'Fénix Fitness',
    requiereAdaptacion: true,
    impuestoPuntosBase: 1900,
    ordenCatalogo: 1,
  ),
  PlanMembership(
    id: 'fenix_pro',
    nombre: 'Pro',
    descripcion: 'Entrena con más control',
    precioMenor: 999,
    decimalesMoneda: 2,
    moneda: 'USD',
    periodo: 'mes',
    beneficios: const [
      'Todo lo de Free',
      'Análisis nutricional',
      'Estadísticas',
      'Sincronización',
    ],
    procedencia: 'Fénix Fitness',
    requiereAdaptacion: true,
    impuestoPuntosBase: 1900,
    ordenCatalogo: 2,
  ),
  PlanMembership(
    id: 'fenix_elite',
    nombre: 'Elite',
    descripcion: 'Sin límites',
    precioMenor: 1999,
    decimalesMoneda: 2,
    moneda: 'USD',
    periodo: 'mes',
    beneficios: const [
      'Todo lo de Pro',
      'IA premium',
      'Reportes avanzados',
      'Soporte prioritario',
    ],
    procedencia: 'Fénix Fitness',
    requiereAdaptacion: true,
    impuestoPuntosBase: 1900,
    ordenCatalogo: 3,
  ),
];

class ImportarCatalogoMembershipFenix {
  const ImportarCatalogoMembershipFenix(this.base);
  final BaseLocal base;
  static const version = 'membership_fenix_2026_10_20_v1';

  Future<void> preparar() async {
    if (await base.obtener('meta', version) != null) return;
    // Un solo lote inserta únicamente lo que falta y publica el marcador.
    // Otra app/ventana o un futuro catálogo no reemplazan registros existentes.
    await base.aplicar([
      for (final plan in planesReferenciaFenix())
        {
          'tipo': 'guardar_si_nuevo',
          'coleccion': 'planes_membership',
          'id': plan.id,
          'datos': plan.toJson(),
        },
      {
        'tipo': 'guardar_si_nuevo',
        'coleccion': 'meta',
        'id': version,
        'datos': {
          'id': version,
          'fuente': '/home/rolo/flutter_projects/fenix_fitness',
          'catalogo': 'referencia_pendiente_de_adaptacion_champ',
        },
      },
    ]);
  }
}
