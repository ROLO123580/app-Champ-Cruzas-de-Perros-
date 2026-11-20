import 'dart:convert';
import 'dart:io';
import 'dart:ffi';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart';
import 'package:sqlite3/open.dart';

import 'base_local.dart';

bool _sqliteConfigurado = false;
void configurarSqlite() {
  if (_sqliteConfigurado) return;
  // El paquete de runtime de Ubuntu incluye .so.0; no necesita libsqlite3-dev.
  if (Platform.isLinux) {
    open.overrideFor(
      OperatingSystem.linux,
      () => DynamicLibrary.open('libsqlite3.so.0'),
    );
  }
  _sqliteConfigurado = true;
}

/// Motor reutilizable, sin dependencias de Flutter ni de cuentas cloud.
class SqliteLocal implements ServicioBaseLocal {
  SqliteLocal({Directory? directorio})
    : directorio = directorio ?? carpetaPersistente() {
    configurarSqlite();
  }
  final Directory directorio;
  Database? _db;
  static const version = 3;

  static Directory carpetaPersistente() {
    final env = Platform.environment;
    final explicita = env['CHAMP_DATA_DIR'];
    if (explicita != null && explicita.isNotEmpty) {
      if (!p.isAbsolute(explicita)) {
        throw StateError('CHAMP_DATA_DIR debe ser una ruta absoluta.');
      }
      return Directory(explicita);
    }
    final String base;
    if (Platform.isWindows) {
      base =
          env['LOCALAPPDATA'] ??
          (throw StateError('No se encontró LOCALAPPDATA.'));
    } else {
      final home = env['HOME'] ?? (throw StateError('No se encontró HOME.'));
      base = Platform.isMacOS
          ? p.join(home, 'Library', 'Application Support')
          : env['XDG_DATA_HOME'] ?? p.join(home, '.local', 'share');
    }
    return Directory(p.join(base, 'RHIA', 'Champ'));
  }

  Database get db {
    if (_db != null) return _db!;
    directorio.createSync(recursive: true);
    Directory(p.join(directorio.path, 'imagenes')).createSync();
    final conexion = sqlite3.open(p.join(directorio.path, 'champ.db'));
    _db = conexion;
    try {
      conexion.execute('PRAGMA busy_timeout=5000');
      conexion.execute('PRAGMA foreign_keys=ON');
      final actual =
          conexion.select('PRAGMA user_version').first.values.first as int;
      if (actual > version) {
        throw StateError('Esta base necesita una versión más nueva de Champ.');
      }
      if (actual > 0 && actual < version) _respaldo('antes-v$version');
      if (actual < 1) {
        _transaccion(() {
          if ((conexion.select('PRAGMA user_version').first.values.first
                  as int) >=
              1) {
            return;
          }
          conexion.execute('''CREATE TABLE documentos (
          coleccion TEXT NOT NULL, id TEXT NOT NULL, datos TEXT NOT NULL,
          PRIMARY KEY (coleccion, id))''');
          conexion.execute(
            '''CREATE TABLE imagenes (
          referencia TEXT PRIMARY KEY, ruta TEXT NOT NULL UNIQUE, tamano INTEGER NOT NULL)''',
          );
          conexion.execute('PRAGMA user_version=1');
        });
      }
      if (actual < 2) {
        _transaccion(() {
          if ((conexion.select('PRAGMA user_version').first.values.first
                  as int) >=
              2) {
            return;
          }
          conexion.execute('''CREATE TABLE likes (
          origen TEXT NOT NULL, destino TEXT NOT NULL,
          decision TEXT NOT NULL CHECK(decision IN ('gusta','pasar')),
          PRIMARY KEY(origen,destino), CHECK(origen <> destino))''');
          conexion.execute('''CREATE TABLE matches (
          perro_a TEXT NOT NULL, perro_b TEXT NOT NULL,
          fecha TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
          PRIMARY KEY(perro_a,perro_b), CHECK(perro_a < perro_b))''');
          conexion.execute('CREATE INDEX likes_por_destino ON likes(destino)');
          conexion.execute('PRAGMA user_version=2');
        });
      }
      if (actual < 3) {
        _transaccion(() {
          if ((conexion.select('PRAGMA user_version').first.values.first
                  as int) >=
              3) {
            return;
          }
          for (final evento in ['INSERT', 'UPDATE']) {
            conexion.execute(
              'DROP TRIGGER IF EXISTS match_tras_${evento.toLowerCase()}',
            );
            conexion.execute(
              '''CREATE TRIGGER match_tras_${evento.toLowerCase()}
            AFTER $evento ON likes WHEN NEW.decision='gusta'
            BEGIN
              INSERT OR IGNORE INTO matches(perro_a,perro_b)
              SELECT MIN(NEW.origen,NEW.destino), MAX(NEW.origen,NEW.destino)
              WHERE EXISTS(SELECT 1 FROM likes WHERE origen=NEW.destino
                AND destino=NEW.origen AND decision='gusta')
              AND NOT EXISTS(SELECT 1 FROM matches
                WHERE perro_a=MIN(NEW.origen,NEW.destino)
                AND perro_b=MAX(NEW.origen,NEW.destino));
            END''',
            );
          }
          conexion.execute('PRAGMA user_version=3');
        });
      }
      conexion.execute('PRAGMA journal_mode=WAL');
      conexion.execute('PRAGMA synchronous=FULL');
      return conexion;
    } catch (_) {
      conexion.dispose();
      _db = null;
      rethrow;
    }
  }

