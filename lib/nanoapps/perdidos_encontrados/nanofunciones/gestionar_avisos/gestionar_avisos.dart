import 'dart:async';
import 'dart:typed_data';

import 'package:champ/core/controladores/operacion_comunidad.dart';
import 'package:champ/core/modelos/aviso_perro.dart';
import 'package:champ/core/repositorios/avisos_perros.dart';
import 'package:champ/core/servicios/seleccionar_foto.dart';

import 'nanoactividades/consultar_avisos/consultar_avisos.dart';
import 'nanoactividades/guardar_aviso/guardar_aviso.dart';
import 'nanoactividades/resolver_aviso/resolver_aviso.dart';
import 'nanoactividades/seleccionar_foto/seleccionar_foto.dart';

class GestionarAvisos extends OperacionComunidad {
  GestionarAvisos(
    RepositorioAvisosPerros repositorio, {
    SeleccionarFoto? selector,
  }) : uid = repositorio.uid,
       _consulta = ConsultarAvisos(repositorio),
       _guardar = GuardarAviso(repositorio),
       _resolver = ResolverAviso(repositorio),
       _foto = SeleccionarFotoAviso(selector ?? SeleccionarFoto());
  final String uid;
  final ConsultarAvisos _consulta;
  final GuardarAviso _guardar;
  final ResolverAviso _resolver;
  final SeleccionarFotoAviso _foto;
  List<AvisoPerro> avisos = const [];
  bool cargando = true;
  StreamSubscription<List<AvisoPerro>>? _escucha;
  int _generacion = 0;
  bool _iniciado = false;
  void iniciar({bool reintentar = false}) {
    if (destruido || (_iniciado && !reintentar)) return;
    _iniciado = true;
    final generacion = ++_generacion;
    unawaited(_escucha?.cancel());
    cargando = true;
    error = null;
    notifyListeners();
    void fallo(Object e) {
      if (destruido || generacion != _generacion) return;
      cargando = false;
      error = 'No pudimos cargar los avisos. Revisa la conexión y vuelve a intentar.';
      notifyListeners();
    }

    try {
      _escucha = _consulta.listar().listen((datos) {
        if (destruido || generacion != _generacion) return;
        avisos = List.unmodifiable(datos);
        cargando = false;
        error = null;
        notifyListeners();
      }, onError: fallo);
    } catch (e) {
      fallo(e);
    }
  }

  Stream<AvisoPerro?> observar(String id) => _consulta.observar(id);
  Future<bool> guardar(String id, DatosAvisoPerro datos) =>
      proteger(() => _guardar.ejecutar(id, datos));
  Future<bool> resolver(String id, String nota) =>
      proteger(() => _resolver.ejecutar(id, nota));
  Future<Uint8List?> seleccionarFoto() async {
    Uint8List? resultado;
    await proteger(() async {
      resultado = await _foto.ejecutar();
    });
    return resultado;
  }

  @override
  void dispose() {
    ++_generacion;
    unawaited(_escucha?.cancel());
    super.dispose();
  }
}
