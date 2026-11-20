import 'dart:typed_data';

import 'package:shared_preferences/shared_preferences.dart';

import '../persistencia/base_local.dart';
import '../catalogos/perfiles_demo.dart';

class DatosIniciales {
  DatosIniciales(
    this.base, {
    Future<String?> Function(String)? leerLegado,
    this.cargarFotoSemilla,
  }) : leerLegado =
           leerLegado ?? ((clave) => SharedPreferencesAsync().getString(clave));
  final BaseLocal base;
  final Future<String?> Function(String) leerLegado;
  final Future<Uint8List?> Function(String)? cargarFotoSemilla;
  Future<void>? _preparacion;
  Future<void> preparar() async {
    try {
      await (_preparacion ??= _sembrar());
    } catch (_) {
      _preparacion = null;
      rethrow;
    }
  }

  Future<void> _sembrar() async {
    final perfiles = CargarPerfiles().ejecutar();
    if (await base.obtener('meta', 'catalogo_v1') == null) {
      await base.aplicar([
        for (final perfil in perfiles)
          {
            'tipo': 'guardar_si_nuevo',
            'coleccion': 'perfiles',
            'id': perfil.id,
            'datos': perfil.toJson()..remove('foto'),
          },
        for (final raza in perfiles.map((p) => p.raza).toSet())
          {
            'tipo': 'guardar_si_nuevo',
            'coleccion': 'razas',
            'id': raza,
            'datos': {'id': raza, 'nombre': raza},
          },
        {
          'tipo': 'guardar_si_nuevo',
          'coleccion': 'catalogos',
          'id': 'cruces_demo',
          'datos': {
            'id': 'cruces_demo',
            'demostracion': true,
            'perfiles': perfiles.map((p) => p.id).toList(),
          },
        },
        {
          'tipo': 'guardar',
          'coleccion': 'meta',
          'id': 'catalogo_v1',
          'datos': {'id': 'catalogo_v1'},
        },
      ]);
    }
    if (cargarFotoSemilla == null ||
        await base.obtener('meta', 'fotos_catalogo_v1') != null) {
      return;
    }
    final cambios = <Map<String, dynamic>>[];
    for (final p in perfiles.where((p) => p.imagenUrl != null)) {
      final actual = await base.obtener('perfiles', p.id);
      if (actual == null || actual['fotoReferencia'] != null) continue;
      final bytes = await cargarFotoSemilla!(p.id);
      if (bytes == null) return;
      final ref = await base.guardarImagen(bytes);
      cambios.add({
        'tipo': 'guardar',
        'coleccion': 'perfiles',
        'id': p.id,
        'datos': {
          ...actual,
          'imagenUrl': null,
          'fuenteImagen': p.imagenUrl,
          'fotoReferencia': ref,
        },
      });
    }
    cambios.add({
      'tipo': 'guardar',
      'coleccion': 'meta',
      'id': 'fotos_catalogo_v1',
      'datos': {'id': 'fotos_catalogo_v1'},
    });
    await base.aplicar(cambios);
  }
}
