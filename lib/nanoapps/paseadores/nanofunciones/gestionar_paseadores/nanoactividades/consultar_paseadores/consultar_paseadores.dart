import 'package:champ/core/modelos/servicios_paseos.dart';
import 'package:champ/core/repositorios/servicios_paseos.dart';

class ConsultarPaseadores {
  const ConsultarPaseadores(this._repo);
  final RepositorioServiciosPaseos _repo;
  Stream<List<PerfilPaseador>> catalogo() => _repo.catalogo();
  Stream<PerfilPaseador?> miPerfil() => _repo.miPerfil();
}
