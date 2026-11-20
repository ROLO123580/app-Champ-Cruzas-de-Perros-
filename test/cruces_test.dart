import 'package:champ/app_champ.dart';
import 'package:champ/nanoapps/chat/app_chat.dart';
import 'package:champ/core/repositorios/legado/preferencias_chat.dart';
import 'package:champ/nanoapps/chat/nanofunciones/gestionar_chat/gestionar_chat.dart';
import 'package:champ/nanoapps/cruces/app_cruces.dart';
import 'package:champ/core/modelos/cruces.dart';
import 'package:champ/core/repositorios/legado/preferencias_cruces.dart';
import 'package:champ/nanoapps/cruces/nanofunciones/gestionar_cruces/gestionar_cruces.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'soporte/preferencias_prueba.dart';

const miPerro = PerfilPerro(
  id: 'mi-perro',
  nombre: 'Toby',
  raza: 'Golden retriever',
  sexo: 'Macho',
  edadMeses: 36,
  ciudad: 'Santiago',
  responsable: 'Rolo',
  descripcion: 'Juguetón',
);

Future<GestionarCruces> preparar(PreferenciasPrueba preferencias) async {
  final cruces = GestionarCruces(
    almacen: PersistirCruces(preferencias: preferencias),
  );
  await cruces.cargar();
  await cruces.guardarPerfil(miPerro);
  return cruces;
}

