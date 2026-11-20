# Membership y Carro de Champ

Actualizado: 2026-10-20.

## Fuente real y reutilización

La fuente funcional revisada, sin modificarla, es
`/home/rolo/flutter_projects/fenix_fitness` dentro de Ubuntu/WSL:

- `lib/membership/app_memb.dart`: tarjetas Free, Pro y Elite, beneficios,
  precios por mes, presentación adaptable y callback de selección.
- `lib/membership/membership_service.dart`: moneda USD, órdenes pendientes
  y escritura de membresías en Firestore.
- `lib/carro/app_carro.dart`: composición producto/resumen, subtotal, impuesto
  del 19 %, total y navegación de regreso.
- `lib/ui/fenix_widgets.dart` y `lib/ui/fenix_theme.dart`: tarjetas de borde
  redondeado, colores, encabezados, banner y distribución ResponsiveWrap.

El proyecto homónimo `C:/flutter_projects/fenix_fitness` es otra copia:
Membership allí solo muestra un texto. Sus cuatro documentos `.docx` describen
esa base visual y no sustituyen los módulos funcionales de WSL. Las copias de
esos documentos en `docs/` tienen los mismos hashes que los de su raíz.

Se reutilizaron en Champ los valores literales del catálogo funcional, el
patrón de tarjetas y ResponsiveWrap, la selección hacia Carro y la composición
adaptable producto/resumen. Se adaptaron nombres, imports y conexión a las
NanoFunciones/actividades y a la API local existente. No se copió el acceso
Firestore a contenido por usuario: el repositorio de Champ usa su `champ.db`.

## Catálogo conservado del origen

| Plan | Precio base | Periodo | Beneficios literales de Fénix |
| --- | --- | --- | --- |
| Free | USD 0.00 | mes | Registro de consumos; Gastos energéticos; Seguimiento básico |
| Pro | USD 9.99 | mes | Todo lo de Free; Análisis nutricional; Estadísticas; Sincronización |
| Elite | USD 19.99 | mes | Todo lo de Pro; IA premium; Reportes avanzados; Soporte prioritario |

Se conservan también los subtítulos: “Comienza tu camino”, “Entrena con más
control” y “Sin límites”. No se renombraron los beneficios de Fitness como
funciones caninas: serían condiciones inventadas. Cada plan importado lleva
`procedencia: Fénix Fitness` y `requiereAdaptacion: true`. Membership y Carro
muestran que esos beneficios todavía no están implementados en Champ y que el
catálogo es de referencia. Seleccionar conserva una intención local y no
constituye una oferta o contratación habilitada.

El 19 % se reproduce como tasa del Carro de origen, señalada expresamente como
referencia de Fénix. Con redondeo a centavos, Pro muestra USD 1.90 de impuestos y
USD 11.89 de total de referencia; Elite, USD 3.80 y USD 23.79. Esto no fija una
condición fiscal de Champ ni habilita un cobro.

## Rutas y responsabilidades

```text
lib/microapps/comercio/app_comercio.dart
lib/nanoapps/membership/app_membership.dart
lib/nanoapps/membership/nanofunciones/gestionar_membership/
  gestionar_membership.dart
  nanoactividades/persistir_membership/persistir_membership.dart
lib/nanoapps/carro/app_carro.dart
lib/nanoapps/carro/nanofunciones/gestionar_carro/
  gestionar_carro.dart
  nanoactividades/persistir_carro/persistir_carro.dart
lib/core/modelos/membership.dart
lib/core/repositorios/membership_local.dart
lib/core/catalogos/membership_fenix.dart
```

El orquestador principal inyecta `GestionarMembership(repositorio: ...)` en
`AppComercio`. La MicroApp conecta Membership y Carro mediante callbacks;
no apila rutas al seleccionar o volver. Carro crea/destruye su NanoFunción y
comunica cambios a la de Membership para refrescar su resumen. Reentrar a
Membership vuelve a consultar el catálogo por API. Las pantallas no abren la
base ni implementan persistencia. Las funciones evitan operaciones duplicadas
y notificaciones después de `dispose`.

## API, SQLite y conservación

El flujo es App → MicroApp → NanoApp → NanoFunción → NanoActividad →
repositorio core → API HTTP local → `champ.db`. El catálogo usa
`planes_membership`; la selección y el Carro comparten un único documento
`membership/estado`, confirmado transaccionalmente por `BaseLocal.guardar`.
No hay bases por cuenta, campos UID, credenciales ni tokens de Google.

