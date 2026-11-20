import 'package:flutter/foundation.dart';

import '../../../../core/servicios/seleccionar_foto.dart';
import '../../../../core/modelos/cruces.dart';
import '../../../../core/repositorios/contratos.dart';
import '../../../../core/servicios/servicios_champ.dart';
import '../../../../core/servicios/identificadores.dart';
import 'nanoactividades/persistir_cruces/persistir_cruces.dart';
import 'nanoactividades/seleccionar_foto/seleccionar_foto.dart';

class GestionarCruces extends ChangeNotifier {
  GestionarCruces({AlmacenCruces? almacen, SeleccionarFoto? selector})
    : _almacen = PersistirCrucesActividad(
        almacen ?? ServiciosChamp.predeterminados.cruces,
      ),
      _selector = SeleccionarFotoCruceActividad(selector ?? SeleccionarFoto());
  final PersistirCrucesActividad _almacen;
  final SeleccionarFotoCruceActividad _selector;
  List<PerfilPerro> perfiles = const [];
  EstadoCruces _estado = EstadoCruces();
  bool get enCuenta => _almacen.enCuenta;
  bool cargado = false;
  bool ocupado = false;
  bool _cerrado = false;
  String? error;
  String raza = '';
  String ciudad = '';
  PerfilPerro? get miPerro => _estado.miPerro;
  String identidadParaPerfil() =>
      miPerro?.id ?? 'local-${crearIdentificador()}';
  List<PerfilPerro> get pendientes => perfiles
      .where(
        (p) =>
            miPerro != null &&
            p.sexo != miPerro!.sexo &&
            !_estado.decisiones.containsKey(p.id) &&
            (raza.isEmpty || p.raza == raza) &&
            (ciudad.isEmpty || p.ciudad == ciudad),
      )
      .toList();
  List<PerfilPerro> get matches =>
      perfiles.where((p) => _estado.matches.contains(p.id)).toList();
  int get intereses =>
      _estado.decisiones.values.where((v) => v == DecisionCruce.gusta).length;
  void _avisar() {
    if (!_cerrado) notifyListeners();
  }

  Future<bool> _ejecutar(Future<void> Function() accion) async {
    if (ocupado || _cerrado) return false;
    ocupado = true;
    error = null;
    _avisar();
    try {
      await accion();
      return true;
    } catch (e) {
      error = e is StateError
          ? e.message.toString()
          : 'No pudimos guardar los cambios. Intenta nuevamente.';
      return false;
    } finally {
      ocupado = false;
      _avisar();
    }
  }

  Future<void> cargar() async {
    if (cargado) return;
    await _ejecutar(() async {
      _estado = await _almacen.cargar();
      perfiles = List.unmodifiable(await _almacen.perfiles());
      cargado = true;
    });
  }

  void filtrar({required String porRaza, required String porCiudad}) {
    raza = porRaza;
    ciudad = porCiudad;
    _avisar();
  }

  Future<Uint8List?> seleccionarFoto() async {
    Uint8List? foto;
    await _ejecutar(() async {
      foto = await _selector.ejecutar();
    });
    return foto;
  }

  Future<bool> guardarPerfil(PerfilPerro perro) async {
    if (!cargado) return false;
    return _ejecutar(() async {
      if ([
            perro.nombre,
            perro.raza,
            perro.ciudad,
            perro.responsable,
          ].any((s) => s.trim().isEmpty) ||
          perro.edadMeses < 1 ||
          perro.edadMeses > 300 ||
          !['Macho', 'Hembra'].contains(perro.sexo)) {
        throw StateError('Completa los datos del perro y su responsable.');
      }
      // El perfil se edita manteniendo su identidad y su historial.
      if (miPerro != null && perro.id != miPerro!.id) {
        throw StateError('No se puede cambiar la identidad del perfil.');
      }
      _estado = await _almacen.guardarPerfil(perro);
    });
  }

  Future<bool> decidir(String id, DecisionCruce decision) async {
    if (!cargado || miPerro == null) return false;
    return _ejecutar(() async {
      final perfil = pendientes.where((p) => p.id == id).firstOrNull;
      if (perfil == null) {
        throw StateError('Este perfil ya no está disponible.');
      }
      _estado = await _almacen.decidir(_estado, perfil, decision);
    });
  }

  String? conversacionPara(String perfilId) =>
      miPerro != null && _estado.matches.contains(perfilId)
      ? 'cruce:${miPerro!.id}:$perfilId'
      : null;

  Future<void> revisarDescartados() async {
    if (!cargado) return;
    await _ejecutar(() async {
      _estado = await _almacen.revisarDescartados(_estado);
    });
  }

  @override
  void dispose() {
    _cerrado = true;
    super.dispose();
  }
}
