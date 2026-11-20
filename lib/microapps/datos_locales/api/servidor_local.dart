import 'dart:convert';
import 'dart:io';

import '../../../core/persistencia/base_local.dart';

class ServidorLocal {
  ServidorLocal(this.base);
  final BaseLocal base;
  HttpServer? _servidor;
  int get puerto => _servidor!.port;

  Future<void> iniciar({int puerto = 8787}) async {
    _servidor = await HttpServer.bind(InternetAddress.loopbackIPv4, puerto);
    _servidor!.listen(_atender);
  }

  Future<void> _atender(HttpRequest solicitud) async {
    final respuesta = solicitud.response;
    respuesta.headers.contentType = ContentType.json;
    respuesta.headers.set('Cache-Control', 'no-store');
    final host = solicitud.headers.value('host') ?? '';
    final origen = solicitud.headers.value('origin');
    final local = RegExp(r'^https?://(localhost|127\.0\.0\.1)(:\d+)?$');
    if (!RegExp(r'^(localhost|127\.0\.0\.1)(:\d+)?$').hasMatch(host) ||
        (origen != null && !local.hasMatch(origen))) {
      respuesta.statusCode = 403;
      respuesta.write(jsonEncode({'error': 'Acceso solo desde este equipo.'}));
      await respuesta.close();
      return;
    }
    if (origen != null) {
      respuesta.headers.set('Access-Control-Allow-Origin', origen);
      respuesta.headers.set('Vary', 'Origin');
    }
    respuesta.headers.set('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
    respuesta.headers.set('Access-Control-Allow-Headers', 'Content-Type');
    try {
      if (solicitud.method == 'OPTIONS') {
        respuesta.statusCode = 204;
      } else if (solicitud.method == 'GET' && solicitud.uri.path == '/health') {
        respuesta.write(
          jsonEncode({
            'aplicacion': 'Champ',
            'version': (await base.estado())['version'],
          }),
        );
      } else if (solicitud.method == 'POST' &&
          solicitud.uri.path == '/v1/comando') {
        if (solicitud.headers.contentType?.mimeType != 'application/json') {
          throw const FormatException('Se requiere JSON.');
        }
        final bytes = <int>[];
        await for (final bloque in solicitud) {
          if (bytes.length + bloque.length > 16 * 1024 * 1024) {
            throw const FormatException('Solicitud demasiado grande.');
          }
          bytes.addAll(bloque);
        }
        final cuerpo = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
        final datos = await base.operar(
          cuerpo['operacion'] as String,
          Map<String, dynamic>.from(cuerpo['argumentos'] as Map),
        );
        respuesta.write(jsonEncode(datos));
      } else {
        respuesta.statusCode = 404;
        respuesta.write(jsonEncode({'error': 'Ruta no encontrada.'}));
      }
    } on FormatException catch (e) {
      respuesta.statusCode = 400;
      respuesta.write(jsonEncode({'error': e.message}));
    } catch (_) {
      respuesta.statusCode = 500;
      respuesta.write(
        jsonEncode({
          'error': 'No se pudo completar la operación local. Los datos previos se conservan.',
        }),
      );
    } finally {
      await respuesta.close();
    }
  }

  Future<void> cerrar() async {
    await _servidor?.close(force: true);
    await base.cerrar();
  }
}
