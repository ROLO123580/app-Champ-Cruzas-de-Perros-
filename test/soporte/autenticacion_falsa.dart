import 'dart:async';

import 'package:champ/core/modelos/sesion.dart';
import 'package:champ/core/servicios/autenticacion.dart';

/// Sustituto explícito de pruebas; nunca se elige desde la aplicación normal.
class AutenticacionFalsa implements ServicioAutenticacion {
  AutenticacionFalsa({this.usuarioActual, this.configuracionPendiente});

  final eventos = StreamController<UsuarioChamp?>.broadcast(sync: true);
  Completer<void>? esperaInicializacion;
  Completer<UsuarioChamp?>? esperaAcceso;
  Completer<UsuarioChamp?>? esperaCorreo;
  Completer<UsuarioChamp?>? esperaCreacion;
  Completer<void>? esperaSalida;
  Object? falloInicializacion;
  Object? falloAcceso;
  Object? falloCorreo;
  Object? falloCreacion;
  Object? falloSalida;
  int inicializaciones = 0;
  int accesos = 0;
  int accesosCorreo = 0;
  int creacionesCuenta = 0;
  int salidas = 0;
  String? correoRecibido;
  String? claveRecibida;

  @override
  UsuarioChamp? usuarioActual;

  @override
  String? configuracionPendiente;

  @override
  bool get disponible => configuracionPendiente == null;

  @override
  Stream<UsuarioChamp?> get cambios => eventos.stream;

  @override
  Future<void> inicializar() async {
    inicializaciones++;
    if (esperaInicializacion != null) await esperaInicializacion!.future;
    if (falloInicializacion != null) throw falloInicializacion!;
  }

  @override
  Future<UsuarioChamp?> entrarGoogle() async {
    accesos++;
    if (falloAcceso != null) throw falloAcceso!;
    usuarioActual = esperaAcceso == null
        ? const UsuarioChamp(
            uid: 'google-prueba',
            nombre: 'Ana',
            correo: 'ana@example.test',
          )
        : await esperaAcceso!.future;
    eventos.add(usuarioActual);
    return usuarioActual;
  }

  @override
  Future<UsuarioChamp?> entrarCorreo({
    required String correo,
    required String clave,
  }) async {
    accesosCorreo++;
    correoRecibido = correo;
    claveRecibida = clave;
    if (falloCorreo != null) throw falloCorreo!;
    usuarioActual = esperaCorreo == null
        ? UsuarioChamp(uid: 'correo-prueba', correo: correo)
        : await esperaCorreo!.future;
    eventos.add(usuarioActual);
    return usuarioActual;
  }

  @override
  Future<UsuarioChamp?> crearCuenta({
    required String correo,
    required String clave,
  }) async {
    creacionesCuenta++;
    correoRecibido = correo;
    claveRecibida = clave;
    if (falloCreacion != null) throw falloCreacion!;
    usuarioActual = esperaCreacion == null
        ? UsuarioChamp(uid: 'cuenta-nueva-prueba', correo: correo)
        : await esperaCreacion!.future;
    eventos.add(usuarioActual);
    return usuarioActual;
  }

  @override
  Future<void> cerrarSesion() async {
    salidas++;
    if (esperaSalida != null) await esperaSalida!.future;
    if (falloSalida != null) throw falloSalida!;
    usuarioActual = null;
    eventos.add(null);
  }

  Future<void> dispose() => eventos.close();
}
