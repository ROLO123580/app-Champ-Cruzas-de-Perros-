import 'package:flutter/foundation.dart';

import '../../../../core/modelos/membership.dart';
import '../../../../core/repositorios/membership_local.dart';
import 'nanoactividades/persistir_carro/persistir_carro.dart';

class GestionarCarro extends ChangeNotifier {
  GestionarCarro({required RepositorioMembership repositorio, this.onCambio})
    : _persistir = PersistirCarroActividad(repositorio);

  final PersistirCarroActividad _persistir;
  final Future<void> Function()? onCambio;
  EstadoMembership estado = const EstadoMembership.vacio();
  bool cargado = false;
  bool ocupado = false;
  bool _cerrado = false;
  String? error;

  Future<bool> _ejecutar(Future<void> Function() accion) async {
    if (ocupado || _cerrado) return false;
    ocupado = true;
    error = null;
    notifyListeners();
    try {
      await accion();
      return true;
    } catch (excepcion) {
      error = excepcion is StateError
          ? excepcion.message.toString()
          : 'No pudimos actualizar el Carro. Intenta nuevamente.';
      return false;
    } finally {
      ocupado = false;
      if (!_cerrado) notifyListeners();
    }
  }

  Future<void> cargar() async {
    await _ejecutar(() async {
      estado = await _persistir.cargar();
      cargado = true;
    });
  }

  Future<bool> dejarPendiente() async {
    final plan = estado.plan;
    if (!cargado || plan == null) return false;
    return _ejecutar(() async {
      estado = await _persistir.dejarPendiente(plan);
      await onCambio?.call();
    });
  }

  Future<bool> quitar() async {
    if (!cargado) return false;
    return _ejecutar(() async {
      estado = await _persistir.quitar();
      await onCambio?.call();
    });
  }

  @override
  void dispose() {
    _cerrado = true;
    super.dispose();
  }
}
