import 'package:champ/core/modelos/servicios_paseos.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const perfil = PerfilPaseador(
    uid: 'p',
    nombre: 'Paseador',
    zona: 'Parque',
    descripcion: 'Paseos',
    condiciones: 'Sin cobros',
    disponibilidad: 'Coordinar',
    revision: 1,
    duracion: 120,
  );
  test('rechaza solicitud sin perfil publicado o horario alineado', () {
    expect(
      () => SolicitudPaseo(
        paseador: perfil,
        perro: 'Luna',
        zona: 'Parque',
        inicio: DateTime.fromMillisecondsSinceEpoch(
          DateTime.now().millisecondsSinceEpoch + 86400123,
        ),
      ).validar(),
      throwsStateError,
    );
    expect(
      () => SolicitudPaseo(
        paseador: perfil,
        perro: '',
        zona: 'Parque',
        inicio: DateTime.now(),
      ).validar(),
      throwsStateError,
    );
  });
  ReservaPaseo reserva(EstadoReservaPaseo estado, DateTime inicio) =>
      ReservaPaseo(
        id: 'r',
        clienteUid: 'a',
        clienteNombre: 'Ana',
        paseadorUid: 'p',
        paseadorNombre: 'Paseador',
        perro: 'Luna',
        zona: 'Parque',
        inicio: inicio,
        duracion: 120,
        condiciones: 'Sin cobros',
        nota: '',
        estado: estado,
      );
  test('roles y ciclo de reserva no permiten iniciar antes de tiempo', () {
    final futura = DateTime.now().add(const Duration(days: 1));
    expect(reserva(EstadoReservaPaseo.solicitada, futura).acciones('a'), [
      EstadoReservaPaseo.cancelada,
    ]);
    expect(reserva(EstadoReservaPaseo.solicitada, futura).acciones('p'), [
      EstadoReservaPaseo.aceptada,
      EstadoReservaPaseo.rechazada,
    ]);
    expect(reserva(EstadoReservaPaseo.aceptada, futura).acciones('p'), [
      EstadoReservaPaseo.cancelada,
    ]);
    expect(
      reserva(
        EstadoReservaPaseo.aceptada,
        DateTime.now().subtract(const Duration(minutes: 1)),
      ).acciones('p'),
      contains(EstadoReservaPaseo.enCurso),
    );
    for (final e in EstadoReservaPaseo.values) {
      expect(reserva(e, futura).acciones('ajeno'), isEmpty);
    }
    expect(reserva(EstadoReservaPaseo.enCurso, futura).acciones('a'), isEmpty);
    expect(
      reserva(EstadoReservaPaseo.finalizada, futura).acciones('p'),
      isEmpty,
    );
    final bloques = reserva(EstadoReservaPaseo.aceptada, futura).bloques;
    expect(bloques.length, 4);
    expect(bloques.last - bloques.first, 3);
  });
}
