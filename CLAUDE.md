# CLAUDE.md — pawfare-client

Este es el repositorio del **cliente** de Pawfare (proyecto Godot 4.x).

**Antes de trabajar aquí, lee el documento maestro:** `../CLAUDE.md` (visión de producto, reglas legales no negociables, mecánicas validadas en el prototipo, y plan de fases completo). Este archivo solo cubre lo específico de este repo.

## Qué vive aquí

Proyecto Godot que implementa el cliente móvil (iOS/Android): personajes, armas, terreno destructible, UI, y la conexión al servidor de partida (`pawfare-server`).

Estructura real del proyecto:

```
pawfare-client/
├── scenes/
│   ├── menu/MainMenu.tscn     # escena inicial: título, selector de jugadores/mapa, jugar local u online
│   ├── main/Main.tscn         # partida LOCAL — simula todo en el cliente
│   ├── main/NetworkMain.tscn  # partida ONLINE — renderiza el estado que manda pawfare-server
│   ├── characters/Player.tscn
│   ├── obstacles/Rock.tscn
│   ├── weapons/Projectile.tscn
│   └── ui/Hud.tscn
├── scripts/
│   ├── autoload/GameConfig.gd # singleton: pasa player_count/biome_id/team_mode del menú a Main (local)
│   ├── net/NetworkClient.gd   # singleton: cliente REST hacia pawfare-server (ver sección de red más abajo)
│   ├── menu/MainMenu.gd
│   ├── main/Main.gd          # LOCAL: turnos, input, viento, resolución de explosiones, todo en el cliente
│   ├── main/NetworkMain.gd   # ONLINE: sin física propia — solo sincroniza nodos con el estado del servidor
│   ├── characters/Player.gd  # cuerpo dibujado por código, arma, knockback (usado por ambos modos)
│   ├── terrain/Terrain.gd    # mapa de alturas, carve_crater, render, set_heights() (para el modo online)
│   ├── obstacles/Rock.gd     # forma procedural, grietas, destrucción
│   ├── weapons/Projectile.gd # integración de física por tick (solo modo local)
│   ├── effects/Effects.gd    # explosión + escombros
│   ├── world/Background.gd, AimOverlay.gd, Biomes.gd (tabla de biomas)
│   ├── ui/Hud.gd, UiTheme.gd (tema visual compartido menú+HUD)
│   ├── util/Constants.gd, DrawUtils.gd
│   ├── dev/smoke_test.gd            # test de regresión del modo local, ver más abajo
│   └── dev/network_smoke_test.gd    # test de regresión de la integración con el servidor, ver más abajo
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
- Test de regresión headless del modo local (no requiere abrir el editor): `snap run godot4 --headless --path . --script res://scripts/dev/smoke_test.gd` — simula un disparo completo (arrastre, física, cráter, daño, cambio de turno), los 5 biomas, eliminación/podio y el modo equipos, y falla con `assert` si algo se rompe. Usa `seed(1)` al inicio para ser determinista (el terreno/rocas son aleatorios). Nota: usa `propagate_call("_ready")` en vez de dejar que el motor dispare `_ready` porque el harness de `--script` no corre el bucle normal del engine; esto es solo para el arnés de pruebas, el juego real (`--path .` sin `--script`, o el editor) no necesita este truco.
- Test de regresión de la integración de red: **requiere `pawfare-server` corriendo** (`npm run dev` en ese repo, puerto 2567 por defecto). Luego: `snap run godot4 --headless --path . --script res://scripts/dev/network_smoke_test.gd` — instancia dos `NetworkClient.gd` sueltos (no el singleton), hace `quickmatch` con ambos, valida que caen en la misma sala, que la partida arranca al llenarse el cupo, y que un disparo real por HTTP cambia el terreno. Si el servidor no está corriendo, este test falla con un error de conexión claro (no se cuelga).

## Estado actual

