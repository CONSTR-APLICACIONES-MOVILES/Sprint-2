# Cierre local de sprint 3 — 26 de octubre de 2026

Alcance: Flutter y backend compartido. Se conservó Java. Las referencias son el PRD 2.5, los HTML del export y las seis capturas que corrigió el usuario. Esta revisión completa los pendientes de código del segmento Actividades/Alertas y mantiene los recorridos A–D. No certifica despliegue ni prueba en un teléfono físico.

## Funcionalidad y fidelidad visual

- Marca y tema compartidos: logo original, Inter incluida, azul #0047BA, verde, tarjetas blancas y fondos claros. Navegación Home / Groups / Schedule.
- Home, lista/detalle/creación de grupos, estado, Alerts, Profile, Schedule e invitación/detalle de actividad conservan datos, IDs, permisos, carga, vacíos y errores reales.
- Create Activity presenta Details → Review, título/grupo, categorías en píldoras y selección de intervalo. Review conserva el borrador y vuelve al inicio al cambiar de paso. El resultado presenta confirmación visual, resumen, invitados y navegación al mismo ID.
- Confirmación muestra fecha y hora legibles en Bogotá. Profile presenta el estado real ampliado, sin convertir In class/Offline en Busy.
- Groups ofrece View group en lugar de dos botones que hacían la misma comparación. Se eliminó el acceso redundante separado. Participantes abren perfiles autorizados; compartir actividad abre el adaptador real. Rutas/salas del prototipo no se ofrecen como acciones conectadas en datos reales.
- Schedule permite crear una propuesta cuando no hay un slot seleccionado. La comparación sin huecos también puede acompañar al borrador, con validación del servidor.
- Google Calendar permanece deshabilitado en la composición Firebase mientras no se configure explícitamente `ENABLE_GOOGLE_CALENDAR_IMPORT=true` y los accesos OAuth correspondientes. Las pruebas demo conservan su adaptador inyectado. La importación no se presenta como sincronización automática.
- El alta de una cuenta deja de incorporarla automáticamente a grupos de ejemplo. El comportamiento de demostración requiere dos condiciones explícitas del servidor: Functions emulado y `ALLOW_DEMO_AUTOJOIN=true`.

Las propuestas heredadas sin fecha siguen admitidas y claramente identificadas. Maybe se conserva. No se copian bordes punteados de interacción, marcos de teléfono, personas fijas, Live Sync ni porcentajes de muestra. La tipografía Inter sigue el sistema visual compartido; algunos PNG del export usan serif o están dañados.

## Conectividad, almacenamiento y concurrencia

`OfflineMobileApi` conserva lecturas y cola persistente por proyecto/UID. Solo se anuncian respuestas pendientes después de guardarlas. Se mantienen reintentos por invitación, espera progresiva, conflictos pausados y descarte selectivo. Publicar, editar y cancelar requieren conexión y reconocimientos reales.

Details y Alerts muestran la fecha/hora guardada cuando se leen desde caché. La advertencia de antigüedad aparece tras 15 minutos o si falta la fecha; no significa que el contenido deje de poder consultarse. Responder localmente no actualiza esa fecha como si se hubiese descargado de nuevo. El reloj de persistencia es inyectable y se prueba tras reinicio y cambio de cuenta.

`OfflineDocumentCodec` procesa documentos grandes mediante `compute` en un isolate nativo; el trabajador recibe JSON y no escribe almacenamiento. La cola serial conserva la propiedad de todas las escrituras para evitar pérdida de actualizaciones. Se usa para decodificar documentos de al menos 32 KiB y para codificar cachés con al menos ocho entradas o listas de al menos cien actividades/alertas. En web `compute` usa el bucle del navegador, por lo que no se afirma un hilo adicional allí. SharedPreferences continúa como estrategia de almacenamiento; SQLite no es requisito para acreditar almacenamiento local.

## BQ9 implementada

Pregunta: proporción de actividades creadas con comparación previa y diferencia de confirmación en siete días respecto a creación directa.

