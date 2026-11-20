import 'dart:io';

import 'package:champ/core/persistencia/base_local.dart';
import 'package:champ/core/persistencia/sqlite_local.dart';
import 'package:champ/core/servicios/servicios_champ.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

Future<Directory> carpetaPrueba() async {
  final carpeta = Directory.systemTemp.createTempSync('champ-prueba-');
  addTearDown(() {
    final ruta = carpeta.resolveSymbolicLinksSync();
    final temporal = Directory.systemTemp.resolveSymbolicLinksSync();
    if (!p.isWithin(temporal, ruta) ||
        !p.basename(ruta).startsWith('champ-prueba-')) {
      throw StateError('Carpeta de prueba fuera del destino autorizado.');
    }
    carpeta.deleteSync(recursive: true);
  });
  return carpeta;
}

Future<ServiciosChamp> serviciosPrueba() async {
  final carpeta = await carpetaPrueba();
  final servicios = ServiciosChamp(
    base: BaseLocal(SqliteLocal(directorio: carpeta)),
    leerLegado: (_) async => null,
    cargarFotoSemilla: (_) async => null,
    sembrarPlanesReferencia: false,
  );
  addTearDown(servicios.cerrar);
  return servicios;
}
