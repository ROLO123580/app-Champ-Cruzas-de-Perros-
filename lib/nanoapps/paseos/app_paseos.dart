import 'package:flutter/material.dart';

import '../paseadores/app_paseadores.dart';
import '../paseadores/nanofunciones/gestionar_paseadores/gestionar_paseadores.dart';
import '../reservas/app_reservas.dart';
import '../reservas/nanofunciones/gestionar_reservas/gestionar_reservas.dart';

import '../comunidad/app_comunidad.dart';
import '../comunidad/nanofunciones/gestionar_comunidad/gestionar_comunidad.dart';

class AppPaseos extends StatelessWidget {
  const AppPaseos({
    super.key,
    required this.controlador,
    this.paseadores,
    this.reservas,
    this.onContactar,
  });
  final GestionarComunidad controlador;
  final GestionarPaseadores? paseadores;
  final GestionarReservas? reservas;
  final Future<bool> Function(String)? onContactar;

  @override
  Widget build(BuildContext context) => DefaultTabController(
    length: 3,
    child: Column(
      children: [
        const TabBar(
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: [
            Tab(text: 'Compartidos'),
            Tab(text: 'Paseadores'),
            Tab(text: 'Mi agenda'),
          ],
        ),
        Expanded(
          child: TabBarView(
            children: [
              AppComunidad(controlador: controlador, soloPaseos: true),
              paseadores == null || reservas == null || onContactar == null
                  ? const Center(
                      child: Text(
                        'Inicia sesión para coordinar con paseadores.',
                      ),
                    )
                  : AppPaseadores(
                      controlador: paseadores!,
                      reservas: reservas!,
                      onContactar: onContactar!,
                    ),
              reservas == null || onContactar == null
                  ? const Center(
                      child: Text('Inicia sesión para consultar tu agenda.'),
                    )
                  : AppReservas(
                      controlador: reservas!,
                      onContactar: onContactar!,
                      comunidad: controlador,
                    ),
            ],
          ),
        ),
      ],
    ),
  );
}
