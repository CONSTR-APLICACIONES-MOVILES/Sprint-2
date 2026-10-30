# Implementación de la auditoría por fases

Referencia: `AUDITORIA_MOCKUPS_FUNCIONALIDADES_Y_IO.md`, sección 5.
Fecha de inicio: 20 de octubre de 2026. Orden obligatorio: A → B → C → D → E.
F23 (I/O, errores, aislamiento por UID y offline) se aplica en cada fase.

## Fase A — Coherencia inmediata

Implementada en Flutter: F01, composición y datos de F02, F18 y primera
revisión compartida de F22.

- Navegación principal Home / Groups / Schedule. Profile se abre desde el avatar.
- Barra superior compartida en Home, Groups, Schedule, Alerts y Profile.
  Los destinos secundarios permiten Back; abrir Profile directamente permite
  volver a Home. Se conserva la búsqueda local dentro de Alerts.
- Home real presenta identidad autenticada, tarjetas de invitaciones y estado,
  actividades con sus IDs y grupos con el número real de miembros. Los grupos
  abren el listado; el detalle por grupo corresponde a C.
- La campana usa el número de alertas sin leer y sin respuesta del repositorio,
  con la misma definición que Alerts. No muestra un badge cuando el conteo
  está cargando o su consulta falló.
- Carga, error y vacío independientes por sección; pull-to-refresh y Retry;
  los datos anteriores sobreviven a un fallo de actualización. Al volver de
  Profile/Alerts/Details se recargan los datos de Home. Se rechazan respuestas
  tardías de otra sesión o de una generación anterior de la misma cuenta.
- Alerts abre el Profile inyectado, sin la hoja fija de Alex Kuprev.
- Quick Status muestra Active/Busy del perfil y abre su control existente.
  El selector ampliado, duración y privacidad pertenecen a C (F03).
- Search tiene un destino recuperable que declara Discover no disponible.
  Esto cierra la navegación de A, **no implementa F04**; buscar queda en D.
- La UI de ejemplo anterior está en `home_preview_view.dart` y solo se utiliza
  cuando `ActivitiesDependencies.mock()` inyecta explícitamente la demo.
  Firebase utiliza las tarjetas y los repositorios reales.

No cambió el contrato del backend, las reglas de Firestore ni la aplicación Java.
Los campos legacy de fecha/hora se presentan como propuesta; este bloque no
convierte esos textos en una agenda canónica. La UI no anuncia push, exportación,
asistencia individual ni enlaces operativos que el servidor no reconoce.

### Verificación de A

```powershell
flutter analyze --no-pub
flutter test --no-pub --reporter expanded
node tool/verify_phase_a_emulators.cjs
```

Las pruebas cubren las tres pestañas, avatar Alerts → Profile → Back, entrada
directa a Profile, destino de Search, tarjetas y contadores reales, errores
distintos de vacíos, reintentos, respuestas tardías, cambio de cuenta y disposición
durante solicitudes. Layout comprobado por widget tests a 390 y 320 px con texto
al 180 %, además de los recorridos existentes de edición, invitaciones y offline.

La verificación local de Firebase usa las dos cuentas existentes de Alex y
Camila. Consulta Auth, perfil, actividades, buzón, grupos autorizados y la última
actividad de cada grupo con las reglas del cliente. Comprueba el rechazo de
lecturas sin sesión. No ejecuta seed/reset ni cambia respuestas de invitación.
El 20/10/2026 ambas cuentas devolvieron 2 grupos y 3 actividades; Alex tuvo
2 alertas (1 sin leer) y Camila 2 alertas (2 sin leer).
El reporte local se escribe en `build/phase-a-emulators.json`.

Las pruebas de repositorios falsos verifican estado y UI; la comprobación
emulada verifica las consultas reales. No equivalen a una prueba visual en
dispositivo de toda la aplicación ni a comparar píxeles con las capturas dañadas
del export. La revisión completa de accesibilidad y fidelidad de F22 continúa
con las vistas que cambien en las siguientes fases.

## Fase B — Flujo principal completo (implementada y verificada localmente)

F09–F14, con F13 como contrato de asistencia por actividad.

- Schedule valida el intervalo en el servidor antes de abrir el formulario.
  `PlanningContext` conserva participantes, duración, grupo cuando existe,
  inicio/fin UTC, zona Bogotá, slot y evidencia de comparación con caducidad.
  El codec del router conserva ese contexto al serializar el historial.
  La publicación vuelve a comprobar membresía, vigencia y disponibilidad:
  un slot desconocido, ocupado o vencido no se publica como comparación válida.
