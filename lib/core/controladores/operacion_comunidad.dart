import 'package:flutter/foundation.dart';

/// Estado comun de una operacion; cada NanoFuncion mantiene su propia instancia.
abstract class OperacionComunidad extends ChangeNotifier {
  bool ocupado = false;
  String? error;
  bool _destruido = false;
  bool get destruido => _destruido;
  Future<bool> proteger(Future<void> Function() accion) async {
    if (ocupado || destruido) return false;
    ocupado = true;
    error = null;
    notifyListeners();
    var exito = false;
    try {
      await accion();
      exito = true;
    } catch (e) {
      error = e is StateError ? e.message.toString() : 'No pudimos confirmar la operación. Conservamos lo escrito; revisa tu conexión e intenta otra vez.';
    } finally {
      ocupado = false;
      if (!destruido) notifyListeners();
    }
    return exito;
  }

  @override
  void dispose() {
    _destruido = true;
    super.dispose();
  }
}
