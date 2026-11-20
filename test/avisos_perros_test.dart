import 'dart:async';
import 'dart:io';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:champ/core/modelos/aviso_perro.dart';
import 'package:champ/core/repositorios/avisos_perros.dart';
import 'package:champ/nanoapps/perdidos_encontrados/app_perdidos_encontrados.dart';
import 'package:champ/nanoapps/perdidos_encontrados/nanofunciones/gestionar_avisos/gestionar_avisos.dart';
import 'package:champ/nanoapps/perdidos_encontrados/nanofunciones/gestionar_avisos/nanoactividades/seleccionar_foto/seleccionar_foto.dart';
import 'package:champ/nanoapps/perdidos_encontrados/vistas/formulario_aviso.dart';
import 'package:champ/nanoapps/perdidos_encontrados/vistas/detalle_aviso.dart';

DatosAvisoPerro datosAviso({
  TipoAvisoPerro tipo = TipoAvisoPerro.perdido,
  String nombre = 'Toby',
  String chip = 'si',
  String ultimos = '1234',
}) => DatosAvisoPerro(
  tipo: tipo,
  nombre: nombre,
  raza: 'Mestizo',
  zona: 'Santiago',
  lugar: 'Parque central',
  descripcion: 'Collar azul y una mancha blanca.',
  fechaVista: DateTime.now().subtract(const Duration(hours: 1)),
  chip: chip,
  chipUltimos: ultimos,
);

class AvisosPrueba implements RepositorioAvisosPerros {
  AvisosPrueba({this.uid = 'autora'});
  @override
  final String uid;
  final cambios = StreamController<void>.broadcast();
  final registros = <String, AvisoPerro>{};
  bool fallaGuardar = false, fallaCarga = false;
  int guardados = 0;
  void semilla() {
    registros['aviso'] = AvisoPerro(
      id: 'aviso',
      autorUid: 'autora',
      autorNombre: 'Ana',
      datos: datosAviso(),
    );
  }

  Stream<T> leer<T>(T Function() valor) async* {
    if (fallaCarga) throw StateError('Sin conexión');
    yield valor();
    await for (final _ in cambios.stream) {
      yield valor();
    }
  }

  @override
  Stream<List<AvisoPerro>> listar() => leer(() => registros.values.toList());
  @override
  Stream<AvisoPerro?> observar(String id) => leer(() => registros[id]);
  @override
  Future<void> guardar(String id, DatosAvisoPerro datos) async {
    if (fallaGuardar) throw StateError('No se pudo guardar el aviso.');
    guardados++;
    registros[id] = AvisoPerro(
      id: id,
      autorUid: uid,
      autorNombre: 'Ana',
      datos: datos,
    );
    cambios.add(null);
  }

  @override
  Future<void> resolver(String id, String nota) async {
    final actual = registros[id]!;
    registros[id] = AvisoPerro(
      id: id,
      autorUid: actual.autorUid,
      autorNombre: actual.autorNombre,
      datos: actual.datos,
      resuelto: true,
      notaCierre: nota,
    );
    cambios.add(null);
  }
}

