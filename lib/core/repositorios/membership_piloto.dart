import '../modelos/membership.dart';
import 'membership_local.dart';

/// Prueba de Champ sin catálogo comercial ni cobros.
class RepositorioMembershipPiloto implements RepositorioMembership {
  @override
  Future<List<PlanMembership>> cargarPlanes() async => const [];
  @override
  Future<EstadoMembership> cargarEstado() async =>
      const EstadoMembership.vacio();
  @override
  Future<EstadoMembership> quitar() async => const EstadoMembership.vacio();
  @override
  Future<EstadoMembership> seleccionar(String planId) async =>
      throw StateError('Champ está en prueba sin cobros.');
  @override
  Future<EstadoMembership> dejarPendiente(
    PlanMembership condicionesVistas,
  ) async => throw StateError('Los cobros todavía no están habilitados.');
}