`ImportarCatalogoMembershipFenix` importa por primera vez los IDs estables
`fenix_free`, `fenix_pro` y `fenix_elite`. Inserta solo faltantes mediante
`guardar_si_nuevo` y escribe el marcador
`meta/membership_fenix_2026_10_20_v1` en el mismo lote. Dos clientes no duplican
ni reemplazan planes existentes. El marcador evita volver a insertar planes
retirados posteriormente. Los catálogos o ediciones locales previos conservan
sus registros. Las pruebas de catálogo exclusivamente ficticio pueden construir
`RepositorioMembershipLocal(base, sembrarReferenciaFenix: false)`.

Se reutiliza el almacén documental del esquema 3. Los campos opcionales de
procedencia, adaptación, orden e impuesto admiten documentos previos y no
requieren un cambio físico de esquema. El respaldo general incluye las
colecciones y su marcador. Cerrar sesión no borra fichas, catálogos, likes,
matches, chat ni selección comercial.

La herramienta de mantenimiento existente opera por la misma API:

```bash
dart run tool/champ_db.dart listar planes_membership
dart run tool/champ_db.dart guardar planes_membership ID_PLAN /ruta/plan-real.json
```

El JSON requiere `id` (igual a `ID_PLAN`), `nombre`, `precioMenor` (entero
no negativo en unidades monetarias menores), `decimalesMoneda` (0 a 4),
`moneda` (tres letras mayúsculas), `periodo` explícito y `beneficios`
(lista de textos no vacíos). Admite `descripcion`, `disponible`,
`procedencia`, `requiereAdaptacion`, `ordenCatalogo` e
`impuestoPuntosBase` (0 a 10000; 1900 significa 19 %). El precio y los impuestos
se calculan como enteros; no se guardan dobles monetarios. Un plan inválido no
se publica como seleccionable.

## Estados y límites de contratación

Los estados locales son `sinSeleccion` → `seleccionado` → `pendiente`.
Revisar la misma selección conserva su estado pendiente. Antes de pasar a
pendiente se comparan las condiciones mostradas con el documento persistido
y el catálogo: si ya cambiaron precio, beneficios, moneda, periodo o impuesto,
se exige actualizar/volver a seleccionar. Las escrituras entre ventanas siguen
la política local de última escritura; no son transacciones comerciales.

`EstadoMembership.membresiaActiva` siempre es falso, incluso para Free. Ningún
documento con `pagado` o `membresiaActiva: true` concede permisos; el estado
local desconocido `activa` se rechaza.

La fuente funcional contiene `activarPlanFree` y `confirmarMembership`, que
escriben “activo” desde el cliente, sin una pasarela verificable. Su botón
“Pagar ahora” tiene callback vacío y los campos de tarjeta son visuales.
Champ no reproduce esas activaciones ni pide números de tarjeta, CVC o
descuentos sin servicio. La selección/pendiente funcionan realmente mediante
API y SQLite; pagos y licencias requieren una autoridad externa de contratación.

## Comprobaciones incorporadas y pendientes

- `test/membership_test.dart`: valores literales de origen y cálculo del
  impuesto; aviso visible de beneficios pendientes; validación de precios;
  estados sin permisos; duplicados/dispose; error/reintento; rechazo de
  activación local; catálogo ficticio vacío; reentrada y recorrido
  Membership → Carro → pendiente → Membership → Carro → quitar.
- `test/membership_api_test.dart`: HTTP real con SQLite temporal aislado;
  importación concurrente idempotente preservando ediciones y bajas; reinicios
  conservando selección y pendiente, fichas y un único match; rechazo de
  condiciones antiguas entre dos clientes; planes ausentes, retirados o
  inválidos; conservación del esquema 3.

Los fixtures identificados como prueba permanecen exclusivamente en
`test/soporte/membership_prueba.dart`. Las comprobaciones automáticas y su
resultado final se registran en `CHANGELOG.md` y `ARQUITECTURA.md`. La revisión
manual en Chrome/Android y los pagos reales solo deben considerarse probados
cuando exista evidencia de ejecución. Pendiente externo: definir qué
beneficios reales ofrecerá Champ y conectarlos a contratación/pagos verificables.
