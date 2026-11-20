import 'package:champ/core/persistencia/base_local.dart';

class AdministrarBaseActividad {
  AdministrarBaseActividad(this.base);
  final BaseLocal base;
  Future<Map<String, dynamic>> consultar() => base.estado();
  Future<String> respaldar() => base.respaldar();
}
