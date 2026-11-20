import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:file_selector/file_selector.dart';

class SeleccionarFoto {
  Future<Uint8List?> ejecutar() async {
    final archivo = await openFile(
      acceptedTypeGroups: [
        const XTypeGroup(
          label: 'Fotos',
          extensions: ['jpg', 'jpeg', 'png', 'webp'],
          mimeTypes: ['image/jpeg', 'image/png', 'image/webp'],
          uniformTypeIdentifiers: [
            'public.jpeg',
            'public.png',
            'org.webmproject.webp',
          ],
        ),
      ],
    );
    if (archivo == null) return null;
    if (await archivo.length() > 1024 * 1024) {
      throw StateError('Selecciona una foto de hasta 1 MB.');
    }
    final bytes = await archivo.readAsBytes();
    final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
    try {
      final descriptor = await ui.ImageDescriptor.encoded(buffer);
      try {
        if (descriptor.width * descriptor.height > 20000000) {
          throw StateError('La foto supera los 20 megapíxeles.');
        }
      } finally {
        descriptor.dispose();
      }
    } finally {
      buffer.dispose();
    }
    return bytes;
  }
}
