import 'package:flutter/material.dart';
import 'package:champ/nanoapps/perdidos_encontrados/app_perdidos_encontrados.dart';
import 'package:champ/nanoapps/perdidos_encontrados/nanofunciones/gestionar_avisos/gestionar_avisos.dart';

class AppRescateCanino extends StatelessWidget {
  const AppRescateCanino({
    super.key,
    this.controlador,
    required this.onContactar,
  });
  final GestionarAvisos? controlador;
  final Future<bool> Function(String uid) onContactar;
  @override
  Widget build(BuildContext context) => controlador == null
      ? const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Inicia sesión para publicar avisos y ayudar a encontrar perros.',
            ),
          ),
        )
      : AppPerdidosEncontrados(
          controlador: controlador!,
          onContactar: onContactar,
        );
}
