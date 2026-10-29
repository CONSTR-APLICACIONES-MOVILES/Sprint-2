# Correcciones de Flutter frente a los mockups — funcionalidades, errores e I/O

Fecha: 20 de octubre de 2026. Alcance: ParchApp Flutter y sus contratos con el
backend compartido. No modificar la aplicación Java.

**Conclusión:** la disparidad principal está en flujos incompletos y en la
composición de las vistas con datos reales. Varias pantallas del prototipo sí
existen como demostración, pero la rama Firebase omite secciones o no tiene sus
contratos. Corregir colores por sí solo no cierra estas diferencias.

En esta lista, **I/O significa entradas y salidas**. Conservar validaciones,
errores, carga, vacíos, reintentos y resultados pendientes al refactorizar la UI.
No convertir errores en datos vacíos ni éxitos del prototipo en éxitos reales.

## 1. Fuentes, cobertura y referencia a seguir

Material revisado en:
`C:\Users\gabri\Downloads\sprintsinstruct\stitch_remix_of_student_social_sync`.

- Los dos PRD: `parchapp_prd_project_brief.md` (2.0) y
  `parchapp_master_prd_design_brief_v2.5.md` (2.5).
- Inventario de los **34 HTML**: textos, campos, acciones y funciones del
  prototipo, contrastados con rutas, vistas, entidades, repositorios e inyección
  Firebase de Flutter. No basta encontrar una clase mock para dar un flujo por listo.
- Inspección visual de seis PNG representativos: prototipo unificado, creación
  de actividad, Alerts móvil, detalle Friday Plans, estado de disponibilidad y
  Search/Discover. No se ejecutaron nuevamente todos los flujos en dispositivo.
- De los 34 archivos llamados `screen.png`, **19 son PNG válidos y 15 contienen
  únicamente `<FIFE Image failed to fetch>`**. Para esos casos se revisó el HTML;
  no se puede afirmar una comparación visual exacta de sus capturas.

Referencia propuesta: PRD **2.5**, complementado por cada HTML específico. Hay
contradicciones dentro del export: navegación Home/Compare/Slots/Profile en el
prototipo unificado; History en Roomies; Home/Groups/Alerts en estados. El PRD 2.5
pide **Home / Groups / Schedule**, con perfil, búsqueda y alertas en la barra
superior. No mezclar esas variantes como si fueran requisitos simultáneos.

Se mantienen las decisiones explícitas del usuario: Sign-In al arrancar,
controles de simulación offline ocultos por defecto, Alex y su correo local de
testing, y cámara fuera de este trabajo. No regresar a datos fijos para obtener
una captura parecida. El PRD describe también integraciones futuras; su presencia
en un mockup no las convierte automáticamente en alcance obligatorio de sprint 3.

## 2. Lista priorizada de correcciones

P0: coherencia del resultado y protección de flujos existentes. P1: recorrido
principal y correspondencia con las vistas. P2: ampliación funcional que necesita
contrato. P3: servicios externos del roadmap, pendientes de alcance y proveedor.

