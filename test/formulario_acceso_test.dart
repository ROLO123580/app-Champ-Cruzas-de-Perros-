import 'dart:async';

import 'package:champ/app_champ.dart';
import 'package:champ/core/modelos/sesion.dart';
import 'package:champ/microapps/acceso/app_acceso.dart';
import 'package:champ/nanoapps/login/nanofunciones/gestionar_sesion/gestionar_sesion.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'soporte/autenticacion_falsa.dart';
import 'soporte/base_prueba.dart';

void main() {
  Future<GestionarSesion> mostrar(
    WidgetTester tester,
    AutenticacionFalsa servicio,
  ) async {
    final sesion = GestionarSesion(servicio: servicio);
    addTearDown(servicio.dispose);
    addTearDown(sesion.dispose);
    await sesion.inicializar();
    await tester.pumpWidget(MaterialApp(home: AppAcceso(controlador: sesion)));
    await tester.pumpAndSettle();
    return sesion;
  }

  testWidgets(
    'el formulario se adapta a 320 píxeles y permite mostrar la clave',
    (tester) async {
      tester.view.physicalSize = const Size(320, 740);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await mostrar(tester, AutenticacionFalsa());
      expect(find.text('CHAMP'), findsOneWidget);
      expect(find.text('INICIAR SESIÓN'), findsOneWidget);
      expect(find.text('CREAR CUENTA'), findsOneWidget);
      final clave = find.descendant(
        of: find.byKey(const Key('clave_acceso')),
        matching: find.byType(TextField),
      );
      expect(tester.widget<TextField>(clave).obscureText, isTrue);
      await tester.enterText(
        find.byKey(const Key('clave_acceso')),
        'clave-visible',
      );
      await tester.tap(find.byTooltip('Mostrar contraseña'));
      await tester.pumpAndSettle();
      expect(tester.widget<TextField>(clave).obscureText, isFalse);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'correo inválido no llama al proveedor y Enter inicia una sola vez',
    (tester) async {
      final servicio = AutenticacionFalsa()
        ..esperaCorreo = Completer<UsuarioChamp?>();
      await mostrar(tester, servicio);
      await tester.enterText(
        find.byKey(const Key('correo_acceso')),
        'correo-invalido',
      );
      await tester.enterText(
        find.byKey(const Key('clave_acceso')),
        'clave-existente',
      );
      await tester.tap(find.byKey(const Key('enviar_acceso')));
      await tester.pumpAndSettle();
      expect(servicio.accesosCorreo, 0);
      await tester.enterText(
        find.byKey(const Key('correo_acceso')),
        'ana@example.test',
      );
      await tester.tap(find.byKey(const Key('clave_acceso')));
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      expect(servicio.accesosCorreo, 1);
      expect(
        tester
            .widget<FilledButton>(find.byKey(const Key('enviar_acceso')))
            .onPressed,
        isNull,
      );
      expect(
        tester
            .widget<OutlinedButton>(find.byKey(const Key('alternar_acceso')))
            .onPressed,
        isNull,
      );
      servicio.esperaCorreo!.complete(const UsuarioChamp(uid: 'correo-prueba'));
      await tester.pumpAndSettle();
    },
  );

  testWidgets(
    'crear cuenta exige confirmación y volver limpia las contraseñas',
    (tester) async {
      final servicio = AutenticacionFalsa();
      await mostrar(tester, servicio);
      await tester.enterText(
        find.byKey(const Key('correo_acceso')),
        'ana@example.test',
      );
      await tester.tap(find.byKey(const Key('alternar_acceso')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('confirmacion_acceso')), findsOneWidget);
      await tester.enterText(
        find.byKey(const Key('clave_acceso')),
        'clave-nueva',
      );
      await tester.enterText(
        find.byKey(const Key('confirmacion_acceso')),
        'otra-clave',
      );
      await tester.ensureVisible(find.byKey(const Key('enviar_acceso')));
      await tester.tap(find.byKey(const Key('enviar_acceso')));
      await tester.pumpAndSettle();
      expect(find.text('Las contraseñas no coinciden.'), findsOneWidget);
      expect(servicio.creacionesCuenta, 0);
      await tester.ensureVisible(find.byKey(const Key('alternar_acceso')));
      await tester.tap(find.byKey(const Key('alternar_acceso')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('confirmacion_acceso')), findsNothing);
      final clave = find.descendant(
        of: find.byKey(const Key('clave_acceso')),
        matching: find.byType(TextField),
      );
      expect(tester.widget<TextField>(clave).controller!.text, isEmpty);
      final correo = find.descendant(
        of: find.byKey(const Key('correo_acceso')),
        matching: find.byType(TextField),
      );
      expect(
        tester.widget<TextField>(correo).controller!.text,
        'ana@example.test',
      );
    },
  );

  testWidgets('crear cuenta entra al shell sin apilar otra pantalla', (
    tester,
  ) async {
    final servicio = AutenticacionFalsa();
    final sesion = GestionarSesion(servicio: servicio);
    addTearDown(servicio.dispose);
    addTearDown(sesion.dispose);
    await tester.pumpWidget(
      ChampApp(servicios: await serviciosPrueba(), controladorSesion: sesion),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('alternar_acceso')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('correo_acceso')),
      'ana@example.test',
    );
    await tester.enterText(
      find.byKey(const Key('clave_acceso')),
      'clave-nueva',
    );
    await tester.enterText(
      find.byKey(const Key('confirmacion_acceso')),
      'clave-nueva',
    );
    await tester.ensureVisible(find.byKey(const Key('enviar_acceso')));
    await tester.tap(find.byKey(const Key('enviar_acceso')));
    await tester.pumpAndSettle();
    expect(servicio.creacionesCuenta, 1);
    expect(find.byType(ChampShell), findsOneWidget);
    expect(
      Navigator.of(tester.element(find.byType(ChampShell))).canPop(),
      isFalse,
    );
    await tester.pumpWidget(const SizedBox());
  });
}
