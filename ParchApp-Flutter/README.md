# ParchApp Flutter

Estado vigente: [Cierre local de sprint 3](docs/CIERRE_SPRINT_3.md).
Implementación por fases: [A–D y corrección visual](docs/IMPLEMENTACION_POR_FASES.md).
Referencias y alcance: [Auditoría de mockups](docs/AUDITORIA_MOCKUPS_FUNCIONALIDADES_Y_IO.md).

Flutter con MVVM, repositorios inyectados y backend Firebase compartido. Home / Groups / Schedule; creación, revisión, publicación idempotente, invitaciones y respuestas por actividad, edición/cancelación con versión, recursos/checklist y exportación ICS. Perfil, grupos, estado con duración/privacidad y búsqueda usan datos autorizados. Marca, tarjetas y formularios siguen el sistema visual de los mockups; Inter está incluida localmente.

Las respuestas de invitación se guardan por cuenta/proyecto para sincronizar con reconexión, con reintento/descarte individual y conflictos explícitos. Details/Alerts muestran antigüedad del caché. La serialización grande usa un isolate nativo y conserva escrituras seriales. BQ9 tiene evidencia validada, medición/confirmación y panel agregado local; el dashboard compartido requiere despliegue.

La app abre Sign-In y utiliza emuladores por defecto. Iniciar `npm run emulators` desde Backend y después `flutter run` desde esta carpeta. Para credenciales de pruebas, dispositivos y configuración externa, consultar la [guía de ejecución](docs/GUIA_PRUEBAS_E_INTEGRACIONES_SPRINT_3.md).

Google Sign-In y la importación Google sin configuración, push, correo de invitaciones, dominios, chat, mapas, reservas y sincronización automática no se presentan como operativos. El APK local requiere el backend emulado; no acredita App Distribution, despliegue ni prueba física.

Validación:

```powershell
flutter analyze --no-pub
flutter test --no-pub --reporter expanded
```

Prueba adicional con API real y cuentas QA propias: `npm run seed:sprint3-qa` en Backend y `flutter test --no-pub test/sprint3_api_ui_e2e_test.dart --dart-define=RUN_SPRINT3_E2E=true` en Flutter. Capturas de widgets: `build/visual-review/`.

Arquitectura: [contrato](docs/architecture/architecture-contract.md), [ADR](docs/architecture/adr-001-state-management.md), [conectividad](docs/architecture/offline-and-quality.md).