**Fase 2 completa y generalizada a N jugadores (2-4), local sin red:** terreno destructible con mapa de alturas, resortera de arrastre, knockback físico con rebote, rocas procedurales con grietas/destrucción, viento variable, HUD superpuesto con barras de vida dinámicas (una por jugador, coloreadas por `Constants.PLAYER_COLORS`). `Main.gd` ya no asume p1/p2 fijos: mantiene `players: Array[Player]` y rota el turno saltando a jugadores eliminados (`health <= 0`), con fin de partida cuando queda 1 o 0 en pie. `player_count` es un `@export_range(2,4)` en el nodo `Main` — el cliente local lo trae en 2 por defecto; el servidor (Fase 3) será quien lo determine según cuántos jugadores entren a la sala. Validado con `import` headless y con el smoke test corriendo el mismo escenario de disparo con 2 y con 4 jugadores.

**Pendiente conocido / decisiones tomadas al portar:**
- El HUD se dibuja como overlay sobre el viewport 800×450 (CanvasLayer), no debajo como en el prototipo HTML — mejor encaje para un juego móvil real.
- Los degradados de canvas (cuerpo del personaje, terreno, cielo) se aproximaron con polígonos/elipses de 1-2 tonos en vez de gradientes exactos — es arte placeholder, no arte final (sección 9 del maestro).
- El input usa mouse/touch unificado vía los eventos estándar de Godot (`InputEventMouseButton`/`MouseMotion`); no se replicó el manejo separado de touch del prototipo.
- 5 especies dibujadas (perro/gato/conejo/panda/zorro, sección 7.1 del maestro; `Constants.AVAILABLE_SPECIES`). El roster de 4 jugadores usa `Constants.PLAYER_SPECIES = ["dog","cat","rabbit","fox"]` — cada uno un animal distinto. Panda queda en `AVAILABLE_SPECIES` sin slot fijo, para cuando exista selección de personaje (Fase 5). Cada especie solo varía orejas/cola en `Player.gd` (mismo cuerpo/paleta por jugador) — ampliar ahí si se agregan más.
- Las posiciones de spawn se reparten uniformemente entre los márgenes del mapa (`_spawn_players` en `Main.gd`); no evitan la zona de rocas a propósito — no hace falta, las rocas no bloquean el spawn, solo los disparos.

**Sistema de biomas (5 mapas, sin arte final todavía):** `scripts/world/Biomes.gd` define una tabla de biomas (`Patio Trasero`, `Playa`, `Bosque Nocturno`, `Cumbre Nevada`, `Callejón Urbano`) — cada uno con su propia paleta de cielo/terreno/rocas, densidad de obstáculos (`obstacle_delta`) y fuerza de viento (`wind_scale`), más el modo noche (luna + estrellas en vez de sol) para el bosque nocturno. `Main.gd` elige un bioma al azar cada partida (`biome_id` vacío) o uno fijo si se fuerza vía el `@export biome_id` del nodo `Main` (útil para probar un bioma específico en el editor). Todo esto es 100% paramétrico por código — no depende de assets de imagen, así que no bloquea ni compite con la Fase 1 (roster/arte final); cuando llegue el arte definitivo, cada bioma es el punto de partida natural para su propia dirección de fondos/props. El smoke test valida que los 5 biomas cargan sin error y que la densidad de obstáculos y el modo noche coinciden con lo esperado.

**Menú principal mínimo:** `MainMenu.tscn` es ahora la escena de arranque del proyecto (`run/main_scene`). Deja elegir cantidad de jugadores (2-4) y mapa (aleatorio o uno fijo de los 5 biomas), y al presionar "Jugar" guarda esa elección en el autoload `GameConfig` (`scripts/autoload/GameConfig.gd`) antes de cambiar a `Main.tscn`. `Main.gd` solo sobreescribe sus `@export` (`player_count`, `biome_id`) desde `GameConfig` si `GameConfig.configured` es `true` — así probar `Main.tscn` directo en el editor (F6) sigue funcionando con sus valores por defecto, sin pasar por el menú. Desde la pantalla de fin de partida hay botones para revancha (misma configuración) o volver al menú. No hay pantalla de "Opciones" todavía — no tiene sentido hasta que exista algo real que configurar (audio, etc.), y el lobby real (crear/unirse a sala) se construye en la Fase 3 contra el servidor, no antes.

