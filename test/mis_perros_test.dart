import 'dart:async';

import 'package:champ/core/modelos/cruces.dart';
import 'package:champ/core/repositorios/legado/preferencias_cruces.dart';
import 'package:champ/nanoapps/cruces/nanofunciones/gestionar_cruces/gestionar_cruces.dart';
import 'package:champ/nanoapps/mis_perros/app_mis_perros.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'soporte/preferencias_prueba.dart';

const _perro = PerfilPerro(
  id: 'perro-prueba',
  nombre: 'Toby',
  raza: 'Golden retriever',
  sexo: 'Macho',
  edadMeses: 36,
  ciudad: 'Santiago',
  responsable: 'Rolo',
  descripcion: 'Juguetón y compañero de paseos.',
);

class _AlmacenControlado extends AlmacenCruces {
  Completer<EstadoCruces>? pendiente;
  Completer<void>? guardadoPendiente;
  EstadoCruces estado = EstadoCruces();
  bool fallar = false;

  @override
  Future<EstadoCruces> cargar() async {
    if (pendiente != null) return pendiente!.future;
    if (fallar) throw StateError('El servicio local no está disponible.');
    return estado;
  }

  @override
  Future<void> guardar(EstadoCruces nuevo) async {
    await guardadoPendiente?.future;
    estado = nuevo;
  }

  @override
  Future<List<PerfilPerro>> cargarPerfiles() async => [];
}

Future<void> _campo(WidgetTester tester, String etiqueta, String valor) async {
  final campo = find.widgetWithText(TextFormField, etiqueta);
  await tester.ensureVisible(campo);
  await tester.enterText(campo, valor);
}

void main() {
  testWidgets(
    'crear y editar desde Mis perros conserva el perfil compartido e historial',
    (tester) async {
      tester.view.physicalSize = const Size(1000, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final preferencias = PreferenciasPrueba();
      final controlador = GestionarCruces(
        almacen: PersistirCruces(preferencias: preferencias),
      );
      addTearDown(controlador.dispose);
      var aperturasCruces = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppMisPerros(
              controlador: controlador,
              onIrCruces: () => aperturasCruces++,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Crear perfil de mi perro'));
      await tester.pumpAndSettle();
      await _campo(tester, 'Nombre de tu perro', 'Toby');
      await _campo(tester, 'Raza', 'Golden retriever');
      await _campo(tester, 'Edad en meses', '36');
      await _campo(tester, 'Ciudad', 'Santiago');
      await _campo(tester, 'Tu nombre', 'Rolo');
      await _campo(tester, 'Cuéntanos cómo es', 'Juguetón');
      await tester.tap(find.text('Guardar perfil'));
      await tester.pumpAndSettle();
      expect(find.text('Toby'), findsOneWidget);
      expect(find.text('Santiago'), findsOneWidget);
      final id = controlador.miPerro!.id;
      expect(
        await controlador.decidir('demo-luna', DecisionCruce.gusta),
        isTrue,
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Editar perfil'));
      await tester.tap(find.text('Editar perfil'));
      await tester.pumpAndSettle();
      await _campo(tester, 'Nombre de tu perro', 'Toby actualizado');
      await _campo(tester, 'Ciudad', 'Valparaíso');
      await tester.tap(find.text('Guardar perfil'));
      await tester.pumpAndSettle();
      expect(controlador.miPerro!.id, id);
      expect(controlador.miPerro!.ciudad, 'Valparaíso');
      expect(controlador.matches.single.id, 'demo-luna');
      expect(find.text('Toby actualizado'), findsOneWidget);
      await tester.ensureVisible(find.text('Ir a Cruces'));
      await tester.tap(find.text('Ir a Cruces'));
      expect(aperturasCruces, 1);

      await tester.pumpWidget(const SizedBox());
      // El controlador inyectado pertenece al shell y sigue utilizable al salir.
      controlador.filtrar(porRaza: '', porCiudad: 'Santiago');
      final restaurado = GestionarCruces(
        almacen: PersistirCruces(preferencias: preferencias),
      );
      addTearDown(restaurado.dispose);
      await restaurado.cargar();
      expect(restaurado.miPerro!.nombre, 'Toby actualizado');
      expect(restaurado.miPerro!.id, id);
      expect(restaurado.matches.single.id, 'demo-luna');
    },
  );

  testWidgets('muestra la carga y permite reintentar sin inventar un perfil', (
    tester,
  ) async {
    final almacen = _AlmacenControlado()..pendiente = Completer<EstadoCruces>();
    final controlador = GestionarCruces(almacen: almacen);
    addTearDown(controlador.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: AppMisPerros(controlador: controlador)),
      ),
    );
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    expect(find.text('Crear perfil de mi perro'), findsNothing);
    almacen.pendiente!.completeError(
      StateError('El servicio local no está disponible.'),
    );
    await tester.pumpAndSettle();
    expect(find.text('El servicio local no está disponible.'), findsOneWidget);
    expect(find.text('Reintentar'), findsOneWidget);
    expect(controlador.miPerro, isNull);
    almacen.pendiente = null;
    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();
    expect(find.text('Crear perfil de mi perro'), findsOneWidget);
    expect(find.text('El servicio local no está disponible.'), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
    'la ficha se adapta a 320 px y texto grande con edición bloqueada al guardar',
    (tester) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final almacen = _AlmacenControlado()
        ..estado = EstadoCruces(miPerro: _perro);
      final controlador = GestionarCruces(almacen: almacen);
      addTearDown(controlador.dispose);
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(1.8)),
            child: child!,
          ),
          home: Scaffold(
            body: AppMisPerros(controlador: controlador, onIrCruces: () {}),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Toby'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.ensureVisible(find.text('Editar perfil'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      almacen.guardadoPendiente = Completer<void>();
      final guardando = controlador.guardarPerfil(_perro);
      await tester.pump();
      final editar = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Editar perfil'),
      );
      expect(editar.onPressed, isNull);
      final cruces = tester.widget<OutlinedButton>(
        find.widgetWithText(OutlinedButton, 'Ir a Cruces'),
      );
      expect(cruces.onPressed, isNull);
      almacen.guardadoPendiente!.complete();
      await guardando;
      await tester.pumpWidget(const SizedBox());
    },
  );
}
