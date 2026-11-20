import 'dart:convert';

import 'package:http/http.dart' as http;

import 'base_local.dart';

class HttpLocal implements ServicioBaseLocal {
  HttpLocal({String? url, http.Client? cliente})
    : url =
          url ??
          const String.fromEnvironment(
            'CHAMP_API_URL',
            defaultValue: 'http://127.0.0.1:8787',
          ),
      _cliente = cliente ?? http.Client();
  final String url;
  final http.Client _cliente;
  @override
  Future<Map<String, dynamic>> ejecutar(
    String operacion,
    Map<String, dynamic> argumentos,
  ) async {
    try {
      final respuesta = await _cliente
          .post(
            Uri.parse('$url/v1/comando'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'operacion': operacion,
              'argumentos': argumentos,
            }),
          )
          .timeout(const Duration(seconds: 30));
      final cuerpo = jsonDecode(respuesta.body) as Map<String, dynamic>;
      if (respuesta.statusCode != 200) {
        throw StateError(cuerpo['error'] as String? ?? 'Error de base local.');
      }
      return cuerpo;
    } on StateError {
      rethrow;
    } catch (_) {
      throw StateError(
        'No se pudo conectar con el servicio local de Champ. Comprueba que esté iniciado.',
      );
    }
  }

  @override
  Future<void> cerrar() async => _cliente.close();
}
