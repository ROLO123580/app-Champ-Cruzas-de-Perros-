import 'package:champ/core/repositorios/comunidad.dart';

class CancelarEvento {
  const CancelarEvento(this._repositorio);
  final RepositorioComunidad _repositorio;
  Future<void> ejecutar(String id) => _repositorio.cancelar(id);
}
