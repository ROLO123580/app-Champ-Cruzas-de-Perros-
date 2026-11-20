// Capturas de las pantallas reales con datos de prueba, sin Firebase/productivo.
// CHAMP_CAPTURAS y CHAMP_FUENTE indican la carpeta de salida y un TTF local.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:champ/core/modelos/comunidad.dart';
import 'package:champ/nanoapps/comunidad/app_comunidad.dart';
import 'package:champ/nanoapps/comunidad/nanofunciones/gestionar_comunidad/gestionar_comunidad.dart';
import 'package:champ/nanoapps/chat_eventos/app_chat_eventos.dart';
import 'package:champ/nanoapps/eventos/app_eventos.dart';
import 'package:champ/nanoapps/eventos/vistas/formulario_evento.dart';

import '../test/comunidad_test.dart' show ComunidadPrueba;

void main() {
  testWidgets('Capturas de comunidad con datos identificados de prueba', (
    tester,
  ) async {
    final salida = Platform.environment['CHAMP_CAPTURAS'];
    final fuente = Platform.environment['CHAMP_FUENTE'];
    expect(salida, isNotNull);
    expect(fuente, isNotNull);
    await tester.runAsync(() async {
      final bytes = await File(fuente!).readAsBytes();
      await (FontLoader(
        'Roboto',
      )..addFont(Future.value(ByteData.sublistView(bytes)))).load();
      final iconos = await File(
        '${File(fuente).parent.path}/MaterialIcons-Regular.otf',
      ).readAsBytes();
      await (FontLoader(
        'MaterialIcons',
      )..addFont(Future.value(ByteData.sublistView(iconos)))).load();
      await Directory(salida!).create(recursive: true);
    });
    tester.view.physicalSize = const Size(1100, 940);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repo = ComunidadPrueba();
    final gestion = GestionarComunidad(repo);
    await repo.participar('parque', true);
    repo.historial.add(
      MensajeEvento(
        id: 'uno',
        uid: 'organizador',
        nombre: 'Ana',
        texto: '¡Hola! Nos encontramos junto a la entrada del parque. ¿Quién trae agua para los perros?',
        fecha: DateTime.now(),
      ),
    );
    repo.historial.add(
      MensajeEvento(
        id: 'dos',
        uid: repo.uid,
        nombre: 'Jaime',
        texto: 'Yo llevo agua. ¡Nos vemos allá!',
        fecha: DateTime.now(),
      ),
    );
    final pantallas = <String, Widget>{
      '01-muro': Scaffold(
        appBar: AppBar(title: const Text('Champ · Comunidad')),
        body: AppComunidad(controlador: gestion),
      ),
      '02-crear-evento': FormularioEvento(controlador: gestion.eventosGestion),
      '03-detalle-evento': AppEventos(
        controlador: gestion.eventosGestion,
        controladorChat: gestion.chatGestion,
        eventoId: 'parque',
      ),
      '04-chat-evento': AppChatEventos(
        controlador: gestion.chatGestion,
        eventoId: 'parque',
      ),
    };
    for (final entrada in pantallas.entries) {
      final key = GlobalKey();
      await tester.pumpWidget(
        RepaintBoundary(
          key: key,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              useMaterial3: true,
              fontFamily: 'Roboto',
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFF25856A),
              ),
            ),
            home: entrada.value,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final boundary =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      await tester.runAsync(() async {
        final image = await boundary.toImage();
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        await File('$salida/${entrada.key}.png')
            .writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
      });
      await tester.pumpWidget(const SizedBox());
    }
    gestion.dispose();
    await repo.cambios.close();
  });
}
