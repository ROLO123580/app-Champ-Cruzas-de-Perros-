import 'package:champ/app_champ.dart';
import 'package:champ/core/modelos/sesion.dart';
import 'package:champ/core/repositorios/preferencias.dart';
import 'package:champ/nanoapps/configuracion/configuracion_cuenta.dart';
import 'package:champ/nanoapps/configuracion/nanofunciones/gestionar_preferencias/gestionar_preferencias.dart';
import 'package:champ/nanoapps/login/nanofunciones/gestionar_sesion/gestionar_sesion.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'soporte/autenticacion_falsa.dart';

class PreferenciasPrueba implements RepositorioPreferencias {
  Map<String, dynamic> datos = {};
  bool fallar = false;
  @override
  Future<Map<String, dynamic>> cargar() async => Map.of(datos);
  @override
  Future<void> guardar(Map<String, dynamic> d) async {
    if (fallar) throw StateError('No se pudo guardar en este equipo.');
    datos = Map.of(d);
  }
}

void main() {
  test(
    'apariencia se recupera tras reabrir y no cambia si el guardado falla',
    () async {
      SharedPreferences.setMockInitialValues({});
      final p = GestionarPreferencias(PreferenciasDispositivo());
      await p.cargar();
      await p.cambiar(tema: ThemeMode.dark, texto: 1.3);
      final otra = GestionarPreferencias(PreferenciasDispositivo());
      await otra.cargar();
      expect(otra.modo, ThemeMode.dark);
      expect(otra.escala, 1.3);
      final repo = PreferenciasPrueba()..fallar = true;
      final fallida = GestionarPreferencias(repo);
      await fallida.cargar();
      expect(await fallida.cambiar(tema: ThemeMode.dark), isFalse);
      expect(fallida.modo, ThemeMode.system);
      expect(fallida.error, isNotNull);
      p.dispose();
      otra.dispose();
      fallida.dispose();
    },
  );
  test('restablecer recupera un archivo de preferencias corrupto', () async {
    SharedPreferences.setMockInitialValues({
      PreferenciasDispositivo.clave: 'contenido dañado',
    });
    final p = GestionarPreferencias(PreferenciasDispositivo());
    expect(await p.cargar(), isFalse);
    expect(await p.restablecer(), isTrue);
    expect(p.cargado, isTrue);
    expect(p.error, isNull);
    p.dispose();
  });
  testWidgets('cambiar apariencia actualiza el tema y tamaño de la app', (
    tester,
  ) async {
    final p = GestionarPreferencias(PreferenciasPrueba());
    await p.cargar();
    final auth = AutenticacionFalsa();
    final sesion = GestionarSesion(servicio: auth);
    addTearDown(p.dispose);
    addTearDown(sesion.dispose);
    addTearDown(auth.dispose);
    await tester.pumpWidget(
      ChampApp(controladorSesion: sesion, preferencias: p),
    );
    await tester.pumpAndSettle();
    await p.cambiar(tema: ThemeMode.dark, texto: 1.3);
    await tester.pumpAndSettle();
    expect(
      tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
      ThemeMode.dark,
    );
    expect(
      Theme.of(tester.element(find.byType(Scaffold).first)).brightness,
      Brightness.dark,
    );
    expect(
      MediaQuery.textScalerOf(tester.element(find.byType(Scaffold).first))
          .scale(10),
      closeTo(13, 0.01),
    );
    await p.restablecer();
    await tester.pumpAndSettle();
    expect(
      tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
      ThemeMode.system,
    );
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('cuenta confirma salir y no ofrece respaldos locales ajenos', (
    tester,
  ) async {
    final auth = AutenticacionFalsa(
      usuarioActual: const UsuarioChamp(
        uid: 'ana',
        nombre: 'Ana',
        correo: 'ana@example.test',
      ),
    );
    final sesion = GestionarSesion(servicio: auth);
    await sesion.inicializar();
    addTearDown(sesion.dispose);
    addTearDown(auth.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ConfiguracionCuenta(usuario: sesion.usuario!, sesion: sesion),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('ana@example.test'), findsOneWidget);
    expect(find.text('Respaldar base y fotos'), findsNothing);
    await tester.tap(find.text('Cerrar sesión'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Volver'));
    await tester.pumpAndSettle();
    expect(auth.salidas, 0);
    await tester.tap(find.text('Cerrar sesión'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Cerrar sesión'));
    await tester.pumpAndSettle();
    expect(auth.salidas, 1);
    await tester.pumpWidget(const SizedBox());
  });
}
