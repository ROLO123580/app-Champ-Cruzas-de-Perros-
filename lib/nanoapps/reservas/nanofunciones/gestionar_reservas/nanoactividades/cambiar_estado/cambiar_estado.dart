import 'package:champ/core/modelos/servicios_paseos.dart';
import 'package:champ/core/repositorios/servicios_paseos.dart';

class CambiarEstadoReserva {
  const CambiarEstadoReserva(this._repo);
  final RepositorioServiciosPaseos _repo;
  Future<void> ejecutar(String id, EstadoReservaPaseo estado) =>
      _repo.cambiarEstado(id, estado);
}
