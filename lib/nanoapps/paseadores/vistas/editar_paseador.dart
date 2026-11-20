import 'package:flutter/material.dart';
import 'package:champ/core/modelos/servicios_paseos.dart';
import 'package:champ/ui/componentes_comunidad.dart';

import '../nanofunciones/gestionar_paseadores/gestionar_paseadores.dart';

class EditarPaseador extends StatefulWidget {
  const EditarPaseador({super.key, required this.controlador});
  final GestionarPaseadores controlador;
  @override
  State<EditarPaseador> createState() => _EditarPaseadorState();
}

class _EditarPaseadorState extends State<EditarPaseador> {
  final _form = GlobalKey<FormState>();
  late final _perfil = widget.controlador.perfil;
  late final _nombre = TextEditingController(text: _perfil?.nombre ?? ''),
      _zona = TextEditingController(text: _perfil?.zona ?? ''),
      _bio = TextEditingController(text: _perfil?.descripcion ?? ''),
      _condiciones = TextEditingController(text: _perfil?.condiciones ?? ''),
      _horario = TextEditingController(text: _perfil?.disponibilidad ?? '');
  late int _duracion = _perfil?.duracion ?? 60;
  late bool _activo = _perfil?.activo ?? true;
  bool _tocado = false;
  @override
  void dispose() {
    for (final c in [_nombre, _zona, _bio, _condiciones, _horario]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_form.currentState!.validate()) return;
    final ok = await widget.controlador.guardar(
      PerfilPaseador(
        uid: widget.controlador.uid,
        nombre: _nombre.text,
        zona: _zona.text,
        descripcion: _bio.text,
        condiciones: _condiciones.text,
        disponibilidad: _horario.text,
        duracion: _duracion,
        activo: _activo,
        revision: _perfil?.revision ?? 0,
      ),
    );
    if (ok && mounted) {
      setState(() => _tocado = false);
      Navigator.pop(context);
    }
  }

  Future<void> _salir() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('¿Descartar los cambios?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Seguir editando'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Descartar'),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      setState(() => _tocado = false);
      Navigator.pop(context);
    }
  }

  Widget _campo(
    TextEditingController c,
    String titulo,
    int max, {
    int lineas = 1,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: TextFormField(
      controller: c,
      readOnly: widget.controlador.ocupado,
      maxLength: max,
      maxLines: lineas,
      decoration: InputDecoration(
        labelText: titulo,
        border: const OutlineInputBorder(),
      ),
      validator: (v) =>
          v == null || v.trim().isEmpty ? 'Completa este campo.' : null,
    ),
  );
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.controlador,
    builder: (context, _) {
      final g = widget.controlador;
      return PopScope(
        canPop: !g.ocupado && !_tocado,
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop && !g.ocupado) _salir();
        },
        child: Scaffold(
          appBar: AppBar(title: const Text('Mi perfil de paseador')),
          body: MarcoComunidad(
            children: [
              const Text(
                'Presenta tu servicio y las condiciones que acordarás con cada responsable.',
              ),
              const SizedBox(height: 20),
              Form(
                key: _form,
                onChanged: () {
                  if (!_tocado) setState(() => _tocado = true);
                },
                child: Column(
                  children: [
                    _campo(_nombre, 'Nombre público', 120),
                    _campo(_zona, 'Zona de cobertura', 120),
                    _campo(_bio, 'Presentación y experiencia', 1500, lineas: 3),
                    _campo(_horario, 'Disponibilidad habitual', 500, lineas: 2),
                    _campo(
                      _condiciones,
                      'Condiciones del paseo',
                      1500,
                      lineas: 3,
                    ),
                    DropdownButtonFormField<int>(
                      initialValue: _duracion,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Duración de cada paseo',
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        for (final n in [30, 60, 90, 120])
                          DropdownMenuItem(value: n, child: Text('$n minutos')),
                      ],
                      onChanged: g.ocupado
                          ? null
                          : (v) => setState(() {
                              _duracion = v!;
                              _tocado = true;
                            }),
                    ),
                    SwitchListTile(
                      title: const Text('Recibir solicitudes'),
                      subtitle: const Text(
                        'Al pausar el perfil, las reservas anteriores se conservan.',
                      ),
                      value: _activo,
                      onChanged: g.ocupado
                          ? null
                          : (v) => setState(() {
                              _activo = v;
                              _tocado = true;
                            }),
                    ),
                  ],
                ),
              ),
              if (g.error != null) AvisoComunidad(g.error!),
              FilledButton(
                key: const Key('guardar_perfil_paseador'),
                onPressed: g.ocupado ? null : _guardar,
                child: Text(g.ocupado ? 'Guardando…' : 'Guardar perfil'),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      );
    },
  );
}
