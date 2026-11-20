import '../modelos/aviso_perro.dart';

abstract class RepositorioAvisosPerros {
  String get uid;
  Stream<List<AvisoPerro>> listar();
  Stream<AvisoPerro?> observar(String id);
  Future<void> guardar(String id, DatosAvisoPerro datos);
  Future<void> resolver(String id, String nota);
}