| ID | Prioridad | Funcionalidad / referencia Stitch | Diferencia comprobada | Corrección y dependencia |
|---|---|---|---|---|
| F01 | P1 | Navegación global; PRD 2.5 §3 | `ParchNavigationBar` tiene cuatro destinos, incluyendo Profile. Las barras superiores cambian entre pantallas. | Dejar Home/Groups/Schedule, acceso consistente a búsqueda/alertas/perfil y Back correcto. Mantener Profile accesible desde avatar; probar enlaces y pila de navegación. Flutter. |
| F02 | P1 | Home; `home_dashboard_scrollable_1/2` | En producción se reemplazan tarjetas del prototipo por botones View invitations, Compare availability y Open your groups; falta Quick Status y composición de planes/grupos. | Recuperar las secciones del mockup con datos reales: saludo, estado, planes y grupos en tarjetas. Avatar/contador de no leídos reales; la campana de Home tiene un badge fijo. No inventar 2 planes, 4/4 asistentes ni cinco grupos. Flutter + resúmenes/contadores del backend. |
| F03 | P2 | Estado; `select_availability_status_bottom_sheet_en`, `set_availability_status_en_1/2` | Perfil solo permite Active/Busy. No hay estados de clase, biblioteca/foco o tránsito, duración ni caducidad. | Unificar Home y Profile en un selector común con estado, vigencia y visibilidad; ampliar contrato de forma compatible. Un cambio de disponibilidad no debe inventar una ubicación ni dar por sincronizado un calendario. Flutter + backend. |
| F04 | P1 | Search/Discover; `search_discover_3_item_nav` | `/discover` existe como constante, pero no tiene GoRoute. La lupa de Home abre una hoja que termina en Coming soon. | Crear la vista con búsqueda, categorías, resultados/vacío y acceso a detalle. Definir catálogo autorizado antes de añadir Join/Connect y descubrimiento fuera de los grupos propios. Flutter + consultas/visibilidad del backend. |
| F05 | P1/P2 | Sign-In y registro; `parchapp_sign_in_1/2`, variantes Create Account | Email/password y cuenta reconocida funcionan. Forgot password solo muestra un mensaje; Google Auth no está configurado. Las variantes de registro añaden distintos campos. | Alinear formulario básico con PRD 2.5 (nombre, email, contraseña y confirmación), mantener errores y visibilidad de contraseña. Implementar recuperación y OAuth por separado. No mostrar verificación institucional ficticia; acordar campos académicos/intereses de las variantes. No bloquear a.va@test.com en emuladores. |
| F06 | P1 | Lista de grupos; `active_groups_scrollable` | La vista real tiene filtros y tarjetas, pero no búsqueda de grupos, acceso a crear grupo ni apertura de un detalle de grupo. Las dos rutas Groups/Active Groups llevan a la misma lista. | Reproducir lista navegable, búsqueda y CTA Create Group con contadores reales. Acordar si las variantes de lista son un mismo listado o dos modos; no duplicar pantallas solo por tener dos HTML. Flutter. |
| F07 | P2 | Crear grupo; `create_group_parchapp_1/2` | No hay formulario ni ruta; las reglas permiten crear grupos solo al backend. Los fixtures no sustituyen esta funcionalidad. | Formulario, revisión de participantes y creación autorizada; después enlace/QR e invitación por email con estados. Definir propietario, incorporación, expiración y revocación del enlace. Un texto parchapp.me/... no es un enlace operativo. Flutter + nuevo contrato. |
| F08 | P1/P2 | Detalle de grupo; Friday Plans y Roomies | No existe ruta/vista con próximo plan, participantes, respuestas, historial y Create Activity con grupo preseleccionado. View Schedule no conserva el grupo. | Una vista común Group Details con variaciones de contenido, no copias con personas fijas. Obtener miembros y actividades autorizados; persistir groupId al comparar y crear. Los badges académicos solo aparecen si existen datos válidos y autorizados. |
| F09 | P0 | Schedule → Plan with this slot | `_planActivity` transporta solo fecha y etiqueta horaria en texto. Pierde participantes seleccionados, identidad de comparación y referencias de slot/grupo. | Transportar un contexto tipado con participantes, duración, fecha, zona y evidencia de comparación. Validarlo al publicar. Base también para atribución BQ9; no implementarla con un booleano global. Flutter + contrato canónico. |
| F10 | P0 | Crear actividad; `create_activity` | Hay un único formulario con dropdowns y guardado directo; el mockup tiene Details → Review y categorías como chips. Fecha/hora actuales son textos opcionales, no agenda canónica. | Incorporar selección de fecha/hora y paso Review, conservando el borrador al volver. Definir publicación con start/end/timeZone y reconocimiento idempotente del servidor. Actualmente escribir fecha/hora no agenda la actividad: no ocultar esa distinción con un rediseño. Mantener compatibilidad con actividades antiguas sin agenda. |
| F11 | P0/P1 | Activity Created / Confirmed | Al crear se navega directamente a Details; no existe la confirmación dedicada con resumen, invitados y accesos al calendario. | Añadir pantalla de resultado ligada al ID guardado. Diferenciar Created, Scheduled y Confirmed. Mostrar invitaciones disponibles en el buzón, sin afirmar push enviado o sincronización externa exitosa cuando no existen esas operaciones. Flutter + resultados verificables del backend. |
| F12 | P1 | `activity_invitation` | Hay tarjetas de invitación en Alerts y detalle genérico de actividad; falta el recorrido dedicado con logística, invitados, contadores y Join/Can't attend. | Crear vista o modo de invitación sobre el mismo ID de actividad, sin duplicar entidades. Conectar acciones a respuestas por actividad, mostrando pendiente local y conflicto. La alternativa Maybe existente debe conservarse o resolverse explícitamente, no desaparecer por copiar dos botones del mockup. |
| F13 | P0 | Asistencia en Home, Groups, Details e invitación | Alerts persiste RSVP por actividad; Groups todavía actualiza goingIds/maybeIds del grupo. Details etiqueta ambos orígenes y llega a usar el campo de programa para texto técnico de RSVP. | Unificar lectura/escritura de asistencia por activityId y UID; generar contadores y pendientes en backend autorizado. No confundir Confirmed de actividad con Accepted de una persona. No cambiar unilateralmente el contrato Java: mantener adaptación de los campos heredados durante la transición. |
| F14 | P1/P2 | Details y hoja contextual de sesión | Editar metadatos y recomendaciones funciona; cancelación no está habilitada para la entidad Firebase (`supportsDetailsEditing=false`). Acciones de compartir/chat/recordatorio del prototipo no tienen recorrido completo. | Unificar edición y hoja contextual con permisos del organizador. Añadir cancelación real, confirmación y resultado persistido mediante contrato compatible. No prometer liberar sala o avisar a todos sin esos servicios. |
| F15 | P2 | Topics y recursos de Study Session Details | El modelo real entrega listas vacías de topics/resources y no hay persistencia de checklist, archivos, aula o recordatorio. Parte de la UI solo existe con mocks. | Añadir datos/operaciones de checklist y recursos si entran en alcance; distinguir campos editables y de solo lectura. No mostrar progreso, Wi-Fi, enchufes o descarga ficticios. Los adjuntos necesitan origen real y permisos. |
| F16 | P1/P2 | Schedule y `optimized_time_slots_en_scrollable` | Existen timeline, duración y slots; recomendaciones de actividad están dentro de Details, no como vista de Suggested Times con orden/filtros. El backend de recomendaciones admite hoy en Bogotá. | Armonizar selector y drawer; decidir si Suggested Times es ruta o presentación del mismo resultado. Conservar ranking/razones del servidor y BQ3. No anunciar opciones futuras ni Every member free cuando falta disponibilidad; ampliar horizonte antes de ofrecerlo. |
| F17 | P2 | Alerts Hub móvil | La UI conoce varios tipos, pero el repositorio Firebase solo genera invitaciones a actividades. Recordatorios, overlap, friend request, cambio de hora, digest e invitación a grupo aparecen solo en ejemplos. | Mantener filtros y aspecto del hub, pero alimentar cada tipo con eventos reales y entidad/acción válida. Producir esos eventos en backend antes de mostrar tarjetas y contadores. Push es una integración adicional al buzón. |
| F18 | P0 | Identidad desde Alerts | El avatar de Alerts abre `AlertProfileSheet(friendRequest:false)`, una hoja con datos fijos, en lugar del Profile real. Los perfiles de solicitudes también son constantes. | Avatar propio → `/profile` con usuario autenticado. Perfil de tercero → ID y datos autorizados, cuando exista esa funcionalidad. Corregir esta fuga de UI de ejemplo antes de reproducir más pantallas. Flutter. |
| F19 | P1/P2 | Profile; `user_profile_en_scrollable_fix` | Identidad, edición, estadísticas derivadas y logout son reales. Se redujeron menús a Calendar & availability y My Groups; no existen privacidad de agenda, Close Friends ni preferencias/notificaciones/tema. | Recuperar jerarquía visual; implementar cada ajuste con persistencia y efecto verificable, no solo un toggle. Mantener estadísticas desconocidas sin porcentaje inventado. Separar permisos de agenda de importar Google Calendar. |
| F20 | P2 | Compartir e invitar; Home, Create Group y confirmación | No existe flujo real de enlace personal/de grupo/de actividad, QR y compartir. Los HTML usan URLs fijas y algunos muestran Copied aunque falle clipboard. | Enlace por entidad y destino resoluble, servicio de incorporación autorizado y adaptador Clipboard/Share. Solo mostrar Copied tras éxito; separar cancelar compartir de error. Flutter + backend/enlaces. |
| F21 | P1/P2 | Calendar & Sync y Add to Calendar | Hay importación FreeBusy del calendario primario de Google, no sincronización bidireccional ni exportación de actividades a Google/Apple/Outlook. El mockup afirma varias de ellas. | Mostrar conectado/importado/última actualización/error con datos reales. Añadir exportación de actividad como operación separada si se acuerda. No copiar Google & Apple active ni un switch de auto-sync que solo cambia su aspecto. |
| F22 | P1 | Sistema visual y accesibilidad | Temas, títulos, avatar y barra superior se construyen de manera distinta por módulo; Profile extra en navegación, etiquetas técnicas y formularios genéricos aumentan la distancia con los diseños. | Componentes compartidos de top bar, chips, tarjetas, estado y formularios; tipografía Inter/sistema, azul #0047BA y verde según tokens. Revisar 390 px, teclado, tamaño de texto, scroll, SafeArea y objetivo táctil de 44×44. No copiar artefactos de exportación ni textos de prueba. |
| F23 | P0 | Errores, I/O y offline en todos los flujos | Ya existen errores, recuperación, aislamiento por UID y cola de invitaciones; un reemplazo de vistas puede perderlos. Los mockups se concentran en el camino feliz. | Mantener la matriz de la sección 3 como criterio obligatorio de aceptación. No suprimir validaciones ni mostrar guardado antes del reconocimiento local/servidor correspondiente. |
| F24 | P3 | Chat, mapas, salas, descargas y otros servicios | El mockup simula conversación, rutas/ETA, reservas/código de acceso, Wi-Fi y descarga. No hay servicios reales conectados para esas promesas. | Planificar proveedor y contrato por servicio. Hasta entonces usar estado no disponible honesto; no fabricar rutas, mensajes entregados, sala liberada ni archivo descargado. Son trabajo de integración del roadmap, no mero ajuste visual. |

