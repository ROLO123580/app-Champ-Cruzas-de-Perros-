import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:champ/core/modelos/comunidad.dart';
import 'package:champ/core/repositorios/comunidad.dart';
import 'package:champ/nanoapps/comunidad/app_comunidad.dart';
import 'package:champ/nanoapps/comunidad/nanofunciones/gestionar_comunidad/gestionar_comunidad.dart';
import 'package:champ/nanoapps/chat_eventos/app_chat_eventos.dart';
import 'package:champ/nanoapps/eventos/app_eventos.dart';
import 'package:champ/nanoapps/eventos/vistas/formulario_evento.dart';

class ComunidadPrueba implements RepositorioComunidad {
  @override
  final String uid = 'visitante';
  final cambios = StreamController<void>.broadcast();
  bool fallaEnvio = false;
  bool fallaPublicacion = false;
  late EventoChamp actual = EventoChamp(
    id: 'parque',
    autorUid: 'organizador',
    autorNombre: 'Ana',
    datos: BorradorEvento(
      titulo: 'Encuentro de amigos',
      descripcion: 'Nos vemos junto a la entrada.',
      lugar: 'Parque del barrio',
      zona: 'Santiago',
      inicio: DateTime.now().add(const Duration(days: 1)),
      cupos: 3,
    ),
    participantes: const {'organizador': 'Ana'},
  );
  final historial = <MensajeEvento>[];
  Stream<T> observar<T>(T Function() leer) async* {
    yield leer();
    await for (final _ in cambios.stream) {
      yield leer();
    }
  }

  void actualizar() => cambios.add(null);
  @override
  Stream<List<EventoChamp>> eventos() => observar(() => [actual]);
  @override
  Stream<EventoChamp?> evento(String id) => observar(() => actual);
  @override
  Stream<List<PublicacionChamp>> publicaciones() => observar(() => []);
  @override
  Stream<List<MensajeEvento>> mensajes(String id) =>
      observar(() => List.of(historial));
  @override
  Future<void> crearEvento(String id, BorradorEvento datos) async {
    actual = EventoChamp(
      id: id,
      autorUid: uid,
      autorNombre: 'Jaime',
      datos: datos,
      participantes: {uid: 'Jaime'},
    );
    actualizar();
  }

  @override
  Future<void> publicar(String id, String texto) async {
    if (fallaPublicacion) throw StateError('No se pudo publicar.');
  }

  @override
  Future<void> participar(String id, bool inscribir) async {
    final miembros = Map<String, String>.from(actual.participantes);
    if (inscribir) {
      miembros[uid] = 'Jaime';
    } else {
      miembros.remove(uid);
    }
    actual = EventoChamp(
      id: actual.id,
      autorUid: actual.autorUid,
      autorNombre: actual.autorNombre,
      datos: actual.datos,
      participantes: miembros,
    );
    actualizar();
  }

  @override
  Future<void> cancelar(String id) async {}
  @override
  Future<void> enviar(String evento, String id, String texto) async {
    if (fallaEnvio) throw StateError('No se pudo enviar.');
    historial.add(
      MensajeEvento(
        id: id,
        uid: uid,
        nombre: 'Jaime',
        texto: texto,
        fecha: DateTime.now(),
      ),
    );
    actualizar();
  }
}

