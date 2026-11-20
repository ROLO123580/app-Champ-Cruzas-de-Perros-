import 'package:flutter/widgets.dart';

import '../../nanoapps/login/app_login.dart';
import '../../nanoapps/login/nanofunciones/gestionar_sesion/gestionar_sesion.dart';

class AppAcceso extends StatelessWidget {
  const AppAcceso({super.key, required this.controlador});
  final GestionarSesion controlador;

  @override
  Widget build(BuildContext context) => AppLogin(controlador: controlador);
}
