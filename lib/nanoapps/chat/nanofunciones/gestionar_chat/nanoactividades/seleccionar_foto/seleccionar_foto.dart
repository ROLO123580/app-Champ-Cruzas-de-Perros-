import 'dart:typed_data';

import 'package:champ/core/servicios/seleccionar_foto.dart';

class SeleccionarFotoActividad {
  SeleccionarFotoActividad(this.selector);
  final SeleccionarFoto selector;
  Future<Uint8List?> ejecutar() => selector.ejecutar();
}
