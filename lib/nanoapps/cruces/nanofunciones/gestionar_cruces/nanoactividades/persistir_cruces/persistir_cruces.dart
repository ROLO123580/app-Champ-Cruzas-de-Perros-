import 'package:champ/core/modelos/cruces.dart';
import 'package:champ/core/repositorios/contratos.dart';

class PersistirCrucesActividad {
  PersistirCrucesActividad(this.repositorio);
  final AlmacenCruces repositorio;
  bool get enCuenta => repositorio.enCuenta;
  Future<EstadoCruces> cargar() => repositorio.cargar();
  Future<List<PerfilPerro>> perfiles() => repositorio.cargarPerfiles();
  Future<void> guardar(EstadoCruces estado) => repositorio.guardar(estado);
  Future<EstadoCruces> guardarPerfil(PerfilPerro perfil) =>
      repositorio.guardarPerfil(perfil);
  Future<EstadoCruces> revisarDescartados(EstadoCruces estado) =>
      repositorio.revisarDescartados(estado);
  Future<EstadoCruces> decidir(
    EstadoCruces estado,
    PerfilPerro perfil,
    DecisionCruce decision,
  ) => repositorio.decidir(estado, perfil, decision);
}