void main() {
  late ComunidadPrueba repositorio;
  late GestionarComunidad gestion;
  setUp(() {
    repositorio = ComunidadPrueba();
    gestion = GestionarComunidad(repositorio);
  });
  tearDown(() async {
    gestion.dispose();
    await repositorio.cambios.close();
  });

  test('No admite eventos pasados ni cupos fuera del rango', () {
    BorradorEvento borrador(int cupos, DateTime inicio) => BorradorEvento(
      titulo: 'Parque',
      descripcion: 'Nos encontramos',
      lugar: 'Entrada',
      zona: 'Centro',
      inicio: inicio,
      cupos: cupos,
    );
    expect(
      () => borrador(1, DateTime.now().add(const Duration(days: 1))).validar(),
      throwsStateError,
    );
    expect(
      () => borrador(
        3,
        DateTime.now().subtract(const Duration(days: 1)),
      ).validar(),
      throwsStateError,
    );
  });

  testWidgets(
    'Muro conecta detalle, inscripcion y chat; un fallo conserva el mensaje',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: AppComunidad(controlador: gestion)),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Encuentro de amigos'), findsOneWidget);
      await tester.ensureVisible(find.text('Encuentro de amigos'));
      await tester.tap(find.text('Encuentro de amigos'));
      await tester.pumpAndSettle();
      expect(find.byType(AppEventos), findsOneWidget);
      await tester.ensureVisible(find.byKey(const Key('inscripcion_evento')));
      await tester.tap(find.byKey(const Key('inscripcion_evento')));
      await tester.pumpAndSettle();
      expect(find.text('Cancelar mi inscripción'), findsOneWidget);
      await tester.ensureVisible(find.byKey(const Key('abrir_chat_evento')));
      await tester.tap(find.byKey(const Key('abrir_chat_evento')));
      await tester.pumpAndSettle();
      expect(find.byType(AppChatEventos), findsOneWidget);
      repositorio.fallaEnvio = true;
      await tester.enterText(
        find.byKey(const Key('mensaje_evento')),
        'Nos vemos en la entrada',
      );
      await tester.tap(find.byKey(const Key('enviar_mensaje_evento')));
      await tester.pumpAndSettle();
      expect(find.text('No se pudo enviar.'), findsOneWidget);
      expect(
        tester
            .widget<TextField>(find.byKey(const Key('mensaje_evento')))
            .controller!
            .text,
        'Nos vemos en la entrada',
      );
      repositorio.fallaEnvio = false;
      await tester.tap(find.byKey(const Key('enviar_mensaje_evento')));
      await tester.pumpAndSettle();
      expect(repositorio.historial.single.texto, 'Nos vemos en la entrada');
      expect(
        tester
            .widget<TextField>(find.byKey(const Key('mensaje_evento')))
            .controller!
            .text,
        isEmpty,
      );
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'Crear un evento abre su detalle despues de confirmar la publicacion',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: AppComunidad(controlador: gestion)),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('crear_evento')));
      await tester.pumpAndSettle();
      for (final campo in <String, String>{
        'Nombre del encuentro': 'Paseo de domingo',
        'Parque o punto de encuentro': 'Parque central',
        'Ciudad o comuna': 'Santiago',
        'Cuéntanos el plan y cómo encontrarse':
            'Nos vemos en la entrada principal',
      }.entries) {
        await tester.enterText(
          find.widgetWithText(TextFormField, campo.key),
          campo.value,
        );
      }
      await tester.ensureVisible(find.byKey(const Key('elegir_fecha_evento')));
      await tester.tap(find.byKey(const Key('elegir_fecha_evento')));
      await tester.pumpAndSettle();
      await tester.tap(
        find
            .descendant(
              of: find.byType(DatePickerDialog),
              matching: find.byType(TextButton),
            )
            .last,
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find
            .descendant(
              of: find.byType(TimePickerDialog),
              matching: find.byType(TextButton),
            )
            .last,
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.byKey(const Key('publicar_evento')),
        400,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.byKey(const Key('publicar_evento')));
      await tester.pumpAndSettle();
      expect(find.byType(AppEventos), findsOneWidget);
      expect(find.text('Paseo de domingo'), findsOneWidget);
      expect(repositorio.actual.participantes.keys, contains(repositorio.uid));
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets('Salir del evento revoca la vista del chat inmediatamente', (
    tester,
  ) async {
    await repositorio.participar('parque', true);
    await tester.pumpWidget(
      MaterialApp(
        home: AppChatEventos(
          controlador: gestion.chatGestion,
          eventoId: 'parque',
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('mensaje_evento')), findsOneWidget);
    await repositorio.participar('parque', false);
    await tester.pumpAndSettle();
    expect(find.text('Este chat es para los participantes'), findsOneWidget);
    expect(find.byKey(const Key('mensaje_evento')), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
    'Formulario valida antes de publicar y permite recuperar texto ante fallo del muro',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: FormularioEvento(controlador: gestion.eventosGestion),
        ),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.byKey(const Key('publicar_evento')),
        400,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.byKey(const Key('publicar_evento')));
      await tester.pumpAndSettle();
      expect(find.text('Elige una fecha y hora futuras.'), findsOneWidget);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: AppComunidad(controlador: gestion)),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Publicar en el muro'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextField, '¿Qué quieres compartir?'),
        'Una idea para el parque',
      );
      repositorio.fallaPublicacion = true;
      await tester.tap(find.widgetWithText(FilledButton, 'Publicar'));
      await tester.pumpAndSettle();
      expect(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('No se pudo publicar.'),
        ),
        findsOneWidget,
      );
      expect(find.text('Una idea para el parque'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets('Las cuatro pantallas funcionan a 320 px con texto ampliado', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await repositorio.participar('parque', true);
    for (final pantalla in <Widget>[
      Scaffold(body: AppComunidad(controlador: gestion)),
      FormularioEvento(controlador: gestion.eventosGestion),
      AppEventos(
        controlador: gestion.eventosGestion,
        controladorChat: gestion.chatGestion,
        eventoId: 'parque',
      ),
      AppChatEventos(controlador: gestion.chatGestion, eventoId: 'parque'),
    ]) {
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(1.5)),
            child: child!,
          ),
          home: pantalla,
        ),
      );
      await tester.pumpAndSettle();
      expect(
        tester.takeException(),
        isNull,
        reason: pantalla.runtimeType.toString(),
      );
      await tester.pumpWidget(const SizedBox());
    }
  });
}
