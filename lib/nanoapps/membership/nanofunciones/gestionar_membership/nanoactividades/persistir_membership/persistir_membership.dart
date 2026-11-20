import '../../../../../../core/modelos/membership.dart';
import '../../../../../../core/repositorios/membership_local.dart';

class PersistirMembershipActividad {
  const PersistirMembershipActividad(this.repositorio);
  final RepositorioMembership repositorio;

  Future<List<PlanMembership>> planes() => repositorio.cargarPlanes();
  Future<EstadoMembership> estado() => repositorio.cargarEstado();
  Future<EstadoMembership> seleccionar(String id) =>
      repositorio.seleccionar(id);
}