- Creación: Details → Review → Create Activity → resultado por ID. El usuario
  puede seleccionar fecha/hora con pickers y categorías con chips. Review
  conserva el borrador al volver y presenta el grupo y los participantes reales.
  Se permiten propuestas sin agenda para conservar el contrato heredado;
  se identifican como Not scheduled.
- Publicación mediante callable y transacción, con ID derivado de UID/requestId
  y recibo persistido. Doble toque y reintentos devuelven el mismo ID.
  La solicitud se guarda localmente por proyecto/UID antes de enviarla;
  si falta el reconocimiento, se conserva el contenido revisado y se recupera
  al volver a abrir Create Activity. No se muestra éxito antes del recibo.
  Crear, editar, cancelar y validar slots requieren conexión; el diario de
  creación no es una confirmación de publicación offline.
- Resultado separado de la lectura del resumen. Si guardó y falla esa lectura,
  Retry summary solo relee el ID. Created, Scheduled y el estado de actividad
  Proposed/Confirmed aparecen diferenciados. View in Schedule conserva día,
  grupo e ID y muestra el resumen canónico de esa actividad dentro de Schedule.
  No exporta un evento a Google/Apple ni realiza una reserva externa.
- Invitación dedicada por el mismo activityId, con logística, participantes,
  contadores y Join / Maybe / Can’t attend. Alerts y Groups llegan a ese ID;
  Details permite abrir la invitación y recarga al volver. Las respuestas
  continúan en el buzón por UID/actividad, con la cola persistida existente,
  Pending sync y revisión individual con Retry/Discard en el shell offline.
  Un fallo de disco o un conflicto no se convierte en respuesta guardada.
- Home, Groups, Details e invitación leen respuestas por actividad. Los
  contadores del servidor distinguen accepted/maybe/declined/pending; el
  organizador se considera accepted de forma explícita. Pending sync local
  se muestra aparte de los contadores remotos. Groups delega la respuesta a
  la invitación y su fuente Firestore ya no escribe goingIds/maybeIds.
- Se conservan los campos y estados heredados para Java. Las matrices RSVP
  del grupo siguen siendo información heredada separada; el trigger existente
  que las vacía al crear una actividad no cambió. Flutter no las utiliza como
  asistencia de la actividad. No se cambió la aplicación Java.
- Edición y cancelación autorizadas al organizador, con versión del documento
  y comprobación transaccional. Una modificación concurrente pide recargar.
  Cancelar se persiste como `cancelled/cancelledAt`, sin introducir un enum que
  rompa PROPOSED/CONFIRMED. La repetición es idempotente; las invitaciones
  canceladas dejan de aceptar respuestas y no se cuentan como planes completados.
  Los clientes Java antiguos requieren una adaptación de UI para presentar el
  nuevo flag; sus operaciones heredadas compatibles siguen verificadas.

### Contratos y verificación de B

Contratos añadidos: `validatePlanningSlot`, `publishActivity`,
`updateActivityDetails` y `cancelActivity`. Detalle en
`Backend/docs/mobile-api.md` y `Backend/docs/data-model.md`.

```powershell
# En Flutter
flutter analyze --no-pub
flutter test --no-pub --reporter expanded
node tool/verify_phase_b_emulators.cjs

# En Backend; con Firestore emulado activo
npm --prefix functions test
node --test --test-concurrency=1 tests/activity.lifecycle.test.js tests/activity.lifecycle.rules.test.js
```

Las pruebas específicas usan `demo-parchapp-phase-b` y
`demo-parchapp-phase-b-rules`, con dos identidades autorizadas y otra ajena.
Comprueban comparar → publicar → buzón → responder → detalle con persistencia
Firestore, doble envío, clave reutilizada con otros datos, slots ocupados o
caducados, permisos, edición concurrente, cancelación repetida y reglas de Java.
No son repositorios simulados: ejecutan callables con contexto Auth inyectado y
Firestore emulado. Las pruebas Flutter cubren UI/estado, codec, diario local por
cuenta, reconocimiento perdido, recuperación, errores y layouts de invitación y
Review a 390/320 px con texto al 180 % y teclado.

Resultado final: **210 pruebas Flutter aprobadas**, analizador sin incidencias,
**24 pruebas unitarias de Functions**, **10 pruebas específicas de ciclo de vida y
reglas** y las **43 pruebas preexistentes** de API/reglas aprobadas. El smoke HTTP
con Auth/Functions reales del emulador también pasó con Alex y Camila: funciones
registradas, campos nuevos serializados y rechazos de permisos/versiones sin
mutar sus fixtures (`build/phase-b-http.json`).

