import 'dart:async';

import 'package:champ/core/modelos/membership.dart';
import 'package:champ/core/repositorios/membership_local.dart';

/// Solo fixture: estos valores no son planes ni precios publicados de Champ.
PlanMembership planPrueba({int precioMenor = 1250}) => PlanMembership(
  id: 'plan-solo-pruebas',
  nombre: 'Plan de prueba',
  precioMenor: precioMenor,
  decimalesMoneda: 2,
  moneda: 'USD',
  periodo: 'mes de prueba',
  beneficios: const ['Beneficio exclusivo de la prueba'],
  descripcion: 'Fixture sin validez comercial',
);

class MembershipPrueba implements RepositorioMembership {
  MembershipPrueba({this.planes = const []});
  List<PlanMembership> planes;
  EstadoMembership estado = const EstadoMembership.vacio();
  int selecciones = 0;
  Completer<void>? bloqueo;
  bool fallar = false;

  @override
  Future<List<PlanMembership>> cargarPlanes() async {
    if (fallar) throw StateError('Sin conexión de prueba');
    return planes;
  }

  @override
  Future<EstadoMembership> cargarEstado() async => estado;

  @override
  Future<EstadoMembership> seleccionar(String planId) async {
    selecciones++;
    await bloqueo?.future;
    estado = EstadoMembership.seleccionado(
      planes.firstWhere((plan) => plan.id == planId),
    );
    return estado;
  }

  @override
  Future<EstadoMembership> dejarPendiente(
    PlanMembership condicionesVistas,
  ) async {
    estado = EstadoMembership.pendiente(estado.plan!);
    return estado;
  }

  @override
  Future<EstadoMembership> quitar() async {
    estado = const EstadoMembership.vacio();
    return estado;
  }
}
