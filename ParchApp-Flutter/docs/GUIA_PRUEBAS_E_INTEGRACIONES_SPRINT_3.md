# Guía práctica — ejecutar, probar e integrar el sprint 3

Responsable del segmento: Gabriel Enrique Rodríguez Pinto, Flutter.
Actualización: 26 de octubre de 2026. Estado vigente: [CIERRE_SPRINT_3.md](CIERRE_SPRINT_3.md). Las cifras históricas siguientes se sustituyen por la evidencia de ese documento.

Esta guía corresponde a Actividades, Alertas, respuestas pendientes y la nueva
BQ9. Los comandos son para PowerShell en este equipo. En otro equipo, sustituir
las dos rutas base. No modificar la aplicación Java: el backend sí es compartido
y cualquier ampliación debe conservar sus contratos existentes.

## 1. Qué está listo y qué falta

| Elemento | Estado |
|---|---|
| Creación y edición de actividades, detalle y recomendaciones | Implementados; requieren backend accesible |
| Invitaciones dentro de Alerts | Implementadas; no son notificaciones push |
| Responder sin conexión y recuperar pendientes al reiniciar | Implementado con SharedPreferences |
| Reintento y descarte por invitación | Implementados en el panel de pendientes |
| Continuar con otras invitaciones tras un rechazo | Implementado |
| Espera progresiva y pausa automática de conflictos | Implementadas; dependen del proceso en ejecución |
| BQ9 | Instrumentación, agregado Firestore y panel local; publicación compartida pendiente |
| Caché/concurrencia | Edad visible e isolate nativo implementados; SharedPreferences persiste datos; tareas de background no garantizadas |
| Despliegue en parchapp-852e8 | Pendiente de acceso y verificación |
| Prueba del nuevo conflicto en dispositivo físico | Pendiente |

Última verificación local de código: **180 pruebas Flutter aprobadas** y
`flutter analyze` sin problemas. Esto no acredita despliegue, Google OAuth real,
prueba física ni medición de BQ9. La cobertura anterior de 69,23 % corresponde a
otra ejecución; recalcularla si se necesita un porcentaje actualizado.

## 2. Preparación

### Cuenta sencilla para testing diario (20 de octubre)

Con el backend activo, ejecutar desde `C:\Users\gabri\MovsLocal\Backend`:
`npm run seed:testing`. Entrar como **Alex Valenzuela**, **a.va@test.com**,
contraseña **12345678**. Incluye dos grupos estables y los dos usuarios anteriores
como compañeros. `npm run verify:testing` verifica login y callables sin volver
a crear fixtures; reescribe únicamente el mismo estado de perfil durante la prueba.

`npm run emulators` ahora importa/exporta Auth y Firestore en `.emulator-data`.
Cerrar con Ctrl+C y esperar la exportación; `npm run emulators:save` guarda
mientras está activo. Abrir `C:\Users\gabri\MovsLocal\ParchApp.code-workspace`
para trabajar solo con Flutter, backend y contexto. La guía detallada está en
`C:\Users\gabri\MovsLocal\Backend\docs\local-testing.md`.

Para cerrar de forma explícita en Windows: `npm run emulators:stop` desde Backend.
Primero guarda Auth/Firestore y solo detiene la instancia si la exportación tuvo éxito.

El seed Flutter de las secciones siguientes sigue siendo útil para el smoke de
recomendaciones con fixtures nuevos; no hace falta ejecutarlo cada vez para Alex.

La revisión del panel Problems de VS Code redujo 49.788 diagnósticos a nueve
TODO informativos de Home (sin errores/advertencias). La ventana de MovsLocal
ahora excluye `smooth-app` y plantillas Dart de node_modules del backend; el
análisis de `lib` y `test` permanece activo.

Rutas:

```powershell
$flutterProject = 'C:\Users\gabri\MovsLocal\Sprint-2\ParchApp-Flutter'
$backendProject = 'C:\Users\gabri\MovsLocal\Backend'
```

Estas variables solo existen en la terminal donde se definen. Los ejemplos
siguientes usan rutas completas para que cada terminal funcione por separado.

