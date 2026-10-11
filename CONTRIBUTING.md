# Guía de contribución

## Ramas
- `main`: estable, solo recibe merges desde `develop` (releases).
- `develop`: integración.
- `feature/<nombre>`, `fix/<nombre>`: trabajo diario, PR hacia `develop`.

## Commits (Conventional Commits)
`feat:`, `fix:`, `docs:`, `refactor:`, `test:`, `chore:`, `ci:`

Ejemplo: `feat(transactions): agregar formulario de gasto`

## Antes de abrir un PR
```bash
dart format .
flutter analyze
flutter test
```

## Seguridad
Nunca subas keystores, `key.properties`, `.env` ni datos personales.
