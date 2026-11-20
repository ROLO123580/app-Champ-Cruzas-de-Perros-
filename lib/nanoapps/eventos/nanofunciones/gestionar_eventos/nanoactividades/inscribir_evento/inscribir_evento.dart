import 'package:champ/core/repositorios/comunidad.dart';

class InscribirEvento {
  const InscribirEvento(this._repositorio);
  final RepositorioComunidad _repositorio;
  Future<void> ejecutar(String id, bool inscribir) =>
      _repositorio.participar(id, inscribir);
}
