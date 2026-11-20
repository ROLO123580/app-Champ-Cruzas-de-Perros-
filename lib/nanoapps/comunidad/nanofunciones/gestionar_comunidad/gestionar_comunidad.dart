import 'dart:async';

import 'package:champ/core/controladores/operacion_comunidad.dart';
import 'package:champ/core/modelos/comunidad.dart';
import 'package:champ/core/repositorios/comunidad.dart';
import 'package:champ/nanoapps/eventos/nanofunciones/gestionar_eventos/gestionar_eventos.dart';
import 'package:champ/nanoapps/chat_eventos/nanofunciones/gestionar_chat_eventos/gestionar_chat_eventos.dart';

import 'nanoactividades/consultar_comunidad/consultar_comunidad.dart';
import 'nanoactividades/publicar_muro/publicar_muro.dart';

class GestionarComunidad extends OperacionComunidad {
  GestionarComunidad(RepositorioComunidad repositorio)
    : uid = repositorio.uid,
      _consulta = ConsultarComunidad(repositorio),
      _publicar = PublicarMuro(repositorio),
      eventosGestion = GestionarEventos(repositorio),
      chatGestion = GestionarChatEventos(repositorio);
  final String uid;
  final ConsultarComunidad _consulta;
  final PublicarMuro _publicar;
  final GestionarEventos eventosGestion;
  final GestionarChatEventos chatGestion;
  List<EventoChamp> eventos = const [];
  List<PublicacionChamp> publicaciones = const [];
  bool cargando = true;
  final List<StreamSubscription<dynamic>> _escuchas = [];
  bool _iniciado = false;
  int _generacion = 0;
  void iniciar({bool reintentar = false}) {
    if (destruido || (_iniciado && !reintentar)) return;
    _iniciado = true;
    final generacion = ++_generacion;
    for (final escucha in _escuchas) {
      unawaited(escucha.cancel());
    }
    _escuchas.clear();
    error = null;
    cargando = true;
    notifyListeners();
    var eventosListos = false, muroListo = false;
    void fallo(Object e) {
      if (destruido || generacion != _generacion) return;
      error = 'No pudimos cargar la comunidad. Revisa la conexión y vuelve a intentar.';
      cargando = false;
      notifyListeners();
    }

    void recibido() {
      cargando = !(eventosListos && muroListo);
      notifyListeners();
    }

    try {
      _escuchas.add(
        _consulta.eventos().listen((datos) {
          if (destruido || generacion != _generacion) return;
          eventos = List.unmodifiable(datos);
          eventosListos = true;
          recibido();
        }, onError: fallo),
      );
      _escuchas.add(
        _consulta.muro().listen((datos) {
          if (destruido || generacion != _generacion) return;
          publicaciones = List.unmodifiable(datos);
          muroListo = true;
          recibido();
        }, onError: fallo),
      );
    } catch (e) {
      fallo(e);
    }
  }

  Future<bool> publicar(String id, String texto) =>
      proteger(() => _publicar.ejecutar(id, texto));
  @override
  void dispose() {
    ++_generacion;
    for (final escucha in _escuchas) {
      unawaited(escucha.cancel());
    }
    eventosGestion.dispose();
    chatGestion.dispose();
    super.dispose();
  }
}
