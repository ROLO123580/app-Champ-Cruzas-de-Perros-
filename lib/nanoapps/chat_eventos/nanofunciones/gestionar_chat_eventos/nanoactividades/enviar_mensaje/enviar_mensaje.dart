import 'package:champ/core/repositorios/comunidad.dart';

class EnviarMensajeEvento {
  const EnviarMensajeEvento(this._repositorio);
  final RepositorioComunidad _repositorio;
  Future<void> ejecutar(String evento, String id, String texto) {
    final limpio = texto.trim();
    if (limpio.isEmpty || limpio.length > 4000) {
      throw StateError('Escribe entre 1 y 4000 caracteres.');
    }
    return _repositorio.enviar(evento, id, limpio);
  }
}
