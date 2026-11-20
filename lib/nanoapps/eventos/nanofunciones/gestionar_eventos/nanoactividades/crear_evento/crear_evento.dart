import 'package:champ/core/repositorios/comunidad.dart';
import 'package:champ/core/modelos/comunidad.dart';

class CrearEvento {
  const CrearEvento(this._repositorio);
  final RepositorioComunidad _repositorio;
  Future<void> ejecutar(String id, BorradorEvento datos) {
    datos.validar();
    return _repositorio.crearEvento(id, datos);
  }
}
