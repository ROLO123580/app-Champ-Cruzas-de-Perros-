import '../modelos/comunidad.dart';

abstract class RepositorioComunidad {
  String get uid;
  Stream<List<EventoChamp>> eventos();
  Stream<EventoChamp?> evento(String id);
  Stream<List<PublicacionChamp>> publicaciones();
  Stream<List<MensajeEvento>> mensajes(String eventoId);
  Future<void> crearEvento(String id, BorradorEvento datos);
  Future<void> publicar(String id, String texto);
  Future<void> participar(String eventoId, bool inscribir);
  Future<void> cancelar(String eventoId);
  Future<void> enviar(String eventoId, String mensajeId, String texto);
}
