import 'package:champ/core/repositorios/comunidad.dart';
import 'package:champ/core/modelos/comunidad.dart';

class ConsultarMensajes {
  const ConsultarMensajes(this._repositorio);
  final RepositorioComunidad _repositorio;
  Stream<List<MensajeEvento>> ejecutar(String id) => _repositorio.mensajes(id);
}
