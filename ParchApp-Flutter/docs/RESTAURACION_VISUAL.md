# Restauración visual — 20 de octubre de 2026

Corrección solicitada tras A–D: los flujos funcionales habían simplificado demasiado la presentación de los mockups. Esta revisión recupera la identidad y la composición de las seis referencias aportadas por el usuario.

## Cambios

- Barra compartida: logo original `assets/images/parchapp_logo.png` y nombre ParchApp; búsqueda, alertas y perfil conservan sus rutas reales. Las vistas con título de contexto mantienen ese título.
- Tema: fondo azul muy claro, superficies blancas, bordes suaves, azul de marca, acentos verdes/ámbar/rojos. Inter se incluye localmente, con licencia OFL en `assets/fonts/`, para evitar descargas de tipografía durante el uso.
- Dashboard: saludo e identidad reales, compartir perfil, panel azul Quick Status, duración y edición del estado, comparación, tarjetas de actividades con progreso real, grupos y botón New Activity.
- Groups: detalle con actividad destacada, progreso agregado, miembros con iniciales/estado compartido, historial y Create Activity fijo. Crear grupo vuelve a usar la barra de marca y el bloque azul de participantes. La revisión vuelve al comienzo del formulario. Las fechas canónicas se presentan en Bogotá.
- Disponibilidad manual: tarjetas con iconos y colores para Available, In Class/Lab, Library/Focus, Busy, In Transit y Offline; duración y privacidad conservan sus contratos anteriores.
- Invitación: imagen de portada, ficha superpuesta de título/fecha/lugar, invitados y respuestas reales. Join verde y Can’t attend delineado rojo permanecen fijos, junto con Maybe. El resultado/error de responder aparece en esa barra.
- Detalle de actividad: portada, contraste del título y ubicación en la ficha principal, manteniendo edición/cancelación, recomendaciones, recursos y permisos.
- Alerts conserva las tarjetas con acentos por tipo de alerta y recibe el logo y la tipografía compartidos.

## Referencias y datos

Las portadas `activity_social_reference.jpg` y `activity_study_reference.jpg` se descargaron desde las URL de imagen incluidas en los HTML del material entregado, respectivamente `activity_invitation/code.html` y `study_session_details_fully_interactive/code.html`. Son imágenes decorativas por categoría; no prueban el lugar de una actividad ni representan a sus participantes. El logo ya existía en el proyecto.

Se conserva la navegación acordada Home / Groups / Schedule y la tipografía Inter del sistema visual. No se copian las marcas de interacción punteadas, marcos de teléfono, contadores ficticios, Live Sync, ubicaciones GPS o correos enviados que aparecen en los mockups. El enlace/QR de incorporación se genera después de crear el grupo; no se simulan invitaciones por email ni integraciones de calendario.

## Verificación

- `flutter analyze --no-pub`: sin incidencias.
- `flutter test --no-pub --reporter expanded`: 247 pruebas aprobadas; incluye identidad, rutas por ID real, revisión/creación de grupo, errores y reintentos, RSVP y layouts de 320/390 px con texto al 180 %.
- `test/visual_restoration_test.dart` genera ocho capturas con el tema de producción, Inter e iconos cargados. Las fixtures están limitadas al test y no modifican Firebase. La lista de grupos usa el repositorio mock exclusivamente para revisar su composición.
- Capturas revisadas visualmente en `build/visual-review/`: dashboard, groups, group-details, create-group, availability, alerts, activity-invitation y activity-details. El tamaño renderizado es 390 × 844; la pantalla de estado y otras secciones requieren desplazamiento para todo su contenido. El entorno de pruebas no incorpora una fuente de emojis de plataforma.
- Compilación web y APK Android debug: ver logs `build/visual-restoration-web.log` y `build/visual-restoration-apk.log`.
- APK: `build/app/outputs/flutter-apk/app-debug.apk`.

No se cambió el backend en esta revisión. Las capturas son renders de widgets; no sustituyen una prueba manual en dispositivo. La composición recupera las referencias manteniendo los contratos implementados y no se presenta como una réplica idéntica píxel a píxel. No se instaló el APK ni se desplegó la aplicación.
