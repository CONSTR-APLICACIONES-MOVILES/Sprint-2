# Ejecutar ParchApp con Firebase real en PowerShell

## 1. Qué terminal necesitas

Usa tu PowerShell de siempre, en:

```text
PS C:\Users\gabri\sprintsinstruct\MovsLocal\Sprint-2\ParchApp-Flutter>
```

Ejecuta solo los comandos dentro de los bloques PowerShell; no copies el prefijo `PS ...>`.

Para usar la app **solo necesitas correr Flutter**. El backend ya está desplegado en Firebase `parchapp-ee6cc`; no necesitas otra terminal ejecutando Node, Functions ni Firebase Emulator Suite. Necesitas conexión a internet.

## 2. Detener la ejecución anterior

En la terminal donde tienes `flutter run`, pulsa `q`. Si no responde, pulsa `Ctrl+C`.

Tu comando anterior incluía `--dart-define=USE_FIREBASE_EMULATORS=true`: eso conecta la app con los servicios Firebase locales. Ahora usa **false**. Cambiar este parámetro requiere detener y volver a ejecutar la app; hot reload no basta.

## 3. Si tu Pixel 10 ya está encendido

Ejecuta desde tu PowerShell:

```powershell
Set-Location 'C:\Users\gabri\sprintsinstruct\MovsLocal\Sprint-2\ParchApp-Flutter'
flutter pub get
flutter run -d emulator-5554 -t lib/main.dart --dart-define=USE_FIREBASE_EMULATORS=false
```

Deja abierta esa terminal mientras pruebas. Este comando recompila e instala la app normal con la configuración de Google y Maps de este equipo. No uses `tool/google_places_smoke.dart` para la demo: ese archivo es una prueba aislada.

## 4. Si tu Pixel 10 está apagado

Desde la misma carpeta:

```powershell
flutter emulators --launch Pixel_10_Pro
```

Espera hasta ver la pantalla de inicio de Android. Después:

```powershell
flutter devices
```

Si aparece `emulator-5554`, ejecuta:

```powershell
flutter run -d emulator-5554 -t lib/main.dart --dart-define=USE_FIREBASE_EMULATORS=false
```

Si aparece otro identificador, sustituye `emulator-5554` por el que muestra `flutter devices`.

## 5. Qué probar al abrir

1. Pulsa **Continuar con Google** y elige tu cuenta. Si Android pide agregar una cuenta, hazlo tú desde su pantalla de Google. Si no aparece el selector, revisa las cuentas de Google del Pixel.
2. Comprueba que llegas a Home y puedes abrir tu perfil.
3. Crea un evento. En Location, pulsa **Choose on Google Maps**, busca un sitio y elige un resultado. También puedes tocar el mapa o mover el pin.
4. Pulsa **Use this location**, completa los campos del evento y guarda.
5. Reabre el evento y verifica dirección y pin. Edita el lugar y vuelve a comprobarlo.

Los tres endpoints de actividades ya están desplegados con soporte para coordenadas. Maps y Places se comprobaron con una consulta real desde este emulador; el inicio de sesión con tu cuenta todavía requiere esta prueba contigo.

## 6. Backend: cuándo abrir su carpeta

**No lo ejecutes para iniciar la app.** Firebase ejecuta las funciones en la nube. No necesitas Google Cloud Shell.

Solo si vas a desarrollar o comprobar cambios del backend, puedes abrir otra PowerShell y correr sus pruebas locales:

```powershell
Set-Location 'C:\Users\gabri\sprintsinstruct\MovsLocal\Backend\functions'
npm test
```

Estas pruebas terminan y no dejan un servidor corriendo. Modificar un archivo local del backend no modifica Firebase real: los cambios requieren un despliegue separado. Las funciones necesarias para login y ubicación ya están configuradas/desplegadas; no necesitas redesplegarlas para cada ejecución de Flutter.

## 7. Si algo falla

- **Error de conexión a localhost o 10.0.2.2:** detén la app y repite el comando con `USE_FIREBASE_EMULATORS=false`.
- **No encuentra emulator-5554:** ejecuta `flutter devices`; espera a que termine de arrancar el Pixel y usa el identificador que aparezca.
- **Google no inicia sesión:** conserva el error exacto mostrado y las últimas líneas de la terminal para diagnosticarlo. No compartas contraseñas ni tokens.
- **Mapa no disponible en este build:** verifica únicamente si existe la configuración local, sin mostrar su contenido:

```powershell
Test-Path .\android\maps.properties
```

En este equipo debe devolver `True`. Después detén y vuelve a ejecutar `flutter run`. Ese archivo contiene la clave restringida y está ignorado por Git; no lo publiques.

Si necesitas reconstruir después de cambios de configuración nativa y reiniciar no bastó:

```powershell
flutter clean
flutter pub get
flutter run -d emulator-5554 -t lib/main.dart --dart-define=USE_FIREBASE_EMULATORS=false
```

No hace falta ejecutar `flutter clean` cada vez.
