# Muro, eventos, inscripcion y chat de participantes

Implementacion del 31 de octubre de 2026. Este bloque utiliza el Firebase propio
de Champ, sin cambiar SQLite ni los registros locales existentes.

## Pantallas

- **Comunidad:** muro de texto y tarjetas de eventos; filtros Todo, Eventos,
  Paseos y Mis eventos, y busqueda por parque, ciudad o comuna.
- **Crear evento:** nombre, tipo (encuentro/paseo), parque o punto de encuentro,
  zona, fecha/hora, cupos, duracion y descripcion. El organizador ocupa un cupo.
- **Detalle:** informacion, participantes, inscripcion, cancelacion de la
  inscripcion, cancelacion del evento por su organizador y acceso al chat.
- **Chat del evento:** conversacion grupal, autor, fecha, envio y reintento que
  conserva el mensaje cuando falla. Un evento finalizado/cancelado queda en lectura.

Paseos abre el mismo catalogo filtrado por paseos compartidos. Chat conserva los
privados y agrega una pestana Eventos y paseos para acceder a los grupos inscritos.
La ficha se comparte por ID: muro, Paseos y Chat no crean copias del evento.

Los formularios no confirman exito hasta completar la transaccion. Si falla un
envio se conserva el texto en la pantalla abierta. Al salir de un formulario de
evento modificado se pide descartar; no hay guardado persistente de borradores.
Las fechas se almacenan como instantes UTC y se presentan en la hora local del
cliente. La hora se elige en la zona local del dispositivo que crea el evento.

## Persistencia y permisos

Firestore almacena:

```text
muro_champ/{publicacionId}
eventos_champ/{eventoId}
eventos_champ/{eventoId}/mensajes/{mensajeId}
```

El muro y los detalles de eventos son visibles para cuentas autenticadas de Champ.
Los nombres de participantes son visibles en las fichas. Solo los participantes
actuales pueden leer el chat; solo pueden enviar si el evento no ha finalizado ni
esta cancelado. Salir del evento revoca el acceso al chat. Como con todo mensaje
ya recibido, esto no elimina capturas o copias que alguien haya guardado antes.

Cada participante modifica exclusivamente su propia inscripcion. El organizador
no puede agregar cuentas ajenas ni borrarse de la lista; puede cancelar el evento.
La capacidad y el ultimo cupo se validan con transacciones y reglas de servidor.
Los mensajes no pueden editarse ni borrarse desde el cliente.

La jerarquia es App → AppComunidadSocial (MicroApp) → NanoApps Comunidad,
Eventos y ChatEventos → sus NanoFunciones → NanoActividades especificas →
RepositorioComunidad. La estructura completa esta en `estructura_comunidad.md`.
La implementacion real usa RepositorioComunidadFirestore. Las pruebas de pantalla
usan un repositorio de prueba; los permisos se verificaron ademas en el emulador.
Al cambiar de cuenta se destruye el shell y se cancelan las escuchas.

## Activacion en el Firebase real

El codigo queda integrado, pero la nueva funcionalidad entre cuentas requiere
Firestore y publicar el archivo actualizado `firestore.rules` en el proyecto
Firebase real de Champ. No se desplego nada en produccion en esta entrega.

```bash
firebase deploy --only firestore:rules --project ID_REAL_DE_CHAMP
```

Este comando sustituye las reglas publicadas: revisar que el proyecto y las reglas
actualmente desplegadas correspondan a esta copia de Champ antes de ejecutarlo.
Las reglas incluidas conservan el chat privado y suman muro/eventos/grupos.
No se debe habilitar una regla general de acceso publico para probar las pantallas.

Mantener la configuracion Firebase externa ya usada por el proyecto. Para iniciar
en Ubuntu, desde el proyecto actualizado:

```bash
dart run tool/champ_api.dart
# En otra terminal:
bash tool/iniciar_champ_web.sh
```

El servicio local sigue siendo necesario para los modulos locales; muro y eventos
compartidos utilizan Firestore directamente y requieren conexion para transacciones.
Un error de permisos o conexion muestra un error y permite reintentar, sin simular
datos publicados. La cache del SDK puede mostrar contenido recibido anteriormente.

## Alcance de esta etapa

Muro de texto, encuentros/paseos gratuitos, inscripcion directa por cupos, lista
de participantes y chat grupal de texto. Hasta 100 eventos/publicaciones recientes
y 100 mensajes recientes por grupo; no hay paginacion de contenido anterior.

Pendientes para otras etapas: fotos remotas, comentarios y guardados del muro,
edicion de eventos, moderacion/reportes, notificaciones push, mapa interactivo,
directorio y contratacion de paseadores, pagos y avisos de perros perdidos.
No se atribuyen esas funciones a esta implementacion.

## Comprobar

```bash
flutter analyze
flutter test
flutter build web
firebase emulators:exec --only firestore --project demo-champ 'node tool/verificar_comunidad_emulador.mjs'
```

El script utiliza el paquete JS `firebase` del proyecto y unicamente un emulador
en localhost con proyecto demo-champ. Comprueba cuatro identidades simuladas,
competencia por el ultimo cupo, mensajes, revocacion al salir y rechazos de acceso.
`tool/verificar_chat_emulador.mjs` comprueba ademas las reglas de privados existentes.

Las capturas se pueden regenerar con `flutter test tool/previsualizar_comunidad_test.dart`,
indicando `CHAMP_CAPTURAS` (carpeta de salida) y `CHAMP_FUENTE` (ruta a
roboto-regular.ttf del SDK, junto a MaterialIcons-Regular.otf). Usan datos de prueba.

Referencias de implementacion:
[transacciones](https://firebase.google.com/docs/firestore/manage-data/transactions),
[escuchas](https://firebase.google.com/docs/firestore/query-data/listen),
[validacion de campos](https://firebase.google.com/docs/firestore/security/rules-fields).
