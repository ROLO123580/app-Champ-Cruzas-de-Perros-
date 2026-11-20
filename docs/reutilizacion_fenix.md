# Referencia Fénix Fitness

Inspección de solo lectura: 2026-10-20. Hay dos copias distintas:
`C:/flutter_projects/fenix_fitness` es una base visual y
`/home/rolo/flutter_projects/fenix_fitness` en Ubuntu/WSL es la versión funcional
que el usuario mostró ejecutándose en Chrome. Fénix se conserva como referencia:
no se ejecutó `pub get`, no se cambiaron archivos ni configuración, ni se
trasladaron credenciales.

## Código encontrado en Windows

| Fuente real | Contenido comprobado | Adaptación en Champ |
| --- | --- | --- |
| `lib/nanoapps/login/app_login.dart` | `AppLogin` con nombre de app y botón `Entrar`; ejecuta un callback. Sin autenticación. | Se conserva la ruta y la entrada del módulo, agregando servicio real de Google/Firebase y estados. |
| `lib/nanoapps/membership/app_membership.dart` | `AppMembership` muestra únicamente el título `Membership`. | Se conserva la ruta; catálogo, selección y estados se implementan en Champ. |
| `lib/app_fenix_fitness.dart` | Entrada y navegación por reemplazo a un shell con sidebar/Drawer. | Se toma la distribución; Champ conserva su propio orquestador y módulos existentes. |
| `lib/core/catalogo_pantallas.dart`, `lib/sidebar/app_sidebar.dart` | Membership en el menú. | Champ reutiliza sus rutas y catálogo de navegación propios. |
| `pubspec.yaml`, `pubspec.lock` | Flutter y Cupertino; sin `firebase_core`, `firebase_auth` ni `google_sign_in`. | Champ añade dependencias reales; no hay API de autenticación del origen que adaptar. |

En esta copia Windows no existen Carro, planes, precios, beneficios, cobros,
modelos o servicios de autenticación. Esta conclusión inicial se limita a esa
copia: la versión funcional se encontró después en WSL y sí aporta planes y
servicios, descritos debajo. Los importes de esa fuente sustituyen el catálogo
vacío inicial; una selección sigue sin acreditar pago ni activar permisos.

## Documentos revisados

Se leyeron los cuatro DOCX de la raíz y sus copias en `docs/`, extrayendo
`word/document.xml` sin modificar los contenedores. Las copias tienen los mismos
SHA-256. Sus decisiones útiles son Login como entrada, Membership en menú,
sidebar desde 900 px, jerarquía modular y separación de servicios. El informe
de pantallas declara expresamente que la base visual no realiza autenticación
ni cobros; el de backend propone Firebase sin configuración verificada.
Ninguno contiene planes, importes ni condiciones.

También se revisaron `ARQUITECTURA.md`, `CHANGELOG.md`, el manifiesto de
dependencias y las rutas reales de `lib/`. Una búsqueda acotada de variantes
en `C:/flutter_projects` no encontró implementación funcional de Google ni
Carro en los proyectos vecinos `fenix_controls`, `myfitmentor`, `rh_comercio`
y `rh_pay`; las coincidencias de Membership corresponden a pantallas base.

## Fuente funcional encontrada en Ubuntu/WSL

El servidor `http://localhost:42141` pertenece al proceso Flutter PID `15293`.
`/proc/15293/cwd` resolvió a `/home/rolo/flutter_projects/fenix_fitness`.
Chrome PID `15369` usa ese URL y CDP local `46695`. Los PID y puertos son evidencia
de esta inspección y pueden cambiar al reiniciar. No se interactuó con cuentas
ni se enviaron formularios de Fénix.

