import 'package:champ/core/repositorios/avisos_perros.dart';
import 'package:champ/core/modelos/aviso_perro.dart';

class ConsultarAvisos {
  const ConsultarAvisos(this._repositorio);
  final RepositorioAvisosPerros _repositorio;
  Stream<List<AvisoPerro>> listar() => _repositorio.listar();
  Stream<AvisoPerro?> observar(String id) => _repositorio.observar(id);
}
