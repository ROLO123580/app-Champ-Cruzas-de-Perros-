import 'package:flutter/material.dart';

import '../../nanoapps/carro/app_carro.dart';
import '../../nanoapps/membership/app_membership.dart';
import '../../nanoapps/membership/nanofunciones/gestionar_membership/gestionar_membership.dart';

/// Conecta las NanoApps de planes y carro con una misma persistencia local.
class AppComercio extends StatelessWidget {
  const AppComercio({
    super.key,
    required this.modulo,
    required this.controlador,
    required this.onIrCarro,
    required this.onIrMembership,
  });
  final String modulo;
  final GestionarMembership controlador;
  final VoidCallback onIrCarro;
  final VoidCallback onIrMembership;

  @override
  Widget build(BuildContext context) => modulo == 'Carro'
      ? AppCarro(
          repositorio: controlador.repositorio,
          onIrMembership: onIrMembership,
          onCambio: controlador.actualizar,
        )
      : AppMembership(controlador: controlador, onIrCarro: onIrCarro);
}
