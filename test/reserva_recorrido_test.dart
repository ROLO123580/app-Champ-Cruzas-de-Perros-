import 'dart:async';

import 'package:champ/core/modelos/servicios_paseos.dart';
import 'package:champ/nanoapps/reservas/nanofunciones/gestionar_reservas/gestionar_reservas.dart';
import 'package:champ/nanoapps/reservas/vistas/detalle_reserva.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'paseadores_navegacion_test.dart' show ServiciosPrueba;

class AgendaPrueba extends ServiciosPrueba {
  AgendaPrueba(this.usuario, EstadoReservaPaseo estado, {bool pasado = false})
    : actual = ReservaPaseo(
        id: 'r',
        clienteUid: 'cliente',
        clienteNombre: 'Ana',
        paseadorUid: 'paseador',
        paseadorNombre: 'Jaime',
        perro: 'Luna',
        zona: 'Entrada del parque',
        inicio: DateTime.now().add(Duration(days: pasado ? -1 : 1)),
        duracion: 60,
        condiciones: 'Sin cobros',
        nota: '',
        estado: estado,
      );
  final String usuario;
  @override
  String get uid => usuario;
  ReservaPaseo actual;
  bool fallar = false;
  final estados = <EstadoReservaPaseo>[];
  final cambios = StreamController<ReservaPaseo?>.broadcast();
  @override
  Stream<ReservaPaseo?> observarReserva(String id) async* {
    yield actual;
    yield* cambios.stream;
  }

  @override
  Future<void> cambiarEstado(String id, EstadoReservaPaseo estado) async {
    if (fallar) throw StateError('No se pudo confirmar. Vuelve a intentar.');
    if (!actual.acciones(uid).contains(estado)) {
      throw StateError('Acción no permitida');
    }
    estados.add(estado);
    actual = ReservaPaseo.fromMap(id, {
      'clienteUid': actual.clienteUid,
      'clienteNombre': actual.clienteNombre,
      'paseadorUid': actual.paseadorUid,
      'paseadorNombre': actual.paseadorNombre,
      'perro': actual.perro,
      'zona': actual.zona,
      'inicioMs': actual.inicio.millisecondsSinceEpoch,
      'duracion': 60,
      'condiciones': actual.condiciones,
      'nota': '',
      'estado': estado.name,
    });
    cambios.add(actual);
  }
}

void main() {
  Future<void> abrir(WidgetTester tester, AgendaPrueba repo) async {
    tester.view.physicalSize = const Size(1400, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final g = GestionarReservas(repo);
    addTearDown(g.dispose);
    addTearDown(repo.cambios.close);
    await tester.pumpWidget(
      MaterialApp(
        home: DetalleReserva(
          controlador: g,
          reservaId: 'r',
          onContactar: (_) async => false,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'paseador reintenta aceptación fallida y luego cancela con confirmación',
    (tester) async {
      final repo = AgendaPrueba('paseador', EstadoReservaPaseo.solicitada)
        ..fallar = true;
      await abrir(tester, repo);
      await tester.tap(find.text('Aceptar solicitud'));
      await tester.pumpAndSettle();
      expect(repo.estados, isEmpty);
      expect(
        find.text('No se pudo confirmar. Vuelve a intentar.'),
        findsOneWidget,
      );
      repo.fallar = false;
      await tester.tap(find.text('Aceptar solicitud'));
      await tester.pumpAndSettle();
      expect(repo.estados, [EstadoReservaPaseo.aceptada]);
      expect(find.text('Iniciar paseo'), findsNothing);
      await tester.tap(find.text('Cancelar reserva'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Conservar'));
      await tester.pumpAndSettle();
      expect(repo.estados.length, 1);
      await tester.tap(find.text('Cancelar reserva'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.widgetWithText(FilledButton, 'Cancelar reserva').last,
      );
      await tester.pumpAndSettle();
      expect(repo.estados.last, EstadoReservaPaseo.cancelada);
      expect(find.text('Aceptar solicitud'), findsNothing);
    },
  );
  testWidgets(
    'paseador inicia y finaliza un paseo confirmado cuyo horario llegó',
    (tester) async {
      final repo = AgendaPrueba(
        'paseador',
        EstadoReservaPaseo.aceptada,
        pasado: true,
      );
      await abrir(tester, repo);
      await tester.tap(find.text('Iniciar paseo'));
      await tester.pumpAndSettle();
      expect(find.text('En curso'), findsOneWidget);
      await tester.tap(find.text('Finalizar paseo'));
      await tester.pumpAndSettle();
      expect(repo.estados, [
        EstadoReservaPaseo.enCurso,
        EstadoReservaPaseo.finalizada,
      ]);
      expect(find.text('Finalizada'), findsOneWidget);
      expect(find.text('Iniciar paseo'), findsNothing);
    },
  );
  testWidgets(
    'cliente no puede aceptar y conserva la reserva si cancela el diálogo',
    (tester) async {
      final repo = AgendaPrueba('cliente', EstadoReservaPaseo.solicitada);
      await abrir(tester, repo);
      expect(find.text('Aceptar solicitud'), findsNothing);
      expect(find.text('Rechazar'), findsNothing);
      await tester.tap(find.text('Cancelar reserva'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Conservar'));
      await tester.pumpAndSettle();
      expect(repo.estados, isEmpty);
    },
  );
}
