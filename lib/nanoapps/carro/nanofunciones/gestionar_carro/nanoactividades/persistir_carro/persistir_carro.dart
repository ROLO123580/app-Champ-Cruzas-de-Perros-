import '../../../../../../core/modelos/membership.dart';
import '../../../../../../core/repositorios/membership_local.dart';

class PersistirCarroActividad {
  const PersistirCarroActividad(this.repositorio);
  final RepositorioMembership repositorio;

  Future<EstadoMembership> cargar() => repositorio.cargarEstado();
  Future<EstadoMembership> dejarPendiente(PlanMembership condicionesVistas) =>
      repositorio.dejarPendiente(condicionesVistas);
  Future<EstadoMembership> quitar() => repositorio.quitar();
}
