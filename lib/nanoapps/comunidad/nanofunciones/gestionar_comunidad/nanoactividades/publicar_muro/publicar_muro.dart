import 'package:champ/core/repositorios/comunidad.dart';

class PublicarMuro {
  const PublicarMuro(this._repositorio);
  final RepositorioComunidad _repositorio;
  Future<void> ejecutar(String id, String texto) {
    final limpio = texto.trim();
    if (limpio.isEmpty || limpio.length > 2000) {
      throw StateError('Escribe entre 1 y 2000 caracteres.');
    }
    return _repositorio.publicar(id, limpio);
  }
}