Verificar herramientas:

```powershell
flutter --version
flutter doctor
node --version
npm --version
java -version
flutter devices
```

El backend declara Node 22. El procedimiento local existente usa Java 21 o
superior para los emuladores de Firebase; no se trata de ejecutar el proyecto
Java del otro equipo. Para Chrome hace falta ese navegador; Android requiere
su SDK y un dispositivo reconocido por `flutter devices`.

Instalar dependencias, una vez o después de cambiar los lockfiles:

```powershell
Set-Location 'C:\Users\gabri\MovsLocal\Backend'
npm ci
npm --prefix functions ci
Set-Location 'C:\Users\gabri\MovsLocal\Sprint-2\ParchApp-Flutter'
flutter pub get
```

Si `npm ci` informa desajuste de lockfile, resolverlo con el equipo; conservar
el mensaje y no borrar el lockfile para esconder el problema.

## 3. Ejecutar localmente con Firebase Emulator Suite

### Terminal 1: backend

```powershell
Set-Location 'C:\Users\gabri\MovsLocal\Backend'
npm run emulators
```

Esperar a que Auth, Firestore y Functions estén listos. Mantener esta terminal
abierta. Proyecto local: `demo-parchapp`. Puertos:

| Servicio | Puerto |
|---|---|
| Auth | 9099 |
| Firestore | 8080 |
| Functions | 5001 |
| Interfaz de emuladores | 4000 |

Interfaz local: http://127.0.0.1:4000 . Si se solicita `ANALYTICS_DATASET` al
cargar las funciones, para este ensayo local puede configurarse un valor de
prueba en `functions/.env.local`; no introducir credenciales de producción.
La prueba de invitaciones no necesita ejecutar agregaciones reales de BigQuery.

### Terminal 2: datos de prueba y Flutter

```powershell
Set-Location 'C:\Users\gabri\MovsLocal\Sprint-2\ParchApp-Flutter'
node tool/seed_activity_emulator.cjs
flutter run -d chrome --web-port=7357 --dart-define=USE_FIREBASE_EMULATORS=true --dart-define=SHOW_CONNECTIVITY_DEBUG_CONTROLS=true
```

El seed crea un grupo con dos usuarios y una actividad con identificadores reales;
escribe `build/emulator_fixture.json`. No elimina datos anteriores. Repetirlo crea
otro grupo/actividad: identificar siempre los IDs de la ejecución actual.

Credenciales **exclusivas de emuladores**:

La app normal ya no muestra una barra permanente Online/Offline. Los comandos
web de esta guía habilitan explícitamente controles de simulación con
`--dart-define=SHOW_CONNECTIVITY_DEBUG_CONTROLS=true`. Para una ejecución normal
omitir esa opción o usar `false`. Solo los pendientes reales muestran acceso a
su revisión. Al arrancar se abre Sign-In; una cuenta guardada se ofrece para
confirmación, y una cuenta borrada del Auth local se descarta sin borrar la cola.

| Rol | Correo | Contraseña |
|---|---|---|
| Organizador | organizer@parchapp.test | ParchApp123! |
| Participante | participant@parchapp.test | ParchApp123! |

El organizador crea/edita; el participante recibe y responde invitaciones. Usar
cuentas diferentes para probar autor frente a invitado. Los datos del emulador
se conservan al cerrar ordenadamente mediante el comando actualizado de backend.
Un cierre forzado puede perder cambios posteriores al último respaldo manual.

### Android emulado

```powershell
flutter devices
flutter run -d <ID_ANDROID> --dart-define=USE_FIREBASE_EMULATORS=true
```

Sustituir `<ID_ANDROID>` por el identificador real; no escribir los signos `< >`.
Android emulado usa `10.0.2.2`; Chrome usa `127.0.0.1` por defecto.

### Android físico por USB, para ejecución local

Con el dispositivo autorizado y `adb` disponible, redirigir los tres puertos:

