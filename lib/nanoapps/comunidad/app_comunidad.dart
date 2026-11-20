import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/modelos/comunidad.dart';
import '../../core/servicios/identificadores.dart';
import 'nanofunciones/gestionar_comunidad/gestionar_comunidad.dart';

import 'package:champ/ui/componentes_comunidad.dart';
import 'package:champ/nanoapps/eventos/vistas/formulario_evento.dart';
import 'package:champ/nanoapps/eventos/app_eventos.dart';

class AppComunidad extends StatefulWidget {
  const AppComunidad({
    super.key,
    required this.controlador,
    this.soloPaseos = false,
    this.misEventos = false,
  });
  final GestionarComunidad controlador;
  final bool soloPaseos, misEventos;
  @override
  State<AppComunidad> createState() => _AppComunidadState();
}

class _AppComunidadState extends State<AppComunidad> {
  String _filtro = 'Todo', _zona = '';
  GestionarComunidad get gestion => widget.controlador;
  @override
  void initState() {
    super.initState();
    gestion.iniciar();
  }

  @override
  void didUpdateWidget(covariant AppComunidad oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controlador != gestion) gestion.iniciar();
  }

  Future<void> _crear() async {
    final id = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => FormularioEvento(
          controlador: gestion.eventosGestion,
          esPaseo: widget.soloPaseos,
        ),
      ),
    );
    if (id != null && mounted) unawaited(_detalle(id));
  }

  Future<void> _detalle(String id) => Navigator.of(context).push<void>(
    MaterialPageRoute(
      builder: (_) => AppEventos(
        controlador: gestion.eventosGestion,
        controladorChat: gestion.chatGestion,
        eventoId: id,
      ),
    ),
  );
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: gestion,
    builder: (context, _) {
      final tema = Theme.of(context);
      final eventos = gestion.eventos.where((e) {
        if (widget.soloPaseos && !e.datos.esPaseo) return false;
        if ((widget.misEventos || _filtro == 'Mis eventos') &&
            !e.participantes.containsKey(gestion.uid)) {
          return false;
        }
        if (_filtro == 'Eventos' && e.datos.esPaseo) return false;
        if (_filtro == 'Paseos' && !e.datos.esPaseo) return false;
        return '${e.datos.zona} ${e.datos.lugar}'.toLowerCase().contains(_zona);
      }).toList()..sort((a, b) => a.datos.inicio.compareTo(b.datos.inicio));
      final mostrarMuro =
          !widget.soloPaseos &&
          !widget.misEventos &&
          _filtro == 'Todo' &&
          _zona.isEmpty;
      return MarcoComunidad(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: tema.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  widget.soloPaseos
                      ? Icons.directions_walk
                      : Icons.groups_outlined,
                  size: 36,
                ),
                const SizedBox(height: 12),
                Text(
                  widget.misEventos
                      ? 'Tus planes, sus conversaciones'
                      : widget.soloPaseos
                      ? 'Mejor pasear en compañía'
                      : 'Un parque. Nuevos amigos.',
                  style: tema.textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  widget.misEventos
                      ? 'Abre un evento para conversar con sus participantes.'
                      : 'Comparte con la comunidad, organiza un encuentro y disfruta con tu perro.',
                ),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 12,
                  runSpacing: 10,
                  children: [
                    FilledButton.icon(
                      key: const Key('crear_evento'),
                      onPressed: gestion.ocupado ? null : _crear,
                      icon: const Icon(Icons.add),
                      label: Text(
                        widget.soloPaseos ? 'Organizar paseo' : 'Crear evento',
                      ),
                    ),
                    if (!widget.soloPaseos && !widget.misEventos)
                      OutlinedButton.icon(
                        onPressed: gestion.ocupado
                            ? null
                            : () => showDialog<void>(
                                context: context,
                                barrierDismissible: false,
                                builder: (_) => _Publicar(controlador: gestion),
                              ),
                        icon: const Icon(Icons.edit_outlined),
                        label: const Text('Publicar en el muro'),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          if (!widget.misEventos) ...[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final filtro
                    in widget.soloPaseos
                        ? ['Todo', 'Mis eventos']
                        : ['Todo', 'Eventos', 'Paseos', 'Mis eventos'])
                  ChoiceChip(
                    label: Text(filtro),
                    selected: _filtro == filtro,
                    onSelected: (_) => setState(() => _filtro = filtro),
                  ),
              ],
            ),
            const SizedBox(height: 12),
          ],
          TextField(
            decoration: const InputDecoration(
              labelText: 'Buscar por parque, ciudad o comuna',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            onChanged: (v) => setState(() => _zona = v.trim().toLowerCase()),
          ),
          const SizedBox(height: 16),
          if (gestion.cargando)
            const LinearProgressIndicator(semanticsLabel: 'Cargando comunidad'),
          if (gestion.error != null)
            AvisoComunidad(
              gestion.error!,
              onReintentar: gestion.ocupado
                  ? null
                  : () => gestion.iniciar(reintentar: true),
            ),
          if (!gestion.cargando && gestion.error == null && eventos.isEmpty)
            const VacioComunidad(
              titulo: 'El próximo encuentro puede ser el tuyo',
              texto: 'Todavía no hay eventos para esta selección. Organiza uno o cambia los filtros.',
            ),
          if (eventos.isNotEmpty) ...[
            Text(
              widget.misEventos
                  ? 'Mis eventos y paseos'
                  : 'Encuentros de la comunidad',
              style: tema.textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            for (final evento in eventos) _tarjeta(evento),
          ],
          if (mostrarMuro) ...[
            const SizedBox(height: 24),
            Text('El muro de Champ', style: tema.textTheme.titleLarge),
            const SizedBox(height: 12),
            if (!gestion.cargando &&
                gestion.error == null &&
                gestion.publicaciones.isEmpty)
              const VacioComunidad(
                titulo: 'Una comunidad empieza conversando',
                texto: 'Comparte una idea o invita a otros a conocer su parque favorito.',
                icono: Icons.forum_outlined,
              ),
            for (final p in gestion.publicaciones)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p.autorNombre, style: tema.textTheme.titleMedium),
                      Text(
                        fechaComunidad(p.fecha),
                        style: tema.textTheme.bodySmall,
                      ),
                      const SizedBox(height: 12),
                      SelectableText(p.texto),
                      if (p.pendiente) const Text('Pendiente de confirmación'),
                    ],
                  ),
                ),
              ),
          ],
          const SizedBox(height: 20),
          const Text(
            'Mostramos los últimos 100 eventos y publicaciones. Los horarios se muestran en la hora local de este equipo.',
          ),
        ],
      );
    },
  );
  Widget _tarjeta(EventoChamp e) => Card(
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: () => _detalle(e.id),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                Chip(
                  avatar: Icon(
                    e.datos.esPaseo
                        ? Icons.directions_walk
                        : Icons.park_outlined,
                    size: 18,
                  ),
                  label: Text(
                    e.datos.esPaseo
                        ? 'Paseo compartido'
                        : 'Evento en comunidad',
                  ),
                ),
                if (e.cancelado)
                  const Chip(label: Text('Cancelado'))
                else if (e.finalizado)
                  const Chip(label: Text('Finalizado')),
                if (e.participantes.containsKey(gestion.uid))
                  const Chip(label: Text('Participas')),
              ],
            ),
            const SizedBox(height: 8),
            Text(e.datos.titulo, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text('${e.datos.lugar} · ${e.datos.zona}'),
            Text(fechaComunidad(e.datos.inicio)),
            const SizedBox(height: 12),
            Text(
              '${e.participantes.length}/${e.datos.cupos} participantes · Organiza ${e.autorNombre}',
            ),
            if (e.pendiente) const Text('Pendiente de confirmación'),
            const SizedBox(height: 8),
            const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Ver evento'),
                SizedBox(width: 6),
                Icon(Icons.arrow_forward, size: 18),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

class _Publicar extends StatefulWidget {
  const _Publicar({required this.controlador});
  final GestionarComunidad controlador;
  @override
  State<_Publicar> createState() => _PublicarState();
}

class _PublicarState extends State<_Publicar> {
  final texto = TextEditingController();
  final id = crearIdentificador();
  @override
  void dispose() {
    texto.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.controlador,
    builder: (context, _) => PopScope(
      canPop: !widget.controlador.ocupado,
      child: AlertDialog(
        title: const Text('Comparte con la comunidad'),
        content: SizedBox(
          width: 480,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: texto,
                  maxLines: 5,
                  maxLength: 2000,
                  enabled: !widget.controlador.ocupado,
                  decoration: const InputDecoration(
                    labelText: '¿Qué quieres compartir?',
                    border: OutlineInputBorder(),
                  ),
                ),
                if (widget.controlador.error != null)
                  AvisoComunidad(widget.controlador.error!),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: widget.controlador.ocupado
                ? null
                : () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: widget.controlador.ocupado
                ? null
                : () async {
                    final ok = await widget.controlador.publicar(
                      id,
                      texto.text,
                    );
                    if (ok && context.mounted) Navigator.pop(context);
                  },
            child: Text(
              widget.controlador.ocupado ? 'Publicando…' : 'Publicar',
            ),
          ),
        ],
      ),
    ),
  );
}
