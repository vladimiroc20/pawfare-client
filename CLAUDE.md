# CLAUDE.md — pawfare-client

Este es el repositorio del **cliente** de Pawfare (proyecto Godot 4.x).

**Antes de trabajar aquí, lee el documento maestro:** `../CLAUDE.md` (visión de producto, reglas legales no negociables, mecánicas validadas en el prototipo, y plan de fases completo). Este archivo solo cubre lo específico de este repo.

## Qué vive aquí

Proyecto Godot que implementa el cliente móvil (iOS/Android): personajes, armas, terreno destructible, UI, y la conexión al servidor de partida (`pawfare-server`).

Estructura real del proyecto:

```
pawfare-client/
├── scenes/
│   ├── main/Main.tscn        # escena raíz, orquesta el estado de partida
│   ├── characters/Player.tscn
│   ├── obstacles/Rock.tscn
│   ├── weapons/Projectile.tscn
│   └── ui/Hud.tscn
├── scripts/
│   ├── main/Main.gd          # turnos, input, viento, resolución de explosiones
│   ├── characters/Player.gd  # cuerpo dibujado por código, arma, knockback
│   ├── terrain/Terrain.gd    # mapa de alturas, carve_crater, render
│   ├── obstacles/Rock.gd     # forma procedural, grietas, destrucción
│   ├── weapons/Projectile.gd # integración de física por tick
│   ├── effects/Effects.gd    # explosión + escombros
│   ├── world/Background.gd, AimOverlay.gd
│   ├── ui/Hud.gd
│   ├── util/Constants.gd, DrawUtils.gd
│   └── dev/smoke_test.gd     # test de regresión headless, ver más abajo
├── assets/
│   ├── sprites/   # vacío — todo el arte actual es dibujado por código (_draw())
│   ├── audio/
│   └── fonts/
└── project.godot
```

Todo el arte (personajes, rocas, nubes, terreno) se dibuja por código en `_draw()` — no hay assets de imagen todavía, es intencional (ver sección 9 del maestro, arte final pendiente).

## Reglas específicas de este repo

- El cliente **nunca es la fuente de verdad**: no implementar validación de daño/física decisiva aquí — eso vive en `pawfare-server`. El cliente predice/renderiza, el servidor valida.
- Las mecánicas de referencia (resortera de arrastre, terreno como mapa de alturas, knockback, viento) están descritas con pseudocódigo GDScript en la sección 6 del documento maestro — úsalas como punto de partida, ajustando escala a Godot.
- Arte placeholder actual: ninguno todavía. No hay "arte final" definido (ver sección 9 del maestro) — no asumir dirección de arte sin confirmar.
- Build Android: `godot --headless --export-release "Android" build/pawfare.apk` (aún faltan presets de exportación configurados en el editor).
- Godot 4.5 está instalado vía snap (`snap run godot4`). Abrir el editor: `snap run godot4 --path .`
- Test de regresión headless (no requiere abrir el editor): `snap run godot4 --headless --path . --script res://scripts/dev/smoke_test.gd` — simula un disparo completo (arrastre, física, cráter, daño, cambio de turno) y falla con `assert` si algo se rompe. Nota: usa `propagate_call("_ready")` en vez de dejar que el motor dispare `_ready` porque el harness de `--script` no corre el bucle normal del engine; esto es solo para el arnés de pruebas, el juego real (`--path .` sin `--script`, o el editor) no necesita este truco.

## Estado actual

**Fase 2 completa** (port local a Godot, 1v1 sin red): terreno destructible con mapa de alturas, resortera de arrastre, knockback físico con rebote, rocas procedurales con grietas/destrucción, viento variable, HUD superpuesto (overlay, no debajo del viewport como en la maqueta web original), turnos p1/p2. Validado con `import` headless y con el smoke test simulando un disparo real (cráter + daño con caída + cambio de turno).

**Pendiente conocido / decisiones tomadas al portar:**
- El HUD se dibuja como overlay sobre el viewport 800×450 (CanvasLayer), no debajo como en el prototipo HTML — mejor encaje para un juego móvil real.
- Los degradados de canvas (cuerpo del personaje, terreno, cielo) se aproximaron con polígonos/elipses de 1-2 tonos en vez de gradientes exactos — es arte placeholder, no arte final (sección 9 del maestro).
- El input usa mouse/touch unificado vía los eventos estándar de Godot (`InputEventMouseButton`/`MouseMotion`); no se replicó el manejo separado de touch del prototipo.

**Próximo hito:** este proyecto ahora debe soportar **multijugador online de 2 a 4 jugadores**, con un bot que toma el control de un jugador desconectado y permite su reconexión — esto es nuevo respecto al alcance original de la Fase 3 del maestro (que asumía solo 2 dispositivos). Antes de tocar red, generalizar `Main.gd` de p1/p2 fijos a una lista/cola de N jugadores (turnos, HUD, daño) es el paso natural, ya que el terreno, la física y el dibujo por código no dependen del número de jugadores.
