import 'dart:async';

import 'package:champ/core/controladores/operacion_comunidad.dart';
import 'package:champ/core/modelos/servicios_paseos.dart';
import 'package:champ/core/repositorios/servicios_paseos.dart';

import 'nanoactividades/consultar_reservas/consultar_reservas.dart';
import 'nanoactividades/solicitar_paseo/solicitar_paseo.dart';
import 'nanoactividades/cambiar_estado/cambiar_estado.dart';

class GestionarReservas extends OperacionComunidad {
  GestionarReservas(RepositorioServiciosPaseos repo)
    : uid = repo.uid,
      _consulta = ConsultarReservas(repo),
      _solicitar = SolicitarPaseo(repo),
      _estado = CambiarEstadoReserva(repo);
  final String uid;
  final ConsultarReservas _consulta;
  final SolicitarPaseo _solicitar;
  final CambiarEstadoReserva _estado;
  List<ReservaPaseo> reservas = const [];
  bool cargando = true;
  bool _iniciado = false;
  int _generacion = 0;
  StreamSubscription<List<ReservaPaseo>>? _escucha;
  void iniciar({bool reintentar = false}) {
    if (destruido || (_iniciado && !reintentar)) return;
    _iniciado = true;
    final gen = ++_generacion;
    unawaited(_escucha?.cancel());
    cargando = true;
    error = null;
    notifyListeners();
    void fallo(Object e) {
      if (destruido || gen != _generacion) return;
      cargando = false;
      error = 'No pudimos cargar tu agenda. Revisa tu conexión y vuelve a intentar.';
      notifyListeners();
    }

    try {
      _escucha = _consulta.listar().listen((datos) {
        if (destruido || gen != _generacion) return;
        reservas = List.unmodifiable(datos);
        cargando = false;
        error = null;
        notifyListeners();
      }, onError: fallo);
    } catch (e) {
      fallo(e);
    }
  }

  Stream<ReservaPaseo?> observar(String id) => _consulta.observar(id);
  Future<bool> solicitar(String id, SolicitudPaseo s) =>
      proteger(() => _solicitar.ejecutar(id, s));
  Future<bool> cambiar(String id, EstadoReservaPaseo estado) =>
      proteger(() => _estado.ejecutar(id, estado));
  @override
  void dispose() {
    ++_generacion;
    unawaited(_escucha?.cancel());
    super.dispose();
  }
}
