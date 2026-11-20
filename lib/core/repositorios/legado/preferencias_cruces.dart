import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../modelos/cruces.dart';

import '../contratos.dart';
export '../contratos.dart' show AlmacenCruces;

class PersistirCruces extends AlmacenCruces {
  PersistirCruces({SharedPreferencesAsync? preferencias})
    : _inyectadas = preferencias;
  static const clave = 'champ.cruces.v1';
  final SharedPreferencesAsync? _inyectadas;
  SharedPreferencesAsync get _preferencias =>
      _inyectadas ?? SharedPreferencesAsync();
  @override
  Future<EstadoCruces> cargar() async {
    final json = await _preferencias.getString(clave);
    return json == null
        ? EstadoCruces()
        : EstadoCruces.fromJson(jsonDecode(json) as Map<String, dynamic>);
  }

  @override
  Future<void> guardar(EstadoCruces estado) =>
      _preferencias.setString(clave, jsonEncode(estado.toJson()));
}
