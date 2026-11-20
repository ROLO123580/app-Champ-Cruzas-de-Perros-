import 'package:champ/core/modelos/servicios_paseos.dart';
import 'package:champ/core/repositorios/servicios_paseos.dart';

class ConsultarReservas {
  const ConsultarReservas(this._repo);
  final RepositorioServiciosPaseos _repo;
  Stream<List<ReservaPaseo>> listar() => _repo.misReservas();
  Stream<ReservaPaseo?> observar(String id) => _repo.observarReserva(id);
}