void main() {
  test('solo el interés mutuo habilita el match y su conversación', () async {
    final cruces = await preparar(PreferenciasPrueba());
    addTearDown(cruces.dispose);
    expect(cruces.conversacionPara('demo-luna'), isNull);
    expect(await cruces.decidir('demo-nala', DecisionCruce.gusta), isTrue);
    expect(cruces.matches, isEmpty);
    expect(cruces.conversacionPara('demo-nala'), isNull);
    expect(await cruces.decidir('demo-luna', DecisionCruce.gusta), isTrue);
    expect(cruces.matches.single.id, 'demo-luna');
    expect(cruces.conversacionPara('demo-luna'), 'cruce:mi-perro:demo-luna');
    expect(await cruces.decidir('demo-luna', DecisionCruce.gusta), isFalse);
    expect(cruces.matches, hasLength(1));
  });

  test(
    'restaura perfil, descartes, intereses y matches después de reiniciar',
    () async {
      final preferencias = PreferenciasPrueba();
      final cruces = await preparar(preferencias);
      await cruces.decidir('demo-kira', DecisionCruce.pasar);
      await cruces.decidir('demo-nala', DecisionCruce.gusta);
      await cruces.decidir('demo-luna', DecisionCruce.gusta);
      cruces.dispose();
      final restaurado = GestionarCruces(
        almacen: PersistirCruces(preferencias: preferencias),
      );
      addTearDown(restaurado.dispose);
      await restaurado.cargar();
      expect(restaurado.miPerro!.nombre, 'Toby');
      expect(restaurado.pendientes, isEmpty);
      expect(restaurado.matches.single.id, 'demo-luna');
      expect(restaurado.intereses, 2);
      await restaurado.revisarDescartados();
      expect(restaurado.pendientes.single.id, 'demo-kira');
      expect(restaurado.matches, hasLength(1));
    },
  );

  test(
    'filtra por sexo, raza y ciudad sin descartar otros candidatos',
    () async {
      final cruces = await preparar(PreferenciasPrueba());
      addTearDown(cruces.dispose);
      expect(cruces.pendientes.every((p) => p.sexo == 'Hembra'), isTrue);
      cruces.filtrar(porRaza: 'Golden retriever', porCiudad: 'Santiago');
      expect(cruces.pendientes.single.id, 'demo-luna');
      cruces.filtrar(porRaza: 'Golden retriever', porCiudad: 'Valparaíso');
      expect(cruces.pendientes, isEmpty);
      cruces.filtrar(porRaza: '', porCiudad: '');
      expect(cruces.pendientes, hasLength(3));
    },
  );

  test(
    'si falla el guardado conserva la tarjeta y no publica un match',
    () async {
      final preferencias = PreferenciasPrueba();
      final cruces = await preparar(preferencias);
      addTearDown(cruces.dispose);
      preferencias.fallar = true;
      expect(await cruces.decidir('demo-luna', DecisionCruce.gusta), isFalse);
      expect(cruces.matches, isEmpty);
      expect(cruces.pendientes.first.id, 'demo-luna');
      expect(cruces.error, 'Sin espacio');
      preferencias.fallar = false;
      expect(await cruces.decidir('demo-luna', DecisionCruce.gusta), isTrue);
    },
  );

  test(
    'reabrir un match después de reiniciar conserva su conversación y mensajes',
    () async {
      final preferencias = PreferenciasPrueba();
      final chat = GestionarChat(
        almacen: PersistirChat(preferencias: preferencias),
      );
      final id = (await chat.abrirMatch(
        'cruce:mi-perro:demo-luna',
        'Camila · Luna',
      ))!;
      await chat.enviarTexto(id, 'Hola, soy el responsable de Toby');
      chat.dispose();
      final nuevo = GestionarChat(
        almacen: PersistirChat(preferencias: preferencias),
      );
      addTearDown(nuevo.dispose);
      expect(await nuevo.abrirMatch(id, 'Camila · Luna'), id);
      expect(nuevo.conversaciones, hasLength(1));
      expect(
        nuevo.conversaciones.single.mensajes.single.texto,
        'Hola, soy el responsable de Toby',
      );
    },
  );

  testWidgets('recorre Cruces → match → chat y reabre la misma conversación', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1300, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final preferencias = PreferenciasPrueba();
    final cruces = await preparar(preferencias);
    final chat = GestionarChat(
      almacen: PersistirChat(preferencias: preferencias),
    );
    addTearDown(cruces.dispose);
    addTearDown(chat.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: ChampShell(controladorChat: chat, controladorCruces: cruces),
      ),
    );
    await tester.tap(
      find.descendant(
        of: find.byKey(const Key('navegacion_modulos')),
        matching: find.widgetWithText(ListTile, 'Cruces'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Me gusta'));
    await tester.tap(find.text('Me gusta'));
    await tester.pumpAndSettle();
    expect(find.text('¡Es un match!'), findsOneWidget);
    await tester.tap(find.text('Ir al chat'));
    await tester.pumpAndSettle();
    expect(find.byType(AppChat), findsOneWidget);
    expect(find.text('Camila · Luna'), findsWidgets);
    await tester.enterText(find.byType(TextField), 'Hola Camila');
    await tester.tap(find.byTooltip('Enviar mensaje'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byKey(const Key('navegacion_modulos')),
        matching: find.widgetWithText(ListTile, 'Cruces'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Matches (1)'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Chatear con Camila'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(SelectableText, 'Hola Camila'), findsOneWidget);
    expect(chat.conversaciones, hasLength(1));
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('crea el perfil desde Cruces en una pantalla móvil', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final cruces = GestionarCruces(
      almacen: PersistirCruces(preferencias: PreferenciasPrueba()),
    );
    addTearDown(cruces.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: AppCruces(controlador: cruces)),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Crear perfil de mi perro'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Nombre de tu perro'),
      'Toby',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Raza'),
      'Golden retriever',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Edad en meses'),
      '36',
    );
    await tester.ensureVisible(find.widgetWithText(TextFormField, 'Ciudad'));
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Ciudad'),
      'Santiago',
    );
    await tester.ensureVisible(find.widgetWithText(TextFormField, 'Tu nombre'));
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Tu nombre'),
      'Rolo',
    );
    await tester.tap(find.text('Guardar perfil'));
    await tester.pumpAndSettle();
    expect(cruces.miPerro!.nombre, 'Toby');
    expect(find.text('Me gusta'), findsOneWidget);
    await tester.ensureVisible(find.text('Luna, 3 años'));
    await tester.drag(find.text('Luna, 3 años'), const Offset(-180, 0));
    await tester.pumpAndSettle();
    expect(cruces.pendientes.first.id, 'demo-nala');
    expect(cruces.matches, isEmpty);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}
