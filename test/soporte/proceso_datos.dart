import 'dart:convert';
import 'dart:io';

import 'package:champ/core/modelos/cruces.dart';
import 'package:champ/core/persistencia/base_local.dart';
import 'package:champ/core/persistencia/sqlite_local.dart';
import 'package:champ/core/repositorios/fotos_locales.dart';
import 'package:path/path.dart' as p;

Future<void> main(List<String> argumentos) async {
  if (argumentos.length != 2 || !['escribir', 'leer'].contains(argumentos[0])) {
    throw ArgumentError('Uso: proceso_datos.dart <escribir|leer> <carpeta>');
  }
  final carpeta = Directory(argumentos[1]);
  final ruta = carpeta.resolveSymbolicLinksSync();
  if (!p.isWithin(Directory.systemTemp.resolveSymbolicLinksSync(), ruta) ||
      !p.basename(ruta).startsWith('champ-prueba-')) {
    throw ArgumentError('La prueba necesita su propia carpeta temporal.');
  }
  // SqliteLocal configura libsqlite3.so.0 en Linux en cada proceso nuevo.
  final base = BaseLocal(SqliteLocal(directorio: carpeta));
  final fotos = FotosLocales(base);
  try {
    if (argumentos[0] == 'escribir') {
      final perro = PerfilPerro(
        id: 'toby-proceso',
        nombre: 'Toby',
        raza: 'Golden retriever',
        sexo: 'Macho',
        edadMeses: 36,
        ciudad: 'Santiago',
        responsable: 'Rolo',
        descripcion: 'Ficha conservada entre procesos',
        foto: base64Decode(
          'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+jCr0AAAAASUVORK5CYII=',
        ),
      );
      final ficha = await fotos.aDisco(perro.toJson());
      await base.guardar('perfiles', perro.id, ficha);
      await base.registrarLike('toby-proceso', 'luna-proceso', 'gusta');
      final sinReciprocidad = await base.matches('toby-proceso');
      await base.registrarLike('luna-proceso', 'toby-proceso', 'gusta');
      stdout.write(
        jsonEncode({
          'fotoReferencia': ficha['fotoReferencia'],
          'matchesSinReciprocidad': sinReciprocidad,
          'matches': await base.matches('toby-proceso'),
        }),
      );
    } else {
      final ficha = await base.obtener('perfiles', 'toby-proceso');
      if (ficha == null) throw StateError('No se recuperó la ficha en disco.');
      final perro = PerfilPerro.fromJson(await fotos.desdeDisco(ficha));
      final likes = await base.likes(perro.id);
      final reciprocos = await base.likes('luna-proceso');
      final antes = await base.matches(perro.id);
      // Repetir ambos sentidos tras reiniciar debe conservar la misma fila.
      for (var i = 0; i < 2; i++) {
        await base.registrarLike('luna-proceso', perro.id, 'gusta');
        await base.registrarLike(perro.id, 'luna-proceso', 'gusta');
      }
      stdout.write(
        jsonEncode({
          'ficha': perro.toJson(),
          'fichaDisco': ficha,
          'likes': likes,
          'likesReciprocos': reciprocos,
          'matchesAntes': antes,
          'matchesDespues': await base.matches(perro.id),
          'estado': await base.estado(),
        }),
      );
    }
  } finally {
    await base.cerrar();
  }
}
