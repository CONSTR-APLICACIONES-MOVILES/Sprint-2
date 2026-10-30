# Demo técnica y brechas del viva 3

Revisión: 29 de octubre de 2026. Prioridad acordada: demo y mecanismos técnicos primero; integración final BQ9 y defensa después.

## Cambios preparados y comprobados

| Tema | Antes | Ahora | Evidencia |
|---|---|---|---|
| Almacenamiento nativo | Caché y pendientes juntos en Preferences | SQLite versión 1: cuentas/namespace, respuestas cacheadas y operaciones pendientes en tablas relacionadas con claves compuestas y foráneas. Una transacción guarda caché y cola completas. Android/iOS/macOS usan SQLite; web conserva Preferences. | Pruebas con SQLite real en archivo y ensayo Android |
| Migración | No había migración a BD local | Importación por proyecto/UID del documento `offline.v1...`; copia antigua conservada para recuperación. Una cuenta SQL ya creada no reimporta pendientes antiguos aunque la cola quede vacía. Datos corruptos/fallos SQL no destruyen el original. | Reapertura real del archivo, fallo SQL inyectado y comparación de snapshots |
| Caché | Orden por última escritura | LRU persistida: cada hit mueve la entrada al final; al superar 64 se expulsa la menos usada. Lectura no modifica `savedAt`. Actualizaciones de perfil respetan también el límite. | Test de hit → reinicio → nueva entrada → expulsión correcta |
| Invalidación | Listas/detalles podían conservar valores anteriores a una mutación | Publicación/edición/cancelación/recomendación/respuesta reconocidas invalidan listas y detalles afectados. Cambios de recomendaciones invalidan agenda cacheada. Una intención offline no se anuncia como resultado remoto. | Test y suite de replay/conflictos |
| Visibilidad offline | Details/Alerts mostraban edad; Home/Profile perdían ese contexto | Home y Profile conservan los metadatos del snapshot y muestran hora guardada/advertencia de antigüedad con el contenido. | Dos nuevas pruebas de widgets |
| Concurrencia | Future serial, Stream de conectividad y compute existentes | Se conservan y verifican junto con el nuevo almacenamiento. El trabajador JSON no escribe BD ni plugins; las escrituras se serializan y SQLite añade atomicidad. | Round trip nativo de 50.944 caracteres y regresión |

Archivos principales: `lib/core/data/sqlite_offline_store.dart`, `offline_mobile_api.dart`, `offline_document_codec.dart` y composición en `firebase_dependencies.dart`.

El esquema SQL separa entidades/orden/namespace y mantiene el payload de cada respuesta o comando como JSON para conservar el contrato existente. El límite de caché es por número de entradas, no una promesa de memoria máxima en bytes. La manipulación del orden en Map es constante en promedio; cargar/guardar la instantánea completa tiene coste proporcional a sus filas. El aviso a 15 minutos indica antigüedad; no elimina automáticamente copias que pueden ser útiles sin conexión.

## Resultado de validación

- Regresión Flutter: **260 pruebas aprobadas**, una integración opt-in omitida.
- Analizador: **sin incidencias**.
- Ensayo Android nativo: **PASS**, en `emulator-5554`.
- SQLite reabrió conservando cuatro recursos API: actividades, detalle, alertas y perfil.
- Un pendiente sobrevivió al cierre/reapertura de la BD; cero envíos mientras estaba forzado offline; un reconocimiento simulado y cero pendientes después del replay.
- El codec nativo procesó 50.944 caracteres por la ruta de `compute`.
- APK normal cloud compilado e instalado correctamente en `emulator-5554`, restaurando `lib/main.dart` después del ensayo. Copia de comprobación: `build/app/outputs/flutter-apk/parchapp-viva-cloud-debug.apk`; tamaño y SHA-256 en `build/viva-apk-result.json`.

Evidencia en `build/viva-regression.log`, `build/viva-analyze.log`, `build/viva-native-smoke.log` y `build/viva-native-result.json`.

El ensayo usa **un remoto en memoria y datos de prueba**, identificados en pantalla, y su propia BD `parchapp-viva-rehearsal.sqlite`. No toca cuentas ni datos Firebase. Comprueba almacenamiento/API/isolate nativos, no cuatro pantallas renderizadas ni pérdida real de internet. El APK normal usa `parchapp-offline.sqlite` y Firebase cloud.

## Guion de demo funcional: 6–8 minutos

Preparación: disponer de cuenta organizadora A y participante B del proyecto real, un grupo compartido, dos invitaciones nuevas sin responder y un teléfono físico para la evidencia final. Usar cuentas de prueba, no mostrar contraseñas/tokens. Un emulador Android sirve para el ensayo previo; no se necesita Firebase Emulator Suite.