## 3. I/O y errores que deben quedar en la implementación

Esta matriz es el mínimo de aceptación de las correcciones. Incluye estados que
ya existen y otros que deben añadirse al implementar la funcionalidad faltante;
no afirma que todos estén implementados hoy.

| Flujos | Entradas (I) | Salidas (O) | Errores / recuperación obligatorios |
|---|---|---|---|
| F01, F22 navegación/layout | Destino, entidad/ID, estado de sesión, Back y teclado | Vista correcta, selección de tab, foco y scroll accesibles | Ruta/ID inexistente → salida recuperable; sesión inválida → Sign-In; no perder un formulario por cambiar la estructura de navegación. |
| F02 Home | UID, día de Bogotá, actividades, grupos, respuestas y no leídos | Tarjetas/contadores reales, avatar y acciones al ID correcto | Carga inicial, sin planes, fallo con datos anteriores, pull-to-refresh y error de consulta. Un error no equivale a cero actividades. |
| F03 disponibilidad | Estado, duración/fecha de expiración, alcance autorizado | Estado guardado reflejado en Home/Profile y caducidad | Valor inválido, expiración pasada, sesión distinta, guardado fallido. Mantener elección para reintentar; no afirmar que las preferencias de visibilidad ya se aplicaron sin backend. |
| F04 descubrir | Consulta, categoría, filtros y cursor | Resultados autorizados, detalle y vacío filtrado | Fallo de búsqueda distinto de Sin resultados; limpiar filtros; carrera entre consultas; paginación/privacidad; Join/Connect sin doble envío. |
| F05 Auth | Email/contraseña o proveedor; nombre/confirmación al registrar; email para recuperación | Sesión validada, cuenta creada o solicitud de recuperación reconocida | Campos vacíos, email inválido, contraseñas distintas, credenciales rechazadas, cuenta existente/deshabilitada, red y cancelación OAuth. No pedir recrear cuenta después de que Auth ya la creó. No afirmar email verificado sin evidencia. |
| F06–F08 grupos | Nombre, miembros/invitados, groupId, token de incorporación y contexto del plan | Grupo persistido, membresías, invitaciones, detalle e historial | Sin grupos ≠ fallo de carga; nombre/email inválido, duplicados, no miembro, enlace inválido/expirado, fallo parcial de invitaciones. No atribuir éxito del grupo a una invitación externa fallida. |
| F09, F16 comparación | Participantes, día, duración, disponibilidad conocida/caché y selección | Slots con inicio/fin/zona, contexto conservado y explicación del ranking | Sin permisos, disponibilidad desconocida, cero slots, duración inválida, error de importación, datos antiguos y respuesta tardía de otra selección. No usar falta de datos como libre. |
| F10 creación | Título, grupo, categoría, inicio/fin/zona, lugar, descripción y contexto | Review fiel al borrador; actividad reconocida con ID estable y agenda coherente | Requeridos, límites de texto, grupo sin acceso, fin ≤ inicio, slot obsoleto, timeout y doble toque. Conservar datos; reconocimiento perdido no debe duplicar actividades. Offline actual: explicar que crear requiere conexión. |
| F11 confirmación | Resultado de guardado y reconocimientos separados de agenda/invitaciones/calendario | Resumen real, estado preciso, View in Schedule/Details/Home con IDs | Si guardó y falló la recarga: indicar guardado y reintentar lectura, no creación. Si no hay agenda canónica, no decir Scheduled. Si no hay exportación/push, no afirmar envío o sincronización externa. |
| F12–F13 RSVP | activityId, UID, accepted/maybe/declined | Respuesta por actividad, contadores, confirmación remota o Pending sync | No invitado, actividad eliminada/cancelada, respuesta incompatible, red y disco. Persistir antes de prometer pendiente; conflicto individual con Retry/Discard; conservar otros pendientes; no sobrescribir otra respuesta silenciosamente. |
| F14 edición/cancelación | Organizador, ID, versión/contexto, cambios y confirmación destructiva | Resultado persistido, detalle/Home/Alerts coherentes | No organizador, conflicto concurrente, actividad no encontrada, error de guardado; Keep Session no modifica nada; no notificar/liberar recursos hasta tener reconocimientos reales. |
| F15 checklist/recursos | ID de tema/recurso, cambio deseado, archivo/enlace autorizado | Progreso persistido o descarga real comprobable | Sin permiso, enlace vencido, recurso eliminado, error de descarga/almacenamiento; no simular porcentajes ni archivo guardado. |
| F17–F18 Alerts | Eventos reales, consulta/filtro, marcado de lectura y entidad destino | Buzón, contador coherente, acción y perfil correcto | Vacío filtrado distinto de fallo; ID destino vencido; marcado/acción fallida; error de sesión; deduplicación; una entrega push fallida no borra la invitación del buzón. |
| F19 Profile/ajustes | Perfil autenticado, campos permitidos y valores de preferencias | Cambios persistidos y efecto visible en las vistas | Validación académica, actualización fallida, sin dato estadístico, privacidad no disponible y logout fallido. Conservar aislamiento entre cuentas y confirmación de cierre de sesión. Cámara no se modifica en este trabajo. |
| F20 compartir | Entidad real, enlace válido, canal y permiso del usuario | Clipboard reconocido, selector de compartir o QR correcto | Enlace no generado, clipboard fallido, app destino no instalada, compartir cancelado. No mostrar invitación enviada por abrir el selector. |
| F21 Calendar | Cuenta autorizada, alcance, rango de importación o actividad a exportar | Snapshot FreeBusy importado o evento externo reconocido, con estados separados | Consentimiento cancelado, permiso revocado, fallo del proveedor, rango inválido, error de importación. Conservar snapshot anterior; no incluir títulos/ubicaciones/asistentes privados al compartir ocupación. |
| F23 transversal offline | Cuenta/proyecto, caché, comandos y reconocimientos | Copia guardada o pendiente duradero con fuente/antigüedad claras | Sin copia, caché obsoleto, disco fallido, reinicio y cambio de cuenta; error de permisos no se disfraza de offline. Timer/foreground no son garantía de ejecución con proceso cerrado. |
| F24 servicios externos | Datos, permisos y proveedor de cada integración | Resultado real y específico de ese servicio | Servicio ausente/caído, permiso denegado y timeout; mostrar alternativa honesta. No usar el toast del HTML como prueba del resultado. |

