import 'dart:typed_data';

import 'package:champ/app_champ.dart';
import 'package:champ/microapps/comunidad_canina/app_comunidad_canina.dart';
import 'package:champ/nanoapps/chat/app_chat.dart';
import 'package:champ/core/repositorios/legado/preferencias_chat.dart';
import 'package:champ/core/servicios/seleccionar_foto.dart';
import 'package:champ/nanoapps/chat/nanofunciones/gestionar_chat/gestionar_chat.dart';
import 'package:champ/nanoapps/login/nanofunciones/gestionar_sesion/gestionar_sesion.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'soporte/preferencias_prueba.dart';
import 'soporte/base_prueba.dart';
import 'soporte/autenticacion_falsa.dart';

class FotoPrueba extends SeleccionarFoto {
  Uint8List? foto = Uint8List.fromList([1, 2, 3]);
  @override
  Future<Uint8List?> ejecutar() async => foto;
}

void main() {
  test(
    'restaura conversaciones, texto y bytes de fotos al recrear el chat',
    () async {
      final preferencias = PreferenciasPrueba();
      final chat = GestionarChat(
        almacen: PersistirChat(preferencias: preferencias),
        selector: FotoPrueba(),
      );
      await chat.cargar();
      final id = (await chat.crear('  Ana  '))!;
      expect(await chat.enviarTexto(id, ' Hola '), isTrue);
      await chat.enviarFoto(id);
      chat.dispose();
      final restaurado = GestionarChat(
        almacen: PersistirChat(preferencias: preferencias),
      );
      await restaurado.cargar();
      final c = restaurado.conversaciones.single;
      expect(c.nombre, 'Ana');
      expect(c.mensajes.first.texto, 'Hola');
      expect(c.mensajes.last.foto, orderedEquals([1, 2, 3]));
      restaurado.dispose();
    },
  );

  test(
    'no publica mensajes si falla la persistencia y permite reintentar',
    () async {
      final preferencias = PreferenciasPrueba();
      final chat = GestionarChat(
        almacen: PersistirChat(preferencias: preferencias),
      );
      await chat.cargar();
      final id = (await chat.crear('Ana'))!;
      preferencias.fallar = true;
      expect(await chat.enviarTexto(id, 'Hola'), isFalse);
      expect(chat.conversaciones.single.mensajes, isEmpty);
      expect(chat.error, 'Sin espacio');
      preferencias.fallar = false;
      expect(await chat.enviarTexto(id, 'Hola'), isTrue);
      expect(chat.error, isNull);
      chat.dispose();
    },
  );

  test(
    'rechaza texto vacío y no agrega mensajes al cancelar una foto',
    () async {
      final selector = FotoPrueba()..foto = null;
      final chat = GestionarChat(
        almacen: PersistirChat(preferencias: PreferenciasPrueba()),
        selector: selector,
      );
      await chat.cargar();
      expect(await chat.crear('  '), isNull);
      final id = (await chat.crear('Ana'))!;
      expect(await chat.enviarTexto(id, '  '), isFalse);
      await chat.enviarFoto(id);
      expect(chat.conversaciones.single.mensajes, isEmpty);
      chat.dispose();
    },
  );

  test('datos corruptos no se sobrescriben al fallar la carga', () async {
    final preferencias = PreferenciasPrueba()..datos[PersistirChat.clave] = '{';
    final chat = GestionarChat(
      almacen: PersistirChat(preferencias: preferencias),
    );
    await chat.cargar();
    expect(chat.cargado, isFalse);
    expect(chat.error, isNotNull);
    expect(await chat.crear('Ana'), isNull);
    expect(preferencias.datos[PersistirChat.clave], '{');
    chat.dispose();
  });

  testWidgets('crea una conversación y envía texto desde la interfaz', (
    tester,
  ) async {
    final chat = GestionarChat(
      almacen: PersistirChat(preferencias: PreferenciasPrueba()),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: AppChat(controlador: chat)),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Conversación'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'Ana');
    await tester.pump();
    await tester.tap(find.text('Crear'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Hola Ana');
    await tester.tap(find.byTooltip('Enviar mensaje'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(SelectableText, 'Hola Ana'), findsOneWidget);
    expect(chat.conversaciones.single.mensajes.single.texto, 'Hola Ana');
    await tester.pumpWidget(const SizedBox());
    chat.dispose();
  });

  testWidgets(
    'la entrada abre el shell y Chat se compone mediante su MicroApp',
    (tester) async {
      final autenticacion = AutenticacionFalsa();
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
      expect(find.byType(ChampShell), findsOneWidget);
      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.descendant(
          of: find.byKey(const Key('navegacion_modulos')),
          matching: find.widgetWithText(ListTile, 'Chat'),
        ),
        100,
        scrollable: find.descendant(
          of: find.byKey(const Key('navegacion_modulos')),
          matching: find.byType(Scrollable),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byKey(const Key('navegacion_modulos')),
          matching: find.widgetWithText(ListTile, 'Chat'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(AppChat), findsOneWidget);
      expect(
        find.ancestor(
          of: find.byType(AppChat),
          matching: find.byType(AppComunidadCanina),
        ),
        findsOneWidget,
      );
    },
  );
}
