// Capturas de widgets reales con fotos del catalogo demo, sin datos de usuarios.
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:champ/core/modelos/aviso_perro.dart';
import 'package:champ/nanoapps/perdidos_encontrados/app_perdidos_encontrados.dart';
import 'package:champ/nanoapps/perdidos_encontrados/nanofunciones/gestionar_avisos/gestionar_avisos.dart';
import 'package:champ/nanoapps/perdidos_encontrados/nanofunciones/gestionar_avisos/nanoactividades/seleccionar_foto/seleccionar_foto.dart';
import 'package:champ/nanoapps/perdidos_encontrados/vistas/detalle_aviso.dart';
import 'package:champ/nanoapps/perdidos_encontrados/vistas/formulario_aviso.dart';

import '../test/avisos_perros_test.dart' show AvisosPrueba;

void main() {
  testWidgets('Capturas de Perdidos y encontrados con datos de prueba', (
    tester,
  ) async {
    final salida = Platform.environment['CHAMP_CAPTURAS']!;
    final fuente = Platform.environment['CHAMP_FUENTE']!;
    String? foto;
    await tester.runAsync(() async {
      for (final entry in {
        'Roboto': fuente,
        'MaterialIcons':
            '${File(fuente).parent.path}/MaterialIcons-Regular.otf',
      }.entries) {
        final bytes = await File(entry.value).readAsBytes();
        await (FontLoader(
          entry.key,
        )..addFont(Future.value(ByteData.sublistView(bytes)))).load();
      }
      foto = base64Encode(
        await SeleccionarFotoAviso.comprimir(
          await File('assets/catalogo/demo-luna.jpg').readAsBytes(),
        ),
      );
      await Directory(salida).create(recursive: true);
    });
    final repo = AvisosPrueba(uid: 'visitante');
    repo.registros['aviso'] = AvisoPerro(
      id: 'aviso',
      autorUid: 'autora',
      autorNombre: 'Ana',
      datos: DatosAvisoPerro(
        tipo: TipoAvisoPerro.perdido,
        nombre: 'Toby',
        raza: 'Mestizo',
        zona: 'Santiago',
        lugar: 'Parque del barrio',
        descripcion: 'Se perdió cerca de la entrada del parque. Lleva collar azul y responde a su nombre.',
        fechaVista: DateTime(2026, 10, 31, 18, 30),
        chip: 'si',
        chipUltimos: '1234',
        fotoBase64: foto!,
      ),
    );
    final g = GestionarAvisos(repo);
    tester.view.physicalSize = const Size(1100, 1050);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    for (final entry in <String, Widget>{
      '05-avisos': Scaffold(
        appBar: AppBar(title: const Text('Champ · Perdidos y encontrados')),
        body: AppPerdidosEncontrados(
          controlador: g,
          onContactar: (_) async => false,
        ),
      ),
      '06-publicar-aviso': FormularioAviso(
        controlador: g,
        aviso: repo.registros['aviso'],
      ),
      '07-detalle-aviso': DetalleAviso(
        controlador: g,
        avisoId: 'aviso',
        onContactar: (_) async => false,
      ),
    }.entries) {
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
            home: entry.value,
          ),
        ),
      );
      await tester.pumpAndSettle();
      // Image codecs complete outside the fake widget-test clock.
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 250)),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final boundary =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      await tester.runAsync(() async {
        final image = await boundary.toImage();
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        await File('$salida/${entry.key}.png')
            .writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
      });
      await tester.pumpWidget(const SizedBox());
    }
    g.dispose();
    await repo.cambios.close();
  });
}
