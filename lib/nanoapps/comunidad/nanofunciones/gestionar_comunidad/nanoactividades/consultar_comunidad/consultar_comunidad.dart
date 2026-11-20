import 'package:champ/core/repositorios/comunidad.dart';
import 'package:champ/core/modelos/comunidad.dart';

class ConsultarComunidad {
  const ConsultarComunidad(this._repositorio);
  final RepositorioComunidad _repositorio;
  Stream<List<EventoChamp>> eventos() => _repositorio.eventos();
  Stream<List<PublicacionChamp>> muro() => _repositorio.publicaciones();
}
