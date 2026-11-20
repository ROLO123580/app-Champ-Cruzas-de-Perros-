import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../modelos/chat.dart';

import '../contratos.dart';
export '../contratos.dart' show AlmacenChat;

/// Guarda los bytes de las fotos para no depender del archivo original.
class PersistirChat implements AlmacenChat {
  PersistirChat({SharedPreferencesAsync? preferencias})
    : _inyectadas = preferencias;
  static const clave = 'champ.chat.v1';
  final SharedPreferencesAsync? _inyectadas;
  SharedPreferencesAsync get _preferencias =>
      _inyectadas ?? SharedPreferencesAsync();
  @override
  Future<List<Conversacion>> cargar() async {
    final contenido = await _preferencias.getString(clave);
    if (contenido == null) return [];
    return (jsonDecode(contenido) as List)
        .map((c) => Conversacion.fromJson(c as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> guardar(List<Conversacion> conversaciones) async {
    final contenido = jsonEncode(
      conversaciones.map((c) => c.toJson()).toList(),
    );
    if (utf8.encode(contenido).length > 4 * 1024 * 1024) {
      throw StateError('El chat alcanzó el límite local de 4 MB.');
    }
    await _preferencias.setString(clave, contenido);
  }
}
