import 'package:flutter/material.dart';

import '../../core/modelos/membership.dart';
import '../../core/repositorios/membership_local.dart';
import 'nanofunciones/gestionar_carro/gestionar_carro.dart';

class AppCarro extends StatefulWidget {
  const AppCarro({
    super.key,
    required this.repositorio,
    required this.onIrMembership,
    this.onCambio,
  });
  final RepositorioMembership repositorio;
  final VoidCallback onIrMembership;
  final Future<void> Function()? onCambio;

  @override
  State<AppCarro> createState() => _AppCarroState();
}

class _AppCarroState extends State<AppCarro> {
  late final GestionarCarro gestion = GestionarCarro(
    repositorio: widget.repositorio,
    onCambio: widget.onCambio,
  );

  @override
  void initState() {
    super.initState();
    gestion.cargar();
  }

  @override
  void dispose() {
    gestion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: gestion,
    builder: (context, _) {
      final plan = gestion.estado.plan;
      final pendiente =
          gestion.estado.contratacion == EstadoContratacion.pendiente;
      return ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text('Carro', style: Theme.of(context).textTheme.headlineSmall),
              OutlinedButton.icon(
                onPressed: widget.onIrMembership,
                icon: const Icon(Icons.arrow_back),
                label: const Text('Ver planes'),
              ),
              IconButton(
                onPressed: gestion.ocupado ? null : gestion.cargar,
                tooltip: 'Actualizar Carro',
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (gestion.ocupado) const LinearProgressIndicator(),
          if (gestion.error != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                gestion.error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          if (gestion.cargado && plan == null) ...[
            const SizedBox(height: 32),
            const Text('Tu Carro está vacío.'),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerLeft,
              child: FilledButton(
                onPressed: widget.onIrMembership,
                child: const Text('Consultar planes'),
              ),
            ),
          ],
          if (plan != null) ...[
            const SizedBox(height: 20),
            // Composición de Fénix: producto/resumen en dos columnas desde
            // 900 px. No recoge tarjetas ni simula pagos.
            LayoutBuilder(
              builder: (context, limites) {
                final producto = _producto(plan);
                final resumen = _resumen(plan, pendiente);
                if (limites.maxWidth < 900) {
                  return Column(
                    children: [producto, const SizedBox(height: 14), resumen],
                  );
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 3, child: producto),
                    const SizedBox(width: 14),
                    Expanded(flex: 2, child: resumen),
                  ],
                );
              },
            ),
          ],
        ],
      );
    },
  );

  Widget _tarjeta(Widget contenido) => Card(
    margin: EdgeInsets.zero,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(18),
      side: const BorderSide(color: Color(0xFFE7EAF2)),
    ),
    child: Padding(padding: const EdgeInsets.all(20), child: contenido),
  );

  Widget _producto(PlanMembership plan) => _tarjeta(
    Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Productos en tu carro',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF6F7FB),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.workspace_premium,
                color: Color(0xFF7A4AF4),
                size: 36,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Membresía ${plan.nombre}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(plan.precioPresentado),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (plan.descripcion.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(plan.descripcion),
        ],
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
        if (plan.requiereAdaptacion) ...[
          const SizedBox(height: 18),
          Text(
            'Catálogo de referencia de ${plan.procedencia ?? 'origen'}. '
            'Sus beneficios todavía no están implementados en Champ. '
            'Esta selección es una intención local, sin contratación habilitada.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ],
    ),
  );

  Widget _resumen(PlanMembership plan, bool pendiente) => _tarjeta(
    Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Resumen de tu selección',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 18),
        _linea('Subtotal', plan.importePresentado(plan.precioMenor)),
        if (plan.impuestosMenor != null)
          _linea(
            'Impuestos (${plan.porcentajeImpuesto})',
            plan.importePresentado(plan.impuestosMenor!),
          ),
        const Divider(height: 32),
        _linea(
          'Total de referencia',
          plan.importePresentado(plan.totalMenor),
          destacado: true,
        ),
        if (plan.requiereAdaptacion && plan.impuestoPuntosBase != null) ...[
          const SizedBox(height: 8),
          const Text('Tasa de referencia conservada de Fénix Fitness.'),
        ],
        const SizedBox(height: 18),
        Text(pendiente ? 'Contratación pendiente' : 'Plan seleccionado'),
        const SizedBox(height: 8),
        const Text('Membresía activa: ninguna'),
        const SizedBox(height: 16),
        const Text(
          'Los pagos y la contratación aún no están habilitados. '
          'Tu selección se conserva sin activar beneficios ni permisos.',
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: [
            FilledButton(
              onPressed: gestion.ocupado || pendiente
                  ? null
                  : gestion.dejarPendiente,
              child: Text(
                pendiente
                    ? 'Contratación pendiente'
                    : 'Dejar contratación pendiente',
              ),
            ),
            TextButton.icon(
              onPressed: gestion.ocupado ? null : gestion.quitar,
              icon: const Icon(Icons.remove_shopping_cart_outlined),
              label: const Text('Quitar selección'),
            ),
          ],
        ),
      ],
    ),
  );

  Widget _linea(String etiqueta, String valor, {bool destacado = false}) {
    final estilo = TextStyle(
      fontSize: destacado ? 20 : 15,
      fontWeight: destacado ? FontWeight.w900 : FontWeight.w600,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(child: Text(etiqueta, style: estilo)),
          const SizedBox(width: 12),
          Text(valor, style: estilo),
        ],
      ),
    );
  }
}
