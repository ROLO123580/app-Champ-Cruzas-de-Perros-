import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:champ/core/modelos/chat.dart';
import 'package:champ/core/modelos/cruces.dart';
import 'package:champ/core/persistencia/base_local.dart';
import 'package:champ/core/persistencia/http_local.dart';
import 'package:champ/core/persistencia/sqlite_local.dart';
import 'package:champ/core/repositorios/legado/preferencias_chat.dart';
import 'package:champ/core/repositorios/legado/preferencias_cruces.dart';
import 'package:champ/core/servicios/servicios_champ.dart';
import 'package:champ/microapps/datos_locales/api/servidor_local.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart';

import 'soporte/base_prueba.dart';
import 'soporte/preferencias_prueba.dart';

PerfilPerro perroConFoto() => PerfilPerro(
  id: 'toby',
  nombre: 'Toby',
  raza: 'Golden retriever',
  sexo: 'Macho',
  edadMeses: 36,
  ciudad: 'Santiago',
  responsable: 'Rolo',
  descripcion: 'Juguetón',
  foto: Uint8List.fromList([1, 2, 3, 4]),
);

void main() {
  configurarSqlite();
  test('un origen sin preferencias no bloquea importarlas después ni sustituye datos nuevos', () async {
    final carpeta = await carpetaPrueba();
    final prefs = PreferenciasPrueba();
    final servicios = ServiciosChamp(
      base: BaseLocal(SqliteLocal(directorio: carpeta)),
      leerLegado: prefs.getString,
      cargarFotoSemilla: (_) async => null,
    );
    addTearDown(servicios.cerrar);
    await servicios.cruces.cargar();
    await servicios.chat.cargar();
    expect(
      await servicios.base.obtener('meta', 'preferencias_cruces_v1'),
      isNull,
    );
    expect(
      await servicios.base.obtener('meta', 'preferencias_chat_v1'),
      isNull,
    );
    await servicios.cruces.guardar(EstadoCruces(miPerro: perroConFoto()));
    await servicios.chat.guardar([
      Conversacion(
        id: 'c',
        nombre: 'Nuevo',
        fecha: DateTime(2026),
        mensajes: [Mensaje(id: 'nuevo', fecha: DateTime(2026), texto: 'Nuevo')],
      ),
    ]);
    await PersistirCruces(preferencias: prefs).guardar(
      EstadoCruces(
        miPerro: const PerfilPerro(
          id: 'otro',
          nombre: 'Otra ficha',
          raza: 'Labrador',
          sexo: 'Hembra',
          edadMeses: 30,
          ciudad: 'Santiago',
          responsable: 'Ana',
          descripcion: '',
        ),
      ),
    );
    await PersistirChat(preferencias: prefs).guardar([
      Conversacion(
        id: 'c',
        nombre: 'Anterior',
        fecha: DateTime(2025),
        mensajes: [
          Mensaje(id: 'antiguo', fecha: DateTime(2025), texto: 'Anterior'),
        ],
      ),
    ]);
    expect((await servicios.cruces.cargar()).miPerro!.id, 'toby');
    expect(
      (await servicios.base.obtener('perfiles', 'otro'))!['nombre'],
      'Otra ficha',
    );
    final chat = (await servicios.chat.cargar()).single;
    expect(chat.nombre, 'Nuevo');
    expect(chat.mensajes, hasLength(2));
  });
  test(
    'fotos demo se copian una vez al disco y se recuperan sin fuentes externas',
    () async {
      final carpeta = await carpetaPrueba();
      var servicios = ServiciosChamp(
        base: BaseLocal(SqliteLocal(directorio: carpeta)),
        leerLegado: (_) async => null,
        cargarFotoSemilla: (id) async => Uint8List.fromList(utf8.encode(id)),
      );
      final perfiles = await servicios.cruces.cargarPerfiles();
      expect(perfiles.first.foto, orderedEquals(utf8.encode('demo-luna')));
      expect(perfiles.first.imagenUrl, isNull);
      expect((await servicios.base.estado())['fotos'], 4);
      await servicios.cerrar();
      servicios = ServiciosChamp(
        base: BaseLocal(SqliteLocal(directorio: carpeta)),
        leerLegado: (_) async => null,
        cargarFotoSemilla: (_) async =>
            throw StateError('No debe volver a cargar las semillas'),
      );
      addTearDown(servicios.cerrar);
      expect(
        (await servicios.cruces.cargarPerfiles()).first.foto,
        orderedEquals(utf8.encode('demo-luna')),
      );
    },
  );

  test(
    'migra v2 → v3 sin perder el match existente y permite repetir likes',
    () async {
      final carpeta = await carpetaPrueba();
      final inicial = BaseLocal(SqliteLocal(directorio: carpeta));
      await inicial.registrarLike('a', 'b', 'gusta');
      await inicial.registrarLike('b', 'a', 'gusta');
      await inicial.cerrar();
      final antigua = sqlite3.open(p.join(carpeta.path, 'champ.db'));
      antigua.execute('DROP TRIGGER match_tras_update');
      antigua.execute(
        '''CREATE TRIGGER match_tras_update AFTER UPDATE ON likes
      WHEN NEW.decision='gusta' BEGIN
      INSERT OR IGNORE INTO matches(perro_a,perro_b)
      SELECT MIN(NEW.origen,NEW.destino), MAX(NEW.origen,NEW.destino)
      WHERE EXISTS(SELECT 1 FROM likes WHERE origen=NEW.destino AND destino=NEW.origen AND decision='gusta'); END''',
      );
      antigua.execute('PRAGMA user_version=2');
      antigua.dispose();
      final base = BaseLocal(SqliteLocal(directorio: carpeta));
      addTearDown(base.cerrar);
      await base.registrarLike('a', 'b', 'gusta');
      expect((await base.estado())['version'], 3);
      expect(await base.matches('a'), hasLength(1));
    },
  );

  test(
    'rechaza referencias inexistentes y no publica respaldos con fotos dañadas',
    () async {
      final carpeta = await carpetaPrueba();
      final base = BaseLocal(SqliteLocal(directorio: carpeta));
      addTearDown(base.cerrar);
      await expectLater(
        base.guardar('perfiles', 'p', {
          'id': 'p',
          'fotoReferencia': 'no-existe',
        }),
        throwsFormatException,
      );
      expect(await base.obtener('perfiles', 'p'), isNull);
      final ref = await base.guardarImagen(Uint8List.fromList([7, 6, 5]));
      File(p.join(carpeta.path, 'imagenes', '$ref.img')).writeAsBytesSync([0]);
      await expectLater(base.respaldar(), throwsStateError);
      final copias = Directory(p.join(carpeta.path, 'respaldos')).listSync();
      expect(
        copias.every((c) => p.basename(c.path).endsWith('.incompleto')),
        isTrue,
      );
    },
  );
  test(
    'cierra y reabre SQLite: recupera ficha, fotos, likes, matches y chat',
    () async {
      final carpeta = await carpetaPrueba();
      ServiciosChamp abrir() => ServiciosChamp(
        base: BaseLocal(SqliteLocal(directorio: carpeta)),
        leerLegado: (_) async => null,
        cargarFotoSemilla: (_) async => null,
      );
      var servicios = abrir();
      await servicios.cruces.cargar();
      await servicios.cruces.guardar(EstadoCruces(miPerro: perroConFoto()));
      final perfiles = await servicios.cruces.cargarPerfiles();
      final luna = perfiles.firstWhere((p) => p.id == 'demo-luna');
      final estado = await servicios.cruces.decidir(
        await servicios.cruces.cargar(),
        luna,
        DecisionCruce.gusta,
      );
      expect(estado.matches, {'demo-luna'});
      final foto = Uint8List.fromList([5, 6, 7]);
      await servicios.chat.guardar([
        Conversacion(
          id: 'cruce:toby:demo-luna',
          nombre: 'Camila · Luna',
          fecha: DateTime(2026),
          mensajes: [
            Mensaje(
              id: 'mensaje-1',
              fecha: DateTime(2026),
              texto: 'Hola',
              foto: foto,
            ),
          ],
        ),
      ]);
      final fichaEnDisco = await servicios.base.obtener('perfiles', 'toby');
      expect(fichaEnDisco!['foto'], isNull);
      expect(fichaEnDisco['fotoReferencia'], matches(r'^[a-f0-9]{64}$'));
      expect(
        File(
          p.join(
            carpeta.path,
            'imagenes',
            '${fichaEnDisco['fotoReferencia']}.img',
          ),
        ).existsSync(),
        isTrue,
      );
      await servicios.cerrar();
      servicios = abrir();
      addTearDown(servicios.cerrar);
      final recuperado = await servicios.cruces.cargar();
      expect(recuperado.miPerro!.foto, orderedEquals([1, 2, 3, 4]));
      expect(recuperado.decisiones['demo-luna'], DecisionCruce.gusta);
      expect(recuperado.matches, {'demo-luna'});
      final chat = (await servicios.chat.cargar()).single;
      expect(chat.mensajes.single.texto, 'Hola');
      expect(chat.mensajes.single.foto, orderedEquals(foto));
      expect(await servicios.base.listar('razas'), isNotEmpty);
      expect(await servicios.base.listar('catalogos'), isNotEmpty);
    },
  );

  test('likes recíprocos repetidos, invertidos y en dos conexiones producen un match', () async {
    final carpeta = await carpetaPrueba();
    final a = BaseLocal(SqliteLocal(directorio: carpeta));
    final b = BaseLocal(SqliteLocal(directorio: carpeta));
    addTearDown(a.cerrar);
    addTearDown(b.cerrar);
    await a.registrarLike('a', 'b', 'gusta');
    expect(await a.matches('a'), isEmpty);
    await b.registrarLike('b', 'a', 'gusta');
    await Future.wait([
      a.registrarLike('a', 'b', 'gusta'),
      b.registrarLike('b', 'a', 'gusta'),
    ]);
    expect(await a.matches('a'), hasLength(1));
    expect(await b.matches('b'), hasLength(1));
  });

  test(
    'CRUD y transacciones: un lote inválido revierte todos sus cambios',
    () async {
      final servicios = await serviciosPrueba();
      final base = servicios.base;
      await base.guardar('razas', 'x', {'id': 'x', 'nombre': 'Anterior'});
      await expectLater(
        base.aplicar([
          {
            'tipo': 'guardar',
            'coleccion': 'razas',
            'id': 'x',
            'datos': {'id': 'x', 'nombre': 'Nuevo'},
          },
          {
            'tipo': 'like',
            'origen': 'a',
            'destino': 'b',
            'decision': 'invalida',
          },
        ]),
        throwsA(isA<SqliteException>()),
      );
      expect((await base.obtener('razas', 'x'))!['nombre'], 'Anterior');
      await base.guardar('razas', 'x', {'id': 'x', 'nombre': 'Actualizado'});
      expect((await base.obtener('razas', 'x'))!['nombre'], 'Actualizado');
      await base.eliminar('razas', 'x');
      expect(await base.obtener('razas', 'x'), isNull);
    },
  );

  test('respaldo consistente con WAL, manifest e imágenes permite reabrir la instantánea', () async {
    final servicios = await serviciosPrueba();
    final base = servicios.base;
    final ref = await base.guardarImagen(Uint8List.fromList([9, 8, 7]));
    await base.guardar('perfiles', 'p', {
      'id': 'p',
      'fotoReferencia': ref,
      'nombre': 'Antes',
    });
    final ruta = await base.respaldar();
    await base.guardar('perfiles', 'p', {
      'id': 'p',
      'fotoReferencia': ref,
      'nombre': 'Después',
    });
    final manifest = jsonDecode(
      File(p.join(ruta, 'manifest.json')).readAsStringSync(),
    ) as Map<String, dynamic>;
    for (final e in (manifest['sha256'] as Map<String, dynamic>).entries) {
      expect(
        sha256.convert(File(p.join(ruta, e.key)).readAsBytesSync()).toString(),
        e.value,
      );
    }
    final restaurada = BaseLocal(SqliteLocal(directorio: Directory(ruta)));
    addTearDown(restaurada.cerrar);
    expect((await restaurada.obtener('perfiles', 'p'))!['nombre'], 'Antes');
    expect(await restaurada.leerImagen(ref), orderedEquals([9, 8, 7]));
  });

  test(
    'migración v1 → v3 conserva documentos y fotos y crea respaldo previo',
    () async {
      final carpeta = await carpetaPrueba();
      final bytes = Uint8List.fromList([4, 3, 2]);
      final ref = sha256.convert(bytes).toString();
      Directory(p.join(carpeta.path, 'imagenes')).createSync();
      File(p.join(carpeta.path, 'imagenes', '$ref.img'))
          .writeAsBytesSync(bytes);
      final antigua = sqlite3.open(p.join(carpeta.path, 'champ.db'));
      antigua.execute(
        'CREATE TABLE documentos(coleccion TEXT,id TEXT,datos TEXT,PRIMARY KEY(coleccion,id))',
      );
      antigua.execute(
        'CREATE TABLE imagenes(referencia TEXT PRIMARY KEY,ruta TEXT UNIQUE,tamano INTEGER)',
      );
      antigua.execute('INSERT INTO documentos VALUES(?,?,?)', [
        'perfiles',
        'p',
        jsonEncode({'id': 'p', 'fotoReferencia': ref}),
      ]);
      antigua.execute('INSERT INTO imagenes VALUES(?,?,?)', [
        ref,
        'imagenes/$ref.img',
        bytes.length,
      ]);
      antigua.execute('PRAGMA user_version=1');
      antigua.dispose();
      final base = BaseLocal(SqliteLocal(directorio: carpeta));
      addTearDown(base.cerrar);
      expect((await base.estado())['version'], 3);
      expect((await base.obtener('perfiles', 'p'))!['fotoReferencia'], ref);
      expect(await base.leerImagen(ref), orderedEquals(bytes));
      expect(
        Directory(p.join(carpeta.path, 'respaldos'))
            .listSync()
            .whereType<Directory>(),
        hasLength(1),
      );
    },
  );

  test('importa preferencias antiguas una sola vez sin borrar el origen ni duplicar matches', () async {
    final prefs = PreferenciasPrueba();
    await PersistirCruces(preferencias: prefs).guardar(
      EstadoCruces(
        miPerro: perroConFoto(),
        decisiones: {'demo-luna': DecisionCruce.gusta},
        matches: {'demo-luna'},
      ),
    );
    await PersistirChat(preferencias: prefs).guardar([
      Conversacion(
        id: 'anterior',
        nombre: 'Anterior',
        fecha: DateTime(2026),
        mensajes: [
          Mensaje(
            id: 'm',
            fecha: DateTime(2026),
            foto: Uint8List.fromList([8, 8]),
          ),
        ],
      ),
    ]);
    final carpeta = await carpetaPrueba();
    final servicios = ServiciosChamp(
      base: BaseLocal(SqliteLocal(directorio: carpeta)),
      leerLegado: prefs.getString,
      cargarFotoSemilla: (_) async => null,
    );
    addTearDown(servicios.cerrar);
    expect((await servicios.cruces.cargar()).miPerro!.nombre, 'Toby');
    expect(
      (await servicios.chat.cargar()).single.mensajes.single.foto,
      orderedEquals([8, 8]),
    );
    prefs.datos[PersistirCruces.clave] = '{';
    expect((await servicios.cruces.cargar()).matches, {'demo-luna'});
    expect(await servicios.base.matches('toby'), hasLength(1));
    expect(prefs.datos.containsKey(PersistirChat.clave), isTrue);
  });

  test('API real reinicia: el cliente HTTP conserva registros, fotos y matches en disco', () async {
    final carpeta = await carpetaPrueba();
    var servidor = ServidorLocal(BaseLocal(SqliteLocal(directorio: carpeta)));
    await servidor.iniciar(puerto: 0);
    var cliente = BaseLocal(
      HttpLocal(url: 'http://127.0.0.1:${servidor.puerto}'),
    );
    await cliente.guardar('perfiles', 'api', {
      'id': 'api',
      'nombre': 'Desde Chrome',
    });
    final ref = await cliente.guardarImagen(Uint8List.fromList([3, 3, 3]));
    await cliente.registrarLike('a', 'b', 'gusta');
    await cliente.registrarLike('b', 'a', 'gusta');
    final origenNoLocal = await http.post(
      Uri.parse('http://127.0.0.1:${servidor.puerto}/v1/comando'),
      headers: {
        'Origin': 'https://sitio-externo.example',
        'Content-Type': 'application/json',
      },
      body: '{}',
    );
    expect(origenNoLocal.statusCode, 403);
    await cliente.cerrar();
    await servidor.cerrar();
    servidor = ServidorLocal(BaseLocal(SqliteLocal(directorio: carpeta)));
    await servidor.iniciar(puerto: 0);
    addTearDown(servidor.cerrar);
    cliente = BaseLocal(HttpLocal(url: 'http://127.0.0.1:${servidor.puerto}'));
    addTearDown(cliente.cerrar);
    expect(
      (await cliente.obtener('perfiles', 'api'))!['nombre'],
      'Desde Chrome',
    );
    expect(await cliente.leerImagen(ref), orderedEquals([3, 3, 3]));
    expect(await cliente.matches('a'), hasLength(1));
  });
}
