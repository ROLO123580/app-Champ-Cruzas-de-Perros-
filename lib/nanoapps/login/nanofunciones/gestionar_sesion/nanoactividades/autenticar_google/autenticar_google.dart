import '../../../../../../core/modelos/sesion.dart';
import '../../../../../../core/servicios/autenticacion.dart';

/// Operaciones concretas del SDK, detrás de un contrato sustituible en pruebas.
class AutenticarGoogleActividad {
  const AutenticarGoogleActividad(this.servicio);
  final ServicioAutenticacion servicio;

  Stream<UsuarioChamp?> get cambios => servicio.cambios;
  UsuarioChamp? get usuarioActual => servicio.usuarioActual;
  bool get disponible => servicio.disponible;
  String? get configuracionPendiente => servicio.configuracionPendiente;
  Future<void> inicializar() => servicio.inicializar();
  Future<UsuarioChamp?> entrar() => servicio.entrarGoogle();
  Future<void> salir() => servicio.cerrarSesion();
}
