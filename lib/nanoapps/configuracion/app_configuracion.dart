import 'package:flutter/material.dart';

import '../../core/persistencia/base_local.dart';
import '../../core/servicios/servicios_champ.dart';
import 'nanofunciones/gestionar_base_local/gestionar_base_local.dart';

class AppConfiguracion extends StatefulWidget {
  const AppConfiguracion({super.key, this.base});
  final BaseLocal? base;
  @override
  State<AppConfiguracion> createState() => _AppConfiguracionState();
}

class _AppConfiguracionState extends State<AppConfiguracion> {
  late final funcion = GestionarBaseLocal(
    widget.base ?? ServiciosChamp.predeterminados.base,
  );
  @override
  void initState() {
    super.initState();
    funcion.cargar();
  }

  @override
  void dispose() {
    funcion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: funcion,
    builder: (context, _) => SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Datos de Champ',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 12),
          const Text(
            'Tu base local pertenece a esta aplicación. No necesita cuenta ni plan cloud '
            'y sus datos no tienen fecha de vencimiento.',
          ),
          const SizedBox(height: 20),
          if (funcion.ocupado) const LinearProgressIndicator(),
          if (funcion.error != null) Text(funcion.error!),
          if (funcion.estado != null) ...[
            Text('Base SQLite · versión ${funcion.estado!['version']}'),
            const SizedBox(height: 8),
            SelectableText(funcion.estado!['ruta'] as String),
            const SizedBox(height: 12),
            const Text('Carpeta de fotos'),
            SelectableText(funcion.estado!['imagenes'] as String),
            const SizedBox(height: 12),
            Text(
              '${funcion.estado!['documentos']} registros · ${funcion.estado!['fotos']} fotos · '
              '${funcion.estado!['matches']} matches',
            ),
          ],
          const SizedBox(height: 20),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              OutlinedButton(
                onPressed: funcion.ocupado ? null : funcion.cargar,
                child: const Text('Actualizar'),
              ),
              FilledButton.icon(
                onPressed: funcion.ocupado || funcion.estado == null
                    ? null
                    : funcion.respaldar,
                icon: const Icon(Icons.backup_outlined),
                label: const Text('Respaldar base y fotos'),
              ),
            ],
          ),
          if (funcion.respaldo != null) ...[
            const SizedBox(height: 16),
            const Text('Respaldo verificado'),
            SelectableText(funcion.respaldo!),
          ],
          const SizedBox(height: 16),
          const Text(
            'Conserva una copia de los respaldos en otro disco para poder recuperar tus datos si este equipo falla.',
          ),
        ],
      ),
    ),
  );
}
