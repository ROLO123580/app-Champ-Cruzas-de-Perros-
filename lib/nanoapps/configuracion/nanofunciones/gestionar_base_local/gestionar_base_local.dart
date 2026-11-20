import 'package:flutter/foundation.dart';
import 'package:champ/core/persistencia/base_local.dart';

import 'nanoactividades/administrar_base/administrar_base.dart';

class GestionarBaseLocal extends ChangeNotifier {
  GestionarBaseLocal(BaseLocal base)
    : _actividad = AdministrarBaseActividad(base);
  final AdministrarBaseActividad _actividad;
  Map<String, dynamic>? estado;
  String? respaldo;
  String? error;
  bool ocupado = false;
  bool _cerrado = false;
  Future<void> _hacer(Future<void> Function() accion) async {
    if (ocupado || _cerrado) return;
    ocupado = true;
    error = null;
    notifyListeners();
    try {
      await accion();
    } catch (_) {
      error = 'No se pudo acceder a los datos locales. Comprueba el servicio e intenta nuevamente.';
    } finally {
      ocupado = false;
      if (!_cerrado) notifyListeners();
    }
  }

  Future<void> cargar() => _hacer(() async {
    estado = await _actividad.consultar();
  });
  Future<void> respaldar() => _hacer(() async {
    respaldo = await _actividad.respaldar();
  });
  @override
  void dispose() {
    _cerrado = true;
    super.dispose();
  }
}
