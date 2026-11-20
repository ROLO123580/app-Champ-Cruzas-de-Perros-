import '../modelos/chat.dart';

/// Canal autenticado; el repositorio local conserva su contrato y su historial.
abstract class CanalChatUsuarios {
  String get uid;
  Stream<List<Conversacion>> conversaciones();

  /// Directorio de cuentas: UID → nombre visible (sin incluir la propia).
  Stream<Map<String, String>> contactos();
  Stream<List<Mensaje>> mensajes(String conversacionId);
  Future<Conversacion> abrir(String destinatarioUid);
  Future<void> enviar(String conversacionId, String texto);
}
