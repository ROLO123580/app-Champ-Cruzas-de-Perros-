import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/modelos/cruces.dart';
import '../cruces/nanofunciones/gestionar_cruces/gestionar_cruces.dart';
import '../cruces/widgets/editar_perfil.dart';

class AppMisPerros extends StatefulWidget {
  const AppMisPerros({super.key, required this.controlador, this.onIrCruces});

  final GestionarCruces controlador;
  final VoidCallback? onIrCruces;

  @override
  State<AppMisPerros> createState() => _AppMisPerrosState();
}

class _AppMisPerrosState extends State<AppMisPerros> {
  bool _editando = false;

  @override
  void initState() {
    super.initState();
    unawaited(widget.controlador.cargar());
  }

  @override
  void didUpdateWidget(covariant AppMisPerros oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controlador != widget.controlador) {
      unawaited(widget.controlador.cargar());
    }
  }

  Future<void> _editar() async {
    final controlador = widget.controlador;
    if (_editando || controlador.ocupado || !controlador.cargado) return;
    setState(() => _editando = true);
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => EditarPerfilCruce(cruces: controlador),
    );
    if (mounted) setState(() => _editando = false);
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.controlador,
    builder: (context, _) {
      final controlador = widget.controlador;
      final perro = controlador.miPerro;
      final ocupado = controlador.ocupado || _editando;
      return Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1040),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                'Mis perros',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                controlador.enCuenta
                    ? 'Tu ficha activa es privada y pertenece a esta cuenta.'
                    : 'Su ficha, siempre a mano.',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 20),
              if (controlador.ocupado) ...[
                const LinearProgressIndicator(
                  semanticsLabel: 'Cargando o guardando el perfil de tu perro',
                ),
                const SizedBox(height: 16),
              ],
              if (controlador.error != null) ...[
                Card(
                  color: Theme.of(context).colorScheme.errorContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Semantics(
                          liveRegion: true,
                          child: Text(controlador.error!),
                        ),
                        if (!controlador.cargado) ...[
                          const SizedBox(height: 8),
                          TextButton.icon(
                            onPressed: ocupado ? null : controlador.cargar,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Reintentar'),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              if (!controlador.cargado && controlador.error == null)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(child: Text('Cargando el perfil de tu perro…')),
                ),
              if (controlador.cargado && perro == null) _sinPerfil(ocupado),
              if (controlador.cargado && perro != null) _perfil(perro, ocupado),
              const SizedBox(height: 20),
              const _DatoPerfil(
                icono: Icons.info_outline,
                etiqueta: 'Tu perfil local',
                valor:
                    'Por ahora puedes guardar un perro en este equipo. '
                    'Mis perros y Cruces comparten la misma ficha; '
                    'los cambios se conservan al cerrar la app.',
              ),
            ],
          ),
        ),
      );
    },
  );

  Widget _sinPerfil(bool ocupado) => Card(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Icon(
            Icons.pets,
            size: 64,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 20),
          Text(
            'Presenta a tu compañero',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 12),
          const Text(
            'Añade su nombre, foto y datos para completar su ficha '
            'y empezar a descubrir perfiles en Cruces.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: ocupado ? null : _editar,
            icon: const Icon(Icons.add),
            label: const Text(
              'Crear perfil de mi perro',
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    ),
  );

  Widget _perfil(PerfilPerro perro, bool ocupado) => Card(
    clipBehavior: Clip.antiAlias,
    child: LayoutBuilder(
      builder: (context, constraints) {
        final detalles = Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                perro.nombre,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(perro.raza, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 24),
              _DatoPerfil(
                icono: Icons.cake_outlined,
                etiqueta: 'Edad',
                valor: perro.edad,
              ),
              const SizedBox(height: 16),
              _DatoPerfil(
                icono: Icons.pets_outlined,
                etiqueta: 'Sexo',
                valor: perro.sexo,
              ),
              const SizedBox(height: 16),
              _DatoPerfil(
                icono: Icons.place_outlined,
                etiqueta: 'Ciudad',
                valor: perro.ciudad,
              ),
              const SizedBox(height: 16),
              _DatoPerfil(
                icono: Icons.person_outline,
                etiqueta: 'Responsable',
                valor: perro.responsable,
              ),
              const SizedBox(height: 24),
              Text('Cómo es', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(
                perro.descripcion.trim().isEmpty
                    ? 'Aún no has añadido una descripción.'
                    : perro.descripcion,
              ),
              const SizedBox(height: 24),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  FilledButton.icon(
                    onPressed: ocupado ? null : _editar,
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Editar perfil'),
                  ),
                  if (widget.onIrCruces != null)
                    OutlinedButton.icon(
                      onPressed: ocupado ? null : widget.onIrCruces,
                      icon: const Icon(Icons.explore_outlined),
                      label: const Text('Ir a Cruces'),
                    ),
                ],
              ),
            ],
          ),
        );
        if (constraints.maxWidth >= 720) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(width: 300, child: _foto(perro)),
              Expanded(child: detalles),
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [_foto(perro), detalles],
        );
      },
    ),
  );

  Widget _foto(PerfilPerro perro) {
    final fondo = Theme.of(context).colorScheme.primaryContainer;
    final marcador = ColoredBox(
      color: fondo,
      child: Center(
        child: Icon(
          Icons.pets,
          size: 72,
          color: Theme.of(context).colorScheme.onPrimaryContainer,
          semanticLabel: 'Perfil de ${perro.nombre} sin foto disponible',
        ),
      ),
    );
    return SizedBox(
      height: 280,
      child: perro.foto == null
          ? marcador
          : Image.memory(
              perro.foto!,
              fit: BoxFit.cover,
              width: double.infinity,
              cacheWidth: 800,
              semanticLabel: 'Foto de ${perro.nombre}',
              errorBuilder: (_, error, stack) => marcador,
            ),
    );
  }
}

class _DatoPerfil extends StatelessWidget {
  const _DatoPerfil({
    required this.icono,
    required this.etiqueta,
    required this.valor,
  });
  final IconData icono;
  final String etiqueta;
  final String valor;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icono, size: 22, color: Theme.of(context).colorScheme.primary),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(etiqueta, style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 4),
            Text(valor),
          ],
        ),
      ),
    ],
  );
}
