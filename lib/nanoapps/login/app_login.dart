import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'nanofunciones/gestionar_sesion/gestionar_sesion.dart';
import 'widgets/boton_ingresar_google.dart';

/// Formulario adaptado de /home/rolo/flutter_projects/fenix_fitness/lib/login.
/// La pantalla presenta; la NanoFunción coordina el acceso mediante sus servicios.
class AppLogin extends StatefulWidget {
  const AppLogin({super.key, required this.controlador});
  final GestionarSesion controlador;

  @override
  State<AppLogin> createState() => _AppLoginState();
}

class _AppLoginState extends State<AppLogin> {
  static const _verde = Color(0xFF25856A);
  final _correo = TextEditingController();
  final _clave = TextEditingController();
  final _confirmacion = TextEditingController();
  GlobalKey<FormState> _formulario = GlobalKey<FormState>();
  bool _creandoCuenta = false;
  bool _ocultarClave = true;
  bool _ocultarConfirmacion = true;
  bool _entrandoGoogle = false;

  GestionarSesion get gestion => widget.controlador;
  bool get _bloqueado => !gestion.listo || gestion.ocupado;

  @override
  void dispose() {
    _correo.dispose();
    _clave.dispose();
    _confirmacion.dispose();
    super.dispose();
  }

  bool _puedeAutenticar({bool google = false}) {
    if (_bloqueado) return false;
    if (gestion.disponible) return true;
    final pendiente = gestion.configuracionPendiente;
    if (pendiente != null) {
      showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(
            google
                ? 'Configurar acceso con Google'
                : 'Configurar acceso de Champ',
          ),
          content: SizedBox(
            width: 480,
            child: SingleChildScrollView(child: SelectableText(pendiente)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Entendido'),
            ),
          ],
        ),
      );
    }
    return false;
  }

  Future<void> _enviarFormulario() async {
    if (_bloqueado || !_formulario.currentState!.validate()) return;
    if (!_puedeAutenticar()) return;
    TextInput.finishAutofillContext(shouldSave: false);
    if (_creandoCuenta) {
      await gestion.crearCuenta(correo: _correo.text, clave: _clave.text);
    } else {
      await gestion.entrarCorreo(correo: _correo.text, clave: _clave.text);
    }
  }

  Future<void> _continuarGoogle() async {
    if (!_puedeAutenticar(google: true)) return;
    setState(() => _entrandoGoogle = true);
    try {
      await gestion.entrarGoogle();
    } finally {
      if (mounted) setState(() => _entrandoGoogle = false);
    }
  }

  void _cambiarModo() {
    if (_bloqueado) return;
    FocusScope.of(context).unfocus();
    _clave.clear();
    _confirmacion.clear();
    gestion.limpiarAvisos();
    setState(() {
      _creandoCuenta = !_creandoCuenta;
      _formulario = GlobalKey<FormState>();
      _ocultarClave = true;
      _ocultarConfirmacion = true;
    });
  }

  InputDecoration _decoracion(String etiqueta, IconData icono) =>
      InputDecoration(
        labelText: etiqueta,
        prefixIcon: Icon(icono),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE7EAF2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _verde, width: 1.5),
        ),
      );

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: gestion,
    builder: (context, _) => Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Container(
              key: const Key('tarjeta_acceso'),
              width: 420,
              padding: const EdgeInsets.all(36),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(blurRadius: 20, color: Colors.black12),
                ],
              ),
              child: AutofillGroup(
                onDisposeAction: AutofillContextAction.cancel,
                child: Form(
                  key: _formulario,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.pets, size: 70, color: _verde),
                      const SizedBox(height: 10),
                      const Text(
                        'CHAMP',
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF25211F),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _creandoCuenta
                            ? 'Crea tu cuenta para continuar'
                            : 'Inicia sesión para continuar',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 30),
                      TextFormField(
                        key: const Key('correo_acceso'),
                        controller: _correo,
                        enabled: !_bloqueado,
                        autofillHints: const [AutofillHints.email],
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        autocorrect: false,
                        decoration: _decoracion(
                          'Correo electrónico',
                          Icons.email_outlined,
                        ),
                        validator: GestionarSesion.validarCorreo,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        key: const Key('clave_acceso'),
                        controller: _clave,
                        enabled: !_bloqueado,
                        obscureText: _ocultarClave,
                        autofillHints: [
                          _creandoCuenta
                              ? AutofillHints.newPassword
                              : AutofillHints.password,
                        ],
                        enableSuggestions: false,
                        autocorrect: false,
                        textInputAction: _creandoCuenta
                            ? TextInputAction.next
                            : TextInputAction.done,
                        onFieldSubmitted: (_) {
                          if (!_creandoCuenta) _enviarFormulario();
                        },
                        decoration:
                            _decoracion(
                              'Contraseña',
                              Icons.lock_outline,
                            ).copyWith(
                              suffixIcon: IconButton(
                                tooltip: _ocultarClave
                                    ? 'Mostrar contraseña'
                                    : 'Ocultar contraseña',
                                onPressed: _bloqueado
                                    ? null
                                    : () => setState(
                                        () => _ocultarClave = !_ocultarClave,
                                      ),
                                icon: Icon(
                                  _ocultarClave
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                ),
                              ),
                            ),
                        validator: (valor) => GestionarSesion.validarClave(
                          valor,
                          cuentaNueva: _creandoCuenta,
                        ),
                      ),
                      if (_creandoCuenta) ...[
                        const SizedBox(height: 16),
                        TextFormField(
                          key: const Key('confirmacion_acceso'),
                          controller: _confirmacion,
                          enabled: !_bloqueado,
                          obscureText: _ocultarConfirmacion,
                          autofillHints: const [AutofillHints.newPassword],
                          enableSuggestions: false,
                          autocorrect: false,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _enviarFormulario(),
                          decoration:
                              _decoracion(
                                'Confirmar contraseña',
                                Icons.lock_outline,
                              ).copyWith(
                                suffixIcon: IconButton(
                                  tooltip: _ocultarConfirmacion
                                      ? 'Mostrar confirmación'
                                      : 'Ocultar confirmación',
                                  onPressed: _bloqueado
                                      ? null
                                      : () => setState(
                                          () => _ocultarConfirmacion =
                                              !_ocultarConfirmacion,
                                        ),
                                  icon: Icon(
                                    _ocultarConfirmacion
                                        ? Icons.visibility
                                        : Icons.visibility_off,
                                  ),
                                ),
                              ),
                          validator: (valor) => valor != _clave.text
                              ? 'Las contraseñas no coinciden.'
                              : null,
                        ),
                      ],
                      if (gestion.error case final String mensaje) ...[
                        const SizedBox(height: 15),
                        Semantics(
                          liveRegion: true,
                          child: Text(
                            mensaje,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ),
                        if (!gestion.disponible &&
                            gestion.configuracionPendiente == null)
                          TextButton(
                            onPressed: _bloqueado
                                ? null
                                : gestion.reintentarInicializacion,
                            child: const Text('Reintentar conexión'),
                          ),
                      ],
                      if (gestion.cancelado) ...[
                        const SizedBox(height: 15),
                        const Text(
                          'Acceso cancelado. Puedes volver a intentarlo.',
                        ),
                      ],
                      const SizedBox(height: 22),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: FilledButton(
                          key: const Key('enviar_acceso'),
                          onPressed: _bloqueado ? null : _enviarFormulario,
                          style: FilledButton.styleFrom(
                            backgroundColor: _verde,
                            foregroundColor: Colors.white,
                            shape: const StadiumBorder(),
                          ),
                          child:
                              gestion.ocupado &&
                                  gestion.listo &&
                                  !_entrandoGoogle
                              ? const SizedBox.square(
                                  dimension: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  _creandoCuenta
                                      ? 'CREAR CUENTA'
                                      : 'INICIAR SESIÓN',
                                ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: OutlinedButton(
                          key: const Key('alternar_acceso'),
                          onPressed: _bloqueado ? null : _cambiarModo,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _verde,
                            side: const BorderSide(color: _verde),
                            shape: const StadiumBorder(),
                          ),
                          child: Text(
                            _creandoCuenta
                                ? 'VOLVER A INICIAR SESIÓN'
                                : 'CREAR CUENTA',
                          ),
                        ),
                      ),
                      const SizedBox(height: 25),
                      const Row(
                        children: [
                          Expanded(child: Divider(color: Color(0xFFE0E4E1))),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 12),
                            child: Text('O'),
                          ),
                          Expanded(child: Divider(color: Color(0xFFE0E4E1))),
                        ],
                      ),
                      const SizedBox(height: 20),
                      BotonIngresarGoogle(
                        texto: 'CONTINUAR CON GOOGLE',
                        cargando: gestion.ocupado && _entrandoGoogle,
                        onPressed: _bloqueado ? null : _continuarGoogle,
                      ),
                      if (!gestion.listo) ...[
                        const SizedBox(height: 20),
                        const LinearProgressIndicator(),
                        const SizedBox(height: 12),
                        const Text('Restaurando sesión…'),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