```powershell
adb -s <SERIAL_ANDROID> reverse tcp:9099 tcp:9099
adb -s <SERIAL_ANDROID> reverse tcp:8080 tcp:8080
adb -s <SERIAL_ANDROID> reverse tcp:5001 tcp:5001
flutter run -d <ID_ANDROID> --dart-define=USE_FIREBASE_EMULATORS=true --dart-define=FIREBASE_EMULATOR_HOST=127.0.0.1
```

Usar el serial de `adb devices` y el ID de `flutter devices`. Esta opción permite
probar en hardware sin cambiar el enlace de los emuladores a la red local.
**Apagar Wi-Fi no corta un túnel USB**: para este montaje usar `Use offline`
como simulación y las pruebas automatizadas para reinicio sin red. La prueba
real de pérdida de internet debe hacerse también con el backend desplegado y
sin un túnel que siga proporcionando acceso. No presentar la simulación como
evidencia de pérdida real de conectividad.

## 4. Pruebas manuales y resultados esperados

### A. Flujo normal de actividades y respuesta

1. Entrar como organizador. En Home seleccionar `New Activity`.
2. Elegir el grupo creado por el seed y crear una actividad llamada `Prueba A`.
3. En Details abrir `Modify Session`, cambiar título/ubicación y guardar.
4. Volver a Home y reabrir: los cambios deben persistir.
5. Cerrar sesión y entrar como participante. Abrir Alerts desde la campana.
6. Localizar la invitación y aceptar. Salir de Alerts y volver a entrar.
7. Esperado: respuesta persistida y sin `Pending sync`.

Comprobación independiente: en Emulator UI, colección
`inboxes/{UID_PARTICIPANTE}/items/{ACTIVITY_ID}`, revisar `response`, `isRead`
y `respondedAt`. UID se obtiene en Auth; activity ID en Firestore. El backend
escribe esta colección; no dar permisos directos al cliente para editarla.
Los `goingIds` del grupo son RSVP de grupo heredados y no sustituyen este registro.

### B. Respuesta pendiente y descarte individual

1. Crear dos actividades nuevas `Prueba A` y `Prueba B` como organizador.
2. Entrar como participante y abrir Alerts online antes de desconectarse.
3. Pulsar `Use offline` en la franja superior.
4. Aceptar A y B. Esperado: dos pendientes y ninguna respuesta nueva del servidor.
5. Abrir el icono con tooltip `Review pending invitations`.
6. Pulsar `Discard this local response` para A y luego `Cancel`.
7. Esperado: siguen los dos pendientes.
8. Repetir y confirmar `Discard`.
9. Esperado: queda únicamente B. Pulsar `Go online`: B debe sincronizarse.

Descartar no equivale a rechazar una invitación. Elimina la intención local.
El descarte invalida el caché de Alerts; reconectar para recuperar la respuesta
real del servidor. Si se sigue offline, la vista puede indicar que no tiene una
copia disponible. Los demás comandos pendientes permanecen guardados.

La franja conserva además una acción antigua para descartar **todos** los
pendientes. Para este escenario usar el panel por invitación, no esa acción.

### C. Conflicto reproducible con dos sesiones

Preparar otras dos actividades sin respuesta; reutilizar A/B ya respondidas
no sirve. Abrir una segunda instancia en una tercera terminal:

```powershell
Set-Location 'C:\Users\gabri\MovsLocal\Sprint-2\ParchApp-Flutter'
flutter run -d chrome --web-port=7358 --dart-define=USE_FIREBASE_EMULATORS=true --dart-define=SHOW_CONNECTIVITY_DEBUG_CONTROLS=true
```

Los puertos distintos crean orígenes web distintos y separan el almacenamiento
local. Iniciar **la misma cuenta participante en ambas instancias**:

1. Instancia 7357: cargar Alerts, pulsar `Use offline`, aceptar A y B.
2. Instancia 7358: permanecer online y responder `Decline` a A.
3. Verificar en Emulator UI que A tiene `response=declined`.
4. Instancia 7357: pulsar `Go online`.
5. Esperado: A queda pendiente con `Needs review`; B se sincroniza aunque A falle.
6. Esperar dos ciclos de 30 segundos. A debe seguir pendiente: el rechazo no se
   reenvía automáticamente. Para contar intentos de forma precisa usar el test
   automatizado, no inferirlo solo de que la pantalla no cambia.
