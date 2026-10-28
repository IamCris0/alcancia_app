# Changelog

Formato basado en [Keep a Changelog](https://keepachangelog.com/es-ES/1.1.0/) y [SemVer](https://semver.org/lang/es/).

## [Unreleased]

### Added
- Motion v2:
  - 4 mascotas elegibles (cerdito, gatito, conejito, panda) con mirada,
    parpadeo, orejas y cola animadas, ánimo "celebrando" y reacción al
    registrar movimientos.
  - Intro animada (mascota con rebote, monedas, título letra a letra) y
    arranque nativo de Android con el mismo color.
  - Onboarding de 3 pasos con transiciones direccionales, carrusel de
    mascotas con parallax y celebración con confeti.
  - Revelado circular desde el botón "+", pestañas que se deslizan según la
    dirección e indicador de la barra que se mueve con rebote.
  - Fondo aurora y monedas flotantes en la tarjeta principal, saldos con
    dígitos rodantes, globo de la mascota que se escribe letra a letra.
  - Dona propia que se dibuja en barrido y línea de gasto que se revela.
  - Confirmación al guardar con mascota, sello y confeti; skeletons al cargar.
  - Ícono adaptativo de la app (con soporte de íconos temáticos) y nombre
    visible "Alcancía".
- Movimientos: ingresos, gastos y transferencias con teclado numérico propio,
  selección de categoría, cuenta, fecha y nota; editar, borrar y deshacer.
- Saldos reales por cuenta calculados en SQL (migración de esquema v1 → v2).
- Inicio con saldo animado, ingresos/gastos del mes, dona por categoría,
  gráfica de gasto diario y movimientos recientes.
- Historial agrupado por día con filtros, búsqueda y cambio de mes.
- Mascota vectorial animada (respira, parpadea, salta y se traga una moneda)
  con estados de ánimo según el mes.
- Sistema visual: barra de navegación flotante con efecto vidrio, botones con
  rebote y vibración, tarjetas con sombras suaves, transiciones y montos que
  cuentan hacia su valor. Respeta "reducir movimiento" del sistema.
- Interfaz en español (calendario y fechas).
- Base de datos local con Drift (cuentas y categorías con datos por defecto).
- Gestión de cuentas y categorías (crear, editar, archivar) con colores e iconos.
- Onboarding en 2 pasos: nombre, moneda y primera cuenta.
- Montos en centavos, formato por moneda y parser de entrada.
- Scaffold Flutter (Android, iOS, Windows), tema Material 3 claro/oscuro.
- Onboarding que pide el nombre del usuario y lo guarda localmente.
- Plan del proyecto, CI, plantillas de issues y PR.

