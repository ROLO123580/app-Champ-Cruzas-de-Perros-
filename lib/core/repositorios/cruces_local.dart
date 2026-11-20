import 'dart:convert';

import '../modelos/cruces.dart';
import '../persistencia/base_local.dart';
import 'contratos.dart';
import 'datos_iniciales.dart';
import 'fotos_locales.dart';

class RepositorioCrucesLocal extends AlmacenCruces {
  RepositorioCrucesLocal(this.base, this.iniciales)
    : fotos = FotosLocales(base);
  final BaseLocal base;
  final DatosIniciales iniciales;
  final FotosLocales fotos;

  Future<void> _importar() async {
    if (await base.obtener('meta', 'preferencias_cruces_v1') != null) return;
    final antiguo = await iniciales.leerLegado('champ.cruces.v1');
    if (antiguo == null) return;
    final legado = EstadoCruces.fromJson(
      jsonDecode(antiguo) as Map<String, dynamic>,
    );
    final perro = legado.miPerro;
    final cambios = <Map<String, dynamic>>[];
    if (perro != null) {
      cambios.add({
        'tipo': 'guardar_si_nuevo',
        'coleccion': 'perfiles',
        'id': perro.id,
        'datos': await fotos.aDisco(perro.toJson()),
      });
      cambios.add({
        'tipo': 'guardar_si_nuevo',
        'coleccion': 'ajustes',
        'id': 'perro_activo',
        'datos': {'id': 'perro_activo', 'perroId': perro.id},
      });
      for (final p in await cargarPerfiles()) {
        if (p.interesDemo && p.id != perro.id) {
          cambios.add({
            'tipo': 'like_si_nuevo',
            'origen': p.id,
            'destino': perro.id,
            'decision': 'gusta',
          });
        }
      }
      for (final e in legado.decisiones.entries) {
        cambios.add({
          'tipo': 'like_si_nuevo',
          'origen': perro.id,
          'destino': e.key,
          'decision': e.value.name,
        });
      }
      for (final id in legado.matches) {
        cambios.addAll([
          {
            'tipo': 'like_si_nuevo',
            'origen': id,
            'destino': perro.id,
            'decision': 'gusta',
          },
          {
            'tipo': 'like_si_nuevo',
            'origen': perro.id,
            'destino': id,
            'decision': 'gusta',
          },
        ]);
      }
    }
    cambios.add({
      'tipo': 'guardar',
      'coleccion': 'meta',
      'id': 'preferencias_cruces_v1',
      'datos': {'id': 'preferencias_cruces_v1'},
    });
    await base.aplicar(cambios);
  }

  @override
  Future<EstadoCruces> cargar() async {
    await iniciales.preparar();
    await _importar();
    return _leerEstado();
  }

  Future<EstadoCruces> _leerEstado() async {
    final activo = await base.obtener('ajustes', 'perro_activo');
    if (activo == null) return EstadoCruces();
    final id = activo['perroId'] as String;
    final perfil = await base.obtener('perfiles', id);
    if (perfil == null) throw StateError('No se encontró la ficha activa.');
    return EstadoCruces(
      miPerro: PerfilPerro.fromJson(await fotos.desdeDisco(perfil)),
      decisiones: {
        for (final l in await base.likes(id))
          l['destino'] as String: DecisionCruce.values.byName(
            l['decision'] as String,
          ),
      },
      matches: {
        for (final m in await base.matches(id))
          (m['perro_a'] == id ? m['perro_b'] : m['perro_a']) as String,
      },
    );
  }

  @override
  Future<List<PerfilPerro>> cargarPerfiles() async {
    await iniciales.preparar();
    final lista = <PerfilPerro>[];
    for (final p in await base.listar('perfiles')) {
      lista.add(PerfilPerro.fromJson(await fotos.desdeDisco(p)));
    }
    // Conserva el orden del catálogo de demostración y añade fichas nuevas.
    final orden =
        (await base.obtener('catalogos', 'cruces_demo'))?['perfiles']
            as List? ??
        [];
    int posicion(String id) {
      final n = orden.indexOf(id);
      return n < 0 ? orden.length : n;
    }

    lista.sort((a, b) => posicion(a.id).compareTo(posicion(b.id)));
    return lista;
  }

  @override
  Future<EstadoCruces> guardarPerfil(PerfilPerro perro) async {
    await iniciales.preparar();
    await base.aplicar([
      {
        'tipo': 'guardar',
        'coleccion': 'perfiles',
        'id': perro.id,
        'datos': await fotos.aDisco(perro.toJson()),
      },
      {
        'tipo': 'guardar',
        'coleccion': 'ajustes',
        'id': 'perro_activo',
        'datos': {'id': 'perro_activo', 'perroId': perro.id},
      },
      for (final p in await cargarPerfiles())
        if (p.interesDemo && p.id != perro.id)
          {
            'tipo': 'like_si_nuevo',
            'origen': p.id,
            'destino': perro.id,
            'decision': 'gusta',
          },
    ]);
    return _leerEstado();
  }

  @override
  Future<EstadoCruces> revisarDescartados(EstadoCruces actual) async {
    final id = actual.miPerro?.id;
    if (id == null) return actual;
    // SQL decide sobre la fila actual, sin borrar likes actualizados en otra ventana.
    await base.operar('revisar_descartados', {'origen': id});
    return _leerEstado();
  }

  @override
  Future<void> guardar(EstadoCruces estado) async {
    await iniciales.preparar();
    final perro = estado.miPerro;
    if (perro == null) return;
    final cambios = <Map<String, dynamic>>[
      {
        'tipo': 'guardar',
        'coleccion': 'perfiles',
        'id': perro.id,
        'datos': await fotos.aDisco(perro.toJson()),
      },
      {
        'tipo': 'guardar',
        'coleccion': 'ajustes',
        'id': 'perro_activo',
        'datos': {'id': 'perro_activo', 'perroId': perro.id},
      },
      for (final p in await cargarPerfiles())
        if (p.interesDemo && p.id != perro.id)
          {
            'tipo': 'like',
            'origen': p.id,
            'destino': perro.id,
            'decision': 'gusta',
          },
      for (final e in estado.decisiones.entries)
        {
          'tipo': 'like',
          'origen': perro.id,
          'destino': e.key,
          'decision': e.value.name,
        },
      // Importa también los matches históricos de las preferencias anteriores.
      for (final id in estado.matches) ...[
        {
          'tipo': 'like',
          'origen': id,
          'destino': perro.id,
          'decision': 'gusta',
        },
        {
          'tipo': 'like',
          'origen': perro.id,
          'destino': id,
          'decision': 'gusta',
        },
      ],
    ];
    for (final anterior in await base.likes(perro.id)) {
      if (anterior['decision'] == 'pasar' &&
          !estado.decisiones.containsKey(anterior['destino'])) {
        cambios.add({
          'tipo': 'eliminar_like',
          'origen': perro.id,
          'destino': anterior['destino'],
        });
      }
    }
    await base.aplicar(cambios);
  }

  @override
  Future<EstadoCruces> decidir(
    EstadoCruces actual,
    PerfilPerro destino,
    DecisionCruce decision,
  ) async {
    await base.registrarLike(actual.miPerro!.id, destino.id, decision.name);
    return _leerEstado();
  }
}
