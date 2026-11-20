import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

abstract interface class RepositorioPreferencias {
  Future<Map<String, dynamic>> cargar();
  Future<void> guardar(Map<String, dynamic> datos);
}

/// Solo apariencia de este navegador/equipo; no guarda identidad ni credenciales.
class PreferenciasDispositivo implements RepositorioPreferencias {
  static const clave = 'champ.apariencia.v1';
  @override
  Future<Map<String, dynamic>> cargar() async {
    final texto = (await SharedPreferences.getInstance()).getString(clave);
    return texto == null
        ? {}
        : Map<String, dynamic>.from(jsonDecode(texto) as Map);
  }

  @override
  Future<void> guardar(Map<String, dynamic> datos) async {
    if (!await (await SharedPreferences.getInstance()).setString(
      clave,
      jsonEncode(datos),
    )) {
      throw StateError(
        'No se pudieron guardar las preferencias en este equipo.',
      );
    }
  }
}
