import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import 'soporte/base_prueba.dart';

const _foto =
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+jCr0AAAAASUVORK5CYII=';

String _ejecutableDart() {
  final actual = Platform.resolvedExecutable;
  if (p.basenameWithoutExtension(actual) == 'dart') return actual;
  // flutter test usa flutter_tester, situado en cache/artifacts/engine/<os>.
  final cache = Directory(p.dirname(actual)).parent.parent.parent;
  final dart = p.join(
    cache.path,
    'dart-sdk',
    'bin',
    Platform.isWindows ? 'dart.exe' : 'dart',
  );
  if (!File(dart).existsSync()) {
    throw StateError('No se encontró el ejecutable Dart del SDK Flutter.');
  }
  return dart;
}

Future<Map<String, dynamic>> _ejecutarProceso(
  String modo,
  Directory carpeta,
) async {
  final proceso = await Process.start(_ejecutableDart(), [
    '--packages=${p.absolute('.dart_tool', 'package_config.json')}',
    p.absolute('test', 'soporte', 'proceso_datos.dart'),
    modo,
    carpeta.absolute.path,
  ]);
  final salida = proceso.stdout.transform(utf8.decoder).join();
  final errores = proceso.stderr.transform(utf8.decoder).join();
  try {
    final codigo = await proceso.exitCode.timeout(const Duration(seconds: 30));
    final resultados = await Future.wait([salida, errores]);
    expect(codigo, 0, reason: 'Proceso $modo: ${resultados[1]}');
    expect(proceso.pid, isNot(pid));
    return jsonDecode(resultados[0]) as Map<String, dynamic>;
  } finally {
    proceso.kill();
    await proceso.exitCode;
  }
}

void main() {
  test(
    'dos procesos Dart recuperan ficha, foto y likes sin duplicar el match',
    () async {
      final carpeta = await carpetaPrueba();
      // El primer proceso termina antes de iniciar el segundo: no comparten
      // conexiones SQLite, cachés ni objetos de persistencia en memoria.
      final escritura = await _ejecutarProceso('escribir', carpeta);
      expect(escritura['matchesSinReciprocidad'], isEmpty);
      expect(escritura['matches'], hasLength(1));
      expect(File(p.join(carpeta.path, 'champ.db')).existsSync(), isTrue);
      final referencia = escritura['fotoReferencia'] as String;
      final archivoFoto = File(
        p.join(carpeta.path, 'imagenes', '$referencia.img'),
      );
      expect(
        await archivoFoto.readAsBytes(),
        orderedEquals(base64Decode(_foto)),
      );

      final lectura = await _ejecutarProceso('leer', carpeta);
      expect(lectura['ficha'], {
        'id': 'toby-proceso',
        'nombre': 'Toby',
        'raza': 'Golden retriever',
        'sexo': 'Macho',
        'edadMeses': 36,
        'ciudad': 'Santiago',
        'responsable': 'Rolo',
        'descripcion': 'Ficha conservada entre procesos',
        'foto': _foto,
        'imagenUrl': null,
        'interesDemo': false,
      });
      final fichaDisco = lectura['fichaDisco'] as Map<String, dynamic>;
      expect(fichaDisco.containsKey('foto'), isFalse);
      expect(fichaDisco['fotoReferencia'], referencia);
      expect(lectura['likes'], [
        {
          'origen': 'toby-proceso',
          'destino': 'luna-proceso',
          'decision': 'gusta',
        },
      ]);
      expect(lectura['likesReciprocos'], [
        {
          'origen': 'luna-proceso',
          'destino': 'toby-proceso',
          'decision': 'gusta',
        },
      ]);
      expect(lectura['matchesAntes'], escritura['matches']);
      expect(lectura['matchesDespues'], lectura['matchesAntes']);
      expect((lectura['estado'] as Map<String, dynamic>)['matches'], 1);
    },
    timeout: const Timeout(Duration(seconds: 90)),
  );
}
