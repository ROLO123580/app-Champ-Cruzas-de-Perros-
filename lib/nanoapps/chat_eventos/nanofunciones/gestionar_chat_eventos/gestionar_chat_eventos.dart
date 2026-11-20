import 'package:champ/core/controladores/operacion_comunidad.dart';
import 'package:champ/core/modelos/comunidad.dart';
import 'package:champ/core/repositorios/comunidad.dart';
import 'package:champ/nanoapps/eventos/nanofunciones/gestionar_eventos/nanoactividades/consultar_evento/consultar_evento.dart';

import 'nanoactividades/consultar_mensajes/consultar_mensajes.dart';
import 'nanoactividades/enviar_mensaje/enviar_mensaje.dart';

class GestionarChatEventos extends OperacionComunidad {
  GestionarChatEventos(RepositorioComunidad repositorio)
    : uid = repositorio.uid,
      _evento = ConsultarEvento(repositorio),
      _mensajes = ConsultarMensajes(repositorio),
      _enviar = EnviarMensajeEvento(repositorio);
  final String uid;
  final ConsultarEvento _evento;
  final ConsultarMensajes _mensajes;
  final EnviarMensajeEvento _enviar;
  Stream<EventoChamp?> observarEvento(String id) => _evento.ejecutar(id);
  Stream<List<MensajeEvento>> mensajes(String id) => _mensajes.ejecutar(id);
  Future<bool> enviar(String evento, String id, String texto) =>
      proteger(() => _enviar.ejecutar(evento, id, texto));
}