También se ejecutaron las 43 pruebas preexistentes de API/reglas en una copia
con proyecto de prueba separado, para conservar los fixtures locales del usuario.
No se hizo despliegue a Firebase en la nube ni una prueba visual en dispositivo.
BQ9 dispone de evidencia de comparación vinculada a la actividad; no se declara
implementada su agregación analítica. Push, exportación de calendario, chat y
liberación de salas siguen fuera de esta fase.

## Fase C — Comunidad y perfil (implementada y verificada localmente)

Alcance acordado: F06–F08, F03 y ajustes operativos de F19.

- Un único listado de grupos propios con búsqueda local, filtros y contadores
  reales, Create Group y Group invitations. Home y la lista abren Group Details
  por ID; no existen entidades fijas separadas para Friday Plans y Roomies.
- Create Group ofrece nombre/categoría, selección de compañeros de grupos
  compartidos y revisión antes de enviar. El servidor crea propietario y
  membresía inicial, más invitaciones internas; nadie se añade sin aceptar.
  ID/recibo transaccional y diario local por proyecto/UID evitan duplicados y
  recuperan el mismo envío después de perder el reconocimiento o reiniciar.
- Invitaciones internas con estados pending/accepted/declined/expired/revoked.
  Caducan a los siete días y el propietario puede revocar una pendiente.
  Aceptar/rechazar es autorizado al destinatario e idempotente. Crear el grupo
  y aceptar una invitación requieren conexión y confirmación del backend.
- Group Details presenta miembros reales, propietario si existe, próximo plan
  canónico e historial de las últimas 100 actividades, incluidas propuestas y
  cancelaciones. Los contadores vienen de respuestas por actividad. Los grupos
  antiguos sin propietario no reciben un propietario inventado.
- Create Activity preselecciona groupId; Compare schedules mantiene el mismo
  grupo y limita la selección de compañeros a sus miembros. La validación de
  publicación de B sigue comprobando pertenencia e intervalo en el servidor.
- Home y Profile comparten selector de estado: Active, Busy, In class, Focused,
  In transit y Offline, con duración y visibilidad. La caducidad se aplica en
  lecturas del servidor y se refleja localmente con una revisión cada 30 s.
  Las elecciones se conservan si falla el guardado; no cambian agenda/ubicación.
- Profile recupera la sección Privacy & preferences: visibilidad del estado,
  privacidad de agenda, Close friends y badges de invitaciones en Home. Cada
  control se persiste y tiene efecto; apagar badges conserva el buzón y RSVP.
  La lista Close friends se limita a compañeros actualmente compartidos.
- Privacidad aplicada también a detalle/recomendaciones de actividades,
  getScheduleDay, comparar y revalidar publicación. Una agenda oculta se
  considera desconocida. Al restringirla, el servidor retira los bloques legacy
  de todos los documentos de grupo; las importaciones posteriores no los
  reintroducen. Para volver a compartir datos que solo existían como legacy
  puede hacer falta reimportar. No se puede retirar una copia ya recibida.
- La respuesta confirmada de estado/ajustes actualiza la copia offline del perfil.
  Los formularios abiertos conservan su UID de origen y rechazan guardar tras
  cambiar de cuenta. Errores, vacíos, carga y reintentos son distintos. Se
  conservan las estadísticas desconocidas, confirmación de logout y cámara.

Enlaces públicos/QR e invitaciones por email de F07 siguen en D junto con F20;
no se muestran como enviados ni operativos. F19 no incorpora en esta entrega un
selector de tema ni notificaciones push del sistema. No hay controles ficticios
para estas ampliaciones. No cambió la aplicación Java ni se desplegó a la nube.

### Verificación de C

```powershell
# Flutter
flutter analyze --no-pub
flutter test --no-pub --reporter expanded
node tool/verify_phase_c_emulators.cjs

# Backend; Firestore emulado activo
npm --prefix functions test
node --test --test-concurrency=1 tests/community.profile.test.js tests/community.rules.test.js
```

Las pruebas de C usan `demo-parchapp-phase-c` y
`demo-parchapp-phase-c-rules`, sin borrar fixtures de `demo-parchapp`. Cubren
crear/aceptar entre dos identidades, consentimiento, membresía, autorización,
reintento concurrente, vencimiento/revocación, privacidad en los distintos caminos
de agenda, caducidad del estado y aislamiento por UID. Se repitieron las pruebas
de B y las 43 de regresión API/reglas en otro proyecto de prueba separado.

