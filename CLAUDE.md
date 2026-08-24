# CLAUDE.md — pawfare-client

Este es el repositorio del **cliente** de Pawfare (proyecto Godot 4.x).

**Antes de trabajar aquí, lee el documento maestro:** `../CLAUDE.md` (visión de producto, reglas legales no negociables, mecánicas validadas en el prototipo, y plan de fases completo). Este archivo solo cubre lo específico de este repo.

## Qué vive aquí

Proyecto Godot que implementa el cliente móvil (iOS/Android): personajes, armas, terreno destructible, UI, y la conexión al servidor de partida (`pawfare-server`).

Estructura sugerida (ver sección 13 del documento maestro):

```
pawfare-client/
├── scenes/
│   ├── characters/
│   ├── weapons/
│   ├── terrain/
│   └── ui/
├── scripts/
├── assets/
│   ├── sprites/
│   ├── audio/
│   └── fonts/
└── project.godot
```

## Reglas específicas de este repo

- El cliente **nunca es la fuente de verdad**: no implementar validación de daño/física decisiva aquí — eso vive en `pawfare-server`. El cliente predice/renderiza, el servidor valida.
- Las mecánicas de referencia (resortera de arrastre, terreno como mapa de alturas, knockback, viento) están descritas con pseudocódigo GDScript en la sección 6 del documento maestro — úsalas como punto de partida, ajustando escala a Godot.
- Arte placeholder actual: ninguno todavía. No hay "arte final" definido (ver sección 9 del maestro) — no asumir dirección de arte sin confirmar.
- Build Android: `godot --headless --export-release "Android" build/pawfare.apk` (una vez exista `project.godot` y presets de exportación configurados).

## Estado actual

Repo recién creado, sin contenido todavía. Próximo hito: Fase 2 del plan (port a Godot local, 1v1 sin red) — ver sección 11 del documento maestro.
