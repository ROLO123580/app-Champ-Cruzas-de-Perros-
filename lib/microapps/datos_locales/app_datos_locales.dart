import 'package:flutter/material.dart';

import '../../core/persistencia/base_local.dart';
import '../../nanoapps/configuracion/app_configuracion.dart';

class AppDatosLocales extends StatelessWidget {
  const AppDatosLocales({super.key, required this.base});
  final BaseLocal base;
  @override
  Widget build(BuildContext context) => AppConfiguracion(base: base);
}