7. En el panel, reintentar solo A. El servidor debe volver a rechazarla porque
   ya tiene una respuesta diferente. No se fuerza sobrescritura.
8. Descartar solo A. Recargar Alerts online y verificar que aparece la respuesta
   `declined` del servidor. B debe continuar aceptada.

Regla vigente: el servidor acepta un reintento idéntico, pero rechaza cambiar
una respuesta ya guardada con `failed-precondition`. Resolver el conflicto hoy
significa reintentar o conservar el estado del servidor descartando la intención
local. Cambiar respuestas confirmadas requeriría un contrato nuevo explícito.

### D. Reinicio, red y separación de cuentas

En dispositivo físico con backend accesible por internet:

1. Cargar Alerts y Details online; desactivar Wi-Fi y datos móviles.
2. Responder una invitación nueva y verificar `Pending sync`.
3. Cerrar completamente y reabrir la app manteniendo la falta de red.
4. Esperado: respuesta pendiente conservada y vistas previamente guardadas
   disponibles; una vista nunca consultada no inventa datos.
5. Recuperar internet con la app abierta. Esperado: sincronización y eliminación
   del pendiente después del reconocimiento del servidor.
6. Antes de sincronizar, cambiar de cuenta: la otra cuenta no debe ver ni enviar
   pendientes de la anterior. Volver a la cuenta original y verificar su cola.

`Use offline` no se conserva como preferencia al reconstruir la app. Si hay red
real durante el reinicio, puede sincronizar inmediatamente. En Chrome mantener
el mismo origen/almacenamiento: un nuevo `flutter run` puede abrir un perfil de
navegador nuevo y no sirve para probar persistencia del perfil anterior.
No borrar datos de aplicación ni desinstalar: ambas acciones pueden borrar la cola.

Después de reiniciar, confirmar primero la cuenta en Sign-In. Home permite
deslizar hacia abajo para recargar actividades/perfil y los vuelve a consultar
al regresar la aplicación al primer plano.

Reintentos de transporte: mínimos de 30, 60, 120, 240 y 300 segundos; el timer
consulta cada 30 segundos mientras la app corre. `Retry`/`Go online` pueden
adelantar el intento. No hay ejecución garantizada con la app cerrada.

## 5. Pruebas automáticas

Desde Flutter, sin arrancar Firebase para los tests unitarios/widget:

```powershell
Set-Location 'C:\Users\gabri\MovsLocal\Sprint-2\ParchApp-Flutter'
flutter analyze
flutter test test/core/offline_mobile_api_test.dart
flutter test test/features/alerts
flutter test
```

El primer archivo prueba conflicto, reintento individual, descarte conservando
otros comandos, fallo de disco, cuentas distintas, reinicio, espera progresiva
y confirmación del panel. Para calidad y cobertura actualizadas:

```powershell
.\tool\check_quality.ps1
```

Produce `coverage/lcov.info` y `coverage/summary.json`. SonarQube es opcional:
`-Scan` requiere servidor autorizado con analizador Dart, token en variable de
entorno y SonarScanner instalado. No existe aún evidencia de un Quality Gate
aprobado. Ver `architecture/offline-and-quality.md`.

Prueba SDK contra emuladores reales, con la terminal de backend activa:

```powershell
node tool/seed_activity_emulator.cjs
flutter run -d chrome --target=tool/activity_emulator_smoke.dart --dart-define-from-file=build/emulator_fixture.json
```

Esperado: `PASS:` en pantalla/salida; `FAIL:` es fallo aunque Flutter permanezca
ejecutándose. Repetir el seed antes de cada smoke. Usa recomendaciones para hoy
en Bogotá: ejecutarlo antes de las 22:30 para evitar falta de horizonte útil.
Incluye SDK real, identidad, actividades, recomendaciones, perfil, disponibilidad
e invitaciones; el conflicto selectivo nuevo se cubre específicamente con el
test unitario/widget y el escenario C. Al terminar, salir con `q` y ejecutar la
app normal sin `--target`.