Flutter comprueba revisión/navegación por ID, recuperación tras reiniciar,
reintento aun si fallan los compañeros, cambio de sesión, contexto del grupo,
búsqueda, copia offline de preferencias, errores sin falsa confirmación y layout
con 320/390 px y texto al 180 %. No sustituye una prueba visual en dispositivo.

Resultado: **225 pruebas Flutter**, analizador sin incidencias, **24 pruebas
unitarias de Functions** y **66 pruebas de API/reglas** (C, B y regresión heredada).
Smoke HTTP de Auth/Functions con Alex y Camila aprobado: nuevos contratos,
grupo/miembros/historial reales y rechazos sin cambiar sus fixtures.
Reporte local: `build/phase-c-http.json`.

## Fase D — Ampliaciones (implementada y verificada localmente)

F04, recuperación y protección de registro de F05, recursos de F15,
presentación de F16, eventos reales de F17, enlaces de F20 y exportación/importación
diferenciadas de F21. Las integraciones externas sin configuración se detallan
abajo; no se dan por entregadas por mostrar un control del prototipo.

- **Discover:** catálogo autorizado de grupos propios, compañeros compartidos y
  últimas 100 actividades por grupo. Búsqueda, categorías, tipos, paginación y
  acceso al ID real; sin directorio público ni Connect/Join ficticio. El cursor
  queda ligado a UID/consulta/filtros; las respuestas tardías no reemplazan otra
  búsqueda. Error y vacío se presentan por separado.
- **Auth:** Forgot password solicita recuperación a Firebase Auth con validación,
  bloqueo de doble toque y confirmación solo tras reconocimiento. No verifica
  direcciones ni promete entrega de email. Respuesta neutral para email no
  encontrado. El registro conserva nombre/email/contraseña/confirmación y no pide
  recrear una cuenta tras fallo de perfil; la escritura conserva su UID original.
  Los enlaces conservan destino al volver de Sign-In o registro.
- **Checklist y recursos:** ruta por activityId desde Details. Definiciones
  editables por el organizador activo, versión/conflicto y reintento del mismo
  contenido si se pierde el reconocimiento. Progreso personal persistido por UID,
  sin modificar el de otro miembro. Recursos HTTPS con título, origen del
  organizador y apertura mediante navegador; no se simulan archivos descargados,
  adjuntos subidos ni características del aula.
- **Suggested Times:** ruta por actividad con el componente común de recomendaciones.
  Duración y filtros de franja horaria conservan orden, posición, razones e ID
  del servidor. Se conserva BQ3 y solo se ofrece el horizonte real de hoy en Bogotá.
- **Alerts:** invitaciones internas a grupo y recordatorios de actividades
  canónicas que empiezan dentro de una hora; trigger persistente de cambios de
  hora/cancelación, también para escrituras Java compatibles. IDs deduplicados,
  lectura por UID y destinos reales. Las tarjetas reales ofrecen acciones que
  existen; no muestran On my way o aceptar grupo mediante el contrato de RSVP.
  Marcar eventos leídos requiere conexión y no bloquea la cola durable de RSVP.
  Recordatorios se calculan al consultar el buzón; no garantizan ejecución con
  la app cerrada ni una entrega push.
- **Compartir:** códigos criptográficos por grupo/actividad/perfil, recibo
  idempotente, caducidad y revocación. El propietario crea enlaces de incorporación
  de grupo. La vista previa no añade miembros: exige confirmar; la transacción
  añade una vez y comprueba capacidad/permisos/token. Compartir actividad/perfil
  conserva los permisos existentes. Revocar no expulsa miembros ya incorporados.
  Clipboard solo anuncia Copied tras éxito; Share distingue cancelación y estado
  no reconocido. No declara email o invitación entregados al abrir el selector.
- **URL y QR:** la app web genera una URL resoluble en su mismo origen y ruta
  `#/join/<token>`. `APP_LINK_BASE_URL` permite apuntar a un despliegue web propio;
  QR utiliza exactamente esa URL. En nativo sin dominio configurado se comparte
  un código que se pega desde Discover; no se inventa un enlace público ni QR.
- **Calendario:** estado de la última importación FreeBusy reconocida por el
  backend, rango y error conservando el snapshot previo. La exportación es un
  archivo `.ics` de actividad canónica, autorizado, con UTC/UID estable/escape y
  plegado UTF-8. Compartir el archivo no equivale a importarlo en Google/Apple/
  Outlook ni a conectar o sincronizar esas cuentas.

### Configuración externa y alcance pendiente

- Google Sign-In de cuenta continúa deshabilitado explícitamente en Firebase UI
  hasta configurar proveedor, clientes OAuth y certificados/orígenes. La
  autorización de Google Calendar existente es independiente; su funcionamiento
  externo depende de consentimientos/configuración del proveedor. No se
  reemplaza con una respuesta de éxito simulada.
