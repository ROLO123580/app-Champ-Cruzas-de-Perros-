import 'package:flutter/services.dart';

import '../persistencia/base_local.dart';
import '../persistencia/crear_servicio.dart';
import '../repositorios/chat_local.dart';
import '../repositorios/cruces_local.dart';
import '../repositorios/datos_iniciales.dart';
import '../repositorios/membership_local.dart';

class ServiciosChamp {
  ServiciosChamp({
    BaseLocal? base,
    this.leerLegado,
    this.cargarFotoSemilla,
    this.sembrarPlanesReferencia = true,
  }) : base = base ?? BaseLocal(crearServicioBase());
  static final predeterminados = ServiciosChamp();
  final BaseLocal base;
  final Future<String?> Function(String)? leerLegado;
  final Future<Uint8List?> Function(String)? cargarFotoSemilla;
  final bool sembrarPlanesReferencia;
  late final iniciales = DatosIniciales(
    base,
    leerLegado: leerLegado,
    cargarFotoSemilla: cargarFotoSemilla ?? _fotoEmpaquetada,
  );
  late final chat = RepositorioChatLocal(base, iniciales);
  late final cruces = RepositorioCrucesLocal(base, iniciales);
  late final membership = RepositorioMembershipLocal(
    base,
    sembrarReferenciaFenix: sembrarPlanesReferencia,
  );
  Future<void> cerrar() => base.cerrar();
}

Future<Uint8List?> _fotoEmpaquetada(String id) async {
  final datos = await rootBundle.load('assets/catalogo/$id.jpg');
  return datos.buffer.asUint8List(datos.offsetInBytes, datos.lengthInBytes);
}