Para la comprobación enfocada de sesión y conexión Android usada al corregir
`emulator-5554`:

```powershell
flutter run -d emulator-5554 --target=tool/session_emulator_smoke.dart --dart-define-from-file=build/emulator_fixture.json
```

Comprueba inicio explícito en Sign-In, autenticación, carga de la actividad del
fixture y perfil. Cierra la sesión de prueba al terminar. Después ejecutar de
nuevo la app normal; no distribuir el APK generado con el target de smoke.
Esta comprobación pasó en `emulator-5554`; la app normal se reinstaló con los
controles de simulación deshabilitados y Sign-In visible.

Backend:

```powershell
Set-Location 'C:\Users\gabri\MovsLocal\Backend'
npm run test:functions
```

Para `npm run test:rules`, detener primero la sesión de emuladores de la sección
3: ese script inicia su propio Firestore en 8080 y no debe competir por el puerto.

```powershell
npm run test:rules
```

La verificación anterior del backend fue 23 tests de funciones y 43 de reglas/API;
volver a ejecutarlos al cambiar el contrato. No confundir esos resultados
anteriores con pruebas nuevas de BQ9, que todavía no existe en producción.

## 6. Integraciones pendientes y cómo implementarlas

### 6.1 Despliegue del backend real

Flutter apunta a `parchapp-852e8` en modo live; Backend tiene por defecto el
proyecto local `demo-parchapp`. La cuenta CLI revisada no tenía acceso al proyecto
live. Un integrante con acceso debe verificar proyecto, permisos y configuración:

```powershell
Set-Location 'C:\Users\gabri\MovsLocal\Backend'
npx firebase projects:list
```

Después de revisar las diferencias y coordinar el backend compartido, desplegar
los callables necesarios y las reglas compatibles usando proyecto explícito.
Ejemplo de despliegue acotado de los callables móviles existentes:

```powershell
npx firebase deploy --project parchapp-852e8 --only 'functions:getActivities,functions:getAlerts,functions:markAlertsRead,functions:respondToActivityInvitation,functions:getProfile,functions:updateProfile,functions:getScheduleFriends,functions:getScheduleDay,functions:importCalendarAvailability'
```

Esto no despliega los callables de recomendaciones: revisar también
`functions/src/activityCallables.js` y `functions/index.js` si faltan en live.
Para reglas/índices, revisar antes el diff compartido y luego:

```powershell
npx firebase deploy --project parchapp-852e8 --only firestore:rules,firestore:indexes
```

No sustituir reglas por permisos abiertos. UID sale del token; `clientUserId`
protege el replay ante cambios de sesión. Habilitar Email/Password en el proyecto
y revisar la configuración de parámetros de las funciones desplegadas. No inventar
`ANALYTICS_DATASET`: debe ser el dataset real de la integración analítica.

Ejecutar live solo después de verificar ese backend:

```powershell
Set-Location 'C:\Users\gabri\MovsLocal\Sprint-2\ParchApp-Flutter'
flutter run -d <ID_ANDROID> --dart-define=USE_FIREBASE_EMULATORS=false
```

El smoke y el seed anteriores son exclusivamente locales; no ejecutarlos contra
producción. Para construir un APK live de comprobación:

```powershell
flutter build apk --debug --dart-define=USE_FIREBASE_EMULATORS=false
```

Salida: `build/app/outputs/flutter-apk/app-debug.apk`. Un APK debug local no
significa que se haya completado la distribución requerida por el curso.

### 6.2 BQ9: implementar, no solo documentar

Pregunta acordada: **¿Qué proporción de actividades utiliza previamente Comparar
disponibilidad y cómo difiere su tasa de confirmación en siete días?**

Contrato completo: `architecture/bq9-availability-confirmation.md`. Orden de trabajo:

