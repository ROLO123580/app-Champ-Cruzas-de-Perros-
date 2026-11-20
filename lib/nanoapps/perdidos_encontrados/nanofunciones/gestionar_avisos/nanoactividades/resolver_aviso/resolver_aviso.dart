import 'package:champ/core/repositorios/avisos_perros.dart';

class ResolverAviso {
  const ResolverAviso(this._repositorio);
  final RepositorioAvisosPerros _repositorio;
  Future<void> ejecutar(String id, String nota) {
    final limpio = nota.trim();
    if (limpio.isEmpty || limpio.length > 500) {
      throw StateError('Escribe una nota de cierre de hasta 500 caracteres.');
    }
    return _repositorio.resolver(id, limpio);
  }
}
