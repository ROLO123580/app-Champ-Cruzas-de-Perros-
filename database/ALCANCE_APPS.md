# Alcance de las nueve apps

Definición del usuario recibida el 29-10-2026. Esta definición tiene prioridad
sobre las inferencias realizadas a partir de los menús iniciales. Las entidades
de la tercera columna son una propuesta de modelado pendiente de implementación;
no indican que existan tablas o integraciones funcionales.

## Regla de implementación

Todo desarrollo sigue **App → Microapp → Nanoapp → Nanofunción → Nanoactividad**.
App orquesta; Microapp agrupa el dominio; Nanoapp presenta la pantalla;
Nanofunción coordina el caso de uso; Nanoactividad realiza una operación atómica.
Los adaptadores de SQLite, Turso, cámara e IA son infraestructura invocada por
esa jerarquía. Una pantalla no debe ejecutar SQL ni coordinar directamente la
persistencia. Incorporar archivos o tablas no equivale a completar un módulo.

## Orden inmediato de avance

1. Completar el recorrido nutricional de Fenix Fitness: revisar la delegación de
   confirmación y persistencia según la jerarquía; añadir consulta de porciones,
   historial diario y totales, usando las instantáneas de macros ya guardadas.
2. Validar el recorrido real de crear ficha, registrar porción, reiniciar y
   consultar el historial. Cámara/micrófono requieren comprobación física;
   Gemini/Turso requieren configuración y pruebas reales del servicio.
3. Rediseñar el prototipo RH Comercio alrededor de cuentas, división de pagos
   y reservas, con migración si ya existen datos; conservar RH Pay como dominio
   separado para ejecución y conciliación de pagos.
4. Ampliar los modelos restantes conforme a este alcance, implementando y
   verificando un caso de uso completo por módulo.

Este orden registra el trabajo siguiente; no presenta esas ampliaciones como
funciones ya implementadas.

| App | Propósito confirmado | Datos que debe cubrir el diseño |
| --- | --- | --- |
| Champ | Comunidad para mascotas: cruces tipo Tinder, paseos, veterinarias, productos, perros perdidos y foro. | Responsables, mascotas, decisiones y matches; conversaciones; paseos y participantes; centros veterinarios; productos; avisos de pérdida y avistamientos; temas y publicaciones del foro. |
| SmartConvert AI | Facilitar el trabajo profesional con conversión de archivos, reportes y gestión del trabajo con clientes. | Clientes, encargos, tareas, archivos y versiones, trabajos de conversión, reportes y entregas. El módulo SII del menú previo no define por sí solo el producto. |
| Fenix Fitness | Medir minuciosamente consumos y gastos para personas que viven de su cuerpo; rutinas, módulos por deporte, técnica del movimiento y entrenamiento síncrono o asíncrono. | Fichas de alimentos y porciones; consumo energético y otros consumos definidos por unidad; gasto energético separado de gastos monetarios si estos se incluyen; rutinas y ejercicios; deportes; sesiones en vivo y actividades diferidas; videos, análisis y anotaciones de técnica; relación entrenador/alumno. |
| Legal Smart | Asistente para abogados y estudios jurídicos. | Propuesta a concretar: estudios, miembros y permisos, clientes, asuntos, documentos, tareas y agenda. No se presuponen conexiones con tribunales ni fuentes jurídicas. |
| Myfitmentor | Plataforma para alto rendimiento: deportistas profesionales, entrenadores, kinesiólogos, médicos y clubes. | Clubes, equipos, deportistas, profesionales y relaciones de atención; planes y sesiones; evaluaciones, competiciones y métricas longitudinales. Los registros clínicos y su acceso necesitan un diseño específico antes de incorporarse. |
| RH Pay | Pagos nacionales e internacionales y compra de divisas, permitiendo, por ejemplo, a una persona de Holanda pagar en Chile sin tarjeta local. | Identidades de pagador y beneficiario, cuentas y monedas, cotizaciones con vigencia, órdenes de cambio y pago, comisiones, referencias de proveedor, libro contable y conciliaciones. Los medios de financiación y proveedores concretos están por definir. |
| RH Comercio | Pagar comercios y cuentas en Chile, dividir pagos de restaurantes o cine y pagar reservas de canchas de pádel o futbolito. | Comercios, servicios y cuentas por pagar; órdenes, participantes y partes de pago; recintos, canchas, disponibilidad, reservas y vínculo al pago. Productos e inventario no son el centro del alcance confirmado. |
| Taskflow Pro | Control sencillo de proyectos con Gantt, curva S e indicadores clave. | Proyectos, tareas, dependencias, calendarios, recursos, líneas base, avances y costos reales. Gantt y curva S se derivan de registros consistentes; las líneas base deben conservar versiones para comparar plan y ejecución. |
| Fenix Controls | Control personal de las apps; posible versión comercial independiente. | Apps, hitos, tareas y bitácora; para una futura versión comercial, espacios de trabajo, miembros y permisos. Conservar el funcionamiento personal actual hasta definir la versión comercial. |

## Límites entre productos

RH Comercio administra la obligación comercial, el reparto y la reserva. RH Pay
administra la orden de pago o cambio y su ejecución mediante los proveedores que
se elijan. La integración propuesta usa identificadores externos, confirmaciones
idempotentes y conciliación mediante API; no acceso directo a la base de la otra
app. Esta separación es una propuesta técnica, no un servicio ya disponible.

Fenix Fitness y Myfitmentor comparten conceptos de nutrición y entrenamiento,
pero mantienen registros y permisos propios. Reutilizar código no autoriza a
compartir datos de un deportista entre productos ni entre profesionales.

Los roles de profesionales de Myfitmentor no conceden por sí solos acceso a todos
los registros del deportista: deben definirse relaciones y permisos explícitos.
La versión comercial de Fenix Controls también necesita aislamiento entre
espacios de trabajo antes de admitir varios clientes.

## Diferencias con los prototipos iniciales

- Champ: conservar la persistencia actual y ampliar por módulos.
- SmartConvert AI: añadir clientes, encargos, tareas y reportes al esquema de archivos.
- Fenix Fitness: el módulo nutricional ya se integró en el proyecto vecino con su
  propio esquema; `database/fenix_fitness.sql` sigue siendo un prototipo anterior,
  no una migración ni la fuente de su base operativa. No ejecutarlo sobre ella.
- Legal Smart: el núcleo común sigue siendo suficiente hasta concretar el primer
  flujo jurídico; las entidades propuestas arriba aún no se han implementado.
- Myfitmentor: ampliar perfiles profesionales, relaciones y planes antes de
  incorporar atención clínica.
- RH Pay: el prototipo actual guarda solicitudes; no acredita pagos ni saldos.
- RH Comercio: sustituir el planteamiento inicial de punto de venta por un nuevo
  esquema de cuentas, división de pagos y reservas. El SQL inicial se conserva
  como antecedente y no debe usarse como esquema definitivo del producto.
- Taskflow Pro: incorporar líneas base y calendarios a las tareas ya propuestas.
- Fenix Controls: mantener su base actual; diseñar la variante comercial aparte.

La próxima implementación debe usar migraciones cuando ya existan datos. Esta
actualización documental no modifica bases, proveedores ni registros existentes.