| Ruta en la copia WSL | Implementación real y reutilización |
| --- | --- |
| `lib/login/app_login.dart` | Tarjeta de 420 px; correo, contraseña, mostrar/ocultar, inicio, crear cuenta y Google, carga y error. Los controladores se liberan. Se adapta el formulario y presentación a Champ. |
| `lib/login/auth_service.dart` | Inicio/registro con correo en Firebase, Google popup en web, Google Sign-In 7 con ID token en nativo, restauración por `authStateChanges` y cierre. Champ mantiene estas operaciones en sus servicios y NanoActividades; añade exclusión de solicitudes y mensajes de error/cancelación. |
| `lib/login/auth_gate.dart` | `StreamBuilder` decide Login o shell según Firebase. Champ conecta ese comportamiento desde su MicroApp y orquestador, evitando rutas duplicadas. |
| `lib/membership/app_memb.dart` | Catálogo real Free/Pro/Elite, tarjetas y selección por callback. Se conserva identidad de planes, importes y condiciones de referencia. |
| `lib/carro/app_carro.dart` | Carro con selección, subtotal, impuesto del 19% y total; botón `Pagar ahora` con callback vacío. Es visual, sin pasarela. Champ persiste la contratación pendiente sin simular un cobro. |
| `lib/membership/membership_service.dart` | Métodos Firestore para plan gratuito, orden pendiente y marcar activo desde cliente; no están invocados por la UI inspeccionada. No validan pago. Champ conserva SQLite/API y no porta la activación de pago desde cliente. |
| `lib/sidebar/app_sidebar.dart` | `selectedPlan` y `showCart` locales coordinan Membership → Carro → Volver. Champ conserva el comportamiento con selección persistente y su navegación existente. |
| `lib/ui/fenix_theme.dart`, `fenix_widgets.dart` | Material 3, naranja, tarjetas blancas, banner y distribución adaptable; referencia visual adaptada a Champ. |
| `lib/firebase_options.dart`, `android/app/google-services.json` | Configuración real de Fénix; no se copia como configuración de Champ. |

Versiones resueltas en `pubspec.lock` de esa fuente: `firebase_core 4.15.0`,
`firebase_auth 6.7.0`, `google_sign_in 7.2.0`. También depende de Firestore y
Provider; no se incorporan por arrastre al contenido local de Champ.

### Planes y límites de la fuente

La moneda USD se encuentra en `membership_service.dart`; `app_memb.dart`
presenta valores mensuales con símbolo `$`:

| Plan | Subtotal mensual de origen | Beneficios textuales de origen |
| --- | --- | --- |
| Free | USD 0.00 | Registro de consumos; Gastos energéticos; Seguimiento básico |
| Pro | USD 9.99 | Todo lo de Free; Análisis nutricional; Estadísticas; Sincronización |
| Elite | USD 19.99 | Todo lo de Pro; IA premium; Reportes avanzados; Soporte prioritario |

El carro aplica impuesto del 19%: totales mensuales USD 0.00 / 11.89 / 23.79,
redondeados a dos decimales como en su presentación. Ese impuesto y las
condiciones provienen del código de Fénix, no de una política comercial nueva.
Los beneficios fitness se conservan como referencia del origen y no acreditan
funciones caninas ya desarrolladas ni servicios de pago operativos.

No hay procesamiento de tarjetas ni verificación de pago: los campos de tarjeta
del origen son visuales, y el botón no llama a una pasarela. Champ no recopila
tarjetas ni activa membresías pagadas a partir de la selección local.

### Firebase y separación entre aplicaciones

El proyecto configurado en WSL es `fenix-fitness-4ed48`. Sus opciones web/Android
y JSON coinciden entre sí, pero el paquete es `com.example.fenix_fitness`;
el JSON no contiene un cliente `com.example.champ`. La huella debug de ese JSON
coincide con el certificado WSL observado, lo que no registra automáticamente
otra aplicación. Los dominios autorizados y proveedores no pueden comprobarse
leyendo esos archivos. Champ requiere sus registros reales; véase
[firebase_configuracion.md](firebase_configuracion.md).

### Integridad de la copia funcional

Hashes SHA-256 capturados tras encontrar el proceso. Las rutas son relativas a
`/home/rolo/flutter_projects/fenix_fitness`; no se modificó esta fuente.
Una segunda lectura verificó los doce hashes sin diferencias.

