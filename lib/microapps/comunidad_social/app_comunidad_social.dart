import 'package:flutter/material.dart';

import '../../nanoapps/paseadores/nanofunciones/gestionar_paseadores/gestionar_paseadores.dart';
import '../../nanoapps/reservas/nanofunciones/gestionar_reservas/gestionar_reservas.dart';

import '../../nanoapps/comunidad/app_comunidad.dart';
import '../../nanoapps/paseos/app_paseos.dart';
import '../../nanoapps/comunidad/nanofunciones/gestionar_comunidad/gestionar_comunidad.dart';

class AppComunidadSocial extends StatelessWidget {
  const AppComunidadSocial({
    super.key,
    this.controlador,
    this.soloPaseos = false,
    this.misEventos = false,
    this.paseadores,
    this.reservas,
    this.onContactar,
  });
  final GestionarComunidad? controlador;
  final bool soloPaseos, misEventos;
  final GestionarPaseadores? paseadores;
  final GestionarReservas? reservas;
  final Future<bool> Function(String)? onContactar;
  @override
  Widget build(BuildContext context) => controlador == null
      ? const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Inicia sesión para participar en la comunidad de Champ.',
            ),
          ),
        )
      : soloPaseos
      ? AppPaseos(
          controlador: controlador!,
          paseadores: paseadores,
          reservas: reservas,
          onContactar: onContactar,
        )
      : AppComunidad(
          controlador: controlador!,
          soloPaseos: soloPaseos,
          misEventos: misEventos,
        );
}