  void _transaccion(void Function() accion) {
    final conexion = _db!;
    conexion.execute('BEGIN IMMEDIATE');
    try {
      accion();
      conexion.execute('COMMIT');
    } catch (_) {
      conexion.execute('ROLLBACK');
      rethrow;
    }
  }

  String _texto(Map<String, dynamic> args, String clave) {
    final valor = args[clave];
    if (valor is! String || valor.isEmpty || valor.length > 500) {
      throw FormatException('Campo inválido: $clave');
    }
    return valor;
  }

  String _referencia(Map<String, dynamic> args) {
    final ref = _texto(args, 'referencia');
    if (!RegExp(r'^[a-f0-9]{64}$').hasMatch(ref)) {
      throw const FormatException('Referencia inválida.');
    }
    return ref;
  }

  @override
  Future<Map<String, dynamic>> ejecutar(
    String operacion,
    Map<String, dynamic> args,
  ) async {
    final conexion = db;
    switch (operacion) {
      case 'obtener':
        final filas = conexion.select(
          'SELECT datos FROM documentos WHERE coleccion=? AND id=?',
          [_texto(args, 'coleccion'), _texto(args, 'id')],
        );
        return {
          'registro': filas.isEmpty
              ? null
              : jsonDecode(filas.single['datos'] as String),
        };
      case 'listar':
        return {
          'registros': conexion
              .select(
                'SELECT datos FROM documentos WHERE coleccion=? ORDER BY id',
                [_texto(args, 'coleccion')],
              )
              .map((f) => jsonDecode(f['datos'] as String))
              .toList(),
        };
      case 'aplicar':
        final cambios = (args['cambios'] as List).cast<Map<String, dynamic>>();
        _transaccion(() {
          for (final cambio in cambios) {
            _aplicar(cambio);
          }
        });
        return {'guardado': true};
      case 'guardar_imagen':
        final bytes = base64Decode(args['bytes'] as String);
        if (bytes.isEmpty || bytes.length > 1024 * 1024) {
          throw const FormatException('Foto de hasta 1 MB.');
        }
        final ref = sha256.convert(bytes).toString();
        final archivo = File(p.join(directorio.path, 'imagenes', '$ref.img'));
        if (!archivo.existsSync()) {
          final temporal = File(
            '${archivo.path}.${DateTime.now().microsecondsSinceEpoch}.part',
          );
          temporal.writeAsBytesSync(bytes, flush: true);
          temporal.renameSync(archivo.path);
        }
        conexion.execute(
          'INSERT OR IGNORE INTO imagenes(referencia,ruta,tamano) VALUES(?,?,?)',
          [ref, 'imagenes/$ref.img', bytes.length],
        );
        return {'referencia': ref};
      case 'leer_imagen':
        final ref = _referencia(args);
        final bytes = File(p.join(directorio.path, 'imagenes', '$ref.img'))
            .readAsBytesSync();
        if (sha256.convert(bytes).toString() != ref) {
          throw StateError('La foto está dañada.');
        }
        return {'bytes': base64Encode(bytes)};
      case 'likes':
        return {
          'likes': conexion
              .select(
                'SELECT origen,destino,decision FROM likes WHERE origen=? ORDER BY destino',
                [_texto(args, 'origen')],
              )
              .map((f) => Map<String, dynamic>.from(f))
              .toList(),
        };
      case 'matches':
        final origen = _texto(args, 'origen');
        return {
          'matches': conexion
              .select(
                'SELECT perro_a,perro_b,fecha FROM matches WHERE perro_a=? OR perro_b=?',
                [origen, origen],
              )
              .map((f) => Map<String, dynamic>.from(f))
              .toList(),
        };
      case 'revisar_descartados':
        final origen = _texto(args, 'origen');
        _transaccion(() {
          conexion.execute(
            "DELETE FROM likes WHERE origen=? AND decision='pasar'",
            [origen],
          );
        });
        return {'actualizado': true};
      case 'respaldar':
        return {'ruta': _respaldo('manual')};
      case 'estado':
        return {
          'ruta': p.join(directorio.absolute.path, 'champ.db'),
          'imagenes': p.join(directorio.absolute.path, 'imagenes'),
          'version': conexion.select('PRAGMA user_version').first.values.first,
          'documentos': conexion
              .select('SELECT COUNT(*) AS n FROM documentos')
              .single['n'],
          'fotos': conexion
              .select('SELECT COUNT(*) AS n FROM imagenes')
              .single['n'],
          'matches': conexion
              .select('SELECT COUNT(*) AS n FROM matches')
              .single['n'],
        };
      default:
        throw const FormatException('Operación desconocida.');
    }
  }

