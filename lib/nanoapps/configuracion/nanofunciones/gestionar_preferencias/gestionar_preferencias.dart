import 'package:flutter/material.dart';
import 'package:champ/core/controladores/operacion_comunidad.dart';
import 'package:champ/core/repositorios/preferencias.dart';

import 'nanoactividades/persistir_preferencias/persistir_preferencias.dart';

class GestionarPreferencias extends OperacionComunidad {
  GestionarPreferencias(RepositorioPreferencias repositorio)
    : _actividad = PersistirPreferencias(repositorio);
  final PersistirPreferencias _actividad;
  ThemeMode modo = ThemeMode.system;
  double escala = 1;
  bool cargado = false;
  Future<bool> cargar() => proteger(() async {
    final d = await _actividad.cargar();
    if (destruido) return;
    modo =
        ThemeMode.values.where((m) => m.name == d['modo']).firstOrNull ??
        ThemeMode.system;
    escala = [1.0, 1.15, 1.3].contains(d['escala'])
        ? (d['escala'] as num).toDouble()
        : 1;
    cargado = true;
  });
  Future<bool> cambiar({ThemeMode? tema, double? texto}) => proteger(() async {
    if (!cargado) throw StateError('Carga primero las preferencias.');
    final nuevoModo = tema ?? modo, nuevaEscala = texto ?? escala;
    if (![1.0, 1.15, 1.3].contains(nuevaEscala)) {
      throw StateError('Tamaño de texto no válido.');
    }
    await _actividad.guardar({'modo': nuevoModo.name, 'escala': nuevaEscala});
    if (destruido) return;
    modo = nuevoModo;
    escala = nuevaEscala;
  });
  Future<bool> restablecer() => proteger(() async {
    await _actividad.guardar({'modo': ThemeMode.system.name, 'escala': 1.0});
    if (destruido) return;
    modo = ThemeMode.system;
    escala = 1;
    cargado = true;
  });
}

class PreferenciasChamp extends InheritedNotifier<GestionarPreferencias> {
  const PreferenciasChamp({
    super.key,
    required GestionarPreferencias controlador,
    required super.child,
  }) : super(notifier: controlador);
  static GestionarPreferencias? de(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<PreferenciasChamp>()?.notifier;
}
