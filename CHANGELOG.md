# Changelog

Formato basado en [Keep a Changelog](https://keepachangelog.com/es-ES/1.1.0/) y [SemVer](https://semver.org/lang/es/).

## [Unreleased]

### Added
- Fase 4 (metas, recurrentes y deudas):
  - Metas de ahorro con frasco de líquido animado, aportes/retiros, ritmo
    sugerido por fecha límite y celebración al cumplirlas.
  - Recurrentes (semanal/mensual/anual, día anclado a fin de mes) que se
    registran solos o quedan por confirmar en el inicio; no cuentan para la
    racha si son automáticos.
  - Deudas "me deben / yo debo" con abonos hasta saldarlas.
  - Recordatorios locales opcionales: racha a las 20:00 y pagos recurrentes.
  - Pestaña Metas con Presupuestos, Ahorros y Deudas; 4 logros nuevos.
  - Esquema v4 con migración aditiva probada sobre una base v3 con datos.
- Fase 3 (gamificación y presupuestos):
  - Presupuestos mensuales general y por categoría, con anillo y barras
    animadas, gasto diario sugerido y alertas al 80 % y al pasarse.
  - Rachas diarias con llama animada, semana visual, mejor racha y
    congeladores (uno por cada 7 días registrados, máximo 2).
  - XP con libro de eventos (sin premios dobles, tope diario por registrar),
    niveles con títulos y barra de progreso.
  - 15 logros con medallas, detalle y celebración con confeti.
  - Accesorios para la mascota por nivel: moño, gafas, gorro de fiesta y
    corona; se ponen solos al desbloquearlos.
  - Pestañas nuevas: Metas (presupuestos) y Perfil (mascota, racha, logros,
    ajustes). Cuentas y categorías se abren desde Perfil o el inicio.
  - Premio al abrir la app por meses cerrados dentro del presupuesto o en verde.

### Changed
- La app ahora se llama **PlataPets** (paquete `platapets`, ID
  `com.platapets.app`).
- Rendimiento: sin desenfoque en vivo en la barra, menos repintados y el
  teclado numérico ya no reconstruye toda la pantalla.

### Added (anteriores)
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