**Eliminación, podio y modo equipos (2 vs 2):** cuando la vida de un jugador llega a 0, `Player.gd` emite la señal `eliminated` una sola vez (guardia `was_alive` en `take_damage`), se dibuja tumbado (rotado 90°, colores desaturados, ojos en X, sin arma) y `Effects.spawn_ko_burst` dispara un anillo dorado + chispas en su posición. `Main.gd` registra el orden de eliminación (`elimination_order`) y, al terminar la partida, `Hud.show_podium()` reemplazó el antiguo texto plano de ganador por un panel con medallas (🥇🥈🥉) construido dinámicamente. El ranking es consciente del modo: en "todos contra todos" es por orden de eliminación inverso; en equipos, ambos integrantes del equipo ganador quedan en 1er lugar sin importar quién cayó primero (`_build_ffa_ranking` / `_build_team_ranking` en `Main.gd`).

Modo equipos: solo disponible con 4 jugadores (2 y 3 jugadores siempre son todos-contra-todos). El menú muestra el selector "Modo" únicamente cuando se eligen 4 jugadores. El equipo se asigna por paridad de índice en el orden de turno (`player.team = i % 2`), lo cual además hace que los turnos alternen equipo A/B automáticamente sin lógica extra de rotación. Hay fuego amigo: el daño de explosión no distingue equipo (mismo código de siempre), como es estándar en el género.

**Tema visual compartido:** `scripts/ui/UiTheme.gd` construye un `Theme` en código (paneles oscuros redondeados, botones índigo con estados hover/pressed, barras de progreso con fondo translúcido) aplicado tanto en `MainMenu` como en `Hud` — antes usaban los controles grises por defecto de Godot. Sigue siendo 100% código, sin assets, consistente con el resto del proyecto.

**Integración online con `pawfare-server` (2026-08-24):** el cliente ya se conecta al servidor real. Decisión importante: Godot no tiene SDK oficial de Colyseus, y portar su protocolo binario propietario (`@colyseus/schema` v4) a GDScript a ciegas era demasiado riesgo sin poder validarlo bien — en vez de eso, `pawfare-server` expone una **API REST en JSON** (`/api/quickmatch`, `/api/rooms/:id/state`, `/fire`, `/heartbeat`, `/leave`) pensada específicamente para este cliente, y Godot la consume con `HTTPRequest` nativo. Encaja bien porque el juego es por turnos — no hace falta la latencia de un WebSocket.

- **`NetworkClient.gd`** (autoload): hace `quickmatch(player_count, team_mode, biome_id)`, dispara un `Timer` de *polling* del estado cada 0.7s y otro de *heartbeat* cada 5s mientras haya una partida activa. Señales: `joined`, `join_failed`, `state_updated`, `action_failed`.
- **`NetworkMain.gd`** (`scenes/main/NetworkMain.tscn`) es la contraparte online de `Main.gd`: **no simula física propia** — en cada `state_updated` sincroniza `Terrain.set_heights()`, reconstruye/actualiza los nodos `Player`/`Rock` desde el JSON del servidor, y solo permite arrastrar/disparar cuando el estado dice que es tu turno (`_my_turn()`). Al soltar, llama `NetworkClient.fire(dx, dy)` en vez de spawnear un proyectil local — el servidor resuelve el disparo y el resultado llega en el siguiente *poll*. Como no hay animación de vuelo del proyectil todavía, se compensa detectando el mayor cambio de altura entre un *poll* y el siguiente para lanzar el efecto de explosión (`Effects.spawn_explosion`) en el punto de impacto aproximado — es una aproximación honesta, no una simulación; ver "Pendiente" abajo.
- **Menú:** ahora hay dos botones, "▶ Jugar local" (flujo existente, sin red) y "🌐 Jugar online" (llama `quickmatch` y, al unirse, cambia a `NetworkMain.tscn`).
- **Presencia sin conexión persistente:** como REST no tiene un socket que "se cae", el bot de respaldo se activa por heartbeat: si el jugador en turno no manda heartbeat/disparo en `DISCONNECT_TIMEOUT_MS` (15s, definido en el servidor), el servidor lo marca `isBot=true`; un heartbeat posterior lo reconecta. El cliente no necesita saber nada de esto — solo refleja `isBot`/`connected` del estado recibido.
- Validado end-to-end con `network_smoke_test.gd` contra un servidor real corriendo (no mockeado): dos `NetworkClient` caen en la misma sala, la partida arranca al completarse el cupo, y un disparo por HTTP cambia el terreno.

