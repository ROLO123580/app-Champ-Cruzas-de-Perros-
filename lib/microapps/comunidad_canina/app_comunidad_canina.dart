import 'package:flutter/material.dart';

import '../../core/modelos/sesion.dart';
import '../../nanoapps/inicio/app_inicio.dart';
import '../../nanoapps/mis_perros/app_mis_perros.dart';
import '../../nanoapps/chat/app_chat.dart';
import '../../nanoapps/chat/nanofunciones/gestionar_chat/gestionar_chat.dart';
import '../../nanoapps/cruces/app_cruces.dart';
import '../../nanoapps/cruces/nanofunciones/gestionar_cruces/gestionar_cruces.dart';

/// Compone el inicio, perfil, descubrimiento y conversación con estado compartido.
class AppComunidadCanina extends StatelessWidget {
  const AppComunidadCanina({
    super.key,
    required this.modulo,
    this.chat,
    this.cruces,
    this.conversacionInicial,
    this.usuario,
    this.onSeleccion,
    required this.onAbrirChat,
  });
  final String modulo;
  final GestionarChat? chat;
  final GestionarCruces? cruces;
  final String? conversacionInicial;
  final UsuarioChamp? usuario;
  final ValueChanged<String>? onSeleccion;
  final Future<void> Function(String, String) onAbrirChat;
  @override
  Widget build(BuildContext context) => switch (modulo) {
    'Inicio' => AppInicio(
      controlador: cruces!,
      usuario: usuario,
      onSeleccion: onSeleccion!,
    ),
    'Mis perros' => AppMisPerros(
      controlador: cruces!,
      onIrCruces: onSeleccion == null ? null : () => onSeleccion!('Cruces'),
    ),
    'Chat' => AppChat(
      controlador: chat,
      conversacionInicial: conversacionInicial,
    ),
    _ => AppCruces(controlador: cruces, onAbrirChat: onAbrirChat),
  };
}
