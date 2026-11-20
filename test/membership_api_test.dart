import 'package:champ/core/catalogos/membership_fenix.dart';
import 'package:champ/core/modelos/membership.dart';
import 'package:champ/core/persistencia/base_local.dart';
import 'package:champ/core/persistencia/crear_servicio.dart';
import 'package:champ/core/persistencia/sqlite_local.dart';
import 'package:champ/core/repositorios/membership_local.dart';
import 'package:champ/microapps/datos_locales/api/servidor_local.dart';
import 'package:flutter_test/flutter_test.dart';

import 'soporte/base_prueba.dart';
import 'soporte/membership_prueba.dart';

void main() {
  test('API importa Fénix una vez sin reemplazar planes locales ni resucitar eliminados', () async {
    final carpeta = await carpetaPrueba();
    final servidor = ServidorLocal(BaseLocal(SqliteLocal(directorio: carpeta)));
    await servidor.iniciar(puerto: 0);
    final base = BaseLocal(
      crearServicioBase(url: 'http://127.0.0.1:${servidor.puerto}'),
    );
    addTearDown(() async {
      await base.cerrar();
      await servidor.cerrar();
    });
    final origen = planesReferenciaFenix()[1];
    final editado = origen.toJson()
      ..['precioMenor'] = 2350
      ..['descripcion'] = 'Edición local que debe conservarse';
    await base.guardar('planes_membership', origen.id, editado);
    final repositorio = RepositorioMembershipLocal(base);
    final resultados = await Future.wait([
      repositorio.cargarPlanes(),
      RepositorioMembershipLocal(base).cargarPlanes(),
    ]);
    for (final planes in resultados) {
      expect(planes.map((plan) => plan.nombre), ['Free', 'Pro', 'Elite']);
      expect(planes[1].precioMenor, 2350);
      expect(planes[1].descripcion, 'Edición local que debe conservarse');
    }
    expect(await base.listar('planes_membership'), hasLength(3));
    expect(
      await base.obtener('meta', ImportarCatalogoMembershipFenix.version),
      isNotNull,
    );
    await base.eliminar('planes_membership', 'fenix_elite');
    expect(await repositorio.cargarPlanes(), hasLength(2));
    final seleccionado = await repositorio.seleccionar('fenix_free');
    expect(seleccionado.plan!.requiereAdaptacion, isTrue);
    expect(seleccionado.membresiaActiva, isFalse);
    expect((await base.estado())['version'], 3);
  });

  test(
    'no confirma condiciones cambiadas por otra ventana con el mismo ID',
    () async {
      final carpeta = await carpetaPrueba();
      final servidor = ServidorLocal(
        BaseLocal(SqliteLocal(directorio: carpeta)),
      );
      await servidor.iniciar(puerto: 0);
      BaseLocal conectar() => BaseLocal(
        crearServicioBase(url: 'http://127.0.0.1:${servidor.puerto}'),
      );
      final primeraBase = conectar();
      final segundaBase = conectar();
      addTearDown(() async {
        await primeraBase.cerrar();
        await segundaBase.cerrar();
        await servidor.cerrar();
      });
      final primera = RepositorioMembershipLocal(
        primeraBase,
        sembrarReferenciaFenix: false,
      );
      final segunda = RepositorioMembershipLocal(
        segundaBase,
        sembrarReferenciaFenix: false,
      );
      final visto = planPrueba();
      await primeraBase.guardar('planes_membership', visto.id, visto.toJson());
      await primera.seleccionar(visto.id);
      final actualizado = planPrueba(precioMenor: 2000);
      await segundaBase.guardar(
        'planes_membership',
        actualizado.id,
        actualizado.toJson(),
      );
      await segunda.seleccionar(actualizado.id);
      await expectLater(primera.dejarPendiente(visto), throwsStateError);
      final estado = await primera.cargarEstado();
      expect(estado.contratacion, EstadoContratacion.seleccionado);
      expect(estado.plan!.precioMenor, actualizado.precioMenor);
      expect(estado.membresiaActiva, isFalse);
      expect(
        (await primera.dejarPendiente(actualizado)).contratacion,
        EstadoContratacion.pendiente,
      );
    },
  );

  test('API conserva catálogo, selección y pendiente al reiniciar sin tocar fichas o matches', () async {
    final carpeta = await carpetaPrueba();
    var servidor = ServidorLocal(BaseLocal(SqliteLocal(directorio: carpeta)));
    await servidor.iniciar(puerto: 0);
    BaseLocal abrir() => BaseLocal(
      crearServicioBase(url: 'http://127.0.0.1:${servidor.puerto}'),
    );
    var base = abrir();
    addTearDown(() async {
      await base.cerrar();
      await servidor.cerrar();
    });
    var repositorio = RepositorioMembershipLocal(
      base,
      sembrarReferenciaFenix: false,
    );
    expect(await repositorio.cargarPlanes(), isEmpty);
    await base.guardar('perfiles', 'ficha-conservar', {
      'id': 'ficha-conservar',
      'nombre': 'Ficha antes de Membership',
    });
    await base.registrarLike('perro-a', 'perro-b', 'gusta');
    await base.registrarLike('perro-b', 'perro-a', 'gusta');
    final plan = planPrueba();
    await base.guardar('planes_membership', plan.id, plan.toJson());
    final seleccionado = await repositorio.seleccionar(plan.id);
    expect(seleccionado.contratacion, EstadoContratacion.seleccionado);
    expect(seleccionado.membresiaActiva, isFalse);
    await base.cerrar();
    await servidor.cerrar();

    servidor = ServidorLocal(BaseLocal(SqliteLocal(directorio: carpeta)));
    await servidor.iniciar(puerto: 0);
    base = abrir();
    repositorio = RepositorioMembershipLocal(
      base,
      sembrarReferenciaFenix: false,
    );
    expect((await repositorio.cargarEstado()).plan!.nombre, plan.nombre);
    expect(
      (await repositorio.cargarEstado()).contratacion,
      EstadoContratacion.seleccionado,
    );
    await repositorio.dejarPendiente(plan);
    await repositorio.dejarPendiente(plan);
    await base.cerrar();
    await servidor.cerrar();

    servidor = ServidorLocal(BaseLocal(SqliteLocal(directorio: carpeta)));
    await servidor.iniciar(puerto: 0);
    base = abrir();
    repositorio = RepositorioMembershipLocal(
      base,
      sembrarReferenciaFenix: false,
    );
    final restaurado = await repositorio.cargarEstado();
    expect(restaurado.contratacion, EstadoContratacion.pendiente);
    expect(restaurado.plan!.precioMenor, plan.precioMenor);
    expect(restaurado.membresiaActiva, isFalse);
    expect(await base.listar('membership'), hasLength(1));
    expect(
      (await base.obtener('perfiles', 'ficha-conservar'))!['nombre'],
      'Ficha antes de Membership',
    );
    await base.registrarLike('perro-b', 'perro-a', 'gusta');
    expect(await base.matches('perro-a'), hasLength(1));
    expect((await base.estado())['version'], 3);
  });

  test('API rechaza planes ausentes, inválidos, retirados o con condiciones cambiadas', () async {
    final carpeta = await carpetaPrueba();
    final servidor = ServidorLocal(BaseLocal(SqliteLocal(directorio: carpeta)));
    await servidor.iniciar(puerto: 0);
    final base = BaseLocal(
      crearServicioBase(url: 'http://127.0.0.1:${servidor.puerto}'),
    );
    addTearDown(() async {
      await base.cerrar();
      await servidor.cerrar();
    });
    final repositorio = RepositorioMembershipLocal(
      base,
      sembrarReferenciaFenix: false,
    );
    await expectLater(repositorio.seleccionar('ausente'), throwsStateError);
    expect((await repositorio.cargarEstado()).plan, isNull);
    final plan = planPrueba();
    await base.guardar('planes_membership', plan.id, plan.toJson());
    await repositorio.seleccionar(plan.id);
    await base.guardar(
      'planes_membership',
      plan.id,
      planPrueba(precioMenor: 2000).toJson(),
    );
    await expectLater(repositorio.dejarPendiente(plan), throwsStateError);
    expect(
      (await repositorio.cargarEstado()).contratacion,
      EstadoContratacion.seleccionado,
    );
    expect((await repositorio.cargarEstado()).plan!.precioMenor, 1250);
    await base.guardar(
      'planes_membership',
      plan.id,
      plan.toJson()..['disponible'] = false,
    );
    expect(await repositorio.cargarPlanes(), isEmpty);
    await expectLater(repositorio.seleccionar(plan.id), throwsStateError);
    await base.guardar(
      'planes_membership',
      plan.id,
      plan.toJson()..['precioMenor'] = -1,
    );
    await expectLater(repositorio.cargarPlanes(), throwsFormatException);
    expect((await repositorio.cargarEstado()).membresiaActiva, isFalse);
  });
}
