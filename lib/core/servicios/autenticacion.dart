import '../modelos/sesion.dart';

/// La sesión no escribe usuarios, tokens ni contraseñas en champ.db.
abstract interface class ServicioAutenticacion {
  Stream<UsuarioChamp?> get cambios;
  UsuarioChamp? get usuarioActual;
  bool get disponible;
  String? get configuracionPendiente;

  Future<void> inicializar();
  Future<UsuarioChamp?> entrarGoogle();
  Future<UsuarioChamp?> entrarCorreo({
    required String correo,
    required String clave,
  });
  Future<UsuarioChamp?> crearCuenta({
    required String correo,
    required String clave,
  });
  Future<void> cerrarSesion();
}
