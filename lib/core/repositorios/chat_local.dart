import 'dart:convert';

import '../modelos/chat.dart';
import '../persistencia/base_local.dart';
import 'contratos.dart';
import 'datos_iniciales.dart';
import 'fotos_locales.dart';

class RepositorioChatLocal implements AlmacenChat {
  RepositorioChatLocal(this.base, this.iniciales) : fotos = FotosLocales(base);
  final BaseLocal base;
  final DatosIniciales iniciales;
  final FotosLocales fotos;
  final Set<String> _conversacionesGuardadas = {};
  final Set<String> _mensajesGuardados = {};
  Future<void>? _identidades;
  Future<void> _guardadoPendiente = Future<void>.value();
  static const _registrosPorLote = 100;
  static const _bytesPorLote = 512 * 1024;

  Future<void> _cargarIdentidades() async {
    try {
      await (_identidades ??= _leerIdentidades());
    } catch (_) {
      _identidades = null;
      rethrow;
    }
  }

  Future<void> _leerIdentidades() async {
    final conversaciones = await base.listar('conversaciones');
    final mensajes = await base.listar('mensajes');
    _conversacionesGuardadas.addAll(
      conversaciones.map((c) => c['id'] as String),
    );
    _mensajesGuardados.addAll(mensajes.map((m) => m['id'] as String));
  }

  Future<void> _importar() async {
    if (await base.obtener('meta', 'preferencias_chat_v1') != null) return;
    final antiguo = await iniciales.leerLegado('champ.chat.v1');
    if (antiguo == null) return;
    final lista = (jsonDecode(antiguo) as List).map(
      (c) => Conversacion.fromJson(c as Map<String, dynamic>),
    );
    for (final c in lista) {
      await guardar([c]);
    }
    await base.guardar('meta', 'preferencias_chat_v1', {
      'id': 'preferencias_chat_v1',
    });
  }

  @override
  Future<List<Conversacion>> cargar() async {
    await iniciales.preparar();
    await _importar();
    final mensajes = await base.listar('mensajes');
    final registros = await base.listar('conversaciones');
    _conversacionesGuardadas.addAll(registros.map((c) => c['id'] as String));
    _mensajesGuardados.addAll(mensajes.map((m) => m['id'] as String));
    _identidades ??= Future<void>.value();
    final conversaciones = <Conversacion>[];
    for (final c in registros) {
      final propios = <Mensaje>[];
      for (final m in mensajes.where((m) => m['conversacionId'] == c['id'])) {
        propios.add(Mensaje.fromJson(await fotos.desdeDisco(m)));
      }
      propios.sort((a, b) => a.fecha.compareTo(b.fecha));
      conversaciones.add(
        Conversacion(
          id: c['id'] as String,
          nombre: c['nombre'] as String,
          fecha: DateTime.parse(c['fecha'] as String),
          mensajes: propios,
        ),
      );
    }
    return conversaciones;
  }

  @override
  Future<void> guardar(List<Conversacion> conversaciones) {
    final resultado = _guardadoPendiente.then(
      (_) => _guardarPendientes(conversaciones),
    );
    // Un lote fallido no impide reintentar ni guardar otro mensaje después.
    _guardadoPendiente = resultado.then<void>(
      (_) {},
      onError: (Object _, StackTrace _) {},
    );
    return resultado;
  }

  Future<void> _guardarPendientes(List<Conversacion> conversaciones) async {
    await iniciales.preparar();
    await _cargarIdentidades();
    final lote = <Map<String, dynamic>>[];
    final conversacionesPendientes = <String>{};
    final mensajesPendientes = <String>{};
    var bytes = 0;

    Future<void> confirmarLote() async {
      if (lote.isEmpty) return;
      await base.aplicar(lote);
      for (final cambio in lote) {
        final guardadas = cambio['coleccion'] == 'mensajes'
            ? _mensajesGuardados
            : _conversacionesGuardadas;
        guardadas.add(cambio['id'] as String);
      }
      lote.clear();
      bytes = 0;
    }

    Future<void> agregar(Map<String, dynamic> cambio) async {
      final tamano = utf8.encode(jsonEncode(cambio)).length;
      // Las fotos viajan aparte; los mensajes habituales tienen hasta 4000
      // caracteres. Un registro antiguo mayor ocupa su propio lote.
      if (lote.isNotEmpty &&
          (lote.length >= _registrosPorLote ||
              bytes + tamano > _bytesPorLote)) {
        await confirmarLote();
      }
      lote.add(cambio);
      bytes += tamano;
    }

    for (final c in conversaciones) {
      if (!_conversacionesGuardadas.contains(c.id) &&
          conversacionesPendientes.add(c.id)) {
        await agregar({
          'tipo': 'guardar_si_nuevo',
          'coleccion': 'conversaciones',
          'id': c.id,
          'datos': {
            'id': c.id,
            'nombre': c.nombre,
            'fecha': c.fecha.toIso8601String(),
          },
        });
      }
      for (final m in c.mensajes) {
        if (_mensajesGuardados.contains(m.id) ||
            !mensajesPendientes.add(m.id)) {
          continue;
        }
        final datos = await fotos.aDisco(m.toJson());
        await agregar({
          'tipo': 'guardar_si_nuevo',
          'coleccion': 'mensajes',
          'id': m.id,
          'datos': {...datos, 'conversacionId': c.id},
        });
      }
    }
    await confirmarLote();
  }
}
