# 🐷 PlataPets

App móvil **100 % offline** para gestionar tu dinero: ingresos, gastos, presupuestos y metas, con una mascota que reacciona a tus finanzas, rachas diarias y animaciones. Hecha con Flutter.

> 🚧 En desarrollo temprano (v0.0.1). Mira el [plan del proyecto](docs/PLAN.md).

## Características (planeadas)
- Ingresos, gastos y transferencias entre cuentas
- Categorías con iconos y colores
- Presupuestos con alertas y metas de ahorro
- Mascota, rachas, XP y logros
- Gráficas y reportes
- Tus datos nunca salen del dispositivo

## Estado actual
- [x] Scaffold Flutter, tema Material 3 claro/oscuro
- [x] Onboarding: pide tu nombre al iniciar
- [x] Base de datos local (Drift/SQLite), cuentas y categorías
- [x] Movimientos (ingresos, gastos, transferencias), historial y saldos reales
- [x] Inicio con gráficas y mascota animada
- [x] 4 mascotas animadas, intro y motion graphics
- [x] Presupuestos, rachas, XP, niveles, accesorios y logros
- [x] Metas de ahorro, recurrentes, deudas y recordatorios
- [ ] Respaldo/exportación, PIN y reportes

## Desarrollo
Requisitos: [Flutter](https://docs.flutter.dev/get-started/install) estable.

```bash
flutter pub get
flutter run
flutter analyze
flutter test
```

## Contribuir
Lee [CONTRIBUTING.md](CONTRIBUTING.md). Usamos Conventional Commits y PRs hacia `develop`.

## Licencia
[MIT](LICENSE)