## 4. Contratos que hay que cerrar antes de completar las vistas

1. **Actividad/agenda:** inicio, fin, zona horaria, creación idempotente y relación
   con comparación y participantes. Las reglas actuales no admiten añadir
   arbitrariamente campos canónicos desde el formulario. Coordinar servicio,
   reglas y DTO antes de usar un date picker como prueba de agenda persistida.
2. **RSVP por actividad:** fuente única de respuestas y agregado autorizado para
   participantes/contadores. Mantener el contrato heredado que Java utiliza
   mientras se incorpora el nuevo comportamiento Flutter.
3. **Grupos e invitaciones:** propiedad, membresía, creación, token/link y sus
   estados. Los scripts de fixtures y la afiliación automática demo no son UI
   de creación de grupos ni un sistema de amistad completo.
4. **Cancelación y notificaciones:** ciclo de vida persistido, repetición
   idempotente y alcance de sus efectos. Definirlo sin romper clientes que hoy
   entienden PROPOSED/CONFIRMED; no introducir un estado incompatible a ciegas.
5. **Disponibilidad/privacidad:** enum, caducidad y autorización efectiva. Active
   no significa automáticamente libre en el calendario ni visible para todos.
6. **Enlaces/Google/exportación:** separar link local, incorporación, importación
   FreeBusy y exportación de evento. Cada uno necesita un resultado verificable.

