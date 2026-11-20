import 'dart:convert';

import '../persistencia/base_local.dart';

class FotosLocales {
  FotosLocales(this.base);
  final BaseLocal base;
  final Map<String, String> _guardadas = {};
  Future<Map<String, dynamic>> aDisco(Map<String, dynamic> datos) async {
    final copia = {...datos};
    final foto = copia.remove('foto') as String?;
    if (foto != null) {
      final ref =
          _guardadas[foto] ?? await base.guardarImagen(base64Decode(foto));
      _guardadas[foto] = ref;
      copia['fotoReferencia'] = ref;
    }
    return copia;
  }

  Future<Map<String, dynamic>> desdeDisco(Map<String, dynamic> datos) async {
    final copia = {...datos};
    final ref = copia.remove('fotoReferencia') as String?;
    if (ref != null) copia['foto'] = base64Encode(await base.leerImagen(ref));
    return copia;
  }
}
