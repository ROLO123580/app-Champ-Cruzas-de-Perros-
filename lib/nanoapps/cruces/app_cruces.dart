import 'package:flutter/material.dart';

import '../../core/modelos/cruces.dart';
import 'nanofunciones/gestionar_cruces/gestionar_cruces.dart';
import 'widgets/editar_perfil.dart';

class AppCruces extends StatefulWidget {
  const AppCruces({super.key, this.controlador, this.onAbrirChat});
  final GestionarCruces? controlador;
  final Future<void> Function(String id, String nombre)? onAbrirChat;
  @override
  State<AppCruces> createState() => _AppCrucesState();
}

class _AppCrucesState extends State<AppCruces> {
  late final cruces = widget.controlador ?? GestionarCruces();
  bool verMatches = false;
  bool abriendoChat = false;
  double arrastre = 0;
  bool get ocupado => cruces.ocupado || abriendoChat;
  @override
  void initState() {
    super.initState();
    cruces.cargar();
  }

  @override
  void dispose() {
    if (widget.controlador == null) cruces.dispose();
    super.dispose();
  }

  Future<void> _perfil() => showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => EditarPerfilCruce(cruces: cruces),
  );

  Future<void> _abrir(PerfilPerro perro) async {
    final id = cruces.conversacionPara(perro.id);
    if (id == null || ocupado || widget.onAbrirChat == null) return;
    setState(() => abriendoChat = true);
    try {
      await widget.onAbrirChat!(id, '${perro.responsable} · ${perro.nombre}');
    } finally {
      if (mounted) setState(() => abriendoChat = false);
    }
  }

  Future<void> _decidir(PerfilPerro perro, DecisionCruce decision) async {
    if (ocupado) return;
    final ok = await cruces.decidir(perro.id, decision);
    if (!mounted || !ok) return;
    if (cruces.conversacionPara(perro.id) != null) {
      final abrir = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          icon: Icon(
            Icons.favorite,
            size: 56,
            color: Theme.of(context).colorScheme.primary,
          ),
          title: const Text('¡Es un match!'),
          content: Text(
            'A ${perro.nombre} y ${cruces.miPerro!.nombre} les interesa conocerse.\n\n'
            'Match de demostración. Puedes iniciar una conversación local con ${perro.responsable}.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Seguir explorando'),
            ),
            FilledButton.icon(
              onPressed: widget.onAbrirChat == null
                  ? null
                  : () => Navigator.pop(context, true),
              icon: const Icon(Icons.chat_bubble_outline),
              label: const Text('Ir al chat'),
            ),
          ],
        ),
      );
      if (abrir == true && mounted) await _abrir(perro);
    } else if (decision == DecisionCruce.gusta) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Interés guardado. El chat del match se habilita con interés mutuo.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: cruces,
    builder: (context, _) => SingleChildScrollView(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 820),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Conecta sus historias',
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const Text(
                          'Descubre perros y conversa con sus responsables.',
                        ),
                      ],
                    ),
                    if (cruces.cargado && cruces.miPerro != null)
                      OutlinedButton.icon(
                        onPressed: ocupado ? null : _perfil,
                        icon: const Icon(Icons.pets),
                        label: Text('Mi perro: ${cruces.miPerro!.nombre}'),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Card.filled(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      'Modo demostración · Perfiles e intereses de ejemplo. '
                      '${cruces.enCuenta ? 'Tu ficha y decisiones pertenecen a tu cuenta. El chat de ejemplo dura solo esta sesión; no contacta a otra persona.' : 'Los matches y los chats se guardan en este dispositivo.'}',
                    ),
                  ),
                ),
                if (ocupado) const LinearProgressIndicator(),
                if (cruces.error != null)
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      cruces.error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                if (!cruces.cargado) ...[
                  const SizedBox(height: 32),
                  const Text('Cargando cruces…', textAlign: TextAlign.center),
                  if (cruces.error != null)
                    TextButton(
                      onPressed: ocupado ? null : cruces.cargar,
                      child: const Text('Reintentar'),
                    ),
                ] else if (cruces.miPerro == null) ...[
                  const SizedBox(height: 32),
                  const Icon(Icons.pets, size: 72),
                  const SizedBox(height: 16),
                  Text(
                    'Todo empieza con tu perro',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'Crea su perfil para descubrir candidatos y guardar tus matches.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Center(
                    child: FilledButton.icon(
                      onPressed: ocupado ? null : _perfil,
                      icon: const Icon(Icons.add),
                      label: const Text('Crear perfil de mi perro'),
                    ),
                  ),
                ] else ...[
                  const SizedBox(height: 16),
                  SegmentedButton<bool>(
                    segments: [
                      const ButtonSegment(
                        value: false,
                        icon: Icon(Icons.style_outlined),
                        label: Text('Descubrir'),
                      ),
                      ButtonSegment(
                        value: true,
                        icon: const Icon(Icons.favorite_outline),
                        label: Text('Matches (${cruces.matches.length})'),
                      ),
                    ],
                    selected: {verMatches},
                    onSelectionChanged: ocupado
                        ? null
                        : (v) => setState(() => verMatches = v.single),
                  ),
                  const SizedBox(height: 16),
                  if (verMatches) _matches() else _descubrir(),
                ],
              ],
            ),
          ),
        ),
      ),
    ),
  );

  Widget _filtro(
    String titulo,
    String valor,
    List<String> opciones,
    ValueChanged<String> cambiar,
  ) => InputDecorator(
    decoration: InputDecoration(
      labelText: titulo,
      border: const OutlineInputBorder(),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
    ),
    child: DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        value: valor,
        isExpanded: true,
        items: [
          DropdownMenuItem(
            value: '',
            child: Text('Todas las ${titulo == 'Raza' ? 'razas' : 'ciudades'}'),
          ),
          ...opciones.map((v) => DropdownMenuItem(value: v, child: Text(v))),
        ],
        onChanged: ocupado ? null : (v) => cambiar(v!),
      ),
    ),
  );

  Widget _descubrir() {
    final pendientes = cruces.pendientes;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: _filtro(
                'Raza',
                cruces.raza,
                (cruces.perfiles.map((p) => p.raza).toSet().toList()..sort()),
                (v) => cruces.filtrar(porRaza: v, porCiudad: cruces.ciudad),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _filtro(
                'Ciudad',
                cruces.ciudad,
                (cruces.perfiles.map((p) => p.ciudad).toSet().toList()..sort()),
                (v) => cruces.filtrar(porRaza: cruces.raza, porCiudad: v),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          '${pendientes.length} perfiles por descubrir · ${cruces.intereses} intereses guardados',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.labelLarge,
        ),
        const SizedBox(height: 12),
        if (pendientes.isEmpty) ...[
          const Padding(
            padding: EdgeInsets.all(24),
            child: Icon(Icons.travel_explore, size: 64),
          ),
          const Text(
            'No hay más perfiles con estos filtros.',
            textAlign: TextAlign.center,
          ),
          TextButton(
            onPressed: ocupado
                ? null
                : () => cruces.filtrar(porRaza: '', porCiudad: ''),
            child: const Text('Quitar filtros'),
          ),
          TextButton(
            onPressed: ocupado ? null : cruces.revisarDescartados,
            child: const Text('Volver a ver descartados'),
          ),
        ] else
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Column(
                children: [
                  GestureDetector(
                    onHorizontalDragUpdate: ocupado
                        ? null
                        : (d) => setState(() => arrastre += d.delta.dx),
                    onHorizontalDragCancel: () => setState(() => arrastre = 0),
                    onHorizontalDragEnd: ocupado
                        ? null
                        : (d) {
                            final movimiento = arrastre;
                            setState(() => arrastre = 0);
                            if (movimiento.abs() > 70 ||
                                d.velocity.pixelsPerSecond.dx.abs() > 500) {
                              final derecha = movimiento.abs() > 70
                                  ? movimiento > 0
                                  : d.velocity.pixelsPerSecond.dx > 0;
                              _decidir(
                                pendientes.first,
                                derecha
                                    ? DecisionCruce.gusta
                                    : DecisionCruce.pasar,
                              );
                            }
                          },
                    child: Transform.translate(
                      offset: Offset(arrastre.clamp(-80, 80), 0),
                      child: _tarjeta(pendientes.first),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      OutlinedButton.icon(
                        onPressed: ocupado
                            ? null
                            : () => _decidir(
                                pendientes.first,
                                DecisionCruce.pasar,
                              ),
                        icon: const Icon(Icons.close),
                        label: const Text('Pasar'),
                      ),
                      FilledButton.icon(
                        onPressed: ocupado
                            ? null
                            : () => _decidir(
                                pendientes.first,
                                DecisionCruce.gusta,
                              ),
                        icon: const Icon(Icons.favorite),
                        label: const Text('Me gusta'),
                      ),
                    ],
                  ),
                  const Padding(
                    padding: EdgeInsets.all(12),
                    child: Text(
                      'Desliza a la izquierda para pasar o a la derecha si te gusta.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _tarjeta(PerfilPerro p) => Card(
    clipBehavior: Clip.antiAlias,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 270,
          child: p.foto == null
              ? _sinFoto(p)
              : Image.memory(
                  p.foto!,
                  cacheWidth: 900,
                  fit: BoxFit.cover,
                  errorBuilder: (_, error, stack) => _sinFoto(p),
                ),
        ),
        Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${p.nombre}, ${p.edad}',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  Chip(label: Text(p.raza)),
                  Chip(label: Text(p.sexo)),
                  Chip(
                    avatar: const Icon(Icons.place_outlined, size: 16),
                    label: Text(p.ciudad),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(p.descripcion),
              const SizedBox(height: 12),
              Text('Responsable: ${p.responsable}'),
              if (p.interesDemo)
                const Padding(
                  padding: EdgeInsets.only(top: 10),
                  child: Text(
                    '♥ Interés recibido de ejemplo',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _sinFoto(PerfilPerro p) => Container(
    color: Theme.of(context).colorScheme.primaryContainer,
    child: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.pets, size: 80),
          const SizedBox(height: 12),
          Text(p.nombre),
        ],
      ),
    ),
  );

  Widget _matches() {
    if (cruces.matches.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Text(
          'Tus matches aparecerán aquí cuando el interés sea mutuo.',
          textAlign: TextAlign.center,
        ),
      );
    }
    return Column(
      children: cruces.matches
          .map(
            (p) => Card(
              child: ListTile(
                leading: const CircleAvatar(child: Icon(Icons.favorite)),
                title: Text('${p.nombre} · ${p.responsable}'),
                subtitle: Text('${p.raza} · ${p.ciudad}'),
                trailing: IconButton(
                  tooltip: 'Chatear con ${p.responsable}',
                  icon: const Icon(Icons.chat_bubble_outline),
                  onPressed: ocupado || widget.onAbrirChat == null
                      ? null
                      : () => _abrir(p),
                ),
                onTap: ocupado || widget.onAbrirChat == null
                    ? null
                    : () => _abrir(p),
              ),
            ),
          )
          .toList(),
    );
  }
}
