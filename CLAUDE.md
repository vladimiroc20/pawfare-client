# CLAUDE.md — pawfare-client

Este es el repositorio del **cliente** de Pawfare (proyecto Godot 4.x).

**Antes de trabajar aquí, lee el documento maestro:** `../CLAUDE.md` (visión de producto, reglas legales no negociables, mecánicas validadas en el prototipo, y plan de fases completo). Este archivo solo cubre lo específico de este repo.

## Qué vive aquí

Proyecto Godot que implementa el cliente móvil (iOS/Android): personajes, armas, terreno destructible, UI, y la conexión al servidor de partida (`pawfare-server`).

Estructura real del proyecto:

```
pawfare-client/
├── scenes/
│   ├── menu/MainMenu.tscn     # escena inicial: título, selector de jugadores/mapa, jugar
│   ├── main/Main.tscn         # partida — orquesta el estado de juego
│   ├── characters/Player.tscn
│   ├── obstacles/Rock.tscn
│   ├── weapons/Projectile.tscn
│   └── ui/Hud.tscn
├── scripts/
│   ├── autoload/GameConfig.gd # singleton: pasa player_count/biome_id del menú a Main
│   ├── menu/MainMenu.gd
│   ├── main/Main.gd          # turnos, input, viento, resolución de explosiones
│   ├── characters/Player.gd  # cuerpo dibujado por código, arma, knockback
│   ├── terrain/Terrain.gd    # mapa de alturas, carve_crater, render
│   ├── obstacles/Rock.gd     # forma procedural, grietas, destrucción
│   ├── weapons/Projectile.gd # integración de física por tick
│   ├── effects/Effects.gd    # explosión + escombros
│   ├── world/Background.gd, AimOverlay.gd, Biomes.gd (tabla de biomas)
│   ├── ui/Hud.gd, UiTheme.gd (tema visual compartido menú+HUD)
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
- Test de regresión headless (no requiere abrir el editor): `snap run godot4 --headless --path . --script res://scripts/dev/smoke_test.gd` — simula un disparo completo (arrastre, física, cráter, daño, cambio de turno), los 5 biomas, eliminación/podio y el modo equipos, y falla con `assert` si algo se rompe. Usa `seed(1)` al inicio para ser determinista (el terreno/rocas son aleatorios). Nota: usa `propagate_call("_ready")` en vez de dejar que el motor dispare `_ready` porque el harness de `--script` no corre el bucle normal del engine; esto es solo para el arnés de pruebas, el juego real (`--path .` sin `--script`, o el editor) no necesita este truco.

## Estado actual

**Fase 2 completa y generalizada a N jugadores (2-4), local sin red:** terreno destructible con mapa de alturas, resortera de arrastre, knockback físico con rebote, rocas procedurales con grietas/destrucción, viento variable, HUD superpuesto con barras de vida dinámicas (una por jugador, coloreadas por `Constants.PLAYER_COLORS`). `Main.gd` ya no asume p1/p2 fijos: mantiene `players: Array[Player]` y rota el turno saltando a jugadores eliminados (`health <= 0`), con fin de partida cuando queda 1 o 0 en pie. `player_count` es un `@export_range(2,4)` en el nodo `Main` — el cliente local lo trae en 2 por defecto; el servidor (Fase 3) será quien lo determine según cuántos jugadores entren a la sala. Validado con `import` headless y con el smoke test corriendo el mismo escenario de disparo con 2 y con 4 jugadores.

**Pendiente conocido / decisiones tomadas al portar:**
- El HUD se dibuja como overlay sobre el viewport 800×450 (CanvasLayer), no debajo como en el prototipo HTML — mejor encaje para un juego móvil real.
- Los degradados de canvas (cuerpo del personaje, terreno, cielo) se aproximaron con polígonos/elipses de 1-2 tonos en vez de gradientes exactos — es arte placeholder, no arte final (sección 9 del maestro).
- El input usa mouse/touch unificado vía los eventos estándar de Godot (`InputEventMouseButton`/`MouseMotion`); no se replicó el manejo separado de touch del prototipo.
- Solo hay 2 especies dibujadas (perro/gato, sección 7.1 del maestro); para 3-4 jugadores `Constants.PLAYER_SPECIES` las cicla (`["dog","cat","dog","cat"]`), diferenciados por color. Cuando se cierre el roster de especies (Fase 1) hay que ampliar esa lista y el dibujo en `Player.gd`.
- Las posiciones de spawn se reparten uniformemente entre los márgenes del mapa (`_spawn_players` en `Main.gd`); no evitan la zona de rocas a propósito — no hace falta, las rocas no bloquean el spawn, solo los disparos.

