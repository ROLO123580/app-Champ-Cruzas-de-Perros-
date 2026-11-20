import 'package:flutter/material.dart';

import '../../core/modelos/chat.dart';
import 'nanofunciones/gestionar_chat/gestionar_chat.dart';

class AppChat extends StatefulWidget {
  const AppChat({super.key, this.controlador, this.conversacionInicial});
  final GestionarChat? controlador;
  final String? conversacionInicial;
  @override
  State<AppChat> createState() => _AppChatState();
}

class _AppChatState extends State<AppChat> {
  late final GestionarChat chat = widget.controlador ?? GestionarChat();
  final texto = TextEditingController();
  String? seleccion;
  @override
  void initState() {
    super.initState();
    seleccion = widget.conversacionInicial;
    if (!chat.cargado) chat.cargar();
    _seleccionarInicial();
  }

  void _seleccionarInicial() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) chat.seleccionar(seleccion);
    });
  }

  @override
  void didUpdateWidget(covariant AppChat oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.conversacionInicial != widget.conversacionInicial) {
      seleccion = widget.conversacionInicial;
      texto.clear();
      _seleccionarInicial();
    }
  }

  @override
  void dispose() {
    texto.dispose();
    if (widget.controlador == null) chat.dispose();
    super.dispose();
  }

  Future<void> _crear() async {
    final nombre = await showDialog<String>(
      context: context,
      builder: (_) => _NuevaConversacion(entreUsuarios: chat.uid != null),
    );
    if (nombre == null || !mounted) return;
    final id = await chat.crear(nombre);
    if (id != null && mounted) {
      chat.seleccionar(id);
      setState(() {
        seleccion = id;
        texto.clear();
      });
    }
  }

  Future<void> _enviar() async {
    final id = seleccion;
    if (id == null) return;
    final enviado = texto.text;
    if (await chat.enviarTexto(id, enviado) &&
        mounted &&
        seleccion == id &&
        texto.text == enviado) {
      texto.clear();
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: chat,
    builder: (context, _) {
      final conversaciones = chat.conversaciones;
      final actual = conversaciones.where((c) => c.id == seleccion).firstOrNull;
      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Text('Chat', style: Theme.of(context).textTheme.headlineSmall),
                const Spacer(),
                FilledButton.icon(
                  onPressed: chat.ocupado || (!chat.cargado && chat.uid == null)
                      ? null
                      : _crear,
                  icon: const Icon(Icons.add),
                  label: const Text('Conversación'),
                ),
              ],
            ),
          ),
          if (chat.ocupado) const LinearProgressIndicator(),
          if (chat.uid != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: SelectableText('Tu ID para conversar: ${chat.uid}'),
            ),
          if (chat.conectando) const LinearProgressIndicator(),
          if (chat.errorUsuarios != null)
            ListTile(
              title: Text(chat.errorUsuarios!),
              trailing: TextButton(
                onPressed: () {
                  chat.conectar();
                  chat.seleccionar(seleccion);
                },
                child: const Text('Reconectar'),
              ),
            ),
          if (chat.error != null)
            Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  Expanded(child: Text(chat.error!)),
                  if (!chat.cargado)
                    TextButton(
                      onPressed: chat.ocupado ? null : chat.cargar,
                      child: const Text('Reintentar'),
                    ),
                ],
              ),
            ),
          Expanded(
            child: !chat.cargado && chat.uid == null
                ? const Center(child: Text('Cargando chat…'))
                : LayoutBuilder(
                    builder: (context, constraints) {
                      final lista = _lista(conversaciones);
                      final detalle = actual == null
                          ? const Center(
                              child: Text('Selecciona o crea una conversación'),
                            )
                          : _detalle(actual);
                      if (constraints.maxWidth < 650) {
                        return actual == null ? lista : detalle;
                      }
                      return Row(
                        children: [
                          SizedBox(width: 260, child: lista),
                          const VerticalDivider(width: 1),
                          Expanded(child: detalle),
                        ],
                      );
                    },
                  ),
          ),
        ],
      );
    },
  );
  Widget _lista(List<Conversacion> conversaciones) {
    if (conversaciones.isEmpty) {
      return const Center(child: Text('Aún no tienes conversaciones.'));
    }
    return ListView.builder(
      itemCount: conversaciones.length,
      itemBuilder: (context, index) {
        final c = conversaciones[index];
        final ultimo = c.mensajes.lastOrNull;
        return ListTile(
          leading: const CircleAvatar(child: Icon(Icons.chat_bubble_outline)),
          title: Text(c.nombre, maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: Text(
            c.entreUsuarios
                ? (c.ultimoTexto?.isNotEmpty == true
                      ? c.ultimoTexto!
                      : 'Sin mensajes')
                : 'Local · ${ultimo == null ? 'Sin mensajes' : ultimo.texto ?? '📷 Foto'}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          selected: c.id == seleccion,
          onTap: chat.ocupado
              ? null
              : () {
                  chat.seleccionar(c.id);
                  setState(() {
                    seleccion = c.id;
                    texto.clear();
                  });
                },
        );
      },
    );
  }

  Widget _detalle(Conversacion c) => Column(
    children: [
      ListTile(
        leading: IconButton(
          tooltip: 'Volver a conversaciones',
          icon: const Icon(Icons.arrow_back),
          onPressed: chat.ocupado
              ? null
              : () {
                  chat.seleccionar(null);
                  setState(() {
                    seleccion = null;
                    texto.clear();
                  });
                },
        ),
        title: Text(c.nombre),
        subtitle: Text(
          c.entreUsuarios
              ? 'Chat entre usuarios · últimos 100 mensajes'
              : chat.uid != null
              ? 'Demostración de esta sesión · no contacta a otra persona'
              : 'Historial local · no se envía a otra cuenta',
        ),
      ),
      const Divider(height: 1),
      Expanded(
        child: chat.cargandoMensajes && c.entreUsuarios
            ? const Center(child: CircularProgressIndicator())
            : c.mensajes.isEmpty
            ? const Center(child: Text('Envía el primer mensaje'))
            : ListView.builder(
                key: ValueKey(c.id),
                reverse: true,
                padding: const EdgeInsets.all(12),
                itemCount: c.mensajes.length,
                itemBuilder: (context, index) {
                  final m = c.mensajes[c.mensajes.length - 1 - index];
                  return Align(
                    alignment:
                        m.remitenteId == null || m.remitenteId == chat.uid
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 360),
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color:
                            m.remitenteId == null || m.remitenteId == chat.uid
                            ? Theme.of(context).colorScheme.primaryContainer
                            : Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (m.foto != null)
                            Image.memory(
                              m.foto!,
                              height: 180,
                              fit: BoxFit.contain,
                              semanticLabel: 'Foto enviada',
                              cacheWidth: 720,
                              errorBuilder: (_, error, stack) =>
                                  const Text('No se pudo mostrar la foto'),
                            ),
                          if (m.texto != null) SelectableText(m.texto!),
                          if (m.pendiente) const Text('Pendiente de envío'),
                          const SizedBox(height: 4),
                          Text(
                            '${m.fecha.day}/${m.fecha.month}/${m.fecha.year} '
                            '${m.fecha.hour.toString().padLeft(2, '0')}:'
                            '${m.fecha.minute.toString().padLeft(2, '0')}',
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
      SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!c.entreUsuarios)
                IconButton(
                  tooltip: 'Enviar foto (hasta 1 MB)',
                  icon: const Icon(Icons.photo_outlined),
                  onPressed: chat.ocupado ? null : () => chat.enviarFoto(c.id),
                ),
              Expanded(
                child: TextField(
                  controller: texto,
                  enabled: !chat.ocupado,
                  minLines: 1,
                  maxLines: 4,
                  maxLength: 4000,
                  decoration: const InputDecoration(
                    hintText: 'Escribe un mensaje',
                    counterText: '',
                    border: OutlineInputBorder(),
                  ),
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _enviar(),
                ),
              ),
              IconButton(
                tooltip: 'Enviar mensaje',
                icon: const Icon(Icons.send),
                onPressed: chat.ocupado ? null : _enviar,
              ),
            ],
          ),
        ),
      ),
    ],
  );
}

class _NuevaConversacion extends StatefulWidget {
  const _NuevaConversacion({required this.entreUsuarios});
  final bool entreUsuarios;
  @override
  State<_NuevaConversacion> createState() => _NuevaConversacionState();
}

class _NuevaConversacionState extends State<_NuevaConversacion> {
  final nombre = TextEditingController();
  @override
  void dispose() {
    nombre.dispose();
    super.dispose();
  }

  void crear() {
    if (nombre.text.trim().isNotEmpty) {
      Navigator.pop(context, nombre.text.trim());
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Nueva conversación'),
    content: TextField(
      controller: nombre,
      autofocus: true,
      maxLength: widget.entreUsuarios ? 128 : 80,
      decoration: InputDecoration(
        labelText: widget.entreUsuarios
            ? 'ID del usuario de Champ'
            : 'Nombre del contacto o grupo',
        helperText: widget.entreUsuarios
            ? 'Pide a la otra persona su ID desde Chat.'
            : null,
      ),
      onChanged: (_) => setState(() {}),
      onSubmitted: (_) => crear(),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancelar'),
      ),
      FilledButton(
        onPressed: nombre.text.trim().isEmpty ? null : crear,
        child: const Text('Crear'),
      ),
    ],
  );
}
