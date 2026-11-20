import 'dart:async';

import 'package:champ/core/catalogos/membership_fenix.dart';
import 'package:champ/core/modelos/membership.dart';
import 'package:champ/microapps/comercio/app_comercio.dart';
import 'package:champ/nanoapps/carro/nanofunciones/gestionar_carro/gestionar_carro.dart';
import 'package:champ/nanoapps/membership/app_membership.dart';
import 'package:champ/nanoapps/membership/nanofunciones/gestionar_membership/gestionar_membership.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'soporte/membership_prueba.dart';

void main() {
  test(
    'conserva planes, USD por mes, beneficios y 19% de Fénix como referencia',
    () {
      final planes = planesReferenciaFenix();
      expect(planes.map((plan) => plan.nombre), ['Free', 'Pro', 'Elite']);
      expect(planes.map((plan) => plan.precioMenor), [0, 999, 1999]);
      expect(planes.map((plan) => plan.moneda).toSet(), {'USD'});
      expect(planes.map((plan) => plan.periodo).toSet(), {'mes'});
      expect(planes.first.beneficios, [
        'Registro de consumos',
        'Gastos energéticos',
        'Seguimiento básico',
      ]);
      expect(planes[1].beneficios, [
        'Todo lo de Free',
        'Análisis nutricional',
        'Estadísticas',
        'Sincronización',
      ]);
      expect(planes.last.beneficios, [
        'Todo lo de Pro',
        'IA premium',
        'Reportes avanzados',
        'Soporte prioritario',
      ]);
      expect(planes[1].precioPresentado, 'USD 9.99 / mes');
      expect(
        planes[1].importePresentado(planes[1].impuestosMenor!),
        'USD 1.90',
      );
      expect(planes[1].importePresentado(planes[1].totalMenor), 'USD 11.89');
      expect(
        planes.last.importePresentado(planes.last.totalMenor),
        'USD 23.79',
      );
      expect(planes.every((plan) => plan.requiereAdaptacion), isTrue);
      expect(
        planes.every((plan) => plan.procedencia == 'Fénix Fitness'),
        isTrue,
      );
      for (final plan in planes) {
        expect(EstadoMembership.seleccionado(plan).membresiaActiva, isFalse);
      }
    },
  );

  testWidgets(
    'el catálogo Fénix avisa que sus beneficios están pendientes en Champ',
    (tester) async {
      final controlador = GestionarMembership(
        repositorio: MembershipPrueba(planes: planesReferenciaFenix()),
      );
      addTearDown(controlador.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppMembership(controlador: controlador, onIrCarro: () {}),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.text('Catálogo de referencia de Fénix Fitness'),
        findsOneWidget,
      );
      expect(
        find.textContaining(
          'Estos beneficios todavía no están implementados en Champ.',
        ),
        findsOneWidget,
      );
      await tester.scrollUntilVisible(find.text('Pro'), 250);
      expect(find.text('USD 9.99 / mes'), findsOneWidget);
      expect(find.text('Sincronización'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  test('valida precios enteros, moneda y periodo explícitos del catálogo', () {
    final valido = planPrueba().toJson();
    for (final cambio in <Map<String, dynamic>>[
      {'precioMenor': -1},
      {'precioMenor': 12.5},
      {'decimalesMoneda': -1},
      {'moneda': ''},
      {'moneda': 'usd'},
      {'periodo': ' '},
      {
        'beneficios': [''],
      },
      {'nombre': ''},
    ]) {
      expect(
        () => PlanMembership.fromJson({...valido, ...cambio}),
        throwsFormatException,
      );
    }
    expect(planPrueba().precioPresentado, 'USD 12.50 / mes de prueba');
  });

  test(
    'selección, contratación pendiente y quitar nunca activan permisos',
    () async {
      final repositorio = MembershipPrueba(planes: [planPrueba()]);
      final membership = GestionarMembership(repositorio: repositorio);
      final carro = GestionarCarro(
        repositorio: repositorio,
        onCambio: membership.actualizar,
      );
      addTearDown(membership.dispose);
      addTearDown(carro.dispose);
      await membership.cargar();
      expect(await membership.seleccionar('plan-solo-pruebas'), isTrue);
      expect(membership.estado.contratacion, EstadoContratacion.seleccionado);
      expect(membership.estado.membresiaActiva, isFalse);
      await carro.cargar();
      expect(await carro.dejarPendiente(), isTrue);
      expect(membership.estado.contratacion, EstadoContratacion.pendiente);
      expect(membership.estado.membresiaActiva, isFalse);
      expect(await carro.quitar(), isTrue);
      expect(membership.estado.plan, isNull);
      expect(membership.estado.membresiaActiva, isFalse);
    },
  );

  test(
    'no duplica selección y termina sin notificar después de dispose',
    () async {
      final repositorio = MembershipPrueba(planes: [planPrueba()]);
      final membership = GestionarMembership(repositorio: repositorio);
      await membership.cargar();
      repositorio.bloqueo = Completer<void>();
      final primera = membership.seleccionar('plan-solo-pruebas');
      expect(await membership.seleccionar('plan-solo-pruebas'), isFalse);
      expect(repositorio.selecciones, 1);
      membership.dispose();
      repositorio.bloqueo!.complete();
      expect(await primera, isTrue);
    },
  );

  test('un error de catálogo permite reintentar sin inventar planes', () async {
    final repositorio = MembershipPrueba()..fallar = true;
    final membership = GestionarMembership(repositorio: repositorio);
    addTearDown(membership.dispose);
    await membership.cargar();
    expect(membership.cargado, isFalse);
    expect(membership.error, 'Sin conexión de prueba');
    expect(membership.planes, isEmpty);
    repositorio.fallar = false;
    await membership.cargar();
    expect(membership.cargado, isTrue);
    expect(membership.error, isNull);
    expect(membership.planes, isEmpty);
  });

  test('un documento local no puede declarar una membresía activa', () {
    final datos = EstadoMembership.seleccionado(planPrueba()).toJson()
      ..['membresiaActiva'] = true
      ..['pagado'] = true;
    expect(EstadoMembership.fromJson(datos).membresiaActiva, isFalse);
    datos['contratacion'] = 'activa';
    expect(() => EstadoMembership.fromJson(datos), throwsFormatException);
  });

  testWidgets('muestra catálogo vacío y actualización sin precios inventados', (
    tester,
  ) async {
    final controlador = GestionarMembership(repositorio: MembershipPrueba());
    addTearDown(controlador.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppMembership(controlador: controlador, onIrCarro: () {}),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.text('Los planes todavía no están disponibles.'),
      findsOneWidget,
    );
    expect(find.text('Actualizar planes'), findsOneWidget);
    expect(find.text('Seleccionar plan'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'reentrar a Membership recupera el catálogo publicado desde otra herramienta',
    (tester) async {
      final repositorio = MembershipPrueba();
      final controlador = GestionarMembership(repositorio: repositorio);
      addTearDown(controlador.dispose);
      Widget pantalla() => MaterialApp(
        home: Scaffold(
          body: AppMembership(controlador: controlador, onIrCarro: () {}),
        ),
      );
      await tester.pumpWidget(pantalla());
      await tester.pumpAndSettle();
      expect(
        find.text('Los planes todavía no están disponibles.'),
        findsOneWidget,
      );
      await tester.pumpWidget(const SizedBox.shrink());
      repositorio.planes = [planPrueba()];
      await tester.pumpWidget(pantalla());
      await tester.pumpAndSettle();
      expect(find.text('Seleccionar plan'), findsOneWidget);
      expect(find.text('USD 12.50 / mes de prueba'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'selección abre Carro, pendiente se conserva al volver y quitar',
    (tester) async {
      final repositorio = MembershipPrueba(planes: [planPrueba()]);
      final controlador = GestionarMembership(repositorio: repositorio);
      addTearDown(controlador.dispose);
      var modulo = 'Membership';
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) => AppComercio(
                modulo: modulo,
                controlador: controlador,
                onIrCarro: () => setState(() => modulo = 'Carro'),
                onIrMembership: () => setState(() => modulo = 'Membership'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Seleccionar plan'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Seleccionar plan'));
      await tester.pumpAndSettle();
      expect(find.text('Carro'), findsOneWidget);
      expect(find.text('Plan seleccionado'), findsOneWidget);
      await tester.ensureVisible(find.text('Dejar contratación pendiente'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Dejar contratación pendiente'));
      await tester.pumpAndSettle();
      expect(repositorio.estado.contratacion, EstadoContratacion.pendiente);
      expect(repositorio.estado.membresiaActiva, isFalse);
      await tester.scrollUntilVisible(find.text('Ver planes'), -300);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ver planes'));
      await tester.pumpAndSettle();
      expect(find.text('Contratación pendiente'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('Revisar selección'), 300);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Revisar selección'));
      await tester.pumpAndSettle();
      expect(repositorio.selecciones, 1);
      expect(repositorio.estado.contratacion, EstadoContratacion.pendiente);
      await tester.scrollUntilVisible(find.text('Quitar selección'), 300);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Quitar selección'));
      await tester.pumpAndSettle();
      expect(find.text('Tu Carro está vacío.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
