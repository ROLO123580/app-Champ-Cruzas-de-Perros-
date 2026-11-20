import '../modelos/servicios_paseos.dart';

abstract class RepositorioServiciosPaseos {
  String get uid;
  Stream<List<PerfilPaseador>> catalogo();
  Stream<PerfilPaseador?> miPerfil();
  Stream<List<ReservaPaseo>> misReservas();
  Stream<ReservaPaseo?> observarReserva(String id);
  Future<void> guardarPerfil(PerfilPaseador perfil);
  Future<void> solicitar(String id, SolicitudPaseo solicitud);
  Future<void> cambiarEstado(String id, EstadoReservaPaseo estado);
}
