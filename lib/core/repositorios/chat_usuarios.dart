import '../modelos/chat.dart';

/// Canal autenticado; el repositorio local conserva su contrato y su historial.
abstract class CanalChatUsuarios {
  String get uid;
  Stream<List<Conversacion>> conversaciones();
  Stream<List<Mensaje>> mensajes(String conversacionId);
  Future<Conversacion> abrir(String destinatarioUid);
  Future<void> enviar(String conversacionId, String texto);
}
