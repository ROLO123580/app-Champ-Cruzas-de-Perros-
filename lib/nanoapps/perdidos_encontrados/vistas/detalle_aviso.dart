import 'package:flutter/material.dart';
import 'package:champ/core/modelos/aviso_perro.dart';
import 'package:champ/ui/componentes_comunidad.dart';

import '../nanofunciones/gestionar_avisos/gestionar_avisos.dart';
import 'formulario_aviso.dart';

class DetalleAviso extends StatefulWidget {
  const DetalleAviso({
    super.key,
    required this.controlador,
    required this.avisoId,
    required this.onContactar,
  });
  final GestionarAvisos controlador;
  final String avisoId;
  final Future<bool> Function(String uid) onContactar;
  @override
  State<DetalleAviso> createState() => _DetalleAvisoState();
}

class _DetalleAvisoState extends State<DetalleAviso> {
  late Stream<AvisoPerro?> _stream = widget.controlador.observar(
    widget.avisoId,
  );
  bool _contactando = false;
  String? _errorContacto;
  Future<void> _contactar(AvisoPerro aviso) async {
    setState(() {
      _contactando = true;
      _errorContacto = null;
    });
    var ok = false;
    try {
      ok = await widget.onContactar(aviso.autorUid);
    } catch (_) {
      ok = false;
    }
    if (!mounted) return;
    if (ok) {
      Navigator.pop(context);
    } else {
      setState(() {
        _contactando = false;
        _errorContacto = 'No pudimos abrir el chat. Vuelve a intentarlo.';
      });
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Detalle del aviso')),
    body: StreamBuilder<AvisoPerro?>(
      stream: _stream,
      builder: (context, s) {
        if (s.hasError) {
          return MarcoComunidad(
            children: [
              AvisoComunidad(
                'No pudimos cargar el aviso.',
                onReintentar: () => setState(
                  () => _stream = widget.controlador.observar(widget.avisoId),
                ),
              ),
            ],
          );
        }
        if (s.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final aviso = s.data;
        if (aviso == null) {
          return const VacioComunidad(
            titulo: 'Aviso no disponible',
            texto: 'No encontramos este aviso.',
          );
        }
        return ListenableBuilder(
          listenable: widget.controlador,
          builder: (context, _) {
            final g = widget.controlador;
            final propio = aviso.autorUid == g.uid;
            final ocupado = g.ocupado || _contactando || aviso.pendiente;
            final foto = aviso.datos.foto;
            return MarcoComunidad(
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    Chip(
                      label: Text(
                        aviso.datos.tipo == TipoAvisoPerro.perdido
                            ? 'Se busca'
                            : 'Encontrado',
                      ),
                    ),
                    if (aviso.resuelto)
                      const Chip(label: Text('Caso resuelto')),
                  ],
                ),
                Text(
                  aviso.titulo,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                Text('Publicado por ${aviso.autorNombre}'),
                const SizedBox(height: 20),
                if (foto != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Image.memory(
                      foto,
                      height: 300,
                      cacheWidth: 800,
                      cacheHeight: 600,
                      fit: BoxFit.contain,
                      errorBuilder: (_, e, st) => const SizedBox(
                        height: 180,
                        child: Center(child: Text('Foto no disponible')),
                      ),
                    ),
                  )
                else
                  const Padding(
                    padding: EdgeInsets.all(24),
                    child: Icon(Icons.pets, size: 72),
                  ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.place_outlined),
                  title: Text(aviso.datos.lugar),
                  subtitle: Text(aviso.datos.zona),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.schedule),
                  title: const Text('Último avistamiento reportado'),
                  subtitle: Text(fechaComunidad(aviso.datos.fechaVista)),
                ),
                if (aviso.datos.raza.isNotEmpty)
                  Text('Raza o mezcla: ${aviso.datos.raza}'),
                const SizedBox(height: 12),
                SelectableText(aviso.datos.descripcion),
                const SizedBox(height: 20),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          aviso.datos.chip == 'si'
                              ? 'Microchip informado'
                              : aviso.datos.chip == 'no'
                              ? 'Sin microchip informado'
                              : 'Microchip: no se sabe',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        if (aviso.datos.chipUltimos.isNotEmpty)
                          Text('Terminación: •••• ${aviso.datos.chipUltimos}'),
                        const SizedBox(height: 8),
                        const Text(
                          'Se necesita un lector cercano para identificar el chip. Esta ficha muestra una zona reportada, no rastreo GPS.',
                        ),
                      ],
                    ),
                  ),
                ),
                if (aviso.resuelto)
                  Card(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Este caso fue marcado como resuelto'),
                          Text(aviso.notaCierre),
                        ],
                      ),
                    ),
                  ),
                if (g.error != null) AvisoComunidad(g.error!),
                if (_errorContacto != null) AvisoComunidad(_errorContacto!),
                if (ocupado) const LinearProgressIndicator(),
                if (aviso.pendiente) const Text('Pendiente de confirmación'),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    if (!propio && !aviso.resuelto)
                      FilledButton.icon(
                        key: const Key('contactar_aviso'),
                        onPressed: ocupado ? null : () => _contactar(aviso),
                        icon: const Icon(Icons.chat_bubble_outline),
                        label: Text(
                          _contactando
                              ? 'Abriendo chat…'
                              : 'Tengo información · Abrir chat',
                        ),
                      ),
                    if (propio && !aviso.resuelto)
                      OutlinedButton.icon(
                        key: const Key('editar_aviso'),
                        onPressed: ocupado
                            ? null
                            : () => Navigator.of(context).push<String>(
                                MaterialPageRoute(
                                  builder: (_) => FormularioAviso(
                                    controlador: g,
                                    aviso: aviso,
                                  ),
                                ),
                              ),
                        icon: const Icon(Icons.edit_outlined),
                        label: const Text('Editar aviso'),
                      ),
                    if (propio && !aviso.resuelto)
                      FilledButton.icon(
                        key: const Key('resolver_aviso'),
                        onPressed: ocupado
                            ? null
                            : () => showDialog<void>(
                                context: context,
                                barrierDismissible: false,
                                builder: (_) =>
                                    _CerrarAviso(controlador: g, id: aviso.id),
                              ),
                        icon: const Icon(Icons.check_circle_outline),
                        label: const Text('Marcar como resuelto'),
                      ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            );
          },
        );
      },
    ),
  );
}

