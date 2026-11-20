import 'package:champ/core/repositorios/comunidad.dart';
import 'package:champ/core/modelos/comunidad.dart';

class ConsultarEvento {
  const ConsultarEvento(this._repositorio);
  final RepositorioComunidad _repositorio;
  Stream<EventoChamp?> ejecutar(String id) => _repositorio.evento(id);
}