Future<void> ver(WidgetTester tester, Finder finder) async {
  final scroll = tester.state<ScrollableState>(find.byType(Scrollable).first);
  scroll.position.jumpTo(scroll.position.minScrollExtent);
  await tester.pumpAndSettle();
  await tester.scrollUntilVisible(
    finder,
    300,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
}

void main() {
  test(
    'Microchip parcial no acepta numero completo ni contradiccion con sin chip',
    () {
      expect(
        () => datosAviso(ultimos: '123456789012345').validar(),
        throwsStateError,
      );
      expect(
        () => datosAviso(chip: 'no', ultimos: '1234').validar(),
        throwsStateError,
      );
      final datos = datosAviso();
      datos.validar();
      expect(DatosAvisoPerro.fromMap(datos.toMap()).chipUltimos, '1234');
    },
  );
  testWidgets('La actividad prepara una foto PNG compartida y acotada', (
    tester,
  ) async {
    final bytes = await tester.runAsync(
      () => File('assets/catalogo/demo-luna.jpg').readAsBytes(),
    );
    final foto = await tester.runAsync(
      () => SeleccionarFotoAviso.comprimir(bytes!),
    );
    expect(foto, isNotNull);
    expect(foto!.length, lessThanOrEqualTo(80 * 1024));
    expect(base64Encode(foto), startsWith('iVBORw0KGgo'));
  });
  testWidgets('Publicar, editar y resolver conservan un unico aviso', (
    tester,
  ) async {
    final repo = AvisosPrueba();
    final g = GestionarAvisos(repo);
    addTearDown(g.dispose);
    addTearDown(repo.cambios.close);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppPerdidosEncontrados(
            controlador: g,
            onContactar: (_) async => true,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('crear_aviso')));
    await tester.pumpAndSettle();
    for (final entry in {
      'Nombre del perro (si lo conoces)': 'Toby',
      'Ciudad o comuna': 'Santiago',
      'Último lugar o referencia': 'Parque central',
      'Señas y detalles para reconocerlo': 'Collar azul y mancha blanca',
    }.entries) {
      await tester.enterText(
        find.widgetWithText(TextFormField, entry.key),
        entry.value,
      );
    }
    await tester.scrollUntilVisible(
      find.byKey(const Key('guardar_aviso')),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byKey(const Key('guardar_aviso')));
    await tester.pumpAndSettle();
    expect(find.byType(DetalleAviso), findsOneWidget);
    expect(repo.registros.length, 1);
    await ver(tester, find.byKey(const Key('editar_aviso')));
    await tester.tap(find.byKey(const Key('editar_aviso')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Nombre del perro (si lo conoces)'),
      'Toby actualizado',
    );
    await tester.scrollUntilVisible(
      find.byKey(const Key('guardar_aviso')),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byKey(const Key('guardar_aviso')));
    await tester.pumpAndSettle();
    await ver(tester, find.text('Toby actualizado'));
    expect(find.text('Toby actualizado'), findsOneWidget);
    expect(repo.registros.length, 1);
    await ver(tester, find.byKey(const Key('resolver_aviso')));
    await tester.tap(find.byKey(const Key('resolver_aviso')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('nota_cierre_aviso')),
      'Ya está de vuelta en casa.',
    );
    await tester.tap(find.byKey(const Key('confirmar_resolver_aviso')));
    await tester.pumpAndSettle();
    expect(repo.registros.values.single.resuelto, isTrue);
    await ver(tester, find.text('Caso resuelto'));
    expect(find.text('Caso resuelto'), findsOneWidget);
    expect(find.byKey(const Key('editar_aviso')), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets(
    'Un fallo conserva el formulario y permite reintentar sin duplicar',
    (tester) async {
      final repo = AvisosPrueba()
        ..semilla()
        ..fallaGuardar = true;
      final g = GestionarAvisos(repo);
      addTearDown(g.dispose);
      addTearDown(repo.cambios.close);
      await tester.pumpWidget(
        MaterialApp(
          home: FormularioAviso(controlador: g, aviso: repo.registros['aviso']),
        ),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.byKey(const Key('guardar_aviso')),
        400,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.byKey(const Key('guardar_aviso')));
      await tester.pumpAndSettle();
      await ver(tester, find.text('No se pudo guardar el aviso.'));
      expect(find.text('No se pudo guardar el aviso.'), findsOneWidget);
      expect(
        tester
            .widget<TextFormField>(
              find.widgetWithText(
                TextFormField,
                'Nombre del perro (si lo conoces)',
              ),
            )
            .controller!
            .text,
        'Toby',
      );
      expect(repo.guardados, 0);
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets(
    'Contacto usa el UID del autor; no da acciones de edicion a terceros',
    (tester) async {
      final repo = AvisosPrueba(uid: 'visitante')..semilla();
      final g = GestionarAvisos(repo);
      String? contacto;
      addTearDown(g.dispose);
      addTearDown(repo.cambios.close);
      await tester.pumpWidget(
        MaterialApp(
          home: DetalleAviso(
            controlador: g,
            avisoId: 'aviso',
            onContactar: (uid) async {
              contacto = uid;
              return false;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('editar_aviso')), findsNothing);
      await ver(tester, find.byKey(const Key('contactar_aviso')));
      await tester.tap(find.byKey(const Key('contactar_aviso')));
      await tester.pumpAndSettle();
      expect(contacto, 'autora');
      expect(
        find.text('No pudimos abrir el chat. Vuelve a intentarlo.'),
        findsOneWidget,
      );
      expect(find.byType(DetalleAviso), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets('Lista filtra encontrados y recupera errores de carga', (
    tester,
  ) async {
    final repo = AvisosPrueba()
      ..semilla()
      ..fallaCarga = true;
    repo.registros['encontrado'] = AvisoPerro(
      id: 'encontrado',
      autorUid: 'otro',
      autorNombre: 'Jaime',
      datos: datosAviso(
        tipo: TipoAvisoPerro.encontrado,
        nombre: 'Rayo',
        chip: 'desconocido',
        ultimos: '',
      ),
    );
    final g = GestionarAvisos(repo);
    addTearDown(g.dispose);
    addTearDown(repo.cambios.close);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppPerdidosEncontrados(
            controlador: g,
            onContactar: (_) async => true,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('No pudimos cargar los avisos'), findsOneWidget);
    repo.fallaCarga = false;
    await ver(tester, find.text('Reintentar'));
    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();
    await ver(tester, find.text('Encontrados'));
    await tester.tap(find.text('Encontrados'));
    await tester.pumpAndSettle();
    expect(find.text('Toby'), findsNothing);
    await ver(tester, find.text('Rayo'));
    expect(find.text('Rayo'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets(
    'Pegar el chip completo no lo recorta ni lo publica por accidente',
    (tester) async {
      final repo = AvisosPrueba()..semilla();
      final gestion = GestionarAvisos(repo);
      addTearDown(gestion.dispose);
      addTearDown(repo.cambios.close);
      await tester.pumpWidget(
        MaterialApp(
          home: FormularioAviso(
            controlador: gestion,
            aviso: repo.registros['aviso'],
          ),
        ),
      );
      await tester.pumpAndSettle();
      await ver(tester, find.byKey(const Key('chip_ultimos_aviso')));
      await tester.enterText(
        find.byKey(const Key('chip_ultimos_aviso')),
        '123456789012345',
      );
      await ver(tester, find.byKey(const Key('guardar_aviso')));
      await tester.tap(find.byKey(const Key('guardar_aviso')));
      await tester.pumpAndSettle();
      expect(repo.guardados, 0);
      await ver(tester, find.text('Escribe solo los últimos 4 dígitos.'));
      expect(find.text('Escribe solo los últimos 4 dígitos.'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets('Lista, formulario y ficha no desbordan en movil', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repo = AvisosPrueba()..semilla();
    final g = GestionarAvisos(repo);
    addTearDown(g.dispose);
    addTearDown(repo.cambios.close);
    for (final pantalla in <Widget>[
      Scaffold(
        body: AppPerdidosEncontrados(
          controlador: g,
          onContactar: (_) async => true,
        ),
      ),
      FormularioAviso(controlador: g, aviso: repo.registros['aviso']),
      DetalleAviso(
        controlador: g,
        avisoId: 'aviso',
        onContactar: (_) async => true,
      ),
    ]) {
      await tester.pumpWidget(
        MaterialApp(
          builder: (c, child) => MediaQuery(
            data: MediaQuery.of(c).copyWith(textScaler: TextScaler.linear(1.5)),
            child: child!,
          ),
          home: pantalla,
        ),
      );
      await tester.pumpAndSettle();
      expect(
        tester.takeException(),
        isNull,
        reason: pantalla.runtimeType.toString(),
      );
      await tester.pumpWidget(const SizedBox());
    }
  });
}