class _CerrarAviso extends StatefulWidget {
  const _CerrarAviso({required this.controlador, required this.id});
  final GestionarAvisos controlador;
  final String id;
  @override
  State<_CerrarAviso> createState() => _CerrarAvisoState();
}

class _CerrarAvisoState extends State<_CerrarAviso> {
  final _nota = TextEditingController();
  @override
  void dispose() {
    _nota.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.controlador,
    builder: (context, _) => PopScope(
      canPop: !widget.controlador.ocupado,
      child: AlertDialog(
        title: const Text('Cerrar el caso'),
        content: SizedBox(
          width: 440,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Cuéntale a la comunidad cómo se resolvió. El aviso quedará en el historial.',
                ),
                const SizedBox(height: 12),
                TextField(
                  key: const Key('nota_cierre_aviso'),
                  controller: _nota,
                  enabled: !widget.controlador.ocupado,
                  maxLength: 500,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Nota de cierre',
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
            child: const Text('Volver'),
          ),
          FilledButton(
            key: const Key('confirmar_resolver_aviso'),
            onPressed: widget.controlador.ocupado
                ? null
                : () async {
                    final ok = await widget.controlador.resolver(
                      widget.id,
                      _nota.text,
                    );
                    if (ok && context.mounted) Navigator.pop(context);
                  },
            child: Text(
              widget.controlador.ocupado ? 'Confirmando…' : 'Confirmar cierre',
            ),
          ),
        ],
      ),
    ),
  );
}
