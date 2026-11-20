import '../../../../../../core/modelos/chat.dart';
import '../../../../../../core/repositorios/chat_usuarios.dart';

class ChatUsuariosActividad {
  ChatUsuariosActividad(this.canal);
  final CanalChatUsuarios canal;
  String get uid => canal.uid;
  Stream<List<Conversacion>> observar() => canal.conversaciones();
  Stream<List<Mensaje>> mensajes(String id) => canal.mensajes(id);
  Stream<Map<String, String>> contactos() => canal.contactos();
  Future<Conversacion> abrir(String uid) => canal.abrir(uid);
  Future<void> enviar(String id, String texto) => canal.enviar(id, texto);
}
