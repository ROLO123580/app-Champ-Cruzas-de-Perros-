import 'package:champ/core/modelos/chat.dart';
import 'package:champ/core/repositorios/contratos.dart';

class PersistirChatActividad {
  PersistirChatActividad(this.repositorio);
  final AlmacenChat repositorio;
  Future<List<Conversacion>> cargar() => repositorio.cargar();
  Future<void> guardar(List<Conversacion> conversaciones) =>
      repositorio.guardar(conversaciones);
}
