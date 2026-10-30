# BQ9 — Uso de comparación y confirmación de actividades

**Responsable:** Gabriel Enrique Rodríguez Pinto, Flutter, sprint 3.
**Alcance confirmado por Gabriel el 29/10/2026:** implementar y presentar BQ9 desde Flutter. El SQL y aporte Java previo de Juan David se conservan y se reconocen en el PR Backend #2; esta documentación no sustituye su autoría.
**Tipo:** 3, análisis de funcionalidades.
**Estado (26/10/2026):** instrumentación, primera confirmación, agregación Firestore y panel local implementados. Despliegue y conexión al dashboard unificado del equipo pendientes. Ver [cierre local](../CIERRE_SPRINT_3.md).

**Revisión vigente (29/10/2026):** el backend de esta sesión ya admite `measurementVersion` y `comparisonEvidenceId`; cuatro payloads exportados desde `ActivityDraft` pasan la validación callable y la medición (40 pruebas backend y cinco pruebas Flutter enfocadas). Los endpoints nuevos tienen código desplegado, pero la invocación sigue bloqueada por IAM (HTTP 403). El agregado real está en Firestore; el tablero compartido aún no muestra BQ9. Los resultados del cierre del 26 no certifican el recorrido autenticado actual.

## Pregunta y decisión

¿Qué proporción de las actividades creadas utiliza previamente Comparar
disponibilidad, y cómo difiere su tasa de confirmación en siete días frente a
las creadas sin esa comparación?

Corresponde a BQ9 de la primera tabla canónica de `wiki.md`. La wiki contiene
otra numeración histórica: identificar esta BQ también por su nombre. Es
distinta de BQ3 (aceptación de recomendaciones sin cambios) y BQ13 (rendimiento
de recomendaciones para mejorar el ranking), documentadas para el responsable
en sprint 2. Su resultado sirve al equipo para decidir la visibilidad del acceso
a Comparar disponibilidad y dónde simplificar el flujo de creación.

La diferencia observada es una asociación, no evidencia de causalidad. El tamaño
del grupo, categoría y selección de usuarios pueden explicar parte del resultado.

## Unidad, atribución y población

- Unidad: una actividad creada y reconocida por el servidor, identificada por
  `activity_id`. Un borrador, un toque o un envío fallido no son una actividad.
- Iniciar un borrador genera `creation_flow_id`; el mismo ID acompaña los
  reintentos. El servidor debe impedir contabilizar varias veces una creación
  con el mismo identificador, sin alterar clientes Java existentes.
- `comparison_used=true` requiere una comparación completada correctamente,
  con al menos un participante adicional, dentro de ese mismo flujo y antes
  de la creación. Abrir Schedule no basta. Una comparación sin huecos comunes
  también cuenta: utilizar la función no exige aceptar una recomendación.
- Cambiar el conjunto de participantes o el día invalida esa evidencia hasta
  volver a comparar. Comparaciones de otra actividad no se heredan.
- El origen puede ser servidor o caché; se registra por separado para poder
  interpretar disponibilidad antigua. No se envían intervalos privados.
- `comparison_used=false` solo se asigna cuando el flujo instrumentado completo
  permite asegurar que no hubo comparación. Clientes anteriores, Java sin
  instrumentación o eventos perdidos quedan como `unknown`, nunca como false.
- Primera entrega: cohortes de creación de los últimos 30 días completos en
  America/Bogota con siete días de observación cumplidos. Excluir fixtures y
  cuentas de pruebas mediante un marcador explícito del entorno/dataset.

## Métricas

| Métrica | Definición |
|---|---|
| Cobertura | Actividades con atribución true/false / todas las actividades de la cohorte |
| Uso previo | Actividades con comparación / actividades con atribución conocida |
| Confirmación con comparación | Actividades true confirmadas en siete días / actividades true |
| Confirmación sin comparación | Actividades false confirmadas en siete días / actividades false |
| Diferencia | Tasa con comparación menos tasa sin comparación, en puntos porcentuales |

Confirmación significa primera transición persistida a `CONFIRMED`, incluyendo
creación directamente en ese estado. Se mide por tiempo del servidor, dentro
de `[created_at, created_at + 7 días]`. Una aceptación individual de invitación
no equivale a confirmar la actividad. Los cambios posteriores no borran la
primera transición del historial. Los denominadores vacíos producen NULL/sin
datos, no 0 %. Mostrar siempre n, cobertura y fecha de actualización.

Ejemplo de aceptación: cuatro actividades maduras con atribución conocida,
dos true y dos false; se confirman ambas true y una false. Uso previo: 50 %;
confirmación: 100 % frente a 50 %; diferencia: 50 puntos porcentuales. Una quinta
actividad unknown afecta cobertura (80 %), no los denominadores de comparación.

## Contrato de datos a implementar

| Registro | Campos mínimos | Origen |
|---|---|---|
| Comparación completada | event_id, creation_flow_id, completed_at, source (server/cache), participant_count, schema_version | Flutter, con deduplicación al recibir |
| Creación reconocida | activity_id, creation_flow_id, created_at, comparison_used (true/false/unknown), platform, category, group_size, schema_version | Servidor |
| Primera confirmación | activity_id, first_confirmed_at | Historial/registro persistido del servidor |

La evidencia de comparación debe enlazarse al borrador al navegar de Schedule
a creación; nunca inferirse buscando cualquier evento del mismo usuario en los
minutos anteriores. Una sola fila analítica por actividad se une al historial de
confirmación por activity_id. Conservar unknown si no llega la evidencia.

Los eventos reintentados conservan event_id; su recepción tardía no cambia el
instante de creación ni convierte un pendiente local en éxito del servidor.
El orden debe validarse con el flujo reconocido y metadatos del servidor; un
reloj local no es prueba suficiente. No registrar nombres, emails, títulos,
ubicaciones ni contenido de calendarios. Los identificadores de correlación
permiten vincular registros y requieren acceso restringido; no son datos
agregados anónimos.

## Integración y criterio de terminado

1. Conectar el contexto de comparación con el borrador de creación Flutter y
   preservar su identidad en reintentos y reinicio.
2. Añadir recepción/validación compatible en el backend compartido y registro
   de primera confirmación. Probar creación directa y transición posterior.
3. Llevar ambas fuentes al mismo almacén analítico usado por el dashboard
   unificado. Confirmar proyecto/dataset y exportaciones reales antes de escribir
   una consulta ligada a nombres de tablas concretos.
4. Deduplicar, construir cohortes maduras y validar con el ejemplo anterior,
   casos unknown, denominador vacío, reintentos y confirmación fuera de ventana.
5. Publicar en el dashboard existente dos tasas comparables, diferencia,
   tamaños de muestra y cobertura, con conexión directa a la base analítica.
   No completar mediante CSV descargados manualmente.

La implementación actual utiliza recibos de comparación validados y consumidos por una publicación idempotente, en lugar de inferir atribución por proximidad de eventos. El requestId es el identificador del flujo reconocido. La fuente inicial aceptada es servidor; una publicación no se permite sin conexión. Una lectura de caché no se convierte por sí sola en comparación válida para BQ9.

Las colecciones `coordinationComparisons` y `coordinationMeasurements`, la función diaria `refreshCoordinationInsight` y el panel Profile → Comparison & confirmation están verificados localmente. La primera confirmación incluye transiciones de Java mediante trigger. Se mantiene este documento como definición de la pregunta y sus métricas; la integración en el almacén/dashboard compartido requiere configuración de despliegue y no se declara publicada.
