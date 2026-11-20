# Prueba de Champ con 3 o 4 personas

Esta entrega prepara un piloto sin cobros. Cada persona entra con su propia cuenta de Firebase Authentication; no se deben compartir contraseñas ni cuentas.

## Qué pertenece a cada cuenta

- La ficha activa del perro y su historial de Cruces se guardan en `fichas_privadas_champ/{uid}`. Solo el propietario puede leer o guardar su documento. Los conflictos entre dispositivos se rechazan por revisión para evitar sobrescrituras silenciosas.
- Las reservas se consultan por cliente o paseador. Solo esas dos personas pueden verlas. El paseador acepta o rechaza; el cliente puede cancelar una solicitud; ambos pueden cancelar una reserva aceptada. El paseador inicia cuando llega el horario y finaliza el servicio.
- Los chats entre personas siguen siendo privados para sus participantes. Las conversaciones de demostración de Cruces se conservan solo durante esa sesión; no se mezclan con los datos locales antiguos.
- El muro, los eventos, los perfiles activos de paseadores y los avisos se comparten con las cuentas autenticadas de Champ. Un perfil de paseador es información declarada por su autor, sin verificación profesional ni reputación inventadas.

## Datos anteriores

No se importan ni borran las fichas, fotos, chats o selecciones comerciales guardados en SQLite. La aplicación autenticada empieza con su propia ficha en Firebase. La administración del archivo SQLite anterior no se ofrece desde las cuentas del piloto.

Cruces conserva un catálogo de demostración; no constituye un directorio de perros reales de los otros participantes. Esta etapa permite una ficha activa por cuenta. No se han añadido pagos, planes contratables ni derechos de membresía.

## Paseadores y agenda

Paseos contiene Compartidos, Paseadores y Mi agenda. Un usuario publica su perfil con zona, disponibilidad orientativa, duración y condiciones. Otro revisa esas condiciones y solicita un horario futuro en intervalos de 30 minutos. La solicitud no confirma el paseo: el paseador debe aceptarla.

Al aceptar, una transacción ocupa todos los bloques de media hora del paseo (hasta 120 minutos). Dos solicitudes superpuestas no pueden confirmarse a la vez. Cancelar o finalizar libera los bloques en la misma transacción. La disponibilidad escrita no reemplaza esa validación.

## Antes de invitar personas

1. Publicar las nuevas reglas de fichas privadas, paseadores, reservas y bloques; las reglas anteriores de muro, eventos, avisos y chats ya estaban publicadas. Esta ampliación aún requiere publicación por separado.
2. Ofrecer una URL accesible desde sus equipos. `localhost:8793` solo funciona en el equipo que sirve la aplicación; no es una URL para enviar a los participantes. Una publicación web requiere configurar Hosting y su dominio autorizado en Authentication.
3. Cada participante crea su cuenta o usa Google. No hace falta pertenecer al repositorio GitHub para utilizar la app publicada.
4. Probar con cuatro cuentas reales antes de declarar terminado el piloto. Las pruebas automáticas usan identidades ficticias en el emulador, no cuentas humanas de producción.

## Recorrido de aceptación

- A crea su ficha. B, C y D deben ver sus propias fichas vacías al entrar; al cambiar de cuenta no aparece la ficha de A.
- A publica como paseador. B y C solicitan el mismo horario; A solo puede aceptar una de esas reservas. D no ve ninguna reserva ajena.
- B y A conversan por chat. C y D no ven esa conversación.
- D publica un evento con un cupo. B y C intentan inscribirse; solo uno ocupa el último cupo. Quien salga del evento pierde acceso a su chat de grupo.
- A publica un aviso de perro perdido con solo los últimos cuatro dígitos del chip. B lo ve y contacta; solo A edita o cierra su aviso.
- C publica en el muro. Las cuatro cuentas lo ven. Las operaciones anónimas deben rechazarse.
- Cerrar sesión y volver a entrar desde otro dispositivo: la ficha propia debe recuperarse de Firebase.

No subir datos sensibles de prueba. El microchip identifica al perro cuando se escanea físicamente; no emite ubicación GPS.

## Validación técnica

Scripts `tool/verificar_reservas_emulador.mjs` y `tool/verificar_fichas_emulador.mjs`: cuatro identidades, privacidad, revisiones, concurrencia y liberación de horarios. Se complementan con las verificaciones de chat, comunidad y avisos. Todos rechazan hosts distintos de localhost/127.0.0.1 y usan el proyecto `demo-champ`.

Los archivos de configuración Firebase reales permanecen fuera del paquete de código. No se exportan contraseñas, bases personales ni cuentas de Authentication.