1. **Contexto Flutter.** Crear un objeto de flujo con `creation_flow_id` estable.
   Pasarlo desde comparación a creación, persistirlo con el borrador y conservarlo
   en reintentos. Hoy `ActivityDraft` no transporta esa atribución.
2. **Evidencia.** Registrar comparación completada, no apertura de pantalla;
   invalidarla al cambiar día/participantes. Incluir origen servidor/caché y
   conservar desconocido cuando no exista evidencia fiable. Trabajar con el dueño
   de Schedule para conectar la navegación; no usar una variable global booleana.
3. **Backend compatible.** Ampliar creación con reconocimiento idempotente del
   flujo y atribución validada. Hoy creación usa Firestore directo: decidir una
   ampliación aditiva por callable/transacción o un procesamiento de eventos
   equivalente; no añadir simplemente campos que las reglas actuales rechacen.
   Conservar clientes antiguos/Java como `unknown`, sin exigirles campos nuevos.
4. **Confirmación.** Registrar primera transición a `CONFIRMED`, incluso creación
   ya confirmada, con hora del servidor e historial idempotente. Aceptar una
   invitación no es confirmar la actividad. Rechazar escrituras no autorizadas.
5. **Datos analíticos.** Identificar el proyecto/dataset existente y comprobar
   exportaciones reales de eventos y de negocio. La descripción de la wiki no
   demuestra que estén habilitadas. Unir por activity ID y deduplicar por evento/
   flujo; no correlacionar por cercanía temporal de cualquier evento del usuario.
6. **Consulta.** Cohortes maduras con siete días de observación; mostrar uso,
   tasas con/sin comparación, diferencia en puntos porcentuales, n y cobertura.
   Unknown queda fuera de la comparación; denominador vacío produce sin datos.
7. **Dashboard común.** Añadir el panel al tablero existente, conectado a la misma
   base analítica del equipo. Faltan verificar enlace del tablero, dataset y
   permisos de edición. No crear un tablero aislado ni subir CSV manuales como
   sustituto de la integración.
8. **Pruebas.** Crear fixtures true/false/unknown, confirmación tardía, duplicados,
   eventos fuera de orden y denominadores vacíos; validar contra el ejemplo del
   contrato y después con datos de prueba del pipeline real.

No hay una consulta BQ9 lista para ejecutar sobre un dataset confirmado. Primero
cerrar el contrato de ingestión y los nombres reales de tablas. Tampoco enviar
nombres, emails, contenido del calendario ni títulos de actividades en telemetría.

### 6.3 Almacenamiento, caché y conectividad restantes

- **Almacenamiento transaccional:** implementar otra clase de `OfflineStore`
  manteniendo su interfaz; definir esquema y migración desde `offline.v1.<proyecto>.<uid>`.
  Probar recuperación y atomicidad antes de cambiar la inyección en
  `firebase_dependencies.dart`. No borrar la cola anterior hasta verificar la
  migración. Coordinar esto con el responsable de almacenamiento del equipo.
- **Caché:** `OfflineMobileApi` guarda hasta 64 respuestas y ya entrega `cachedAt`
  al leer offline; faltan política por recurso, caducidad visible e invalidación.
  Activity Details/Alerts deben indicar antigüedad sin afirmar que una copia
  garantiza disponibilidad o una reserva. Probar expiración con reloj controlado.
- **Escrituras restantes:** crear/editar actividad, perfil e importación Calendar
  requieren conexión. Definir por operación si se bloquea con mensaje claro o se
  admite cola; antes de encolar creación añadir idempotencia de servidor. No
  aplicar la cola de invitaciones a todas las escrituras indiscriminadamente.
- **Segundo plano:** timer y reanudación no ejecutan trabajo con proceso cerrado.
  Si se incorpora un scheduler del sistema, conservar la misma cola e identidad;
  probar restricciones reales de Android y no prometer sincronización inmediata.
- **Concurrencia:** la cola serializa modificaciones con Futures. Eso evita
  sobrescrituras locales, pero no constituye un isolate ni otra hebra. Si se
  incorpora cómputo costoso de disponibilidad, medirlo y acordar con Schedule
  si procede aislarlo; mantener plugins fuera del cómputo puro.
