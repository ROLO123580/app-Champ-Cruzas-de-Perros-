import 'dart:convert';
import 'dart:typed_data';

import 'package:champ/core/modelos/chat.dart';
import 'package:champ/core/persistencia/base_local.dart';
import 'package:champ/core/persistencia/sqlite_local.dart';
import 'package:champ/core/repositorios/chat_local.dart';
import 'package:champ/core/repositorios/datos_iniciales.dart';
import 'package:flutter_test/flutter_test.dart';

import 'soporte/base_prueba.dart';

class _Lote {
  _Lote(this.ids, this.bytes);
  final List<String> ids;
  final int bytes;
}

/// Observa el transporte y simula errores sin sustituir SQLite ni sus lotes.
class _ServicioObservado implements ServicioBaseLocal {
  _ServicioObservado(this.sqlite);
  final SqliteLocal sqlite;
  final lotes = <_Lote>[];
  int fotosGuardadas = 0;
  int? fallarAntesDelLote;
  int? fallarDespuesDelLote;

  @override
  Future<Map<String, dynamic>> ejecutar(
    String operacion,
    Map<String, dynamic> argumentos,
  ) async {
    if (operacion == 'guardar_imagen') fotosGuardadas++;
    if (operacion != 'aplicar') {
      return sqlite.ejecutar(operacion, argumentos);
    }
    final cambios = (argumentos['cambios'] as List)
        .cast<Map<String, dynamic>>();
    final esChat = cambios.any(
      (c) => c['coleccion'] == 'mensajes' || c['coleccion'] == 'conversaciones',
    );
    if (!esChat) return sqlite.ejecutar(operacion, argumentos);
    final cuerpo = jsonEncode({
      'operacion': operacion,
      'argumentos': argumentos,
    });
    lotes.add(
      _Lote(
        cambios.map((c) => c['id'] as String).toList(),
        utf8.encode(cuerpo).length,
      ),
    );
    if (fallarAntesDelLote == lotes.length) {
      fallarAntesDelLote = null;
      throw StateError('Fallo antes de guardar el lote.');
    }
    final resultado = await sqlite.ejecutar(operacion, argumentos);
    if (fallarDespuesDelLote == lotes.length) {
      fallarDespuesDelLote = null;
      throw StateError('Se perdió la confirmación del lote.');
    }
    return resultado;
  }

  @override
  Future<void> cerrar() => sqlite.cerrar();
}

RepositorioChatLocal _repositorio(
  BaseLocal base, {
  Future<String?> Function(String)? leerLegado,
}) => RepositorioChatLocal(
  base,
  DatosIniciales(
    base,
    leerLegado: leerLegado ?? (_) async => null,
    cargarFotoSemilla: (_) async => null,
  ),
);

Conversacion _conversacion(int cantidad, {String? texto, Uint8List? foto}) =>
    Conversacion(
      id: 'conversacion',
      nombre: 'Ana',
      fecha: DateTime.utc(2026, 10, 20),
      mensajes: List.generate(
        cantidad,
        (i) => Mensaje(
          id: 'mensaje-$i',
          fecha: DateTime.utc(2026, 10, 20).add(Duration(seconds: i)),
          texto: texto ?? 'Hola $i',
          foto: i == 0 ? foto : null,
        ),
      ),
    );

