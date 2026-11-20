import '../modelos/membership.dart';
import '../catalogos/membership_fenix.dart';
import '../persistencia/base_local.dart';

abstract class RepositorioMembership {
  Future<List<PlanMembership>> cargarPlanes();
  Future<EstadoMembership> cargarEstado();
  Future<EstadoMembership> seleccionar(String planId);
  Future<EstadoMembership> dejarPendiente(PlanMembership condicionesVistas);
  Future<EstadoMembership> quitar();
}

/// Usa el cliente BaseLocal de la aplicación; no abre SQLite ni guarda tokens.
class RepositorioMembershipLocal implements RepositorioMembership {
  RepositorioMembershipLocal(this.base, {this.sembrarReferenciaFenix = true});
  final BaseLocal base;
  final bool sembrarReferenciaFenix;

  Future<void> _preparar() async {
    if (sembrarReferenciaFenix) {
      await ImportarCatalogoMembershipFenix(base).preparar();
    }
  }

  @override
  Future<List<PlanMembership>> cargarPlanes() async {
    await _preparar();
    final planes = (await base.listar('planes_membership'))
        .map(PlanMembership.fromJson)
        .where((plan) => plan.disponible)
        .toList();
    planes.sort((a, b) {
      final orden = a.ordenCatalogo.compareTo(b.ordenCatalogo);
      return orden == 0 ? a.nombre.compareTo(b.nombre) : orden;
    });
    return List.unmodifiable(planes);
  }

  @override
  Future<EstadoMembership> cargarEstado() async {
    final datos = await base.obtener('membership', 'estado');
    return datos == null
        ? const EstadoMembership.vacio()
        : EstadoMembership.fromJson(datos);
  }

  Future<PlanMembership> _planDisponible(String id) async {
    await _preparar();
    final datos = await base.obtener('planes_membership', id);
    if (datos == null) {
      throw StateError(
        'Este plan ya no está disponible. Actualiza los planes.',
      );
    }
    final plan = PlanMembership.fromJson(datos);
    if (!plan.disponible || plan.id != id) {
      throw StateError(
        'Este plan ya no está disponible. Actualiza los planes.',
      );
    }
    return plan;
  }

  Future<EstadoMembership> _guardar(EstadoMembership estado) async {
    // Selección y carro son el mismo documento, confirmado en una transacción.
    // No se crean filas de pago, membresía activa ni bases por usuario.
    await base.guardar('membership', 'estado', estado.toJson());
    return estado;
  }

  @override
  Future<EstadoMembership> seleccionar(String planId) async =>
      _guardar(EstadoMembership.seleccionado(await _planDisponible(planId)));

  @override
  Future<EstadoMembership> dejarPendiente(
    PlanMembership condicionesVistas,
  ) async {
    final actual = await cargarEstado();
    final seleccionado = actual.plan;
    if (seleccionado == null ||
        !seleccionado.mismasCondiciones(condicionesVistas)) {
      throw StateError('La selección cambió. Actualiza el Carro.');
    }
    final publicado = await _planDisponible(seleccionado.id);
    if (!publicado.mismasCondiciones(seleccionado)) {
      throw StateError(
        'Las condiciones del plan cambiaron. Vuelve a seleccionar el plan.',
      );
    }
    return _guardar(EstadoMembership.pendiente(seleccionado));
  }

  @override
  Future<EstadoMembership> quitar() => _guardar(const EstadoMembership.vacio());
}