| Archivo WSL | SHA-256 |
| --- | --- |
| `lib/login/app_login.dart` | `ec1f0a5a1efd6e07bfc77f8c1f31294140dae7601247ebb39b53e9545bc023c7` |
| `lib/login/auth_gate.dart` | `aec6eeca4d5b386625346dd3f24d0fc45e3b2a1af848b5edfedc5a86091c4519` |
| `lib/login/auth_service.dart` | `8a40edd67bc1ed96b5ed7b46938a16d6eb3c734a7bcc310ffcb3d4f10a29e8e3` |
| `lib/membership/app_memb.dart` | `5872535586647909b4f9d35efb140cc69e655d049b1566845c1349a8eb9f33a1` |
| `lib/membership/membership_service.dart` | `67b94cc07671572a47f3301d58ac8d2ae690d68d214482c623a0a2229d9cb187` |
| `lib/carro/app_carro.dart` | `5f723920d00d485b3d6ee85507b06dfd20f1fc53817aba4e4896e558b7a1b417` |
| `lib/firebase_options.dart` | `9303119434554211d311fa6ced9f6d475ae3af2a8130a236222bc244f6fe5cc5` |
| `pubspec.yaml` | `b511b23deb2772e3331facd0954a18d0484ec5e42eaac38e403c925239f51441` |
| `lib/ui/fenix_theme.dart` | `163cac29795b274fedf8bada319043658bd5d1ebd614e4eb69aad7ef2b78b820` |
| `lib/ui/fenix_widgets.dart` | `05663a708b0f1e920b713c6c2b7c7878bc19dc6bc43cc31fa4f89cd4e9e77ba2` |
| `android/app/google-services.json` | `0f87b223d990e3a29ee4207bbabff5501b16b73ab3502e2d630a0b3ae051fa9d` |
| `lib/sidebar/app_sidebar.dart` | `cada77c1c1df525079c42a867181031f3ce72b1c0d78883e9fab215fb32b2f47` |

## Integridad de la copia Windows

SHA-256 capturados durante la inspección; las rutas de esta tabla son relativas
a Fénix Fitness. Al cerrar la integración se vuelven a calcular y comparar.
La segunda lectura comprobó los 17 archivos sin diferencias.

| Archivo | SHA-256 |
| --- | --- |
| `lib/nanoapps/login/app_login.dart` | `fc58989bb99be0fad6337836f011100f98e8685a5e3a12d736f6b925a3ab00d0` |
| `lib/nanoapps/membership/app_membership.dart` | `ca28be801fffc57c6856ab095004ae63e2421e0df2d2a92dbee82de2df0678ef` |
| `lib/app_fenix_fitness.dart` | `8e406e216c65e763ee5f75ef0e273b3ac17c11a4afe30d6ec828e887021a36cc` |
| `lib/core/catalogo_pantallas.dart` | `975d9ea1e80e61e0647ee0c480af9153801e04bedaa48ca91f9ffef0cc14e16b` |
| `lib/sidebar/app_sidebar.dart` | `e3e54eb9d6324ae3fc73daf33016a471d8c9d8608e101b703d2e6fa1cd3e51b6` |
| `pubspec.yaml` | `e3559edb56421ecbe26a6fb497afc7847ea6b8e6f32e3188cb69cf67b4423a58` |
| `pubspec.lock` | `8d86bf6c91a2ae8f54516baa36d24588b252a232167ee0d543e5e8eb3bd3aec4` |
| `ARQUITECTURA.md` | `34a5f9a7835c55959831ce651d1f4dc75a18c83a90eb31750514ad92bdb99c70` |
| `CHANGELOG.md` | `fb41c2a5fb73e1280900e10dd0f382f92e4ca245f6d314a166dc4cceaca48b30` |
| `01_diseno_ui.docx` y `docs/01_diseno_ui.docx` | `0327850b3fb1b6fea59f1f5a871c3d1fa17e8593a5b8368ee39da0abd214a069` |
| `02_logica_y_carpetas.docx` y `docs/02_logica_y_carpetas.docx` | `82e2284c7e30aa369adff215ad01357cf88b99610c3cfe88d8f4ee12a932c293` |
| `03_pantallas.docx` y `docs/03_pantallas.docx` | `2ac457062673abbb4df32a576ef01179e52af13a989b946b9d6f98e02e58f46d` |
| `04_backend_y_api.docx` y `docs/04_backend_y_api.docx` | `f92b63e3b3dc8232390b2614d75fefd96836ac5bdd53a1f1fe59b6cee6a1191b` |
