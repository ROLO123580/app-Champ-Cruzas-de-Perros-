import 'package:champ/core/controladores/operacion_comunidad.dart';
import 'package:champ/core/modelos/comunidad.dart';
import 'package:champ/core/repositorios/comunidad.dart';

import 'nanoactividades/consultar_evento/consultar_evento.dart';
import 'nanoactividades/crear_evento/crear_evento.dart';
import 'nanoactividades/inscribir_evento/inscribir_evento.dart';
import 'nanoactividades/cancelar_evento/cancelar_evento.dart';

class GestionarEventos extends OperacionComunidad {
  GestionarEventos(RepositorioComunidad repositorio)
    : uid = repositorio.uid,
      _consultar = ConsultarEvento(repositorio),
      _crear = CrearEvento(repositorio),
      _inscribir = InscribirEvento(repositorio),
      _cancelar = CancelarEvento(repositorio);
  final String uid;
  final ConsultarEvento _consultar;
  final CrearEvento _crear;
  final InscribirEvento _inscribir;
  final CancelarEvento _cancelar;
  Stream<EventoChamp?> observar(String id) => _consultar.ejecutar(id);
  Future<bool> crear(String id, BorradorEvento datos) =>
      proteger(() => _crear.ejecutar(id, datos));
  Future<bool> participar(String id, bool inscribir) =>
      proteger(() => _inscribir.ejecutar(id, inscribir));
  Future<bool> cancelar(String id) => proteger(() => _cancelar.ejecutar(id));
}