- Una fila `coordinationMeasurements/{activityId}` se crea en la misma transacción de publicación; el requestId estable impide duplicaciones.
- Una comparación utilizada requiere evidencia de servidor, UID, participantes, día, grupo cuando corresponde, vigencia y consumo por el mismo flujo. Abrir Schedule no cuenta. `prepareProposalComparison` valida disponibilidad conocida incluso cuando no hay huecos comunes. El contexto y la atribución sobreviven al router y al diario de publicación.
- El protocolo Flutter nuevo envía `measurementVersion=1`. Creación directa instrumentada = false; clientes anteriores = unknown. Una comparación antigua sin su recibo de medición permanece unknown.
- Primera confirmación en creación/edición se guarda transaccionalmente. El trigger registra también transiciones compatibles de Java y conserva la más temprana ante duplicación o llegada desordenada.
- Agregación diaria: treinta días completos de creación en Bogotá con siete días de observación cumplidos. Muestra n, cobertura, desconocidos, uso, dos tasas y diferencia en puntos porcentuales. Un denominador vacío produce null/No data. Las filas del entorno de pruebas se excluyen de producción.
- Panel funcional en Profile → Comparison & confirmation. Consume el agregado de Firestore mediante callable autenticado; contempla carga, ausencia de medición, error y Retry. La copia local de prueba se etiqueta Test data. El agregado se lee; los clientes no pueden escribir ni leer los registros de correlación crudos.
- No se incluyen nombres, emails, títulos, lugares ni intervalos privados en las filas de medición. El resultado expresa asociación, sin inferencia causal.

Funciones: `prepareProposalComparison`, `getCoordinationInsight`, `recordFirstActivityConfirmation`, `refreshCoordinationInsight`. Colecciones nuevas y comprobaciones no cambian enums ni operaciones heredadas de Java.

El pipeline y el panel están implementados y verificados localmente sobre Firestore. El despliegue del job/trigger, la conexión al dashboard unificado del equipo y una exportación a BigQuery/Looker siguen dependiendo de acceso y configuración de ese entorno. No se presentan como publicados.

## Evidencia reproducible

Desde Backend, con emuladores activos:

```powershell
npm run test:sprint3
npm --prefix functions test
npm run seed:sprint3-qa
npm run insights:sprint3:local
```

El comando de insights recalcula solo el agregado local marcado como prueba, sin insertar cohortes de ejemplo. Si no existen actividades maduras, se muestra No data.

El runner de regresión copia temporalmente las tres suites heredadas a proyectos aislados y borra solo esas copias al terminar. Nunca limpia demo-parchapp. El seed QA crea dos cuentas `sprint3-qa-*` y un grupo exclusivo; no reinicializa las cuentas/grupos de Alex o Camila. No envía emails.

Desde Flutter:

```powershell
flutter analyze --no-pub
flutter test --no-pub --reporter expanded
flutter test --no-pub test/sprint3_api_ui_e2e_test.dart --dart-define=RUN_SPRINT3_E2E=true --reporter expanded
flutter build apk --debug --no-pub
flutter build web --no-pub
```

La suite general no necesita red: la integración se habilita expresamente después del seed. Esa integración combina creación/revisión/resultado renderizados con llamadas HTTP autenticadas reales y prueba del modelo de invitación, persistencia en archivo, reinicio/replay, edición y cancelación contra Functions/Firestore. No es una prueba manual ni una ejecución Android. Resultado persistido sin tokens en `build/sprint3-api-ui-e2e-result.json`.

- Flutter: 252 pruebas generales aprobadas y la integración explícita de dos pruebas; un caso de opt-in se omite en la ejecución general.
- Backend: 87 pruebas de API/reglas y 27 unitarias de Functions aprobadas.
- Analizador: sin incidencias.
- Capturas de widgets revisadas en `build/visual-review/`, tamaño 390 × 844, con Inter e iconos cargados. Además de las ocho anteriores se incluyen create-activity, review-activity, activity-created, schedule, profile y planning-insights. La suite mantiene layout de 320/390 px con texto al 180 % y teclado.
- Compilaciones: logs `build/sprint3-apk.log` y `build/sprint3-web-build.log`.
- APK local: `build/app/outputs/flutter-apk/parchapp-sprint3-local.apk`.

## Límites de entrega externos

El APK local necesita los emuladores de este equipo; no se debe distribuir como si incluyera un backend en la nube. En Android emulado usa 10.0.2.2. Para hardware se necesita redirección USB/host o un backend desplegado; ver la guía de ejecución.

Durante esta revisión Android apareció como unauthorized y expiró la aprobación de la herramienta visual. No se instala ni se declara probado en hardware sin esa autorización. El curso exige demostración física y distribución mediante App Distribution; eso, el despliegue y la publicación de la wiki/dashboard compartidos quedan como acciones externas pendientes. OAuth, correo de invitaciones, dominios, push, mapas/chat/reservas y sincronización automática no se anuncian como implementados.
