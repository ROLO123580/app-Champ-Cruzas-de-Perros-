import 'package:flutter/material.dart';

import '../../core/modelos/membership.dart';
import 'nanofunciones/gestionar_membership/gestionar_membership.dart';

/// Conserva el punto de entrada Membership existente de Fénix/Champ.
class AppMembership extends StatefulWidget {
  const AppMembership({
    super.key,
    required this.controlador,
    required this.onIrCarro,
  });
  final GestionarMembership controlador;
  final VoidCallback onIrCarro;

  @override
  State<AppMembership> createState() => _AppMembershipState();
}

class _AppMembershipState extends State<AppMembership> {
  @override
  void initState() {
    super.initState();
    // Reentrar consulta de nuevo la API: el catálogo puede haberse publicado
    // desde la consola u otra ventana mientras esta NanoApp estaba cerrada.
    widget.controlador.actualizar();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.controlador,
    builder: (context, _) {
      final gestion = widget.controlador;
      return ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                'Membership',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              OutlinedButton.icon(
                onPressed: gestion.ocupado ? null : gestion.actualizar,
                icon: const Icon(Icons.refresh),
                label: const Text('Actualizar planes'),
              ),
              FilledButton.tonalIcon(
                onPressed: gestion.ocupado ? null : widget.onIrCarro,
                icon: const Icon(Icons.shopping_cart_outlined),
                label: const Text('Ir al Carro'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text('Consulta los planes y revisa tu selección en el Carro.'),
          const SizedBox(height: 8),
          const Text('Membresía activa: ninguna'),
          if (gestion.ocupado) ...[
            const SizedBox(height: 16),
            const LinearProgressIndicator(),
          ],
          if (gestion.error != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                gestion.error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          if (gestion.cargado && gestion.planes.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.workspace_premium_outlined, size: 40),
                  SizedBox(height: 12),
                  Text('Los planes todavía no están disponibles.'),
                  SizedBox(height: 8),
                  Text(
                    'Vuelve a actualizar para consultar el catálogo de Champ.',
                  ),
                ],
              ),
            ),
          if (gestion.estado.plan != null) ...[
            const SizedBox(height: 16),
            Card(
              child: ListTile(
                leading: const Icon(Icons.shopping_cart_outlined),
                title: Text(gestion.estado.plan!.nombre),
                subtitle: Text(
                  gestion.estado.contratacion == EstadoContratacion.pendiente
                      ? 'Contratación pendiente'
                      : 'Plan seleccionado',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: gestion.ocupado ? null : widget.onIrCarro,
              ),
            ),
          ],
          if (gestion.planes.any((plan) => plan.requiereAdaptacion)) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF171C26),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.pets, color: Color(0xFFFF7A00), size: 32),
                  SizedBox(height: 12),
                  Text(
                    'Catálogo de referencia de Fénix Fitness',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Conservamos sus planes, precios y beneficios originales. '
                    'Estos beneficios todavía no están implementados en Champ. '
                    'Seleccionar guarda una intención local; la contratación '
                    'y los pagos aún no están habilitados.',
                    style: TextStyle(color: Colors.white70, height: 1.5),
                  ),
                ],
              ),
            ),
          ],
          if (gestion.planes.isNotEmpty) ...[
            const SizedBox(height: 20),
            // ResponsiveWrap de Fénix adaptado: tarjetas de 300 px como mínimo,
            // hasta tres columnas y apilado en ventanas pequeñas.
            LayoutBuilder(
              builder: (context, limites) {
                final posibles = (limites.maxWidth / 300).floor();
                final columnas = posibles < 1
                    ? 1
                    : (posibles > 3 ? 3 : posibles);
                final ancho =
                    (limites.maxWidth - (columnas - 1) * 14) / columnas;
                return Wrap(
                  spacing: 14,
                  runSpacing: 14,
                  children: [
                    for (final plan in gestion.planes)
                      SizedBox(
                        width: ancho,
                        child: _TarjetaPlan(
                          plan: plan,
                          seleccionado:
                              gestion.estado.plan?.mismasCondiciones(plan) ??
                              false,
                          ocupado: gestion.ocupado,
                          onSeleccionar: () async {
                            if (gestion.estado.plan?.mismasCondiciones(plan) ??
                                false) {
                              widget.onIrCarro();
                              return;
                            }
                            final elegido = await gestion.seleccionar(plan.id);
                            if (elegido && mounted) widget.onIrCarro();
                          },
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        ],
      );
    },
  );
}

class _TarjetaPlan extends StatelessWidget {
  const _TarjetaPlan({
    required this.plan,
    required this.seleccionado,
    required this.ocupado,
    required this.onSeleccionar,
  });
  final PlanMembership plan;
  final bool seleccionado;
  final bool ocupado;
  final VoidCallback onSeleccionar;

  Color get color => switch (plan.nombre) {
    'Free' => const Color(0xFF77809A),
    'Pro' => const Color(0xFFFF7A00),
    'Elite' => const Color(0xFF7A4AF4),
    _ => const Color(0xFF25856A),
  };

  @override
  Widget build(BuildContext context) => Card(
    margin: EdgeInsets.zero,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(18),
      side: const BorderSide(color: Color(0xFFE7EAF2)),
    ),
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.workspace_premium, color: color, size: 38),
          const SizedBox(height: 12),
          Text(
            plan.nombre,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
          ),
          if (plan.descripcion.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              plan.descripcion,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
          const SizedBox(height: 14),
          Text(
            plan.precioPresentado,
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          for (final beneficio in plan.beneficios)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle,
                    color: Color(0xFF2CB56F),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: Text(beneficio)),
                ],
              ),
            ),
          const SizedBox(height: 16),
          if (plan.requiereAdaptacion) ...[
            Text(
              'Beneficios de ${plan.procedencia ?? 'origen'}; pendientes en Champ.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
          ],
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: ocupado ? null : onSeleccionar,
              style: FilledButton.styleFrom(backgroundColor: color),
              child: Text(
                seleccionado ? 'Revisar selección' : 'Seleccionar plan',
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