Todo lo anterior requiere pruebas con Firebase real o emulado y dos usuarios;
aprobar un test con repositorio mock no demuestra persistencia ni autorización.

## 5. Orden recomendado y colaboración de los tres integrantes

| Bloque | Trabajo | Participación sugerida | Criterio de cierre |
|---|---|---|---|
| A. Coherencia inmediata | F01, F02, F18 y revisión F22 | Componentes compartidos; cada dueño adapta su módulo | Tres tabs; Home con datos reales en tarjetas; avatar Alerts muestra al usuario correcto; errores existentes visibles. |
| B. Flujo principal completo | F09–F14 y RSVP F13 | Gabriel Pinto en Activities/Alerts + Gabriel Polania en Schedule | Comparar → Review → publicar → resultado → invitación → respuesta → detalle, conservando grupo, participantes, horario y estados de error. |
| C. Comunidad y perfil | F06–F08, F03 y F19 | Jhon Vega + colaboración en contratos de actividades | Grupo navegable y persistido, contexto al crear/comparar, perfil y estado coherentes. |
| D. Ampliaciones | F04, F05 pendientes, F15–F17, F20–F21 | Reparto tras cerrar contratos; integración de todos al tablero | Funciones declaradas disponibles tienen backend y pruebas; el resto tiene estado explícito y alcance acordado. |
| E. Roadmap externo | F24 | Definir proveedor y alcance antes de asignar implementación | No bloquea ajustes visuales ni se confunde con funcionalidad ya entregada. |

