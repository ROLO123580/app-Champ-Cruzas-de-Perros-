import '../../../../../../core/modelos/sesion.dart';
import '../../../../../../core/servicios/autenticacion.dart';

/// Acciones concretas de identidad por correo, sin persistir credenciales.
class AutenticarCorreoActividad {
  const AutenticarCorreoActividad(this.servicio);
  final ServicioAutenticacion servicio;

  Future<UsuarioChamp?> entrar({
    required String correo,
    required String clave,
  }) => servicio.entrarCorreo(correo: correo, clave: clave);

  Future<UsuarioChamp?> crearCuenta({
    required String correo,
    required String clave,
  }) => servicio.crearCuenta(correo: correo, clave: clave);
}
