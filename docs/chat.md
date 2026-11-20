# Chat entre usuarios

Revisión e implementación: 2026-10-21.

## Estado del proyecto revisado

Se leyeron README, ARQUITECTURA, CHANGELOG y documentos de acceso antes de
modificar. No se encontraron archivos AGENTS.md en el proyecto ni en sus
directorios padres. La carpeta `.git` entregada está vacía: no permite obtener
un diff de Git. Se editaron los módulos existentes, sin reemplazar el proyecto.

Cruces tiene perfil, fotos, filtros, decisiones y matches de demostración.
Chat ya tenía conversaciones, mensajes, fotos, migración e historial SQLite.
Membership y Carro tienen catálogo e intención de contratación local; no validan
pagos. Configuración permite respaldar la base. Inicio, Mis perros, Paseos,
Perdidos y encontrados y Comunidad conservan sus pantallas provisionales.

El servicio de acceso actual incorpora Google y correo/contraseña (incluida
creación de cuenta). Google usa popup en web y Google Sign-In en Android.
Firebase se inicializa y restaura en AutenticacionFirebase, una sola vez;
no se añade inicialización en Chat. Las opciones vienen de dart-defines o
google-services.json en Android. No hay configuración web real ni JSON Android
en el repositorio. No se comprobó la configuración externa del propietario.

## Integración

Se conserva la composición:

```text
ChampEntrada (sesión) → ChampShell → AppComunidadCanina
  → AppChat (NanoApp)
    → GestionarChat (NanoFunción)
      → ChatUsuariosActividad / PersistirChatActividad (NanoActividades)
        → CanalChatUsuarios / AlmacenChat (contratos core)
          → RepositorioChatFirestore / RepositorioChatLocal
```

El shell inyecta el canal Firestore con el UID de la sesión actual. Un cambio
de cuenta reconstruye el shell por UID; dispose cancela las suscripciones de
conversaciones y mensajes. El canal comprueba que la sesión Firebase siga
correspondiendo a ese UID. Los controladores siguen siendo inyectables.

La lista combina conversaciones entre usuarios con el historial local rotulado
«Local». Este último conserva su persistencia, fotos y apertura desde matches;
no se migra automáticamente a la nube ni se atribuye a una cuenta. Los matches
del catálogo demo no tienen identidad Firebase y siguen abriendo su chat local.

Para conversar entre dos cuentas: ambas ingresan con el Firebase de Champ,
abren Chat y comparten su ID visible. Una pulsa Conversación e introduce el ID
de la otra. No hay búsqueda por correo ni directorio público. Un ID inexistente
no puede verificarse contra Firebase Authentication desde el cliente: se puede
crear una conversación sin receptor hasta que exista esa identidad. Se debe
usar el ID compartido por la otra persona.

Cada par tiene un ID estable SHA-256 de sus UIDs ordenados, evitando duplicados
al abrir desde cualquiera de las cuentas. Firestore guarda:

- `chats/{id}`: participantes, fecha, actualizada, ultimoTexto.
- `chats/{id}/mensajes/{id}`: remitenteId, texto y fecha del servidor.

La lista escucha solo chats que contienen el UID. Al seleccionar uno se escuchan
sus últimos 100 mensajes; al cambiar se cancela la escucha anterior. El envío
es un lote atómico que crea el mensaje y actualiza la vista previa. La UI
distingue remitentes, conserva el borrador ante error, indica mensajes pendientes
y permite reconectar. El historial remoto permanece en Firestore al cerrar sesión.

## Activación con el proyecto real

1. Completar el registro propio de Champ y probar login siguiendo
   [Firebase](firebase_configuracion.md).
2. Crear la base Cloud Firestore `(default)` en ese mismo proyecto.
3. Publicar `firestore.rules` en esa base, mediante consola o Firebase CLI:
   `firebase deploy --only firestore:rules --project ID_REAL_DE_CHAMP`.
4. Iniciar Champ con sus opciones Firebase reales y probar con dos cuentas.

No se despliega nada automáticamente. `firebase.json` apunta a las reglas y
configura el emulador local; no selecciona un proyecto de producción.
Las reglas permiten lectura y envío solo a participantes autenticados,
impiden suplantar remitentes, cambiar participantes y editar o borrar mensajes.
Los mensajes admiten texto de 1 a 4000 caracteres. No requieren índices compuestos.

Referencias oficiales:
[escuchas en tiempo real](https://firebase.google.com/docs/firestore/query-data/listen),
[autenticación y reglas](https://firebase.google.com/docs/firestore/security/get-started).

## Validación y límites

Resultado: 75 pruebas Flutter aprobadas; análisis de `lib test tool` sin
incidencias; compilación web correcta. El script de emulador finalizó con
código 0 y verificó diez rechazos de seguridad, además del intercambio real
entre clientes del SDK en ese entorno local. Dos pruebas antiguas de comercio
se ajustaron a los desplazamientos y al título actual de su interfaz.

`test/chat_usuarios_test.dart` usa un canal falso compartido para comprobar dos
cuentas, reapertura, recepción, cancelación de suscripciones y reintento con
conservación del borrador. Las pruebas previas siguen cubriendo la persistencia
SQLite, fotos, importación y el recorrido Cruces → Chat.

El script de integración usa el SDK JS existente y las reglas reales en el
emulador; no usa credenciales ni datos productivos:

```bash
firebase emulators:exec --only firestore --project demo-champ 'node tool/verificar_chat_emulador.mjs'
```

Verifica creación concurrente y reapertura, lista por participante, recepción en
tiempo real en otra cuenta, respuesta y rechazo de lecturas ajenas, acceso
anónimo, suplantación, mensajes inválidos y cambios prohibidos.

Pendientes: comprobación con credenciales reales en Chrome/Android y publicación
de reglas en el Firebase real. No incluye fotos remotas, búsqueda de usuarios,
notificaciones push, confirmación de lectura, moderación ni paginación anterior
a los últimos 100 mensajes. Las fotos locales existentes siguen funcionando.
Los respaldos SQLite no incluyen Firestore; su conservación debe gestionarse
en Firebase por separado. El resto de los datos de Champ sigue en su API local.