F23 es obligatorio en todos los bloques. Cada integrante debe poder explicar
el almacenamiento, caché y conectividad del recorrido completo. BQ9 depende de
F09/F10; no queda implementada solo por alinear el mockup.

## 6. Referencias de código para corregir

- `lib/shared/widgets/parch_navigation_bar.dart`: cuatro destinos.
- `lib/app/router/app_router.dart`: rutas registradas; no existe Discover,
  Create Group ni Group Details como destino funcional.
- `lib/features/home/presentation/views/home_view.dart`: ramas demo/producción,
  badge fijo, botones sustitutos y nueve TODO de acciones.
- `lib/features/schedule/presentation/views/schedule_view.dart`, `_planActivity`:
  solo propaga date/time en query parameters.
- `lib/features/activities/presentation/widgets/activity_form.dart` y
  `domain/entities/activity_draft.dart`: guardado directo y fecha/hora legacy.
- `lib/features/activities/data/models/activity_model.dart`: capacidades reales,
  campos ausentes y etiquetas RSVP; distinguir del repositorio mock.
- `lib/features/groups/data/repositories/firebase_active_groups_repository.dart`:
  RSVP de grupo y ausencia de detalle/creación.
- `lib/features/alerts/presentation/views/alerts_view.dart` y
  `widgets/alerts_sheets.dart`: avatar propio con hoja fija de ejemplo.
