# Configuración de Champ

La pantalla de una cuenta autenticada reúne Mi cuenta, Apariencia, Privacidad y datos y Ayuda.

- Mi cuenta muestra nombre y correo de la sesión; permite copiar el identificador que utiliza el chat y cerrar sesión con confirmación. No cambia contraseñas ni elimina cuentas.
- Apariencia ofrece tema del sistema, claro u oscuro y texto normal, grande o más grande. Los cambios se aplican a la aplicación y se guardan en `champ.apariencia.v1` del navegador o equipo mediante SharedPreferences. Se comparten entre las sesiones del mismo dispositivo; no se guardan credenciales ni información personal allí. No se sincronizan con otros dispositivos.
- Restablecer apariencia recupera los valores predeterminados, incluso si las preferencias guardadas estaban dañadas. Un guardado fallido conserva la apariencia anterior y muestra el error.
- Privacidad distingue datos privados por cuenta, publicaciones compartidas y archivos SQLite anteriores. No ofrece respaldar datos locales desde las cuentas del piloto.
- Ayuda explica las reservas, los ejemplos de Cruces, el microchip sin GPS y la etapa sin cobros.

Arquitectura: Configuración → GestionarPreferencias → PersistirPreferencias → RepositorioPreferencias → PreferenciasDispositivo. Las acciones de sesión usan la NanoFunción de sesión existente. La configuración local anterior de SQLite conserva su pantalla separada.

Las pruebas verifican persistencia, recuperación de preferencias dañadas, conservación ante error, aplicación de tema/tamaño en MaterialApp y confirmación de cierre de sesión. No se publican reglas ni Hosting para este cambio.