**Pendiente / rough edges conocidos de la integración:**
- No hay animación de vuelo del proyectil en modo online — el disparo se resuelve "de golpe" en el servidor y el cliente solo ve el resultado en el siguiente *poll* (hasta ~700ms de retraso), compensado parcialmente con el efecto de explosión por delta de terreno descrito arriba. Si se quiere ver el proyectil volar, habría que predecir la trayectoria en el cliente con las mismas constantes (`Constants.gd` ya coincide con `sim/Constants.ts` del servidor) mientras se espera la confirmación — no implementado todavía.
- El botón "🔄 Jugar de nuevo" en la pantalla de fin de partida online hoy solo vuelve al menú (llama a lo mismo que "🏠 Menú principal") — no dispara un *quickmatch* directo. Aceptable por ahora, pero el texto del botón queda un poco impreciso en modo online.
- `NetworkClient.base_url` está fijo en `http://127.0.0.1:2567/api` (`@export`, cambiable en el inspector) — no hay pantalla de configuración de servidor todavía; no hace falta hasta desplegar el servidor en algún host real.
- Reconexión entre sesiones de la app (cerrar y reabrir Godot) no está implementada del lado cliente — `NetworkClient` no persiste `room_id`/`token` en disco. El servidor sí soporta que un jugador vuelva (heartbeat), pero hoy solo se prueba dentro de la misma sesión del cliente.

**Variedad de armas (2026-08-24):** `scripts/util/Weapons.gd` es el espejo exacto de `sim/Weapons.ts` del servidor (mismos ids, radios y daños) — tres armas (ids `bazooka`/`cluster`/`bouncer`, nombres pensados para sonar a munición real, no a descripciones de efecto): **Mini Bazooka** (la de siempre), **Granada Racimo** (explosión primaria chica + 4 sub-proyectiles que se dispersan desde el punto de impacto y explotan por separado, cada uno con su propio radio/daño), y **Granada Rebotante** (rebota una vez en el terreno antes de explotar). Cada una dibuja su propio proyectil en vuelo (`Projectile._draw()` según `weapon_id`) y su propio lanzador en las manos del personaje (`Player._draw_weapon()` según `Player.weapon_id`) — no solo cambia el comportamiento, se ve distinto. El HUD arma un selector con un botón por arma (`Hud._setup_weapons()`, señal `weapon_selected`) visible mientras la partida está activa, oculto al terminar. Tanto `Main.gd` (local) como `NetworkMain.gd` (online) escuchan esa señal y usan el arma elegida al soltar el arrastre.

- **Local:** `Player.apply_knockback()` y `Terrain.carve_crater()` ahora reciben `explosion_radius`/`damage` como parámetros en vez de usar `Constants.EXPLOSION_RADIUS`/`Constants.DAMAGE` fijos. `Projectile.bounces_left` cuenta los rebotes restantes; el rebote en sí se resuelve en `Main._physics_process()` (mismo lugar donde ya se detectaba el impacto contra el suelo) reflejando la velocidad en vez de explotar. El racimo se resuelve instantáneamente en `Main._resolve_impact()`: cada sub-proyectil se integra en un bucle corto (sin nodo `Projectile` visual propio) hasta tocar el suelo, y dispara su propia explosión — es una simplificación consciente: los 4 impactos aparecen casi a la vez en vez de animados en secuencia.
- **Online:** el servidor es quien resuelve todo (igual que el resto de la física); el cliente solo manda `weaponId` junto con `dx`/`dy` en `/fire` y refleja el resultado en el siguiente *poll*, igual que con la bazooka.
- El bot del servidor ahora también elige arma al azar en su turno (ver `pawfare-server/CLAUDE.md`).
- Validado en ambos lados: `smoke_test.gd` dispara las 3 armas localmente y verifica por conteo de "tramos de terreno afectado" que la bazooka deja un cráter, el racimo deja más de uno, y el rebote sí llega a explotar (con un ángulo de tiro que no lo saque del mapa tras rebotar). `smoke_test_api.ts` (servidor) hace la misma verificación contra la API real.

**Pendiente:** Perforador (tercera arma, tunelado en línea recta) quedó fuera de esta pasada — ver `pawfare-server/CLAUDE.md`. La animación de proyectil predicha en modo online sigue sin implementarse (ver sección de red arriba). Roster de especies (solo perro/gato) sigue siendo el otro hueco grande de contenido frente a Wild Ones.
