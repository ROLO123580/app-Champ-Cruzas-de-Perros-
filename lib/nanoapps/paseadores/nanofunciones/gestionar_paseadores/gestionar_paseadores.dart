import 'dart:async';

import 'package:champ/core/controladores/operacion_comunidad.dart';
import 'package:champ/core/modelos/servicios_paseos.dart';
import 'package:champ/core/repositorios/servicios_paseos.dart';

import 'nanoactividades/consultar_paseadores/consultar_paseadores.dart';
import 'nanoactividades/guardar_perfil/guardar_perfil.dart';

class GestionarPaseadores extends OperacionComunidad {
  GestionarPaseadores(RepositorioServiciosPaseos repo)
    : uid = repo.uid,
      _consulta = ConsultarPaseadores(repo),
      _guardar = GuardarPerfilPaseador(repo);
  final String uid;
  final ConsultarPaseadores _consulta;
  final GuardarPerfilPaseador _guardar;
  List<PerfilPaseador> catalogo = const [];
  PerfilPaseador? perfil;
  bool cargando = true;
  final _escuchas = <StreamSubscription<dynamic>>[];
  int _generacion = 0;
  bool _iniciado = false;
  void iniciar({bool reintentar = false}) {
    if (destruido || (_iniciado && !reintentar)) return;
    _iniciado = true;
    final gen = ++_generacion;
    for (final s in _escuchas) {
      unawaited(s.cancel());
    }
    _escuchas.clear();
    cargando = true;
    error = null;
    notifyListeners();
    var listado = false, propio = false;
    void fallo(Object e) {
      if (destruido || gen != _generacion) return;
      error = 'No pudimos cargar los paseadores. Revisa tu conexión y vuelve a intentar.';
      cargando = false;
      notifyListeners();
    }

    void avisar() {
      cargando = !(listado && propio);
      notifyListeners();
    }

    try {
      _escuchas.add(
        _consulta.catalogo().listen((datos) {
          if (destruido || gen != _generacion) return;
          catalogo = List.unmodifiable(datos);
          listado = true;
          avisar();
        }, onError: fallo),
      );
      _escuchas.add(
        _consulta.miPerfil().listen((datos) {
          if (destruido || gen != _generacion) return;
          perfil = datos;
          propio = true;
          avisar();
        }, onError: fallo),
      );
    } catch (e) {
      fallo(e);
    }
  }

  Future<bool> guardar(PerfilPaseador perfil) =>
      proteger(() => _guardar.ejecutar(perfil));
  @override
  void dispose() {
    ++_generacion;
    for (final s in _escuchas) {
      unawaited(s.cancel());
    }
    super.dispose();
  }
}
