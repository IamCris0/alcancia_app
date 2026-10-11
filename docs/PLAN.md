# Alcancía — Plan del proyecto

App Flutter **offline-first** para gestionar dinero personal: ingresos, gastos, presupuestos, metas y hábitos, con mascota, rachas y animaciones.

## 1. Visión
- 100 % sin conexión (datos solo en el dispositivo, privacidad por defecto).
- Gamificada: mascota que reacciona a tus finanzas, rachas diarias, logros.
- Rápida de usar: registrar un gasto en < 5 segundos.

## 2. Onboarding
1. Splash animado (mascota + monedas).
2. "¿Cómo te llamas?" (nombre obligatorio, guardado local).
3. Elegir mascota y nombrarla.
4. Moneda principal y primer saldo inicial (opcional).
5. Meta inicial opcional.

## 3. Funcionalidades
**MVP (v0.1–0.3)**
- Ingresos / gastos / transferencias entre cuentas
- Cuentas (efectivo, banco, tarjeta, ahorro) con saldo
- Categorías con iconos y colores personalizables
- Historial con filtros y búsqueda
- Dashboard: saldo, resumen mensual, gráficas (dona, barras, línea)
- Presupuestos por categoría con alertas
- Mascota + racha diaria de registro
- Tema claro/oscuro

**v0.4–0.6**
- Metas de ahorro con progreso animado
- Gastos recurrentes y suscripciones (recordatorios locales)
- Deudas y préstamos (quién me debe / a quién debo)
- Logros / insignias, niveles de mascota, accesorios desbloqueables
- Exportar / importar respaldo (JSON/CSV) y PDF de reportes
- Bloqueo con PIN / biometría
- Multi-moneda manual

**Ideas futuras**
- Widgets de pantalla de inicio, división de gastos, escaneo de recibos (OCR local), sincronización opcional cifrada.

## 4. Mascota y rachas
- Estados: feliz, normal, preocupada, durmiendo, celebrando (según presupuesto, racha y metas).
- Racha: +1 por día con al menos un registro; "congelar racha" ganable con logros.
- XP por registrar, cumplir presupuesto y alcanzar metas → subir de nivel.

## 5. Diseño
- Material 3, paleta: verde menta (ingreso), coral (gasto), amarillo oro (ahorro/monedas), violeta (acento).
- Animaciones: Rive o Lottie (mascota, confeti, monedas), `flutter_animate` para microinteracciones, Hero y transiciones entre pantallas.
- Iconos: Material Symbols + set propio de categorías.
- Tipografía redondeada (p. ej. Nunito / Baloo 2).

## 6. Arquitectura
- Clean-ish por features: `lib/features/<feature>/{data,domain,presentation}`, `lib/core/`.
- Estado: **Riverpod**. Navegación: **go_router**.
- Base de datos local: **Drift** (SQLite) — consultas agregadas para reportes. Preferencias: `shared_preferences`.
- Gráficas: `fl_chart`. Notificaciones locales: `flutter_local_notifications`.
- i18n: `flutter_localizations` + ARB (es por defecto, en después).
- Tests: unitarios (dominio/repos), widget tests, golden tests clave.

## 7. Hoja de ruta
| Fase | Contenido |
|---|---|
| 0 | Repo, scaffold Flutter, CI, lint, tema base |
| 1 | Onboarding + BD + cuentas + categorías |
| 2 | Transacciones + historial + dashboard |
| 3 | Presupuestos + mascota + rachas |
| 4 | Metas, recurrentes, deudas, logros |
| 5 | Respaldo, seguridad, pulido, accesibilidad |
| 6 | Release en GitHub (APK) y, opcional, Play Store |

## 8. Gestión de GitHub
- Repo público: `alcancia_app`, licencia **MIT**, README con capturas/GIF.
- Ramas: `main` (estable) ← `develop` ← `feature/*`. PRs aunque sea solo-dev.
- Commits: Conventional Commits (`feat:`, `fix:`, `docs:`, `chore:`).
- Issues + Project board (Kanban) con milestones por fase; labels: `feature`, `bug`, `design`, `good first issue`.
- GitHub Actions: `flutter analyze` + `flutter test` en cada PR; build de APK en tags `v*`.
- Releases con SemVer (`v0.1.0` …) y CHANGELOG.
- **Público: nunca subir** keystores, `key.properties`, `.env`, ni datos personales.
- Archivos: `README.md`, `LICENSE`, `CONTRIBUTING.md`, `CHANGELOG.md`, `.gitignore`, `.github/` (workflows, plantillas de issue/PR).
