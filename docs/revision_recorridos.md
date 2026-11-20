# Revisión de recorridos — 1 de noviembre de 2026

Continúa la preparación de Champ. Por decisión del propietario, no se publica el piloto ni se activan las nuevas reglas de Firebase.

## Cambios de uso

- La solicitud de paseo pide confirmación antes de salir con un borrador sin enviar. Seguir editando conserva el contenido; descartar vuelve a la pantalla anterior. Mientras envía, bloquea la salida y los campos.
- La fecha debe ser futura y la hora terminar en :00 o :30. Una elección inválida muestra el motivo y deja sin selección el horario para evitar enviar una hora anterior por error.
- El detalle de reserva actualiza sus acciones cada 30 segundos para habilitar el inicio al llegar el horario sin tener que cerrar la pantalla.
- Un fallo al abrir chat limpia el mensaje anterior cuando se vuelve a intentar.
- Inicio, Mis perros y Cruces explican si la ficha pertenece a la cuenta o se guarda localmente. El chat de demostración de una sesión autenticada aclara que no contacta a otra persona.

## Verificaciones

Pruebas de interfaz: protección de borrador, directorio a solicitud, validación sin envío, aceptación fallida y reintento, cancelación confirmada y descartada, inicio/finalización y restricciones de acciones para el cliente. La suite general también cubre acceso, perfiles, chat, comunidad, avisos y persistencia local.

Estos recorridos usan repositorios de prueba. No son una prueba manual con cuatro personas reales ni activan permisos pendientes en producción. Las reglas de fichas privadas y reservas continúan sin publicar; esas funciones necesitan el emulador local o la futura activación para conectarse de extremo a extremo.

Los datos locales anteriores se conservan, sin importación automática. No hay cobros. Cruces mantiene perfiles e intereses de demostración.
