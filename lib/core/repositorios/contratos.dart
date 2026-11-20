import '../modelos/chat.dart';
import '../modelos/cruces.dart';
import '../catalogos/perfiles_demo.dart';

abstract class AlmacenChat {
  Future<List<Conversacion>> cargar();
  Future<void> guardar(List<Conversacion> conversaciones);
}

abstract class AlmacenCruces {
  bool get enCuenta => false;
  Future<EstadoCruces> cargar();
  Future<void> guardar(EstadoCruces estado);
  Future<EstadoCruces> guardarPerfil(PerfilPerro perro) async {
    final actual = await cargar();
    final nuevo = EstadoCruces(
      miPerro: perro,
      decisiones: actual.decisiones,
      matches: actual.matches,
    );
    await guardar(nuevo);
    return nuevo;
  }

  Future<EstadoCruces> revisarDescartados(EstadoCruces actual) async {
    final nuevo = EstadoCruces(
      miPerro: actual.miPerro,
      decisiones: Map.fromEntries(
        actual.decisiones.entries.where((e) => e.value != DecisionCruce.pasar),
      ),
      matches: actual.matches,
    );
    await guardar(nuevo);
    return nuevo;
  }

  Future<List<PerfilPerro>> cargarPerfiles() async =>
      CargarPerfiles().ejecutar();
  // Adaptación del almacenamiento anterior para conservar pruebas y migración.
  Future<EstadoCruces> decidir(
    EstadoCruces actual,
    PerfilPerro destino,
    DecisionCruce decision,
  ) async {
    final nuevo = EstadoCruces(
      miPerro: actual.miPerro,
      decisiones: {...actual.decisiones, destino.id: decision},
      matches: {
        ...actual.matches,
        if (decision == DecisionCruce.gusta && destino.interesDemo) destino.id,
      },
    );
    await guardar(nuevo);
    return nuevo;
  }
}
