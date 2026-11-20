import 'package:champ/core/repositorios/avisos_perros.dart';
import 'package:champ/core/modelos/aviso_perro.dart';

class GuardarAviso {
  const GuardarAviso(this._repositorio);
  final RepositorioAvisosPerros _repositorio;
  Future<void> ejecutar(String id, DatosAvisoPerro datos) {
    datos.validar();
    return _repositorio.guardar(id, datos);
  }
}
