import 'dart:async';

import 'package:champ/core/modelos/chat.dart';
import 'package:champ/core/repositorios/chat_firestore.dart';
import 'package:champ/core/repositorios/chat_usuarios.dart';
import 'package:champ/core/repositorios/legado/preferencias_chat.dart';
import 'package:champ/nanoapps/chat/app_chat.dart';
import 'package:champ/nanoapps/chat/nanofunciones/gestionar_chat/gestionar_chat.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'soporte/preferencias_prueba.dart';

class _Servidor {
  final cambios = StreamController<void>.broadcast(sync: true);
  final chats = <Conversacion>[];
  final mensajes = <Mensaje>[];
  bool fallar = false;
}

class _Canal implements CanalChatUsuarios {
  _Canal(this.uid, this.servidor);
  @override
  final String uid;
  final _Servidor servidor;
  int escuchas = 0;
  @override
  Stream<List<Conversacion>> conversaciones() async* {
    yield servidor.chats.where((c) => c.participantes.contains(uid)).toList();
    await for (final _ in servidor.cambios.stream) {
      yield servidor.chats.where((c) => c.participantes.contains(uid)).toList();
    }
  }

  @override
  Stream<List<Mensaje>> mensajes(String id) {
    late StreamController<List<Mensaje>> salida;
    StreamSubscription<void>? sub;
    salida = StreamController<List<Mensaje>>(
      onListen: () {
        escuchas++;
        salida.add(List.of(servidor.mensajes));
        sub = servidor.cambios.stream.listen((_) {
          salida.add(List.of(servidor.mensajes));
        });
      },
      onCancel: () async {
        escuchas--;
        await sub?.cancel();
      },
    );
    return salida.stream;
  }

  @override
  Future<Conversacion> abrir(String otro) async {
    if (otro == uid) throw StateError('Elige otra cuenta.');
    final id = RepositorioChatFirestore.identidad(uid, otro);
    var c = servidor.chats.where((c) => c.id == id).firstOrNull;
    if (c == null) {
      c = Conversacion(
        id: id,
        nombre: otro,
        fecha: DateTime.now(),
        participantes: [uid, otro],
      );
      servidor.chats.add(c);
    }
    servidor.cambios.add(null);
    return c;
  }

  @override
  Future<void> enviar(String id, String texto) async {
    if (servidor.fallar) throw StateError('Sin conexión');
    servidor.mensajes.add(
      Mensaje(
        id: '${servidor.mensajes.length}',
        fecha: DateTime.now(),
        texto: texto.trim(),
        remitenteId: uid,
      ),
    );
    servidor.cambios.add(null);
  }
}

GestionarChat _controlador(_Canal canal) => GestionarChat(
  almacen: PersistirChat(preferencias: PreferenciasPrueba()),
  canal: canal,
);

void main() {
  test('la identidad de una conversación no depende del orden de usuarios', () {
    expect(
      RepositorioChatFirestore.identidad('ana', 'pedro'),
      RepositorioChatFirestore.identidad('pedro', 'ana'),
    );
    expect(
      RepositorioChatFirestore.identidad('a_b', 'c'),
      isNot(RepositorioChatFirestore.identidad('a', 'b_c')),
    );
  });

  test(
    'dos cuentas reciben mensajes, un tercero no ve el chat y dispose cancela',
    () async {
      final servidor = _Servidor();
      final canalAna = _Canal('ana', servidor);
      final ana = _controlador(canalAna);
      final pedro = _controlador(_Canal('pedro', servidor));
      final tercero = _controlador(_Canal('otro', servidor));
      await Future.wait([ana.cargar(), pedro.cargar(), tercero.cargar()]);
      final id = (await ana.crear('pedro'))!;
      await Future<void>.delayed(Duration.zero);
      expect(await pedro.crear('ana'), id);
      expect(tercero.conversaciones, isEmpty);
      ana.seleccionar(id);
      pedro.seleccionar(id);
      await Future<void>.delayed(Duration.zero);
      expect(await ana.enviarTexto(id, 'Hola Pedro'), isTrue);
      await Future<void>.delayed(Duration.zero);
      expect(pedro.conversaciones.single.mensajes.single.remitenteId, 'ana');
      expect(await pedro.enviarTexto(id, 'Hola Ana'), isTrue);
      await Future<void>.delayed(Duration.zero);
      expect(ana.conversaciones.single.mensajes.last.remitenteId, 'pedro');
      expect(servidor.chats, hasLength(1));
      ana.dispose();
      pedro.dispose();
      tercero.dispose();
      await Future<void>.delayed(Duration.zero);
      expect(canalAna.escuchas, 0);
      await servidor.cambios.close();
    },
  );

  testWidgets(
    'envío fallido conserva borrador y la interfaz permite reintentar',
    (tester) async {
      final servidor = _Servidor();
      final chat = _controlador(_Canal('ana', servidor));
      await chat.cargar();
      await chat.crear('pedro');
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: AppChat(controlador: chat)),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('pedro'));
      await tester.pumpAndSettle();
      expect(find.byTooltip('Enviar foto (hasta 1 MB)'), findsNothing);
      await tester.enterText(find.byType(TextField), 'Hola');
      servidor.fallar = true;
      await tester.tap(find.byTooltip('Enviar mensaje'));
      await tester.pumpAndSettle();
      expect(find.text('Sin conexión'), findsOneWidget);
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        'Hola',
      );
      servidor.fallar = false;
      await tester.tap(find.byTooltip('Enviar mensaje'));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(SelectableText, 'Hola'), findsOneWidget);
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        isEmpty,
      );
      await tester.pumpWidget(const SizedBox());
      chat.dispose();
      await servidor.cambios.close();
    },
  );
}
