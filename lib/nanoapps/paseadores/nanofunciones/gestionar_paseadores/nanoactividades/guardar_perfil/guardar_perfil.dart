import 'package:champ/core/modelos/servicios_paseos.dart';
import 'package:champ/core/repositorios/servicios_paseos.dart';

class GuardarPerfilPaseador {
  const GuardarPerfilPaseador(this._repo);
  final RepositorioServiciosPaseos _repo;
  Future<void> ejecutar(PerfilPaseador perfil) {
    perfil.validar();
    return _repo.guardarPerfil(perfil);
  }
}