void main() {
  configurarSqlite();

  test('cada mensaje guarda solo su delta y no vuelve a enviar fotos anteriores', () async {
    final carpeta = await carpetaPrueba();
    final observado = _ServicioObservado(SqliteLocal(directorio: carpeta));
    final base = BaseLocal(observado);
    addTearDown(base.cerrar);
    final chat = _repositorio(base);
    await chat.cargar();
    final anterior = _conversacion(2, foto: Uint8List.fromList([1, 2, 3]));
    await chat.guardar([anterior]);
    expect(observado.lotes.single.ids, [
      'conversacion',
      'mensaje-0',
      'mensaje-1',
    ]);
    expect(observado.fotosGuardadas, 1);
    observado.lotes.clear();
    final siguiente = anterior.agregar(
      Mensaje(
        id: 'mensaje-2',
        fecha: DateTime.utc(2026, 10, 20, 0, 0, 2),
        texto: 'Otro mensaje',
      ),
    );
    await chat.guardar([siguiente]);
    expect(observado.lotes.single.ids, ['mensaje-2']);
    expect(observado.fotosGuardadas, 1);
    observado.lotes.clear();
    await chat.guardar([siguiente]);
    expect(observado.lotes, isEmpty);

    final reabierto = _repositorio(base);
    final recuperadas = await reabierto.cargar();
    await reabierto.guardar(recuperadas);
    expect(observado.lotes, isEmpty);
    expect(recuperadas.single.mensajes, hasLength(3));
    expect(recuperadas.single.mensajes.first.foto, orderedEquals([1, 2, 3]));

    // Guardar sin una carga previa también reconoce las identidades de SQLite.
    await _repositorio(base).guardar(recuperadas);
    expect(observado.lotes, isEmpty);
  });

  test(
    'importa un historial superior a 16 MiB usando lotes acotados',
    () async {
      final carpeta = await carpetaPrueba();
      final observado = _ServicioObservado(SqliteLocal(directorio: carpeta));
      final base = BaseLocal(observado);
      addTearDown(base.cerrar);
      final conversacion = _conversacion(
        2500,
        texto: List.filled(4000, 'á').join(),
      );
      final legado = jsonEncode([conversacion.toJson()]);
      expect(utf8.encode(legado).length, greaterThan(16 * 1024 * 1024));
      final chat = _repositorio(
        base,
        leerLegado: (clave) async => clave == 'champ.chat.v1' ? legado : null,
      );
      final recuperadas = await chat.cargar();
      expect(recuperadas.single.mensajes, hasLength(2500));
      expect(observado.lotes.length, greaterThan(1));
      expect(observado.lotes.every((l) => l.ids.length <= 100), isTrue);
      // El sobre JSON y las comas del array agregan menos de 1 KiB por lote.
      expect(observado.lotes.every((l) => l.bytes < 513 * 1024), isTrue);
      expect(observado.lotes.expand((l) => l.ids).toSet(), hasLength(2501));
      expect(await base.obtener('meta', 'preferencias_chat_v1'), isNotNull);
      observado.lotes.clear();
      await chat.guardar(recuperadas);
      expect(observado.lotes, isEmpty);
    },
  );

  test(
    'reintenta los lotes pendientes sin reenviar los ya confirmados',
    () async {
      final carpeta = await carpetaPrueba();
      final observado = _ServicioObservado(SqliteLocal(directorio: carpeta));
      final base = BaseLocal(observado);
      addTearDown(base.cerrar);
      final chat = _repositorio(base);
      final conversacion = _conversacion(250);
      observado.fallarAntesDelLote = 2;
      await expectLater(chat.guardar([conversacion]), throwsStateError);
      final confirmados = observado.lotes.first.ids.toSet();
      expect(await base.listar('mensajes'), hasLength(99));
      observado.lotes.clear();
      await chat.guardar([conversacion]);
      expect(
        observado.lotes.expand((l) => l.ids).any(confirmados.contains),
        isFalse,
      );
      expect(await base.listar('mensajes'), hasLength(250));
      expect(await base.listar('conversaciones'), hasLength(1));
    },
  );

  test('una confirmación perdida se reintenta sin duplicar mensajes ni conversación', () async {
    final carpeta = await carpetaPrueba();
    final observado = _ServicioObservado(SqliteLocal(directorio: carpeta));
    final base = BaseLocal(observado);
    addTearDown(base.cerrar);
    final chat = _repositorio(base);
    final conversacion = _conversacion(3);
    observado.fallarDespuesDelLote = 1;
    await expectLater(chat.guardar([conversacion]), throwsStateError);
    expect(await base.listar('mensajes'), hasLength(3));
    await chat.guardar([conversacion]);
    expect(observado.lotes, hasLength(2));
    expect(observado.lotes.first.ids, observado.lotes.last.ids);
    expect(await base.listar('mensajes'), hasLength(3));
    expect(await base.listar('conversaciones'), hasLength(1));
  });

  test(
    'guardados simultáneos de la instancia confirman cada identidad una vez',
    () async {
      final carpeta = await carpetaPrueba();
      final observado = _ServicioObservado(SqliteLocal(directorio: carpeta));
      final base = BaseLocal(observado);
      addTearDown(base.cerrar);
      final chat = _repositorio(base);
      await Future.wait([
        chat.guardar([_conversacion(1)]),
        chat.guardar([_conversacion(2)]),
      ]);
      expect(observado.lotes.expand((l) => l.ids).toList(), [
        'conversacion',
        'mensaje-0',
        'mensaje-1',
      ]);
      expect(await base.listar('mensajes'), hasLength(2));
    },
  );
}
