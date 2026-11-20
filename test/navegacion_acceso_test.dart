import 'dart:async';

import 'package:champ/app_champ.dart';
import 'package:champ/core/modelos/sesion.dart';
import 'package:champ/core/persistencia/base_local.dart';
import 'package:champ/core/persistencia/sqlite_local.dart';
import 'package:champ/core/servicios/servicios_champ.dart';
import 'package:champ/microapps/comercio/app_comercio.dart';
import 'package:champ/nanoapps/carro/app_carro.dart';
import 'package:champ/nanoapps/login/app_login.dart';
import 'package:champ/nanoapps/login/nanofunciones/gestionar_sesion/gestionar_sesion.dart';
import 'package:champ/nanoapps/membership/app_membership.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'soporte/autenticacion_falsa.dart';
import 'soporte/base_prueba.dart';
import 'soporte/membership_prueba.dart';

void main() {
  testWidgets(
    'restaura la sesión y salir no apila Login ni pierde datos locales',
    (tester) async {
      final servicios = await serviciosPrueba();
      final autenticacion = AutenticacionFalsa(
        usuarioActual: const UsuarioChamp(uid: 'restaurado', nombre: 'Ana'),
      )..esperaInicializacion = Completer<void>();
      final sesion = GestionarSesion(servicio: autenticacion);
      addTearDown(autenticacion.dispose);
      addTearDown(sesion.dispose);
      await tester.pumpWidget(
        ChampApp(servicios: servicios, controladorSesion: sesion),
      );
      expect(find.text('Restaurando sesión…'), findsOneWidget);
      expect(find.byType(ChampShell), findsNothing);
      autenticacion.esperaInicializacion!.complete();
      await tester.pumpAndSettle();
      expect(find.byType(ChampShell), findsOneWidget);
      await tester.runAsync(() async {
        await servicios.base.guardar('catalogos', 'conservar', {
          'id': 'conservar',
          'nombre': 'Contenido anterior al logout',
        });
      });
      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();
      expect(find.text('Ana'), findsOneWidget);
      await tester.tap(find.text('Cerrar sesión'));
      await tester.pumpAndSettle();
      expect(find.byType(AppLogin), findsOneWidget);
      expect(find.byType(ChampShell), findsNothing);
      expect(autenticacion.salidas, 1);
      expect(
        Navigator.of(tester.element(find.byType(AppLogin))).canPop(),
        isFalse,
      );
      await tester.runAsync(() async {
        expect(
          (await servicios.base.obtener('catalogos', 'conservar'))!['nombre'],
          'Contenido anterior al logout',
        );
      });
      await tester.ensureVisible(find.text('CONTINUAR CON GOOGLE'));
      await tester.tap(find.text('CONTINUAR CON GOOGLE'));
      await tester.pumpAndSettle();
      expect(find.byType(ChampShell), findsOneWidget);
      expect(autenticacion.inicializaciones, 1);
      expect(autenticacion.accesos, 1);
      expect(
        Navigator.of(tester.element(find.byType(ChampShell))).canPop(),
        isFalse,
      );
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'cancelación y error conservan la entrada y permiten reintentar',
    (tester) async {
      final autenticacion = AutenticacionFalsa()
        ..falloAcceso = const AccesoCancelado();
      final sesion = GestionarSesion(servicio: autenticacion);
      addTearDown(autenticacion.dispose);
      addTearDown(sesion.dispose);
      await tester.pumpWidget(
        ChampApp(servicios: await serviciosPrueba(), controladorSesion: sesion),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('CONTINUAR CON GOOGLE'));
      await tester.tap(find.text('CONTINUAR CON GOOGLE'));
      await tester.pumpAndSettle();
      expect(
        find.text('Acceso cancelado. Puedes volver a intentarlo.'),
        findsOneWidget,
      );
      expect(find.byType(ChampShell), findsNothing);
      autenticacion.falloAcceso = const FalloAutenticacion('Error de prueba');
      await tester.ensureVisible(find.text('CONTINUAR CON GOOGLE'));
      await tester.tap(find.text('CONTINUAR CON GOOGLE'));
      await tester.pumpAndSettle();
      expect(find.text('Error de prueba'), findsOneWidget);
      autenticacion.falloAcceso = null;
      await tester.ensureVisible(find.text('CONTINUAR CON GOOGLE'));
      await tester.tap(find.text('CONTINUAR CON GOOGLE'));
      await tester.pumpAndSettle();
      expect(find.byType(ChampShell), findsOneWidget);
      expect(find.byType(AppLogin), findsNothing);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'el piloto no muestra planes ni selecciones locales de otra instalación',
    (tester) async {
      final carpeta = await carpetaPrueba();
      ServiciosChamp abrir() => ServiciosChamp(
        base: BaseLocal(SqliteLocal(directorio: carpeta)),
        leerLegado: (_) async => null,
        cargarFotoSemilla: (_) async => null,
        sembrarPlanesReferencia: false,
      );
      var servicios = abrir();
      final plan = planPrueba();
      await servicios.base.guardar('planes_membership', plan.id, plan.toJson());
      await servicios.membership.seleccionar(plan.id);
      final autenticacion = AutenticacionFalsa(
        usuarioActual: const UsuarioChamp(uid: 'usuario-prueba', nombre: 'Ana'),
      );
      final sesion = GestionarSesion(servicio: autenticacion);
      addTearDown(autenticacion.dispose);
      addTearDown(sesion.dispose);
      addTearDown(() async {
        await servicios.cerrar();
      });
      await tester.pumpWidget(
        ChampApp(servicios: servicios, controladorSesion: sesion),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ListTile, 'Membership'));
      await tester.pumpAndSettle();
      expect(find.byType(AppMembership), findsOneWidget);
      expect(find.byType(AppComercio), findsOneWidget);
      expect(find.text('Seleccionar plan'), findsNothing);
      expect(
        find.text('Los planes todavía no están disponibles.'),
        findsOneWidget,
      );
      await tester.tap(find.text('Ir al Carro'));
      await tester.pumpAndSettle();
      expect(find.byType(AppCarro), findsOneWidget);
      expect(find.text('Tu Carro está vacío.'), findsOneWidget);
      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cerrar sesión'));
      await tester.pumpAndSettle();
      expect(find.byType(AppLogin), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      await tester.runAsync(() async {
        await servicios.cerrar();
        servicios = abrir();
        final guardado = await servicios.membership.cargarEstado();
        expect(guardado.plan!.id, plan.id);
        expect(guardado.membresiaActiva, isFalse);
        expect((await servicios.base.estado())['version'], 3);
      });
    },
  );
}
