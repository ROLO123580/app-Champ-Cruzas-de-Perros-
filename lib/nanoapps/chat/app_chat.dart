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

/// Colores estables por persona, como los avatares de una app de mensajería.
const _coloresAvatar = [
  Color(0xFF00897B),
  Color(0xFF5E35B1),
  Color(0xFFD81B60),
  Color(0xFF3949AB),
  Color(0xFFF4511E),
  Color(0xFF43A047),
  Color(0xFF8E24AA),
  Color(0xFF039BE5),
];

Widget _avatar(String nombre, {double radio = 22}) {
  final limpio = nombre.trim();
  final inicial = limpio.isEmpty ? '?' : limpio.characters.first.toUpperCase();
  final color = _coloresAvatar[limpio.hashCode.abs() % _coloresAvatar.length];
  return CircleAvatar(
    radius: radio,
    backgroundColor: color,
    child: Text(
      inicial,
      style: TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w600,
        fontSize: radio * 0.85,
      ),
    ),
  );
}

String _dosDigitos(int n) => n.toString().padLeft(2, '0');
String _hora(DateTime f) => '${_dosDigitos(f.hour)}:${_dosDigitos(f.minute)}';

/// Hora si es de hoy, «Ayer», o la fecha corta, como en la lista de chats.
String _cuando(DateTime f) {
  final hoy = DateUtils.dateOnly(DateTime.now());
  final dia = DateUtils.dateOnly(f);
  if (dia == hoy) return _hora(f);
  if (dia == hoy.subtract(const Duration(days: 1))) return 'Ayer';
  return '${_dosDigitos(f.day)}/${_dosDigitos(f.month)}/${f.year % 100}';
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
    final String? destino;
    if (chat.uid != null) {
      destino = await showModalBottomSheet<String>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (_) => _ElegirContacto(chat: chat),
      );
    } else {
      destino = await showDialog<String>(
        context: context,
        builder: (_) => const _NuevaConversacion(entreUsuarios: false),
      );
    }
    if (destino == null || !mounted) return;
    final id = await chat.crear(destino);
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

  void _abrir(String? id) {
    chat.seleccionar(id);
    setState(() {
      seleccion = id;
      texto.clear();
    });
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
                  icon: const Icon(Icons.add_comment_outlined),
                  label: const Text('Conversación'),
                ),
              ],
            ),
          ),
          if (chat.ocupado || chat.conectando) const LinearProgressIndicator(),
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
                          SizedBox(width: 320, child: lista),
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
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Aún no tienes conversaciones.\nToca «Conversación» para escribirle a alguien.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    final estilo = Theme.of(context).textTheme;
    return ListView.separated(
      itemCount: conversaciones.length,
      separatorBuilder: (_, _) => const Divider(height: 1, indent: 76),
      itemBuilder: (context, index) {
        final c = conversaciones[index];
        final ultimo = c.mensajes.lastOrNull;
        final resumen = c.entreUsuarios
            ? (c.ultimoTexto?.isNotEmpty == true
                  ? c.ultimoTexto!
                  : 'Sin mensajes')
            : (ultimo == null ? 'Sin mensajes' : ultimo.texto ?? '📷 Foto');
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 4,
          ),
          leading: _avatar(c.nombre, radio: 26),
          title: Text(
            c.nombre,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: estilo.titleMedium,
          ),
          subtitle: Text(resumen, maxLines: 1, overflow: TextOverflow.ellipsis),
          trailing: Text(_cuando(c.actualizada), style: estilo.labelSmall),
          selected: c.id == seleccion,
          onTap: chat.ocupado ? null : () => _abrir(c.id),
        );
      },
    );
  }

  Widget _detalle(Conversacion c) {
    final esquema = Theme.of(context).colorScheme;
    return Column(
      children: [
        Material(
          color: esquema.surfaceContainer,
          child: ListTile(
            leading: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: 'Volver a conversaciones',
                  icon: const Icon(Icons.arrow_back),
                  onPressed: chat.ocupado ? null : () => _abrir(null),
                ),
                _avatar(c.nombre, radio: 20),
              ],
            ),
            title: Text(c.nombre, maxLines: 1, overflow: TextOverflow.ellipsis),
            subtitle: Text(
              c.entreUsuarios
                  ? 'En Champ'
                  : chat.uid != null
                  ? 'Demostración de esta sesión · no contacta a otra persona'
                  : 'Historial local · no se envía a otra cuenta',
            ),
          ),
        ),
        Expanded(
          child: ColoredBox(
            color: esquema.surfaceContainerLowest,
            child: chat.cargandoMensajes && c.entreUsuarios
                ? const Center(child: CircularProgressIndicator())
                : c.mensajes.isEmpty
                ? const Center(child: Text('Envía el primer mensaje 👋'))
                : ListView.builder(
                    key: ValueKey(c.id),
                    reverse: true,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    itemCount: c.mensajes.length,
                    itemBuilder: (context, index) {
                      final posicion = c.mensajes.length - 1 - index;
                      final m = c.mensajes[posicion];
                      final anterior = posicion > 0
                          ? c.mensajes[posicion - 1]
                          : null;
                      final nuevoDia =
                          anterior == null ||
                          !DateUtils.isSameDay(anterior.fecha, m.fecha);
                      return Column(
                        children: [
                          if (nuevoDia) _separadorDia(m.fecha),
                          _burbuja(m),
                        ],
                      );
                    },
                  ),
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (!c.entreUsuarios)
                  IconButton(
                    tooltip: 'Enviar foto (hasta 1 MB)',
                    icon: const Icon(Icons.photo_outlined),
                    onPressed: chat.ocupado
                        ? null
                        : () => chat.enviarFoto(c.id),
                  ),
                Expanded(
                  child: TextField(
                    controller: texto,
                    enabled: !chat.ocupado,
                    minLines: 1,
                    maxLines: 4,
                    maxLength: 4000,
                    decoration: InputDecoration(
                      hintText: 'Mensaje',
                      counterText: '',
                      filled: true,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _enviar(),
                  ),
                ),
                const SizedBox(width: 6),
                IconButton.filled(
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

  Widget _separadorDia(DateTime fecha) {
    final hoy = DateUtils.dateOnly(DateTime.now());
    final dia = DateUtils.dateOnly(fecha);
    final etiqueta = dia == hoy
        ? 'Hoy'
        : dia == hoy.subtract(const Duration(days: 1))
        ? 'Ayer'
        : '${_dosDigitos(fecha.day)}/${_dosDigitos(fecha.month)}/${fecha.year}';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          child: Text(etiqueta, style: Theme.of(context).textTheme.labelSmall),
        ),
      ),
    );
  }

  Widget _burbuja(Mensaje m) {
    final esquema = Theme.of(context).colorScheme;
    final propio = m.remitenteId == null || m.remitenteId == chat.uid;
    const radio = Radius.circular(14);
    return Align(
      alignment: propio ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 420),
        margin: EdgeInsets.only(
          bottom: 6,
          left: propio ? 48 : 0,
          right: propio ? 0 : 48,
        ),
        padding: const EdgeInsets.fromLTRB(12, 8, 10, 6),
        decoration: BoxDecoration(
          color: propio
              ? esquema.primaryContainer
              : esquema.surfaceContainerHighest,
          borderRadius: BorderRadius.only(
            topLeft: propio ? radio : Radius.zero,
            topRight: propio ? Radius.zero : radio,
            bottomLeft: radio,
            bottomRight: radio,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (m.foto != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.memory(
                  m.foto!,
                  height: 180,
                  fit: BoxFit.contain,
                  semanticLabel: 'Foto enviada',
                  cacheWidth: 720,
                  errorBuilder: (_, error, stack) =>
                      const Text('No se pudo mostrar la foto'),
                ),
              ),
            if (m.texto != null)
              Align(
                alignment: Alignment.centerLeft,
                widthFactor: 1,
                child: SelectableText(m.texto!),
              ),
            const SizedBox(height: 2),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _hora(m.fecha),
                  style: Theme.of(context).textTheme.labelSmall,
                ),
                if (propio) ...[
                  const SizedBox(width: 4),
                  Icon(
                    m.pendiente ? Icons.schedule : Icons.done,
                    size: 14,
                    semanticLabel: m.pendiente
                        ? 'Pendiente de envío'
                        : 'Enviado',
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Agenda de contactos con buscador, como al iniciar un chat en WhatsApp.
class _ElegirContacto extends StatefulWidget {
  const _ElegirContacto({required this.chat});
  final GestionarChat chat;
  @override
  State<_ElegirContacto> createState() => _ElegirContactoState();
}

class _ElegirContactoState extends State<_ElegirContacto> {
  final buscar = TextEditingController();
  @override
  void dispose() {
    buscar.dispose();
    super.dispose();
  }

  String _normalizar(String t) {
    const con = 'áéíóúüñ';
    const sin = 'aeiouun';
    final bajo = t.toLowerCase();
    final buffer = StringBuffer();
    for (final c in bajo.characters) {
      final i = con.indexOf(c);
      buffer.write(i < 0 ? c : sin[i]);
    }
    return buffer.toString();
  }

  Future<void> _porId() async {
    final id = await showDialog<String>(
      context: context,
      builder: (_) => const _NuevaConversacion(entreUsuarios: true),
    );
    if (id != null && mounted) Navigator.pop(context, id);
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.chat,
    builder: (context, _) {
      final filtro = _normalizar(buscar.text.trim());
      final contactos =
          widget.chat.contactos.entries
              .where((e) => _normalizar(e.value).contains(filtro))
              .toList()
            ..sort(
              (a, b) => _normalizar(a.value).compareTo(_normalizar(b.value)),
            );
      return SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.75,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(
                'Nueva conversación',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: buscar,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Buscar por nombre',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: contactos.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          widget.chat.contactos.isEmpty
                              ? 'Todavía no hay otras cuentas en Champ.'
                              : 'Nadie coincide con «${buscar.text.trim()}».',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: contactos.length,
                      itemBuilder: (context, index) {
                        final contacto = contactos[index];
                        return ListTile(
                          leading: _avatar(contacto.value),
                          title: Text(contacto.value),
                          onTap: () => Navigator.pop(context, contacto.key),
                        );
                      },
                    ),
            ),
            TextButton.icon(
              onPressed: _porId,
              icon: const Icon(Icons.badge_outlined),
              label: const Text('Usar el ID de una cuenta'),
            ),
            if (widget.chat.uid != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: SelectableText(
                  'Tu ID: ${widget.chat.uid}',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ),
            const SizedBox(height: 8),
          ],
        ),
      );
    },
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