**Sistema de biomas (5 mapas, sin arte final todavía):** `scripts/world/Biomes.gd` define una tabla de biomas (`Patio Trasero`, `Playa`, `Bosque Nocturno`, `Cumbre Nevada`, `Callejón Urbano`) — cada uno con su propia paleta de cielo/terreno/rocas, densidad de obstáculos (`obstacle_delta`) y fuerza de viento (`wind_scale`), más el modo noche (luna + estrellas en vez de sol) para el bosque nocturno. `Main.gd` elige un bioma al azar cada partida (`biome_id` vacío) o uno fijo si se fuerza vía el `@export biome_id` del nodo `Main` (útil para probar un bioma específico en el editor). Todo esto es 100% paramétrico por código — no depende de assets de imagen, así que no bloquea ni compite con la Fase 1 (roster/arte final); cuando llegue el arte definitivo, cada bioma es el punto de partida natural para su propia dirección de fondos/props. El smoke test valida que los 5 biomas cargan sin error y que la densidad de obstáculos y el modo noche coinciden con lo esperado.

**Menú principal mínimo:** `MainMenu.tscn` es ahora la escena de arranque del proyecto (`run/main_scene`). Deja elegir cantidad de jugadores (2-4) y mapa (aleatorio o uno fijo de los 5 biomas), y al presionar "Jugar" guarda esa elección en el autoload `GameConfig` (`scripts/autoload/GameConfig.gd`) antes de cambiar a `Main.tscn`. `Main.gd` solo sobreescribe sus `@export` (`player_count`, `biome_id`) desde `GameConfig` si `GameConfig.configured` es `true` — así probar `Main.tscn` directo en el editor (F6) sigue funcionando con sus valores por defecto, sin pasar por el menú. Desde la pantalla de fin de partida hay botones para revancha (misma configuración) o volver al menú. No hay pantalla de "Opciones" todavía — no tiene sentido hasta que exista algo real que configurar (audio, etc.), y el lobby real (crear/unirse a sala) se construye en la Fase 3 contra el servidor, no antes.

**Eliminación, podio y modo equipos (2 vs 2):** cuando la vida de un jugador llega a 0, `Player.gd` emite la señal `eliminated` una sola vez (guardia `was_alive` en `take_damage`), se dibuja tumbado (rotado 90°, colores desaturados, ojos en X, sin arma) y `Effects.spawn_ko_burst` dispara un anillo dorado + chispas en su posición. `Main.gd` registra el orden de eliminación (`elimination_order`) y, al terminar la partida, `Hud.show_podium()` reemplazó el antiguo texto plano de ganador por un panel con medallas (🥇🥈🥉) construido dinámicamente. El ranking es consciente del modo: en "todos contra todos" es por orden de eliminación inverso; en equipos, ambos integrantes del equipo ganador quedan en 1er lugar sin importar quién cayó primero (`_build_ffa_ranking` / `_build_team_ranking` en `Main.gd`).

Modo equipos: solo disponible con 4 jugadores (2 y 3 jugadores siempre son todos-contra-todos). El menú muestra el selector "Modo" únicamente cuando se eligen 4 jugadores. El equipo se asigna por paridad de índice en el orden de turno (`player.team = i % 2`), lo cual además hace que los turnos alternen equipo A/B automáticamente sin lógica extra de rotación. Hay fuego amigo: el daño de explosión no distingue equipo (mismo código de siempre), como es estándar en el género.

**Tema visual compartido:** `scripts/ui/UiTheme.gd` construye un `Theme` en código (paneles oscuros redondeados, botones índigo con estados hover/pressed, barras de progreso con fondo translúcido) aplicado tanto en `MainMenu` como en `Hud` — antes usaban los controles grises por defecto de Godot. Sigue siendo 100% código, sin assets, consistente con el resto del proyecto.

**Próximo hito:** Fase 3 — servidor `pawfare-server` con salas Colyseus de 2 a 4 jugadores, bot de respaldo si alguien se desconecta, y reconexión. El modelo de N jugadores, equipos, biomas y el menú del cliente ya están listos para que el servidor solo tenga que sincronizar `players`, turno activo, bioma elegido y terreno — no requiere otro rediseño del lado del cliente para soportarlo.
