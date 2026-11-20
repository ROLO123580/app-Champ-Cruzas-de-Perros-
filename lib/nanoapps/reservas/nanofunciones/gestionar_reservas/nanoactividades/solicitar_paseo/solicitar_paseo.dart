import 'package:champ/core/modelos/servicios_paseos.dart';
import 'package:champ/core/repositorios/servicios_paseos.dart';

class SolicitarPaseo {
  const SolicitarPaseo(this._repo);
  final RepositorioServiciosPaseos _repo;
  Future<void> ejecutar(String id, SolicitudPaseo solicitud) {
    solicitud.validar();
    return _repo.solicitar(id, solicitud);
  }
}
