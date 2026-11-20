import 'package:champ/app_champ.dart';
import 'package:champ/core/modelos/cruces.dart';
import 'package:champ/core/repositorios/legado/preferencias_cruces.dart';
import 'package:champ/nanoapps/cruces/app_cruces.dart';
import 'package:champ/nanoapps/cruces/nanofunciones/gestionar_cruces/gestionar_cruces.dart';
import 'package:champ/nanoapps/inicio/app_inicio.dart';
import 'package:champ/nanoapps/mis_perros/app_mis_perros.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'soporte/preferencias_prueba.dart';

void main() {
  testWidgets(
    'Inicio, Mis perros y Cruces comparten el perfil y su historial',
    (tester) async {
      tester.view.physicalSize = const Size(1300, 1100);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final preferencias = PreferenciasPrueba();
      final cruces = GestionarCruces(
        almacen: PersistirCruces(preferencias: preferencias),
      );
      addTearDown(cruces.dispose);
      await cruces.cargar();
      await cruces.guardarPerfil(
        const PerfilPerro(
          id: 'perro-compartido',
          nombre: 'Toby',
          raza: 'Mestizo',
          sexo: 'Macho',
          edadMeses: 24,
          ciudad: 'Santiago',
          responsable: 'Rolo',
          descripcion: 'Le gusta pasear.',
        ),
      );
      await cruces.decidir('demo-luna', DecisionCruce.gusta);
      await tester.pumpWidget(
        MaterialApp(home: ChampShell(controladorCruces: cruces)),
      );
      await tester.pumpAndSettle();
      expect(find.byType(AppInicio), findsOneWidget);
      expect(find.text('Champ · Inicio'), findsOneWidget);
      await tester.tap(find.byKey(const Key('inicio_ver_perfil')));
      await tester.pumpAndSettle();
      expect(find.byType(AppMisPerros), findsOneWidget);
      expect(find.text('Toby'), findsWidgets);
      await tester.tap(find.widgetWithText(ListTile, 'Cruces'));
      await tester.pumpAndSettle();
      expect(find.byType(AppCruces), findsOneWidget);
      expect(find.text('Mi perro: Toby'), findsOneWidget);
      expect(find.text('Matches (1)'), findsOneWidget);
      await tester.tap(find.widgetWithText(ListTile, 'Inicio'));
      await tester.pumpAndSettle();
      expect(find.byType(AppInicio), findsOneWidget);
      expect(find.text('Toby'), findsOneWidget);
      expect(cruces.matches, hasLength(1));
      final restaurado = GestionarCruces(
        almacen: PersistirCruces(preferencias: preferencias),
      );
      addTearDown(restaurado.dispose);
      await restaurado.cargar();
      expect(restaurado.miPerro!.id, 'perro-compartido');
      expect(restaurado.matches, hasLength(1));
      await tester.pumpWidget(const SizedBox());
    },
  );
}