- No hay proveedor para envío automático de invitaciones por email; se pueden
  compartir códigos/enlaces mediante el selector del sistema. No se enviaron
  correos reales durante la verificación.
- Dominio público/hosting y asociación nativa Android App Links/iOS Universal
  Links quedan pendientes de despliegue/configuración. Los enlaces web locales y
  los códigos tienen recorrido funcional; no se anuncia un dominio parchapp.me.
- Adjuntos con almacenamiento/descarga, push, amistad global, overlap/digest
  automático, ranking futuro, auto-sync y exportación directa por API de cada
  calendario requieren sus propios contratos/proveedores. No se muestran como
  entregados. El selector de tema pendiente de F19 no forma parte de D.
- La aplicación Java no se modificó. No se hizo despliegue a Firebase en la nube.

### Verificación de D

```powershell
# Flutter
flutter analyze --no-pub
flutter test --no-pub --reporter expanded
flutter build web --no-pub
flutter build apk --debug --no-pub
node tool/verify_phase_d_emulators.cjs

# Backend; emuladores Firestore/Auth activos
npm --prefix functions test
node --test --test-concurrency=1 tests/expansions.test.js tests/expansions.rules.test.js tests/password.recovery.test.js
```

Los proyectos `demo-parchapp-phase-d`, `demo-parchapp-phase-d-rules` y
`demo-parchapp-phase-d-auth` aíslan las pruebas de los datos locales del usuario.
Se prueban creación/preview/incorporación/revocación de enlaces entre identidades,
privacidad del catálogo, paginación, recursos/permisos/conflictos, checklist por
usuario, archivo ICS, importación, eventos reales y reglas que impiden falsificar
recibos/tokens/estado. Auth emulado genera y valida un código de recuperación para
una cuenta exclusiva de prueba, sin enviar correo ni cambiar una contraseña.
También se repiten las pruebas previas de B/C y las 43 de API/reglas heredadas en
una copia con otro proyecto de prueba.

Resultado: **246 pruebas Flutter**, **80 pruebas de API/reglas/Auth** y **24
unitarias de Functions** aprobadas. La comprobación HTTP con Alex y Camila pasó
sin escrituras válidas ni cambios en sus fixtures (`build/phase-d-http.json`).
Analizador sin incidencias; compilaciones web y APK Android debug aprobadas.
APK local: `build/app/outputs/flutter-apk/app-debug.apk` (no se instaló ni ejecutó).
Las pruebas de widget cubren 320/390 px, texto al 180 %,
scroll, errores de portapapeles/compartir, carrera de consultas, incorporación
explícita, reintento idéntico, cuenta creada con perfil fallido y cambio de UID.
No sustituyen una prueba manual en dispositivo ni verifican entrega de correo,
importación final del archivo por una app externa o consentimientos OAuth reales.

## Fase E — Roadmap externo (pendiente de proveedor y alcance)

F24: chat, mapas/ETA, reservas de salas y descargas externas. Definir proveedor,
permisos y resultados verificables por servicio antes de implementarlos.
Estas integraciones no se consideran entregadas con los cambios visuales.


## Corrección visual posterior a A–D — 20 de octubre de 2026

A–D verificaban recorridos y contratos; no certificaban fidelidad visual. Tras la revisión del usuario se restauraron logo, paleta, superficies y composición de Dashboard, detalle/creación de grupos, estado e invitación/detalle de actividad. Inter y las dos portadas decorativas del export se incluyen localmente. Se mantuvieron permisos, IDs reales, errores y la navegación de tres pestañas.

Detalle, diferencias deliberadas respecto a los mockups y evidencia: [RESTAURACION_VISUAL.md](RESTAURACION_VISUAL.md). Regresión actual: **247 pruebas Flutter** y analizador sin incidencias; capturas en `build/visual-review/`. Backend y datos del emulador no modificados por esta corrección. No implica integración OAuth, email, sincronización automática ni despliegue.


## Cierre de código de sprint 3 — 26 de octubre de 2026

Se completaron la fecha visible de caché en Details/Alerts, serialización grande mediante isolate nativo, medición/primera confirmación/agregación y panel local BQ9. Se corrigieron propuesta sin slot, controles heredados, estados de Profile, importación Google sin configuración y presentación de creación/revisión/resultado. Detalle y evidencia: [CIERRE_SPRINT_3.md](CIERRE_SPRINT_3.md). La evidencia local no equivale a despliegue, dashboard unificado publicado o prueba física.
