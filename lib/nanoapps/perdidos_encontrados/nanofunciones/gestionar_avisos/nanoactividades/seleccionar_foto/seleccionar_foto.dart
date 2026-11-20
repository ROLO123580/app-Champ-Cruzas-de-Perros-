import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:champ/core/servicios/seleccionar_foto.dart';

/// Foto PNG acotada para compartirla con el aviso, sin depender del disco del autor.
class SeleccionarFotoAviso {
  SeleccionarFotoAviso(this._selector);
  final SeleccionarFoto _selector;
  Future<Uint8List?> ejecutar() async {
    final bytes = await _selector.ejecutar();
    return bytes == null ? null : comprimir(bytes);
  }

  static Future<Uint8List> comprimir(Uint8List bytes) async {
    final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
    try {
      final descriptor = await ui.ImageDescriptor.encoded(buffer);
      try {
        if (descriptor.width * descriptor.height > 20000000) {
          throw StateError('La imagen supera los 20 megapíxeles.');
        }
        for (final limite in [640, 480, 320, 240, 160, 80]) {
          final escala = min(
            1.0,
            limite / max(descriptor.width, descriptor.height),
          );
          final codec = await descriptor.instantiateCodec(
            targetWidth: max(1, (descriptor.width * escala).round()),
            targetHeight: max(1, (descriptor.height * escala).round()),
          );
          try {
            final frame = await codec.getNextFrame();
            try {
              final png = await frame.image.toByteData(
                format: ui.ImageByteFormat.png,
              );
              if (png != null && png.lengthInBytes <= 80 * 1024) {
                return png.buffer.asUint8List();
              }
            } finally {
              frame.image.dispose();
            }
          } finally {
            codec.dispose();
          }
        }
        throw StateError('No pudimos reducir la foto. Prueba con otra imagen.');
      } finally {
        descriptor.dispose();
      }
    } finally {
      buffer.dispose();
    }
  }
}