1. **Online / minuto 0–1.** Abrir Home, Details de una actividad, Alerts y Profile como B. Anotar ID de actividad y hora. Se deben ver datos reales. La precarga es necesaria: una vista nunca visitada no puede inventar una copia.
2. **Navegación offline / minuto 1–3.** Cortar Wi-Fi y datos. Volver a esas cuatro vistas con navegación normal. Mostrar contenido, estado de copia y hora guardada. En Home comprobar qué secciones tienen datos: no presentar una sección vacía/con error como si estuviera protegida. Crear/editar/cancelar requiere conexión; demostrar el mensaje sin confundirlo con una escritura guardada.
3. **Persistencia / minuto 3–4.** Responder una invitación nueva desde Alerts. Debe aparecer pendiente. Cerrar y reabrir la app sin red; confirmar cuenta si lo solicita. Volver a Alerts y al panel de pendientes: la intención debe seguir allí y las copias consultables.
4. **Sincronización / minuto 4–5.** Recuperar conexión con la app abierta. Esperar reconocimiento o usar el reintento del panel. El pendiente desaparece solo tras éxito; reabrir Alerts online y verificar la respuesta remota con el mismo ID.
5. **Conflicto y cuentas / minuto 5–7.** Preparar otra invitación. Dejar intención local y responder diferente desde una segunda sesión de la misma cuenta; al reconectar debe requerir revisión y no sobrescribir silenciosamente. Cambiar a A: no debe ver ni reenviar la cola de B. Volver a B para revisar/reintentar/descartar la intención.
6. **Código / último minuto técnico.** Abrir las tres tablas y transacción, `_remember`/invalidación, `_locked`, `compute` y Stream de conectividad. Si hace falta repetir mecanismos sin acceso cloud, usar el ensayo técnico claramente etiquetado, sin presentarlo como flujo online real.

Para la prueba de corte real no mantener `adb reverse`/túneles al backend local. Un control de simulación tampoco prueba pérdida de internet. Con proceso cerrado no hay sincronización garantizada; el timer actúa mientras corre y se reintenta al volver al primer plano.

## Comandos para repetir

Desde `C:\Users\gabri\sprintsinstruct\MovsLocal\Sprint-2\ParchApp-Flutter`:

```powershell
flutter analyze --no-pub
flutter test --no-pub test/core/sqlite_offline_store_test.dart test/core/offline_mobile_api_test.dart test/core/sprint3_completion_test.dart test/features/offline_snapshot_views_test.dart --reporter expanded
flutter test --no-pub --reporter expanded
```

Ensayo técnico nativo, base separada y remoto simulado:

```powershell
flutter run -d emulator-5554 --target=tool/viva_storage_smoke.dart --no-pub --no-resident
```

No distribuir ese target. Al terminar restaurar la aplicación normal:

```powershell
flutter build apk --debug --no-pub --dart-define=USE_FIREBASE_EMULATORS=false
adb -s emulator-5554 install -r build/app/outputs/flutter-apk/app-debug.apk
adb -s emulator-5554 shell am start -n com.example.parchapp/.MainActivity
```

Para hardware sustituir el serial por el que devuelva `adb devices -l`. Si se quieren controles explícitos de simulación para un ensayo, añadir `--dart-define=SHOW_CONNECTIVITY_DEBUG_CONTROLS=true`; el APK normal de comprobación los mantiene apagados. Estos controles no se conservan al reiniciar.

## Brechas que todavía no se declaran cerradas

- **Puntuación máxima de almacenamiento:** ahora hay SQLite y Preferences con usos reales. La hoja enumera relacional 10 y Preferences 5; no se añadió una BD llave/valor o archivos artificiales para asumir otros puntos. No se afirma obtener automáticamente 20.
- **Puntuación máxima de caché:** hay LRU explícita y probada. No se añadió una librería de imágenes remotas sin un uso real; no se presume puntuación completa solo por usar Map.
- **Cuatro vistas en hardware:** repositorios/recuperación y widgets están probados, pero faltan el recorrido manual y la grabación en el teléfono del integrante. La prueba de cuatro recursos API no sustituye cuatro vistas protegidas.
- **Tareas de compañeros:** falta la revisión cruzada del código Flutter que ellos presentarán. No basta con explicar estos archivos.
- **Nube:** los endpoints nuevos de BQ9 continúan sujetos al bloqueo IAM ya registrado. Esto no bloquea el ensayo técnico aislado. BQ9/tablero/defensa permanecen como siguiente fase según el orden solicitado.
- **Distribución:** este APK debug es para comprobación, no acredita App Distribution ni recepción por los TAs.

Registrar por escenario: fecha, dispositivo/SO, versión/estado del código, entorno, IDs de prueba, pasos, esperado/observado y enlace de evidencia. No presentar resultados simulados como resultados de usuarios reales.
