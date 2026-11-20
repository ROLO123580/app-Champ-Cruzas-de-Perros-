import 'package:flutter/foundation.dart';

import '../../../../core/modelos/membership.dart';
import '../../../../core/repositorios/membership_local.dart';
import 'nanoactividades/persistir_membership/persistir_membership.dart';

class GestionarMembership extends ChangeNotifier {
  GestionarMembership({required this.repositorio})
    : _persistir = PersistirMembershipActividad(repositorio);

  final RepositorioMembership repositorio;
  final PersistirMembershipActividad _persistir;
  List<PlanMembership> planes = const [];
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
          : 'No pudimos cargar o guardar los planes. Intenta nuevamente.';
      return false;
    } finally {
      ocupado = false;
      if (!_cerrado) notifyListeners();
    }
  }

  Future<void> cargar() async {
    if (cargado) return;
    await actualizar();
  }

  Future<void> actualizar() async {
    await _ejecutar(() async {
      final nuevosPlanes = await _persistir.planes();
      final nuevoEstado = await _persistir.estado();
      planes = nuevosPlanes;
      estado = nuevoEstado;
      cargado = true;
    });
  }

  Future<bool> seleccionar(String id) async {
    if (!cargado || !planes.any((plan) => plan.id == id)) return false;
    return _ejecutar(() async {
      estado = await _persistir.seleccionar(id);
    });
  }

  @override
  void dispose() {
    _cerrado = true;
    super.dispose();
  }
}
