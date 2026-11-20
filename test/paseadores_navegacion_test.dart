import 'package:champ/core/modelos/servicios_paseos.dart';
import 'package:champ/core/repositorios/servicios_paseos.dart';
import 'package:champ/nanoapps/paseadores/app_paseadores.dart';
import 'package:champ/nanoapps/paseadores/nanofunciones/gestionar_paseadores/gestionar_paseadores.dart';
import 'package:champ/nanoapps/reservas/nanofunciones/gestionar_reservas/gestionar_reservas.dart';
import 'package:champ/nanoapps/reservas/vistas/solicitar_reserva.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class ServiciosPrueba implements RepositorioServiciosPaseos {
  @override
  String get uid => 'cliente';
  static const perfil = PerfilPaseador(
    uid: 'paseador',
    nombre: 'Jaime',
    zona: 'Parque central',
    descripcion: 'Paseos tranquilos',
    condiciones: 'Coordinar encuentro. Sin cobros.',
    disponibilidad: 'Por la mañana',
    revision: 1,
  );
  @override
  Stream<List<PerfilPaseador>> catalogo() => Stream.value([perfil]);
  @override
  Stream<PerfilPaseador?> miPerfil() => Stream.value(null);
  @override
  Stream<List<ReservaPaseo>> misReservas() => Stream.value([]);
  @override
  Stream<ReservaPaseo?> observarReserva(String id) => Stream.value(null);
  int solicitudes = 0;
  @override
  Future<void> solicitar(String id, SolicitudPaseo s) async {
    solicitudes++;
  }

  @override
  Future<void> guardarPerfil(PerfilPaseador perfil) async {}
  @override
  Future<void> cambiarEstado(String id, EstadoReservaPaseo estado) async {}
}

void main() {
  testWidgets(
    'directorio abre condiciones y rechaza solicitud incompleta sin enviarla',
    (tester) async {
      tester.view.physicalSize = const Size(1400, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final repo = ServiciosPrueba(),
          p = GestionarPaseadores(ServiciosPrueba()),
          r = GestionarReservas(ServiciosPrueba());
      // El repositorio de la reserva se comparte para comprobar que no envía.
      final reservas = GestionarReservas(repo);
      addTearDown(p.dispose);
      addTearDown(r.dispose);
      addTearDown(reservas.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppPaseadores(
              controlador: p,
              reservas: reservas,
              onContactar: (_) async => true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Jaime'), findsOneWidget);
      await tester.tap(find.text('Jaime'));
      await tester.pumpAndSettle();
      expect(find.text('Coordinar encuentro. Sin cobros.'), findsOneWidget);
      await tester.tap(find.text('Solicitar un paseo'));
      await tester.pumpAndSettle();
      expect(find.byType(SolicitarReserva), findsOneWidget);
      await tester.ensureVisible(find.text('Enviar solicitud'));
      await tester.tap(find.text('Enviar solicitud'));
      await tester.pumpAndSettle();
      expect(repo.solicitudes, 0);
      expect(
        find.text(
          'Completa los datos, el horario y la revisión de las condiciones.',
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'volver protege el borrador y permite seguir editando o descartarlo',
    (tester) async {
      final r = GestionarReservas(ServiciosPrueba());
      addTearDown(r.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => SolicitarReserva(
                      controlador: r,
                      paseador: ServiciosPrueba.perfil,
                    ),
                  ),
                ),
                child: const Text('Abrir'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Abrir'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).first, 'Luna');
      await tester.pump();
      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();
      expect(find.text('¿Descartar la solicitud?'), findsOneWidget);
      await tester.tap(find.text('Seguir editando'));
      await tester.pumpAndSettle();
      expect(find.text('Luna'), findsOneWidget);
      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Descartar'));
      await tester.pumpAndSettle();
      expect(find.byType(SolicitarReserva), findsNothing);
      expect(find.text('Abrir'), findsOneWidget);
    },
  );
}
