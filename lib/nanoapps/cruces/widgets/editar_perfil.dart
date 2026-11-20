import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../core/modelos/cruces.dart';
import '../nanofunciones/gestionar_cruces/gestionar_cruces.dart';

class EditarPerfilCruce extends StatefulWidget {
  const EditarPerfilCruce({super.key, required this.cruces});
  final GestionarCruces cruces;
  @override
  State<EditarPerfilCruce> createState() => _EditarPerfilCruceState();
}

class _EditarPerfilCruceState extends State<EditarPerfilCruce> {
  final form = GlobalKey<FormState>();
  late final inicial = widget.cruces.miPerro;
  late final nombre = TextEditingController(text: inicial?.nombre);
  late final raza = TextEditingController(text: inicial?.raza);
  late final edad = TextEditingController(text: inicial?.edadMeses.toString());
  late final ciudad = TextEditingController(text: inicial?.ciudad);
  late final responsable = TextEditingController(text: inicial?.responsable);
  late final descripcion = TextEditingController(text: inicial?.descripcion);
  late String sexo = inicial?.sexo ?? 'Macho';
  late Uint8List? foto = inicial?.foto;
  bool guardando = false;
  String? error;
  @override
  void dispose() {
    for (final c in [nombre, raza, edad, ciudad, responsable, descripcion]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _foto() async {
    setState(() {
      guardando = true;
      error = null;
    });
    final nueva = await widget.cruces.seleccionarFoto();
    if (!mounted) return;
    setState(() {
      if (nueva != null) foto = nueva;
      error = widget.cruces.error;
      guardando = false;
    });
  }

  Future<void> _guardar() async {
    if (!form.currentState!.validate()) return;
    setState(() {
      guardando = true;
      error = null;
    });
    final ok = await widget.cruces.guardarPerfil(
      PerfilPerro(
        id: inicial?.id ?? widget.cruces.identidadParaPerfil(),
        nombre: nombre.text.trim(),
        raza: raza.text.trim(),
        sexo: sexo,
        edadMeses: int.parse(edad.text.trim()),
        ciudad: ciudad.text.trim(),
        responsable: responsable.text.trim(),
        descripcion: descripcion.text.trim(),
        foto: foto,
      ),
    );
    if (!mounted) return;
    if (ok) {
      Navigator.pop(context);
    } else {
      setState(() {
        guardando = false;
        error = widget.cruces.error;
      });
    }
  }

  Widget _campo(
    String label,
    TextEditingController controller, {
    int max = 80,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextFormField(
      controller: controller,
      enabled: !guardando,
      maxLength: max,
      decoration: InputDecoration(labelText: label, counterText: ''),
      validator: (v) =>
          v == null || v.trim().isEmpty ? 'Completa este campo' : null,
    ),
  );

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !guardando,
    child: AlertDialog(
      title: Text(inicial == null ? 'Presenta a tu perro' : 'Editar mi perro'),
      content: SizedBox(
        width: 460,
        child: SingleChildScrollView(
          child: Form(
            key: form,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (foto != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.memory(
                      foto!,
                      height: 140,
                      fit: BoxFit.cover,
                      cacheWidth: 480,
                    ),
                  ),
                OutlinedButton.icon(
                  onPressed: guardando ? null : _foto,
                  icon: const Icon(Icons.add_a_photo_outlined),
                  label: Text(
                    foto == null ? 'Añadir foto (hasta 1 MB)' : 'Cambiar foto',
                  ),
                ),
                _campo('Nombre de tu perro', nombre),
                _campo('Raza', raza),
                DropdownButtonFormField<String>(
                  initialValue: sexo,
                  decoration: const InputDecoration(labelText: 'Sexo'),
                  items: ['Macho', 'Hembra']
                      .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                      .toList(),
                  onChanged: guardando
                      ? null
                      : (v) => setState(() => sexo = v!),
                ),
                TextFormField(
                  controller: edad,
                  enabled: !guardando,
                  keyboardType: TextInputType.number,
                  maxLength: 3,
                  decoration: const InputDecoration(labelText: 'Edad en meses'),
                  validator: (v) {
                    final n = int.tryParse(v?.trim() ?? '');
                    return n == null || n < 1 || n > 300
                        ? 'Ingresa una edad entre 1 y 300 meses'
                        : null;
                  },
                ),
                _campo('Ciudad', ciudad),
                _campo('Tu nombre', responsable),
                TextFormField(
                  controller: descripcion,
                  enabled: !guardando,
                  maxLength: 400,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Cuéntanos cómo es',
                  ),
                ),
                if (guardando) const LinearProgressIndicator(),
                if (error != null)
                  Text(
                    error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: guardando ? null : () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: guardando ? null : _guardar,
          child: const Text('Guardar perfil'),
        ),
      ],
    ),
  );
}