- **BQ5 offline:** la respuesta puede sincronizarse sin entregar la telemetría
  cliente actual de BQ5. Implementar emisión idempotente desde el servidor o un
  outbox analítico separado para cubrir replay sin duplicar métricas.

### 6.4 Calendar, push y servicios externos

Calendar ya tiene adaptadores para Google FreeBusy e importación por callable.
Falta verificar OAuth real en el dispositivo/proyecto: configuración de cliente,
consentimiento, permisos y errores del proveedor. Revisar
`google_calendar_auth_data_source.dart` y `google_free_busy_data_source.dart`.
Solo se importan intervalos ocupados del calendario primario; no títulos ni
ubicaciones. No tratar días sin importar como libres.

Alerts es un buzón dentro de la app, sin entrega push. Si se requiere push,
implementar registro/renovación de tokens por usuario/dispositivo y envío desde
backend con deduplicación; probar permiso denegado, sesión distinta y app cerrada.
No contarlo como funcionalidad entregada hoy. Mapas, chat, reservas y descarga
de recursos también requieren servicios/contratos propios; no forman parte del
incremento de conflictos aquí descrito. Cámara queda fuera de este trabajo.

## 7. Archivos de referencia

Rutas relativas a la raíz Flutter, salvo las marcadas Backend:

| Archivo | Uso |
|---|---|
| lib/core/data/offline_mobile_api.dart | Caché, cola, replay y descarte individual |
| lib/shared/widgets/pending_invitations_panel.dart | Revisión por invitación y confirmación |
| lib/shared/widgets/offline_shell.dart | Modo offline, timer y estado de conexión |
| lib/app/dependency_injection/alerts_dependencies.dart | Recarga de Alerts al reducir pendientes |
| lib/features/alerts/data/repositories/firebase_alerts_repository.dart | Mapeo, respuesta y telemetría cliente |
| lib/app/dependency_injection/firebase_dependencies.dart | Selección local/live e inyección |
| test/core/offline_mobile_api_test.dart | Casos de cola y panel |
| tool/seed_activity_emulator.cjs | Dos usuarios, grupo y actividad locales |
| tool/activity_emulator_smoke.dart | Verificación SDK local |
| Backend/functions/src/mobileService.js | Validación y persistencia de invitaciones |
| Backend/functions/src/mobileCallables.js | Autenticación y contratos de entrada |
| Backend/tests/mobile.api.test.js | Contratos móviles y permisos |

## 8. Registro de evidencia y diagnóstico

Por escenario anotar fecha, commit/estado local, dispositivo, plataforma,
proyecto usado, IDs de prueba, pasos, resultado esperado/real y enlace a evidencia.
No grabar tokens, contraseñas reales ni datos privados en capturas.

| Síntoma | Revisar |
|---|---|
| No aparecen invitaciones | Sesión participante, miembro del grupo, actividad de otro autor, entorno correcto |
| Cannot connect / unavailable | Emuladores activos, puertos, host y dispositivo; una interfaz Wi-Fi no garantiza internet |
| Puerto ocupado al probar reglas | Detener primero el emulador manual que usa 8080 |
| not-found o callable inexistente | Nombre/export de Functions, proyecto y despliegue; no reemplazar por mock |
| failed-precondition al reenviar | Respuesta diferente ya guardada: conflicto esperado |
| Pendiente reaparece tras fallo local | Revisar persistencia; un reconocimiento perdido permite replay idempotente |
| Alerts sin copia tras descarte offline | Invalidación deliberada: reconectar y recargar |
| Cola desaparece en otra ejecución web | Confirmar mismo origen y perfil de navegador; no usar perfil nuevo como prueba de persistencia |
| No se ve BQ9 en dashboard | Aún faltan instrumentación, ingestión, consulta y panel; no es un bug del panel de conflictos |

Terminar este segmento exige evidencia del escenario C y del reinicio físico,
backend live verificado y BQ9 funcionando de extremo a extremo. La guía y los
tests locales son una base para completar esas integraciones, no su sustituto.
