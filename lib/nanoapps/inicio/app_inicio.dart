import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/modelos/sesion.dart';
import '../cruces/nanofunciones/gestionar_cruces/gestionar_cruces.dart';

/// Resume los datos de Cruces y entrega la navegación al orquestador.
class AppInicio extends StatefulWidget {
  const AppInicio({
    super.key,
    required this.controlador,
    required this.onSeleccion,
    this.usuario,
  });

  final GestionarCruces controlador;
  final UsuarioChamp? usuario;
  final ValueChanged<String> onSeleccion;

  @override
  State<AppInicio> createState() => _AppInicioState();
}

class _AppInicioState extends State<AppInicio> {
  GestionarCruces get cruces => widget.controlador;

  @override
  void initState() {
    super.initState();
    unawaited(cruces.cargar());
  }

  @override
  void didUpdateWidget(covariant AppInicio oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controlador != widget.controlador) {
      unawaited(cruces.cargar());
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: cruces,
    builder: (context, _) {
      final colores = Theme.of(context).colorScheme;
      final nombre = widget.usuario?.nombre?.trim();
      return SingleChildScrollView(
        key: const Key('inicio_contenido'),
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1040),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  nombre == null || nombre.isEmpty
                      ? 'Bienvenido a Champ'
                      : 'Hola, $nombre',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colores.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Un lugar para cuidar su perfil, descubrir conexiones y conversar.',
                ),
                const SizedBox(height: 24),
                if (cruces.ocupado) ...[
                  const LinearProgressIndicator(
                    semanticsLabel: 'Cargando tus datos',
                  ),
                  const SizedBox(height: 12),
                ],
                if (cruces.error != null) ...[
                  _error(context),
                  const SizedBox(height: 16),
                ],
                if (!cruces.cargado && cruces.error == null)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 28),
                    child: Text(
                      'Cargando tu perfil y actividad…',
                      textAlign: TextAlign.center,
                    ),
                  ),
                if (cruces.cargado) ...[
                  _perfil(context),
                  const SizedBox(height: 24),
                  Text(
                    'Tu actividad en Cruces',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  _actividad(context),
                  const SizedBox(height: 8),
                  Text(
                    'Catálogo de demostración: los perfiles e intereses recibidos '
                    'son de ejemplo. '
                    '${cruces.enCuenta ? 'Tu ficha y tus decisiones se guardan en tu cuenta.' : 'Tus decisiones y matches se guardan localmente.'}',
                    style: Theme.of(context).textTheme.bodySmall
                        ?.copyWith(color: colores.onSurfaceVariant),
                  ),
                  const SizedBox(height: 28),
                ],
                Text(
                  '¿Qué quieres hacer?',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                _accesos(context),
              ],
            ),
          ),
        ),
      );
    },
  );

  Widget _error(BuildContext context) => Card.filled(
    color: Theme.of(context).colorScheme.errorContainer,
    margin: EdgeInsets.zero,
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            cruces.cargado
                ? 'No pudimos completar el cambio'
                : 'No pudimos cargar tu actividad',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(cruces.error!),
          if (!cruces.cargado) ...[
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: cruces.ocupado
                  ? null
                  : () => unawaited(cruces.cargar()),
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ],
      ),
    ),
  );

  Widget _perfil(BuildContext context) {
    final perro = cruces.miPerro;
    final colores = Theme.of(context).colorScheme;
    final resumen = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          perro == null ? 'Su historia empieza contigo' : perro.nombre,
          style: Theme.of(context).textTheme.headlineSmall
              ?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Text(
          perro == null
              ? 'Crea el perfil de tu perro y cuéntanos cómo es para empezar a descubrir.'
              : '${perro.raza} · ${perro.edad}\n${perro.ciudad}',
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          key: const Key('inicio_ver_perfil'),
          onPressed: () => widget.onSeleccion('Mis perros'),
          icon: Icon(perro == null ? Icons.add : Icons.pets_outlined),
          label: Text(
            perro == null ? 'Crear perfil de mi perro' : 'Ver mi perro',
          ),
        ),
      ],
    );
    final foto = ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: SizedBox.square(
        dimension: 104,
        child: perro?.foto == null
            ? ColoredBox(
                color: colores.primaryContainer,
                child: Icon(Icons.pets, size: 48, color: colores.primary),
              )
            : Image.memory(
                perro!.foto!,
                fit: BoxFit.cover,
                cacheWidth: 312,
                semanticLabel: 'Foto de ${perro.nombre}',
                errorBuilder: (_, _, _) => ColoredBox(
                  color: colores.primaryContainer,
                  child: Icon(Icons.pets, size: 48, color: colores.primary),
                ),
              ),
      ),
    );
    return Card.filled(
      color: colores.surfaceContainerLow,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: LayoutBuilder(
          builder: (context, constraints) => constraints.maxWidth < 480
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [foto, const SizedBox(height: 20), resumen],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    foto,
                    const SizedBox(width: 24),
                    Expanded(child: resumen),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _actividad(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final ancho = constraints.maxWidth < 500
          ? constraints.maxWidth
          : (constraints.maxWidth - 12) / 2;
      return Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          _indicador(
            context,
            ancho,
            icono: Icons.favorite_outline,
            valor: cruces.matches.length,
            etiqueta: 'Matches guardados',
          ),
          _indicador(
            context,
            ancho,
            icono: Icons.thumb_up_outlined,
            valor: cruces.intereses,
            etiqueta: 'Intereses que enviaste',
          ),
        ],
      );
    },
  );

  Widget _indicador(
    BuildContext context,
    double ancho, {
    required IconData icono,
    required int valor,
    required String etiqueta,
  }) => SizedBox(
    width: ancho,
    child: Card.outlined(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icono, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 12),
            Text('$valor', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 4),
            Text(etiqueta),
          ],
        ),
      ),
    ),
  );

  Widget _accesos(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final ancho = constraints.maxWidth < 600
          ? constraints.maxWidth
          : (constraints.maxWidth - 12) / 2;
      return Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          _acceso(
            ancho,
            'Mis perros',
            'Consulta y edita su perfil.',
            Icons.pets,
          ),
          _acceso(
            ancho,
            'Cruces',
            'Explora el catálogo de demostración y revisa tus matches.',
            Icons.explore_outlined,
          ),
          _acceso(
            ancho,
            'Chat',
            'Abre tus conversaciones o conecta con otra cuenta.',
            Icons.chat_bubble_outline,
          ),
          _acceso(
            ancho,
            'Configuración',
            'Consulta tus datos locales y crea un respaldo.',
            Icons.settings_outlined,
          ),
        ],
      );
    },
  );

  Widget _acceso(double ancho, String titulo, String detalle, IconData icono) =>
      SizedBox(
        width: ancho,
        child: Card.outlined(
          margin: EdgeInsets.zero,
          clipBehavior: Clip.antiAlias,
          child: ListTile(
            key: ValueKey('inicio_acceso_$titulo'),
            contentPadding: const EdgeInsets.all(16),
            leading: Icon(icono),
            title: Text(titulo),
            subtitle: Text(detalle),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => widget.onSeleccion(titulo),
          ),
        ),
      );
}