- `lib/features/alerts/data/repositories/firebase_alerts_repository.dart`:
  mapeo real de invitaciones; los demás tipos no llegan desde este repositorio.
- `lib/features/profile/presentation/views/profile_view.dart` y
  `widgets/profile_sheets.dart`: menús reducidos y selector Active/Busy.
- `lib/features/auth/presentation/views/sign_in_view.dart` y
  `data/data_sources/firebase_auth_data_source.dart`: recuperación pendiente y
  Google Auth sin configurar. No confundir con autorización de Calendar.

Son referencias relativas a la raíz Flutter. Revalidar las líneas al implementar;
esta auditoría no sustituye contratos ni pruebas.

## 7. Inventario del export y límites de fidelidad visual

Familias inspeccionadas (incluyen sus variantes):

| Familia | Carpetas |
|---|---|
| Welcome | welcome_to_parchapp_onboarding_screen |
| Auth | parchapp_sign_in_1/2; parchapp_create_account_reference_match; parchapp_create_account_scrollable_1/2 |
| Home/prototipo | home_dashboard_scrollable_1/2; syncup_unified_interactive_prototype |
| Estado | select_availability_status_bottom_sheet_en; set_availability_status_en_1/2 |
| Agenda/slots | parchapp_schedule_scrollable_custom_duration; optimized_time_slots_en_scrollable |
| Grupos | active_groups_parchapp; active_groups_scrollable; create_group_parchapp_1/2; group_details_friday_plans_en_1/2; group_details_roomies_main_st_1/2 |
| Actividades | create_activity; activity_created_confirmed_parchapp_1/2; activity_confirmation; activity_invitation; study_session_details_fully_interactive; active_session_contextual_actions_bottom_sheet_en |
| Alerts/Profile | parchapp_alerts_social_coordination_hub; parchapp_alerts_social_coordination_hub_mobile_390px; user_profile_en_scrollable_fix |
| Discovery | search_discover_3_item_nav; search_discover_fully_interactive_buttons |

Las capturas dañadas corresponden a Home 1/2, Sign-In 1/2, Active Groups en ambas
variantes, Roomies 1/2, Activity Created 1/2, Suggested Times, Schedule, Study
Session Details, su hoja contextual y Profile. Recuperarlas o renderizar sus
HTML antes de aprobar medidas/espaciados con comparación de capturas.

Además de variantes contradictorias, los HTML simulan acciones: cancelación
solo cambia una etiqueta; Add to Calendar muestra un toast; parte de las
descargas es un temporizador; copiar enlace puede mostrar éxito aunque falle
Clipboard. Conservar la intención de interacción y el diseño, pero implementar
su I/O y errores reales. No reproducir esas simulaciones en producción.

**Entregable de esta revisión:** lista y criterios de corrección. No se cambió
la implementación de las vistas ni se dio por completada ninguna integración
pendiente al elaborar este documento.
