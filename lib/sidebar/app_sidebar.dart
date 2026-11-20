import 'package:flutter/material.dart';

import '../core/modelos/sesion.dart';
import '../navegacion/catalogo_pantallas.dart';

class AppSidebar extends StatelessWidget {
  const AppSidebar({
    super.key,
    required this.seleccion,
    required this.onSeleccion,
    this.usuario,
    this.ocupado = false,
    this.errorSesion,
    this.onCerrarSesion,
  });

  final int seleccion;
  final ValueChanged<int> onSeleccion;
  final UsuarioChamp? usuario;
  final bool ocupado;
  final String? errorSesion;
  final VoidCallback? onCerrarSesion;

  @override
  Widget build(BuildContext context) => Material(
    color: Theme.of(context).colorScheme.surface,
    child: SafeArea(
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Champ',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
          ),
          const Divider(height: 1),
          if (usuario case final UsuarioChamp actual)
            ListTile(
              leading: ClipOval(
                child: actual.fotoUrl == null
                    ? const Icon(Icons.account_circle, size: 40)
                    : Image.network(
                        actual.fotoUrl!,
                        width: 40,
                        height: 40,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) =>
                            const Icon(Icons.account_circle, size: 40),
                      ),
              ),
              title: Text(actual.nombre ?? 'Cuenta de Google'),
              subtitle: actual.correo == null ? null : Text(actual.correo!),
            ),
          Expanded(
            child: ListView.builder(
              key: const Key('navegacion_modulos'),
              padding: const EdgeInsets.all(8),
              itemCount: titulos.length,
              itemBuilder: (context, index) => ListTile(
                leading: Icon(switch (titulos[index]) {
                  'Inicio' => Icons.home_outlined,
                  'Mis perros' => Icons.pets_outlined,
                  'Cruces' => Icons.favorite_outline,
                  'Paseos' => Icons.route_outlined,
                  'Perdidos y encontrados' => Icons.travel_explore,
                  'Comunidad' => Icons.groups_outlined,
                  'Chat' => Icons.chat_bubble_outline,
                  'Configuración' => Icons.settings_outlined,
                  'Carro' => Icons.shopping_bag_outlined,
                  _ => Icons.workspace_premium_outlined,
                }),
                title: Text(titulos[index]),
                selected: seleccion == index,
                selectedTileColor: Theme.of(context)
                    .colorScheme
                    .primaryContainer,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                onTap: () => onSeleccion(index),
              ),
            ),
          ),
          if (onCerrarSesion != null) ...[
            const Divider(height: 1),
            if (errorSesion case final String mensaje)
              Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  mensaje,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: Text(ocupado ? 'Cerrando sesión…' : 'Cerrar sesión'),
              enabled: !ocupado,
              onTap: ocupado ? null : onCerrarSesion,
            ),
          ],
        ],
      ),
    ),
  );
}
