import 'package:champ/core/modelos/cruces.dart';
import 'package:champ/core/persistencia/base_local.dart';
import 'package:champ/core/persistencia/sqlite_local.dart';
import 'package:champ/core/servicios/servicios_champ.dart';
import 'package:champ/nanoapps/cruces/nanofunciones/gestionar_cruces/gestionar_cruces.dart';
import 'package:flutter_test/flutter_test.dart';

import 'soporte/base_prueba.dart';

PerfilPerro perfil({String nombre = 'Toby'}) => PerfilPerro(
  id: 'toby',
  nombre: nombre,
  raza: 'Golden retriever',
  sexo: 'Macho',
  edadMeses: 36,
  ciudad: 'Santiago',
  responsable: 'Rolo',
  descripcion: 'Juguetón',
);

Future<(ServiciosChamp, ServiciosChamp, GestionarCruces)> conexiones() async {
  final carpeta = await carpetaPrueba();
  ServiciosChamp abrir() => ServiciosChamp(
    base: BaseLocal(SqliteLocal(directorio: carpeta)),
    leerLegado: (_) async => null,
    cargarFotoSemilla: (_) async => null,
  );
  final a = abrir();
  final b = abrir();
  addTearDown(a.cerrar);
  addTearDown(b.cerrar);
  final funcion = GestionarCruces(almacen: a.cruces);
  addTearDown(funcion.dispose);
  await funcion.cargar();
  await funcion.guardarPerfil(perfil());
  return (a, b, funcion);
}

void main() {
  test(
    'editar la ficha no sustituye una decisión más reciente de otra conexión',
    () async {
      final (a, b, funcion) = await conexiones();
      await funcion.decidir('demo-nala', DecisionCruce.pasar);
      await b.base.registrarLike('toby', 'demo-nala', 'gusta');
      expect(
        await funcion.guardarPerfil(perfil(nombre: 'Toby actualizado')),
        isTrue,
      );
      expect(
        (await a.cruces.cargar()).decisiones['demo-nala'],
        DecisionCruce.gusta,
      );
      expect(funcion.intereses, 1);
      expect(funcion.miPerro!.nombre, 'Toby actualizado');
    },
  );

  test('volver a ver descartados respeta los likes actuales sin restaurar snapshots', () async {
    final (a, b, funcion) = await conexiones();
    await funcion.decidir('demo-nala', DecisionCruce.gusta);
    await b.base.registrarLike('toby', 'demo-nala', 'pasar');
    await b.base.registrarLike('toby', 'demo-kira', 'gusta');
    await funcion.revisarDescartados();
    final estado = await a.cruces.cargar();
    expect(estado.decisiones.containsKey('demo-nala'), isFalse);
    expect(estado.decisiones['demo-kira'], DecisionCruce.gusta);
    expect(estado.matches, {'demo-kira'});
    expect(funcion.matches.single.id, 'demo-kira');
  });

  test(
    'editar una ficha no regenera el interés demo que ya fue cambiado',
    () async {
      final (a, b, funcion) = await conexiones();
      await b.base.registrarLike('demo-luna', 'toby', 'pasar');
      await funcion.guardarPerfil(perfil(nombre: 'Toby editado'));
      await funcion.decidir('demo-luna', DecisionCruce.gusta);
      expect((await a.cruces.cargar()).matches, isEmpty);
      expect((await a.base.likes('demo-luna')).single['decision'], 'pasar');
    },
  );
}
