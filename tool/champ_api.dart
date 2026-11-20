import 'dart:io';

import 'package:champ/core/persistencia/base_local.dart';
import 'package:champ/core/persistencia/sqlite_local.dart';
import 'package:champ/microapps/datos_locales/api/servidor_local.dart';

Future<void> main(List<String> args) async {
  final puerto = args.isEmpty ? 8787 : int.parse(args.single);
  final base = BaseLocal(SqliteLocal());
  final estado = await base.estado();
  final servidor = ServidorLocal(base);
  await servidor.iniciar(puerto: puerto);
  stdout.writeln('Champ API: http://127.0.0.1:${servidor.puerto}');
  stdout.writeln('SQLite: ${estado['ruta']}');
  stdout.writeln('Fotos: ${estado['imagenes']}');
  ProcessSignal.sigint.watch().listen((_) async {
    await servidor.cerrar();
    exit(0);
  });
}
