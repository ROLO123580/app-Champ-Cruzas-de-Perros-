import 'dart:async';

import 'package:flutter/material.dart';

import 'package:champ/core/modelos/comunidad.dart';
import 'package:champ/core/servicios/identificadores.dart';

import 'nanofunciones/gestionar_chat_eventos/gestionar_chat_eventos.dart';

import 'package:champ/ui/componentes_comunidad.dart';

class AppChatEventos extends StatefulWidget {
  const AppChatEventos({
    super.key,
    required this.controlador,
    required this.eventoId,
  });
  final GestionarChatEventos controlador;
  final String eventoId;
  @override
  State<AppChatEventos> createState() => _AppChatEventosState();
}

class _AppChatEventosState extends State<AppChatEventos> {
  final _texto = TextEditingController();
  String _mensajeId = crearIdentificador();
  late Stream<EventoChamp?> _evento = widget.controlador.observarEvento(
    widget.eventoId,
  );
  late Stream<List<MensajeEvento>> _mensajes = widget.controlador.mensajes(
    widget.eventoId,
  );
  Timer? _reloj;
  @override
  void initState() {
    super.initState();
    _reloj = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _reloj?.cancel();
    _texto.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    if (_texto.text.trim().isEmpty) return;
    final ok = await widget.controlador.enviar(
      widget.eventoId,
      _mensajeId,
      _texto.text,
    );
    if (ok && mounted) {
      _texto.clear();
      _mensajeId = crearIdentificador();
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Chat del evento')),
    body: StreamBuilder<EventoChamp?>(
      stream: _evento,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return AvisoComunidad(
            'No pudimos comprobar tu acceso al evento.',
            onReintentar: () => setState(
              () =>
                  _evento = widget.controlador.observarEvento(widget.eventoId),
            ),
          );
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final evento = snapshot.data;
        if (evento == null ||
            !evento.participantes.containsKey(widget.controlador.uid)) {
          return const VacioComunidad(
            titulo: 'Este chat es para los participantes',
            texto: 'Inscríbete en el evento para conversar con el grupo.',
            icono: Icons.lock_outline,
          );
        }
        return ListenableBuilder(
          listenable: widget.controlador,
          builder: (context, _) {
            final gestion = widget.controlador;
            return Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.park_outlined),
                  title: Text(evento.datos.titulo),
                  subtitle: Text(
                    '${evento.datos.lugar} · ${fechaComunidad(evento.datos.inicio)}',
                  ),
                ),
                const Divider(height: 1),
                if (!evento.chatAbierto)
                  const Padding(
                    padding: EdgeInsets.all(12),
                    child: Text(
                      'El evento terminó o se canceló. Puedes consultar el historial.',
                    ),
                  ),
                Expanded(
                  child: StreamBuilder<List<MensajeEvento>>(
                    stream: _mensajes,
                    builder: (context, mensajes) {
                      if (mensajes.hasError) {
                        return AvisoComunidad(
                          'No pudimos cargar los mensajes.',
                          onReintentar: () => setState(
                            () => _mensajes = gestion.mensajes(widget.eventoId),
                          ),
                        );
                      }
                      if (mensajes.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final lista = (mensajes.data ?? []).reversed.toList();
                      if (lista.isEmpty) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(24),
                            child: Text(
                              'Saluda al grupo y acuerden dónde encontrarse.',
                              textAlign: TextAlign.center,
                            ),
                          ),
                        );
                      }
                      return ListView.builder(
                        reverse: true,
                        padding: const EdgeInsets.all(16),
                        itemCount: lista.length,
                        itemBuilder: (context, index) {
                          final m = lista[index];
                          final propio = m.uid == gestion.uid;
                          return Align(
                            alignment: propio
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 560),
                              child: Card(
                                color: propio
                                    ? Theme.of(context)
                                          .colorScheme
                                          .primaryContainer
                                    : null,
                                child: Padding(
                                  padding: const EdgeInsets.all(14),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        propio ? 'Tú' : m.nombre,
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelLarge,
                                      ),
                                      const SizedBox(height: 6),
                                      SelectableText(m.texto),
                                      const SizedBox(height: 6),
                                      Text(
                                        m.pendiente
                                            ? 'Pendiente de envío'
                                            : fechaComunidad(m.fecha),
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
                if (gestion.error != null) AvisoComunidad(gestion.error!),
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            key: const Key('mensaje_evento'),
                            controller: _texto,
                            enabled:
                                evento.chatAbierto &&
                                !gestion.ocupado &&
                                !evento.pendiente,
                            maxLength: 4000,
                            minLines: 1,
                            maxLines: 4,
                            decoration: const InputDecoration(
                              hintText: 'Escribe al grupo…',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton.filled(
                          key: const Key('enviar_mensaje_evento'),
                          tooltip: 'Enviar mensaje',
                          onPressed:
                              gestion.ocupado ||
                                  !evento.chatAbierto ||
                                  evento.pendiente
                              ? null
                              : _enviar,
                          icon: gestion.ocupado
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.send_outlined),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    ),
  );
}
