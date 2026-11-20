import 'package:flutter/material.dart';

String fechaComunidad(DateTime fecha) {
  final d = fecha.toLocal();
  String dos(int n) => n.toString().padLeft(2, '0');
  return '${dos(d.day)}/${dos(d.month)}/${d.year} · ${dos(d.hour)}:${dos(d.minute)}';
}

class AvisoComunidad extends StatelessWidget {
  const AvisoComunidad(this.texto, {super.key, this.onReintentar});
  final String texto;
  final VoidCallback? onReintentar;
  @override
  Widget build(BuildContext context) => Card(
    color: Theme.of(context).colorScheme.errorContainer,
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(liveRegion: true, child: Text(texto)),
          if (onReintentar != null)
            TextButton.icon(
              onPressed: onReintentar,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
        ],
      ),
    ),
  );
}

class VacioComunidad extends StatelessWidget {
  const VacioComunidad({
    super.key,
    required this.titulo,
    required this.texto,
    this.icono = Icons.park_outlined,
  });
  final String titulo, texto;
  final IconData icono;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        children: [
          Icon(icono, size: 46, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 12),
          Text(
            titulo,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(texto, textAlign: TextAlign.center),
        ],
      ),
    ),
  );
}

class MarcoComunidad extends StatelessWidget {
  const MarcoComunidad({super.key, required this.children});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.topCenter,
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 1120),
      child: ListView(padding: const EdgeInsets.all(20), children: children),
    ),
  );
}
