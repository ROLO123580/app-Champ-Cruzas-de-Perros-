import 'package:champ/nanoapps/chat_eventos/nanofunciones/gestionar_chat_eventos/gestionar_chat_eventos.dart';
import 'package:flutter/material.dart';

import 'package:champ/core/modelos/comunidad.dart';

import 'nanofunciones/gestionar_eventos/gestionar_eventos.dart';

import 'package:champ/ui/componentes_comunidad.dart';
import 'package:champ/nanoapps/chat_eventos/app_chat_eventos.dart';

class AppEventos extends StatefulWidget {
  const AppEventos({
    super.key,
    required this.controlador,
    required this.eventoId,
    required this.controladorChat,
  });
  final GestionarEventos controlador;
  final GestionarChatEventos controladorChat;
  final String eventoId;
  @override
  State<AppEventos> createState() => _AppEventosState();
}

class _AppEventosState extends State<AppEventos> {
  late Stream<EventoChamp?> _stream = widget.controlador.observar(
    widget.eventoId,
  );
  Future<void> _cancelar() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Cancelar este evento?'),
        content: const Text(
          'Los participantes verán el evento cancelado. El chat quedará disponible solo para lectura.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Conservar evento'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cancelar evento'),
          ),
        ],
      ),
    );
    if (confirmar == true && mounted) {
      await widget.controlador.cancelar(widget.eventoId);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Detalle del evento')),
    body: StreamBuilder<EventoChamp?>(
      stream: _stream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return MarcoComunidad(
            children: [
              AvisoComunidad(
                'No pudimos cargar este evento.',
                onReintentar: () => setState(
                  () => _stream = widget.controlador.observar(widget.eventoId),
                ),
              ),
            ],
          );
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final e = snapshot.data;
        if (e == null) {
          return const VacioComunidad(
            titulo: 'Evento no disponible',
            texto: 'Puede que el evento ya no esté disponible.',
          );
        }
        return ListenableBuilder(
          listenable: widget.controlador,
          builder: (context, _) {
            final gestion = widget.controlador;
            final miembro = e.participantes.containsKey(gestion.uid);
            final propio = e.autorUid == gestion.uid;
            final bloqueado = gestion.ocupado || e.pendiente;
            return MarcoComunidad(
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.park_outlined, size: 44),
                      const SizedBox(height: 12),
                      Text(
                        e.datos.titulo,
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 8),
                      Text('Organiza ${e.autorNombre}'),
                      if (e.cancelado)
                        const Chip(label: Text('Evento cancelado'))
                      else if (e.finalizado)
                        const Chip(label: Text('Evento finalizado')),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.place_outlined),
                  title: Text(e.datos.lugar),
                  subtitle: Text(e.datos.zona),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.schedule),
                  title: Text(fechaComunidad(e.datos.inicio)),
                  subtitle: Text(
                    '${e.datos.duracionMinutos} minutos · Hora local de este equipo',
                  ),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.groups_outlined),
                  title: Text('${e.disponibles} cupos disponibles'),
                  subtitle: Text(
                    '${e.participantes.length} de ${e.datos.cupos} participantes, incluyendo al organizador',
                  ),
                ),
                const SizedBox(height: 16),
                SelectableText(e.datos.descripcion),
                const SizedBox(height: 24),
                if (gestion.error != null) AvisoComunidad(gestion.error!),
                if (gestion.ocupado) const LinearProgressIndicator(),
                if (e.pendiente)
                  const Text('Esperando confirmación del evento…'),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    if (!propio)
                      FilledButton.icon(
                        key: const Key('inscripcion_evento'),
                        onPressed:
                            bloqueado ||
                                (!miembro &&
                                    (!e.inscripcionesAbiertas ||
                                        e.disponibles <= 0))
                            ? null
                            : () => gestion.participar(e.id, !miembro),
                        icon: Icon(
                          miembro ? Icons.check : Icons.person_add_alt,
                        ),
                        label: Text(
                          miembro
                              ? 'Cancelar mi inscripción'
                              : e.disponibles <= 0
                              ? 'Sin cupos'
                              : 'Inscribirme',
                        ),
                      ),
                    if (miembro)
                      OutlinedButton.icon(
                        key: const Key('abrir_chat_evento'),
                        onPressed: bloqueado
                            ? null
                            : () => Navigator.of(context).push<void>(
                                MaterialPageRoute(
                                  builder: (_) => AppChatEventos(
                                    controlador: widget.controladorChat,
                                    eventoId: e.id,
                                  ),
                                ),
                              ),
                        icon: const Icon(Icons.chat_bubble_outline),
                        label: const Text('Chat de participantes'),
                      ),
                    if (propio && !e.cancelado && !e.finalizado)
                      TextButton.icon(
                        onPressed: bloqueado ? null : _cancelar,
                        icon: const Icon(Icons.event_busy),
                        label: const Text('Cancelar evento'),
                      ),
                  ],
                ),
                const SizedBox(height: 28),
                Text(
                  'Nos encontramos aquí',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Coordina el punto exacto con el grupo en el chat del evento.',
                ),
                const SizedBox(height: 24),
                Text(
                  'Participantes',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                for (final p in e.participantes.entries)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const CircleAvatar(
                      child: Icon(Icons.person_outline),
                    ),
                    title: Text(p.value),
                    subtitle: p.key == e.autorUid
                        ? const Text('Organizador')
                        : null,
                  ),
              ],
            );
          },
        );
      },
    ),
  );
}
