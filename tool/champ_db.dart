import 'dart:convert';
import 'dart:io';

import 'package:champ/core/persistencia/base_local.dart';
import 'package:champ/core/persistencia/crear_servicio.dart';

/// Cliente de mantenimiento: utiliza la misma API que la aplicación Flutter.
Future<void> main(List<String> args) async {
  final base = BaseLocal(
    crearServicioBase(url: Platform.environment['CHAMP_API_URL']),
  );
  try {
    switch (args.firstOrNull ?? 'estado') {
      case 'estado':
        stdout.writeln(
          const JsonEncoder.withIndent('  ').convert(await base.estado()),
        );
      case 'respaldar':
        stdout.writeln(await base.respaldar());
      case 'listar':
        stdout.writeln(jsonEncode(await base.listar(args[1])));
      case 'guardar':
        final datos = jsonDecode(
          File(args[3]).readAsStringSync(),
        ) as Map<String, dynamic>;
        await base.guardar(args[1], args[2], datos);
        stdout.writeln('Guardado.');
      case 'eliminar':
        await base.eliminar(args[1], args[2]);
        stdout.writeln('Eliminado.');
      default:
        throw ArgumentError(
          'Usa estado, respaldar, listar colección, guardar colección id archivo.json o eliminar colección id.',
        );
    }
  } finally {
    await base.cerrar();
  }
}
