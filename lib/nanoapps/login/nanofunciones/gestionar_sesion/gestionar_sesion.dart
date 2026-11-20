import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../../core/modelos/sesion.dart';
import '../../../../core/servicios/autenticacion.dart';
import 'nanoactividades/autenticar_correo/autenticar_correo.dart';
import 'nanoactividades/autenticar_google/autenticar_google.dart';

class GestionarSesion extends ChangeNotifier {
  GestionarSesion({required ServicioAutenticacion servicio})
    : _actividad = AutenticarGoogleActividad(servicio),
      _correo = AutenticarCorreoActividad(servicio);

  final AutenticarGoogleActividad _actividad;
  final AutenticarCorreoActividad _correo;
  StreamSubscription<UsuarioChamp?>? _suscripcion;
  Future<void>? _inicio;
  bool _cerrado = false;

  UsuarioChamp? usuario;
  bool listo = false;
  bool ocupado = false;
  bool cancelado = false;
  String? error;
  String? get configuracionPendiente => _actividad.configuracionPendiente;
  bool get disponible => listo && _actividad.disponible;

  void limpiarAvisos() {
    if (_cerrado || ocupado || (error == null && !cancelado)) return;
    error = null;
    cancelado = false;
    _avisar();
  }

  void _avisar() {
    if (!_cerrado) notifyListeners();
  }

  Future<void> inicializar() => _inicio ??= _restaurar();

  Future<void> reintentarInicializacion() async {
    if (_cerrado || ocupado || error == null || usuario != null) return;
    ocupado = true;
    await _suscripcion?.cancel();
    if (_cerrado) return;
    _suscripcion = null;
    _inicio = null;
    listo = false;
    error = null;
    await inicializar();
  }

  Future<void> _restaurar() async {
    if (_cerrado) return;
    ocupado = true;
    _avisar();
    try {
      await _actividad.inicializar();
      if (_cerrado) return;
      usuario = _actividad.usuarioActual;
      _suscripcion = _actividad.cambios.listen(
        (actual) {
          if (_cerrado) return;
          usuario = actual;
          _avisar();
        },
        onError: (Object _) {
          if (_cerrado) return;
          error = 'No se pudo actualizar la sesión. Intenta nuevamente.';
          _avisar();
        },
      );
    } catch (e) {
      if (!_cerrado) error = _mensaje(e);
    } finally {
      if (!_cerrado) {
        listo = true;
        ocupado = false;
        _avisar();
      }
    }
  }

  Future<void> entrarGoogle() async {
    if (_cerrado || ocupado || !disponible || usuario != null) return;
    ocupado = true;
    cancelado = false;
    error = null;
    _avisar();
    try {
      final actual = await _actividad.entrar();
      if (_cerrado) return;
      if (actual == null) {
        cancelado = true;
      } else {
        usuario = actual;
      }
    } on AccesoCancelado {
      if (!_cerrado) cancelado = true;
    } catch (e) {
      if (!_cerrado) error = _mensaje(e);
    } finally {
      if (!_cerrado) {
        ocupado = false;
        _avisar();
      }
    }
  }

  static String? validarCorreo(String? valor) {
    final correo = valor?.trim() ?? '';
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(correo)) {
      return 'Escribe un correo electrónico válido.';
    }
    return null;
  }

  static String? validarClave(String? valor, {bool cuentaNueva = false}) {
    if (valor == null || valor.isEmpty) return 'Escribe tu contraseña.';
    if (cuentaNueva && valor.runes.length < 6) {
      return 'Usa una contraseña de al menos 6 caracteres.';
    }
    return null;
  }

  Future<void> entrarCorreo({required String correo, required String clave}) =>
      _autenticarCorreo(correo: correo, clave: clave, crear: false);

  Future<void> crearCuenta({required String correo, required String clave}) =>
      _autenticarCorreo(correo: correo, clave: clave, crear: true);

  Future<void> _autenticarCorreo({
    required String correo,
    required String clave,
    required bool crear,
  }) async {
    if (_cerrado || ocupado || !disponible || usuario != null) return;
    cancelado = false;
    error = validarCorreo(correo) ?? validarClave(clave, cuentaNueva: crear);
    if (error != null) {
      _avisar();
      return;
    }
    ocupado = true;
    _avisar();
    try {
      final actual = crear
          ? await _correo.crearCuenta(correo: correo.trim(), clave: clave)
          : await _correo.entrar(correo: correo.trim(), clave: clave);
      if (_cerrado) return;
      if (actual == null) {
        error =
            'El servicio de acceso no devolvió una sesión válida. '
            'Intenta nuevamente.';
      } else {
        usuario = actual;
      }
    } catch (e) {
      if (!_cerrado) error = _mensaje(e);
    } finally {
      if (!_cerrado) {
        ocupado = false;
        _avisar();
      }
    }
  }

  Future<void> cerrarSesion() async {
    if (_cerrado || ocupado || !listo || usuario == null) return;
    ocupado = true;
    error = null;
    cancelado = false;
    _avisar();
    try {
      await _actividad.salir();
      if (!_cerrado) usuario = null;
    } catch (e) {
      if (!_cerrado) error = _mensaje(e);
    } finally {
      if (!_cerrado) {
        ocupado = false;
        _avisar();
      }
    }
  }

  static String _mensaje(Object e) => e is FalloAutenticacion
      ? e.mensaje
      : 'No se pudo completar la operación. Intenta nuevamente.';

  @override
  void dispose() {
    _cerrado = true;
    unawaited(_suscripcion?.cancel());
    _suscripcion = null;
    super.dispose();
  }
}
