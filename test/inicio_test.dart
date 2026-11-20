import 'dart:async';

import 'package:champ/core/modelos/cruces.dart';
import 'package:champ/core/modelos/sesion.dart';
import 'package:champ/core/repositorios/contratos.dart';
import 'package:champ/nanoapps/cruces/nanofunciones/gestionar_cruces/gestionar_cruces.dart';
import 'package:champ/nanoapps/inicio/app_inicio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _perro = PerfilPerro(
  id: 'mi-perro',
  nombre: 'Toby',
  raza: 'Mestizo',
  sexo: 'Macho',
  edadMeses: 24,
  ciudad: 'Santiago',
  responsable: 'Rolo',
  descripcion: 'Le gusta pasear.',
);

const _candidata = PerfilPerro(
  id: 'demo-luna',
  nombre: 'Luna',
  raza: 'Mestizo',
  sexo: 'Hembra',
  edadMeses: 24,
  ciudad: 'Santiago',
  responsable: 'Ana',
  descripcion: 'Perfil de ejemplo.',
  interesDemo: true,
);

class _Almacen extends AlmacenCruces {
  EstadoCruces estado = EstadoCruces();
  Completer<void>? espera;
  bool fallar = false;

  @override
  Future<EstadoCruces> cargar() async {
    await espera?.future;
    if (fallar) throw StateError('Servicio local sin conexión');
    return estado;
  }

  @override
  Future<void> guardar(EstadoCruces nuevo) async => estado = nuevo;

  @override
  Future<List<PerfilPerro>> cargarPerfiles() async => [_candidata];
}

void main() {
  Future<void> mostrar(
    WidgetTester tester,
    GestionarCruces controlador,
    List<String> destinos, {
    double escala = 1,
  }) => tester.pumpWidget(
    MaterialApp(
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(escala)),
        child: child!,
      ),
      home: Scaffold(
        body: AppInicio(
          controlador: controlador,
          usuario: const UsuarioChamp(uid: 'rolo', nombre: 'Rolo'),
          onSeleccion: destinos.add,
        ),
      ),
    ),
  );

  testWidgets('muestra actividad real y entrega los accesos al orquestador', (
    tester,
  ) async {
    final almacen = _Almacen()
      ..estado = EstadoCruces(
        miPerro: _perro,
        decisiones: {
          'demo-luna': DecisionCruce.gusta,
          'otro': DecisionCruce.gusta,
        },
        matches: {'demo-luna'},
      );
    final controlador = GestionarCruces(almacen: almacen);
    addTearDown(controlador.dispose);
    final destinos = <String>[];
    await mostrar(tester, controlador, destinos);
    await tester.pumpAndSettle();

    expect(find.text('Hola, Rolo'), findsOneWidget);
    expect(find.text('Toby'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.textContaining('Catálogo de demostración:'), findsOneWidget);
    await tester.tap(find.byKey(const Key('inicio_ver_perfil')));
    expect(destinos, ['Mis perros']);
    for (final modulo in ['Mis perros', 'Cruces', 'Chat', 'Configuración']) {
      final acceso = find.byKey(ValueKey('inicio_acceso_$modulo'));
      await tester.ensureVisible(acceso);
      await tester.tap(acceso);
      expect(destinos.last, modulo);
    }
    expect(tester.takeException(), isNull);
    // El dashboard recibe el controlador; no debe destruirlo al salir.
    await tester.pumpWidget(const SizedBox());
    controlador.filtrar(porRaza: '', porCiudad: 'Santiago');
    expect(controlador.ciudad, 'Santiago');
  });

  testWidgets('muestra carga y permite reintentar un servicio fallido', (
    tester,
  ) async {
    final espera = Completer<void>();
    final almacen = _Almacen()
      ..espera = espera
      ..fallar = true;
    final controlador = GestionarCruces(almacen: almacen);
    addTearDown(controlador.dispose);
    await mostrar(tester, controlador, []);
    await tester.pump();
    expect(find.text('Cargando tu perfil y actividad…'), findsOneWidget);
    expect(find.text('Matches guardados'), findsNothing);
    espera.complete();
    await tester.pumpAndSettle();
    expect(find.text('Servicio local sin conexión'), findsOneWidget);
    expect(find.text('Crear perfil de mi perro'), findsNothing);

    almacen.fallar = false;
    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();
    expect(find.text('Crear perfil de mi perro'), findsOneWidget);
    expect(find.text('Servicio local sin conexión'), findsNothing);
  });

  testWidgets('se adapta a 320 píxeles con texto grande y perfil ausente', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 740);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final controlador = GestionarCruces(almacen: _Almacen());
    addTearDown(controlador.dispose);
    final destinos = <String>[];
    await mostrar(tester, controlador, destinos, escala: 2);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    final crear = find.byKey(const Key('inicio_ver_perfil'));
    await tester.ensureVisible(crear);
    await tester.tap(crear);
    expect(destinos, ['Mis perros']);
    final configuracion = find.byKey(
      const ValueKey('inicio_acceso_Configuración'),
    );
    await tester.ensureVisible(configuracion);
    await tester.tap(configuracion);
    expect(destinos.last, 'Configuración');
    expect(tester.takeException(), isNull);
  });
}
