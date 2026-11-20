import 'package:champ/core/repositorios/preferencias.dart';

class PersistirPreferencias {
  PersistirPreferencias(this.repositorio);
  final RepositorioPreferencias repositorio;
  Future<Map<String, dynamic>> cargar() => repositorio.cargar();
  Future<void> guardar(Map<String, dynamic> datos) =>
      repositorio.guardar(datos);
}