  void _aplicar(Map<String, dynamic> cambio) {
    final conexion = _db!;
    switch (cambio['tipo']) {
      case 'guardar':
      case 'guardar_si_nuevo':
        final coleccion = _texto(cambio, 'coleccion');
        final id = _texto(cambio, 'id');
        final datos = Map<String, dynamic>.from(cambio['datos'] as Map);
        _validarFotos(datos);
        if (datos['id'] != id) {
          throw const FormatException('El identificador no coincide.');
        }
        if (cambio['tipo'] == 'guardar_si_nuevo') {
          conexion.execute(
            'INSERT OR IGNORE INTO documentos(coleccion,id,datos) VALUES(?,?,?)',
            [coleccion, id, jsonEncode(datos)],
          );
        } else {
          conexion.execute(
            '''INSERT INTO documentos(coleccion,id,datos) VALUES(?,?,?)
            ON CONFLICT(coleccion,id) DO UPDATE SET datos=excluded.datos''',
            [coleccion, id, jsonEncode(datos)],
          );
        }
      case 'eliminar':
        conexion.execute('DELETE FROM documentos WHERE coleccion=? AND id=?', [
          _texto(cambio, 'coleccion'),
          _texto(cambio, 'id'),
        ]);
      case 'like':
      case 'like_si_nuevo':
        conexion.execute(
          cambio['tipo'] == 'like_si_nuevo'
              ? 'INSERT OR IGNORE INTO likes(origen,destino,decision) VALUES(?,?,?)'
              : '''INSERT INTO likes(origen,destino,decision) VALUES(?,?,?)
          ON CONFLICT(origen,destino) DO UPDATE SET decision=excluded.decision''',
          [
            _texto(cambio, 'origen'),
            _texto(cambio, 'destino'),
            _texto(cambio, 'decision'),
          ],
        );
      case 'eliminar_like':
        conexion.execute('DELETE FROM likes WHERE origen=? AND destino=?', [
          _texto(cambio, 'origen'),
          _texto(cambio, 'destino'),
        ]);
      default:
        throw const FormatException('Cambio desconocido.');
    }
  }

  void _validarFotos(Object? valor) {
    if (valor is Map) {
      final ref = valor['fotoReferencia'];
      if (ref != null) {
        if (ref is! String ||
            !RegExp(r'^[a-f0-9]{64}$').hasMatch(ref) ||
            _db!.select('SELECT referencia FROM imagenes WHERE referencia=?', [
              ref,
            ]).isEmpty ||
            !File(p.join(directorio.path, 'imagenes', '$ref.img'))
                .existsSync()) {
          throw const FormatException(
            'La referencia de foto no existe. Guarda primero la imagen.',
          );
        }
      }
      for (final hijo in valor.values) {
        _validarFotos(hijo);
      }
    } else if (valor is List) {
      for (final hijo in valor) {
        _validarFotos(hijo);
      }
    }
  }

  /// VACUUM INTO obtiene una instantánea SQLite; las imágenes son inmutables.
  String _respaldo(String motivo) {
    final nombre = '$motivo-${DateTime.now().toUtc().microsecondsSinceEpoch}';
    final base = p.join(directorio.path, 'respaldos');
    final pendiente = Directory(p.join(base, '.$nombre.incompleto'))
      ..createSync(recursive: true);
    final destino = p.join(pendiente.path, 'champ.db');
    _db!.execute('VACUUM INTO ?', [destino]);
    final copia = sqlite3.open(destino);
    final hashes = <String, String>{};
    try {
      final imagenes = Directory(p.join(pendiente.path, 'imagenes'))
        ..createSync();
      for (final fila in copia.select('SELECT referencia FROM imagenes')) {
        final ref = fila['referencia'] as String;
        if (!RegExp(r'^[a-f0-9]{64}$').hasMatch(ref)) {
          throw StateError('Referencia de foto dañada.');
        }
        final archivo = File(p.join(directorio.path, 'imagenes', '$ref.img'));
        if (sha256.convert(archivo.readAsBytesSync()).toString() != ref) {
          throw StateError('Foto dañada: $ref');
        }
        archivo.copySync(p.join(imagenes.path, '$ref.img'));
        hashes['imagenes/$ref.img'] = ref;
      }
      if (copia.select('PRAGMA integrity_check').single.values.single != 'ok') {
        throw StateError('No se pudo verificar el respaldo.');
      }
    } finally {
      copia.dispose();
    }
    hashes['champ.db'] = sha256
        .convert(File(destino).readAsBytesSync())
        .toString();
    File(p.join(pendiente.path, 'manifest.json')).writeAsStringSync(
      jsonEncode({
        'aplicacion': 'Champ',
        'fecha': DateTime.now().toUtc().toIso8601String(),
        'sha256': hashes,
      }),
      flush: true,
    );
    return pendiente.renameSync(p.join(base, nombre)).absolute.path;
  }

  @override
  Future<void> cerrar() async {
    _db?.dispose();
    _db = null;
  }
}
