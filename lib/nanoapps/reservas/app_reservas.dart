import 'package:flutter/material.dart';
import 'package:champ/core/modelos/servicios_paseos.dart';
import 'package:champ/ui/componentes_comunidad.dart';
import 'package:champ/nanoapps/comunidad/nanofunciones/gestionar_comunidad/gestionar_comunidad.dart';
import 'package:champ/nanoapps/eventos/app_eventos.dart';

import 'nanofunciones/gestionar_reservas/gestionar_reservas.dart';
import 'vistas/detalle_reserva.dart';

class AppReservas extends StatefulWidget {
  const AppReservas({
    super.key,
    required this.controlador,
    required this.onContactar,
    this.comunidad,
  });
  final GestionarReservas controlador;
  final Future<bool> Function(String) onContactar;
  final GestionarComunidad? comunidad;
  @override
  State<AppReservas> createState() => _AppReservasState();
}

class _AppReservasState extends State<AppReservas> {
  String _filtro = 'Activas';
  @override
  void initState() {
    super.initState();
    widget.controlador.iniciar();
    widget.comunidad?.iniciar();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: Listenable.merge([
      widget.controlador,
      if (widget.comunidad != null) widget.comunidad!,
    ]),
    builder: (context, _) {
      final g = widget.controlador;
      final lista = g.reservas
          .where(
            (r) => switch (_filtro) {
              'Historial' => r.cerrada,
              'Recibidas' =>
                r.paseadorUid == g.uid &&
                    r.estado == EstadoReservaPaseo.solicitada,
              _ => !r.cerrada,
            },
          )
          .toList();
      final comunidad = widget.comunidad;
      return MarcoComunidad(
        children: [
          Text(
            'Tu agenda de paseos',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          const Text(
            'Revisa solicitudes, confirmaciones y encuentros en un solo lugar.',
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final filtro in ['Activas', 'Recibidas', 'Historial'])
                ChoiceChip(
                  label: Text(filtro),
                  selected: _filtro == filtro,
                  onSelected: (_) => setState(() => _filtro = filtro),
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (g.cargando) const LinearProgressIndicator(),
          if (g.error != null)
            AvisoComunidad(
              g.error!,
              onReintentar: () => g.iniciar(reintentar: true),
            ),
          if (!g.cargando && g.error == null && lista.isEmpty)
            const VacioComunidad(
              titulo: 'Tu agenda está libre para nuevos planes',
              texto: 'Envía una solicitud a un paseador o consulta tus encuentros compartidos.',
              icono: Icons.event_available,
            ),
          for (final r in lista)
            Card(
              child: ListTile(
                title: Text('${r.perro} · ${r.etiqueta}'),
                subtitle: Text(
                  '${fechaComunidad(r.inicio)}\n${r.paseadorNombre} · ${r.zona}',
                ),
                isThreeLine: true,
                onTap: () => Navigator.of(context).push<void>(
                  MaterialPageRoute(
                    builder: (_) => DetalleReserva(
                      controlador: g,
                      reservaId: r.id,
                      onContactar: widget.onContactar,
                    ),
                  ),
                ),
              ),
            ),
          if (comunidad != null) ...[
            const SizedBox(height: 24),
            Text(
              'Tus encuentros compartidos',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            for (final e in comunidad.eventos.where(
              (e) => e.participantes.containsKey(g.uid),
            ))
              Card(
                child: ListTile(
                  title: Text(e.datos.titulo),
                  subtitle: Text(
                    '${fechaComunidad(e.datos.inicio)} · ${e.datos.lugar}',
                  ),
                  onTap: () => Navigator.of(context).push<void>(
                    MaterialPageRoute(
                      builder: (_) => AppEventos(
                        controlador: comunidad.eventosGestion,
                        controladorChat: comunidad.chatGestion,
                        eventoId: e.id,
                      ),
                    ),
                  ),
                ),
              ),
          ],
          const SizedBox(height: 16),
          const Text(
            'Se consultan hasta 100 reservas por rol. Las reservas y los encuentros tienen estados independientes.',
          ),
        ],
      );
    },
  );
}
