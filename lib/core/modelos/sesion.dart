/// Datos públicos de la sesión. Las credenciales permanecen en el SDK.
class UsuarioChamp {
  const UsuarioChamp({
    required this.uid,
    this.nombre,
    this.correo,
    this.fotoUrl,
  });

  final String uid;
  final String? nombre;
  final String? correo;
  final String? fotoUrl;
}

class FalloAutenticacion implements Exception {
  const FalloAutenticacion(this.mensaje);
  final String mensaje;

  @override
  String toString() => mensaje;
}

class AccesoCancelado implements Exception {
  const AccesoCancelado();
}
