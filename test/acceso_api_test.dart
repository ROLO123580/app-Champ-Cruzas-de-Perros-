import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:champ/core/modelos/chat.dart';
import 'package:champ/core/modelos/cruces.dart';
import 'package:champ/core/persistencia/base_local.dart';
import 'package:champ/core/persistencia/crear_servicio.dart';
import 'package:champ/core/persistencia/http_local.dart';
import 'package:champ/core/persistencia/sqlite_local.dart';
import 'package:champ/core/servicios/servicios_champ.dart';
import 'package:champ/microapps/datos_locales/api/servidor_local.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import 'soporte/base_prueba.dart';

String _ejecutableDart() {
  final actual = Platform.resolvedExecutable;
  if (p.basenameWithoutExtension(actual) == 'dart') return actual;
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

Future<dynamic> _ejecutarCli(
  String url,
  Directory carpeta,
  List<String> argumentos,
) async {
  final proceso = await Process.start(
    _ejecutableDart(),
    [
      '--packages=${p.absolute('.dart_tool', 'package_config.json')}',
      p.absolute('tool', 'champ_db.dart'),
      ...argumentos,
    ],
    environment: {
      'CHAMP_API_URL': url,
      // El CLI debe consultar al servidor, incluso si su entorno indica otra
      // carpeta para datos. No debe crear allí una segunda base de Champ.
      'CHAMP_DATA_DIR': p.join(carpeta.path, 'no-usar-cli'),
    },
  );
  final salida = proceso.stdout.transform(utf8.decoder).join();
  final errores = proceso.stderr.transform(utf8.decoder).join();
  try {
    final codigo = await proceso.exitCode.timeout(const Duration(seconds: 30));
    final resultados = await Future.wait([salida, errores]);
    expect(codigo, 0, reason: resultados[1]);
    return jsonDecode(resultados[0]);
  } finally {
    proceso.kill();
    await proceso.exitCode;
  }
}

void main() {
  test('la fábrica nativa usa API para fichas, fotos, likes, chat y respaldo tras reiniciar', () async {
    final predeterminado = crearServicioBase();
    addTearDown(predeterminado.cerrar);
    expect(predeterminado, isA<HttpLocal>());
    final carpeta = await carpetaPrueba();
    var servidor = ServidorLocal(BaseLocal(SqliteLocal(directorio: carpeta)));
    await servidor.iniciar(puerto: 0);
    ServiciosChamp abrir() {
      final transporte = crearServicioBase(
        url: 'http://127.0.0.1:${servidor.puerto}',
      );
      expect(transporte, isA<HttpLocal>());
      return ServiciosChamp(
        base: BaseLocal(transporte),
        leerLegado: (_) async => null,
        cargarFotoSemilla: (_) async => null,
      );
    }

    var servicios = abrir();
    addTearDown(() async {
      await servicios.cerrar();
      await servidor.cerrar();
    });
    final base = servicios.base;
    await base.guardar('razas', 'api-raza', {
      'id': 'api-raza',
      'nombre': 'Inicial',
    });
    expect((await base.obtener('razas', 'api-raza'))!['nombre'], 'Inicial');
    await base.guardar('razas', 'api-raza', {
      'id': 'api-raza',
      'nombre': 'Actualizada',
    });
    expect((await base.listar('razas')).single['nombre'], 'Actualizada');
    await base.eliminar('razas', 'api-raza');
    expect(await base.obtener('razas', 'api-raza'), isNull);

    final foto = Uint8List.fromList([1, 3, 5, 7]);
    final referencia = await base.guardarImagen(foto);
    expect(await base.leerImagen(referencia), orderedEquals(foto));
    final toby = PerfilPerro(
      id: 'api-toby',
      nombre: 'Toby',
      raza: 'Golden retriever',
      sexo: 'Macho',
      edadMeses: 36,
      ciudad: 'Santiago',
      responsable: 'Rolo',
      descripcion: 'Ficha mediante API',
      foto: foto,
    );
    const luna = PerfilPerro(
      id: 'api-luna',
      nombre: 'Luna',
      raza: 'Golden retriever',
      sexo: 'Hembra',
      edadMeses: 36,
      ciudad: 'Santiago',
      responsable: 'Camila',
      descripcion: '',
    );
    await base.guardar('perfiles', luna.id, luna.toJson()..remove('foto'));
    var estado = await servicios.cruces.guardarPerfil(toby);
    final ficha = (await base.obtener('perfiles', toby.id))!;
    expect(ficha.containsKey('foto'), isFalse);
    expect(ficha['fotoReferencia'], referencia);
    estado = await servicios.cruces.decidir(estado, luna, DecisionCruce.gusta);
    expect(estado.matches, isEmpty);
    await base.registrarLike(luna.id, toby.id, 'gusta');
    await Future.wait([
      base.registrarLike(luna.id, toby.id, 'gusta'),
      base.registrarLike(toby.id, luna.id, 'gusta'),
    ]);
    expect(await base.matches(toby.id), hasLength(1));
    final descartada = (await servicios.cruces.cargarPerfiles()).firstWhere(
      (perfil) => perfil.id == 'demo-nala',
    );
    estado = await servicios.cruces.decidir(
      estado,
      descartada,
      DecisionCruce.pasar,
    );
    expect(estado.decisiones[descartada.id], DecisionCruce.pasar);
    estado = await servicios.cruces.revisarDescartados(estado);
    expect(estado.decisiones.containsKey(descartada.id), isFalse);
    expect(estado.decisiones[luna.id], DecisionCruce.gusta);
    expect(estado.matches, {luna.id});

    final fotoChat = Uint8List.fromList([8, 6, 4, 2]);
    await servicios.chat.guardar([
      Conversacion(
        id: 'cruce:api-toby:api-luna',
        nombre: 'Camila · Luna',
        fecha: DateTime(2026),
        mensajes: [
          Mensaje(
            id: 'api-mensaje',
            fecha: DateTime(2026),
            texto: 'Hola desde la API',
            foto: fotoChat,
          ),
        ],
      ),
    ]);
    final mensaje = (await base.listar('mensajes')).single;
    expect(mensaje.containsKey('foto'), isFalse);
    final referenciaChat = mensaje['fotoReferencia'] as String;
    expect(await base.leerImagen(referenciaChat), orderedEquals(fotoChat));
    final respaldo = await base.respaldar();
    expect(p.isWithin(carpeta.path, respaldo), isTrue);
    expect(File(p.join(respaldo, 'champ.db')).existsSync(), isTrue);
    expect(File(p.join(respaldo, 'manifest.json')).existsSync(), isTrue);
    for (final ref in [referencia, referenciaChat]) {
      expect(
        File(p.join(respaldo, 'imagenes', '$ref.img')).existsSync(),
        isTrue,
      );
    }

    await servicios.cerrar();
    await servidor.cerrar();
    servidor = ServidorLocal(BaseLocal(SqliteLocal(directorio: carpeta)));
    await servidor.iniciar(puerto: 0);
    servicios = abrir();
    final recuperado = await servicios.cruces.cargar();
    expect(recuperado.miPerro!.foto, orderedEquals(foto));
    expect(recuperado.decisiones, {luna.id: DecisionCruce.gusta});
    expect(recuperado.matches, {luna.id});
    expect(await servicios.base.matches(toby.id), hasLength(1));
    final chat = (await servicios.chat.cargar()).single;
    expect(chat.id, 'cruce:api-toby:api-luna');
    expect(chat.mensajes.single.texto, 'Hola desde la API');
    expect(chat.mensajes.single.foto, orderedEquals(fotoChat));
    expect(
      (await servicios.base.estado())['ruta'],
      p.join(carpeta.absolute.path, 'champ.db'),
    );
  });

  test(
    'el CLI consulta la misma base del servidor mediante CHAMP_API_URL',
    () async {
      final carpeta = await carpetaPrueba();
      final servidor = ServidorLocal(
        BaseLocal(SqliteLocal(directorio: carpeta)),
      );
      await servidor.iniciar(puerto: 0);
      addTearDown(servidor.cerrar);
      final url = 'http://127.0.0.1:${servidor.puerto}';
      final base = BaseLocal(crearServicioBase(url: url));
      addTearDown(base.cerrar);
      await base.guardar('razas', 'api-cli', {
        'id': 'api-cli',
        'nombre': 'Akita',
      });
      final estado = await _ejecutarCli(url, carpeta, ['estado']);
      expect(estado['ruta'], p.join(carpeta.absolute.path, 'champ.db'));
      final registros = await _ejecutarCli(url, carpeta, ['listar', 'razas']);
      expect(registros, [
        {'id': 'api-cli', 'nombre': 'Akita'},
      ]);
      expect(
        Directory(p.join(carpeta.path, 'no-usar-cli')).existsSync(),
        isFalse,
      );
    },
    timeout: const Timeout(Duration(seconds: 90)),
  );
}
