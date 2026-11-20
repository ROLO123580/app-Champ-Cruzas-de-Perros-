import 'dart:async';

import 'package:flutter/material.dart';
import 'package:champ/core/modelos/aviso_perro.dart';
import 'package:champ/ui/componentes_comunidad.dart';

import 'nanofunciones/gestionar_avisos/gestionar_avisos.dart';
import 'vistas/formulario_aviso.dart';
import 'vistas/detalle_aviso.dart';

class AppPerdidosEncontrados extends StatefulWidget {
  const AppPerdidosEncontrados({
    super.key,
    required this.controlador,
    required this.onContactar,
  });
  final GestionarAvisos controlador;
  final Future<bool> Function(String uid) onContactar;
  @override
  State<AppPerdidosEncontrados> createState() => _AppPerdidosEncontradosState();
}

class _AppPerdidosEncontradosState extends State<AppPerdidosEncontrados> {
  String _filtro = 'Todos', _busqueda = '';
  bool _conChip = false;
  GestionarAvisos get gestion => widget.controlador;
  @override
  void initState() {
    super.initState();
    gestion.iniciar();
  }

  @override
  void didUpdateWidget(covariant AppPerdidosEncontrados oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controlador != gestion) gestion.iniciar();
  }

  Future<void> _detalle(String id) => Navigator.of(context).push<void>(
    MaterialPageRoute(
      builder: (_) => DetalleAviso(
        controlador: gestion,
        avisoId: id,
        onContactar: widget.onContactar,
      ),
    ),
  );
  Future<void> _crear() async {
    final id = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => FormularioAviso(controlador: gestion)),
    );
    if (id != null && mounted) unawaited(_detalle(id));
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: gestion,
    builder: (context, _) {
      final tema = Theme.of(context);
      final lista = gestion.avisos.where((a) {
        if (_filtro == 'Mis avisos' && a.autorUid != gestion.uid) return false;
        if (_filtro == 'Resueltos' && !a.resuelto) return false;
        if (_filtro != 'Mis avisos' && _filtro != 'Resueltos' && a.resuelto) {
          return false;
        }
        if (_filtro == 'Perdidos' && a.datos.tipo != TipoAvisoPerro.perdido) {
          return false;
        }
        if (_filtro == 'Encontrados' &&
            a.datos.tipo != TipoAvisoPerro.encontrado) {
          return false;
        }
        if (_conChip && a.datos.chip != 'si') return false;
        return '${a.datos.nombre} ${a.datos.raza} ${a.datos.zona} ${a.datos.lugar} ${a.datos.chipUltimos}'
            .toLowerCase()
            .contains(_busqueda);
      }).toList();
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
                const Icon(Icons.pets_outlined, size: 40),
                const SizedBox(height: 12),
                Text(
                  'Ayudemos a que vuelva a casa',
                  style: tema.textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                const Text(
                  '¿Perdiste a tu perro o encontraste uno? Comparte un aviso y conecta con la comunidad.',
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  key: const Key('crear_aviso'),
                  onPressed: gestion.ocupado ? null : _crear,
                  icon: const Icon(Icons.add),
                  label: const Text('Publicar aviso'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final filtro in [
                'Todos',
                'Perdidos',
                'Encontrados',
                'Mis avisos',
                'Resueltos',
              ])
                ChoiceChip(
                  label: Text(filtro),
                  selected: _filtro == filtro,
                  onSelected: (_) => setState(() => _filtro = filtro),
                ),
              FilterChip(
                label: const Text('Con microchip'),
                selected: _conChip,
                onSelected: (v) => setState(() => _conChip = v),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            key: const Key('buscar_aviso'),
            decoration: const InputDecoration(
              labelText: 'Nombre, zona o últimos 4 dígitos del chip',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            onChanged: (v) =>
                setState(() => _busqueda = v.trim().toLowerCase()),
          ),
          const SizedBox(height: 16),
          if (gestion.cargando)
            const LinearProgressIndicator(semanticsLabel: 'Cargando avisos'),
          if (gestion.error != null)
            AvisoComunidad(
              gestion.error!,
              onReintentar: () => gestion.iniciar(reintentar: true),
            ),
          if (!gestion.cargando && gestion.error == null && lista.isEmpty)
            const VacioComunidad(
              titulo: 'No hay avisos para esta selección',
              texto: 'Prueba con otra zona o publica un aviso para que la comunidad pueda ayudar.',
              icono: Icons.search_outlined,
            ),
          for (final aviso in lista) _tarjeta(aviso),
          const SizedBox(height: 16),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'El microchip sirve para identificar con un lector cercano. No muestra la ubicación del perro; aquí se indica la última zona reportada.',
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Últimos 50 avisos. Los datos del chip son informados por quien publica; una coincidencia parcial no acredita identidad ni propiedad.',
          ),
        ],
      );
    },
  );
  Widget _tarjeta(AvisoPerro a) => Card(
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: () => _detalle(a.id),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: LayoutBuilder(
          builder: (context, c) {
            final foto = a.datos.foto;
            final imagen = ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: foto == null
                  ? Container(
                      width: 160,
                      height: 150,
                      color: Theme.of(context)
                          .colorScheme
                          .surfaceContainerHighest,
                      child: const Icon(Icons.pets, size: 48),
                    )
                  : Image.memory(
                      foto,
                      width: 160,
                      height: 150,
                      cacheWidth: 320,
                      cacheHeight: 300,
                      fit: BoxFit.cover,
                      errorBuilder: (_, e, s) => const SizedBox(
                        width: 160,
                        height: 150,
                        child: Icon(Icons.image_not_supported_outlined),
                      ),
                    ),
            );
            final datos = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    Chip(
                      label: Text(
                        a.datos.tipo == TipoAvisoPerro.perdido
                            ? 'Se busca'
                            : 'Encontrado',
                      ),
                    ),
                    if (a.resuelto) const Chip(label: Text('Resuelto')),
                    if (a.datos.chip == 'si')
                      const Chip(label: Text('Microchip informado')),
                  ],
                ),
                Text(a.titulo, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                Text('${a.datos.lugar} · ${a.datos.zona}'),
                Text(fechaComunidad(a.datos.fechaVista)),
                if (a.datos.raza.isNotEmpty) Text(a.datos.raza),
                if (a.pendiente) const Text('Pendiente de confirmación'),
                const SizedBox(height: 12),
                const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Ver aviso'),
                    SizedBox(width: 6),
                    Icon(Icons.arrow_forward, size: 18),
                  ],
                ),
              ],
            );
            return c.maxWidth >= 600
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      imagen,
                      const SizedBox(width: 20),
                      Expanded(child: datos),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [imagen, const SizedBox(height: 12), datos],
                  );
          },
        ),
      ),
    ),
  );
}
