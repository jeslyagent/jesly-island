# README-FASE2 — JESLY Island, Fase 2 sesiones 1–4

Fecha: 2026-11-27. Estado: **sesión 1 pusheada y VERIFICADA EN VIVO en la Mac de JC
(commit `55708958`, BUILD SUCCEEDED 12:28 AST, app abre desde Aplicaciones y queda
abierta sin Xcode). Sesión 2 hecha en local, SIN pushear, SIN compilar.**
Base: fork `jeslyagent/jesly-island`, HEAD remoto `55708958` (sesión 1).
Plan: `~/workspace/jarvis/COUCOU-FORK-PLAN.md` §5 mapa G y §6.

## 1. Personaje portado (la nube de puntos, ya en el árbol)

Origen: `jeslyagent/Jesly-agent-ai`, `apps/island/Sources/JeslyIsland/Character/`,
HEAD `3e2a59d` (isla JESLY actual, BUILD SUCCEEDED en la Mac 2026-11-26).
Copias **byte a byte, sin adaptar el código** (`diff` limpio contra el origen):

| Archivo en este fork | Origen | Líneas | Imports |
| --- | --- | --- | --- |
| `NotchBuddy/Sources/JeslyIsland/Character/SmokeCharacter.swift` | mismo nombre | 74 | `CoreGraphics`, `Foundation` |
| `NotchBuddy/Sources/JeslyIsland/Character/SmokeCloudView.swift` | mismo nombre | 140 | `SwiftUI` |

No hizo falta adaptar imports ni nombres de módulo: ninguno de los dos archivos
importa nada de JESLY (la matemática es lógica pura; la vista solo usa
`SmokeCharacter`). No hay referencias a `JeslyIsland`, a la API ni al keychain.

**Se compila solo:** el target principal declara `sources: - path: Sources,
type: group` (con excludes solo para `Phone/**`, `Widgets/**`,
`NotificationContent/**`), así que `Sources/JeslyIsland/Character/` entra
en el build al correr `xcodegen` — no hizo falta tocar `project.yml` para esto.

**Conectado en sesión 2 (un solo sitio, el Flow Hub):** `HubLiveMochi`
(`FlowHubMochis.swift:215`) ya no dibuja un mini Mochi: su cuerpo es
`SmokeCloudView(size: size)`. Mantiene su API (`color`, `size`, `state`,
`outfit`) para no tocar a sus 3 llamadores, que heredan la nube gratis:
`FlowHub.swift:277` (cabecera, 28 pt), `HubEmptyState` (54 pt) y
`FlowHubNotes.swift:207` (54 pt). `color` y `outfit` se ignoran (la nube es
blanca y no tiene ropa); `BotState` no tiene caso `.listening`, así que la
sonrisa de escucha no se usa aquí todavía. El resto de Mochi sigue
dibujándose (ver §2 y sesión 2 abajo): la isla animada (`BotCanvasView`),
el flotante (`DesktopMochi`), las escenas del Flow Hub (`HubMochiScene` /
`HubHero`) y los `MochiStill` de Phone/Widgets.

Qué hace el personaje (de su propio código): respiración 3 s ±3%,
parpadeo cada 4 s (0,12 s), pupilas que siguen el cursor (máx. 4 pt),
saltito de alegría 0,6 s con pico de 10 pt, sonrisa al escuchar.
Paleta: blanco sobre oscuro, halo hueso #E8E0D0. 600 puntos = conocimiento
(es el conteo vivo de la nube, no de este archivo).

## 2. Mapa de reemplazo Mochi → nube (sesión 2)

Archivos Mochi del target Mac (`NotchBuddy/Sources`, sin Phone/Widgets):

| Archivo Mochi (a reemplazar) | Qué es | Reemplazo en sesión 2 | Quién lo llama hoy |
| --- | --- | --- | --- |
| `CoucouKit/MochiStill.swift` (89 l., `MochiStill: View`, `MochiPose`) | Dibujo estático de Mochi | `SmokeCloudView` (tamaño fijo, sin animación de estado) | `BotCanvasView`, `IslandWindowController` |
| `CoucouKit/MochiMood.swift` (304 l., `MochiMood`, `MoodDrop`, `MoodHop`) | Estados de ánimo + saltos | Estados de `SmokeCharacter` (respiración, parpadeo, `joyHopHeight`, `isHopping`) | `BotEngine`, `MochiStill`, `MachineVitals`, `WorkStreak` |
| `CoucouKit/MochiOutfitDrawing.swift` (1.464 l., ojos 3D, ropa) | Motor de dibujo de Mochi con outfits | **Borrar entero.** La nube no tiene ropa ni ojos 3D. Es el archivo más grande del reemplazo | `MochiStill`, `BotCanvasView` |
| `CoucouKit/MochiWardrobe.swift` (89 l., `Outfit`) | Guardarropa (ropa de temporada) | **Borrar entero.** JESLY no tiene ropa | `MochiStill`, Settings |
| `CoucouKit/MochiActivityState.swift` (69 l.) | Estado de actividad serializable | Adaptar o borrar según lo que pida `LiveActivityRelay` | `PhoneLink/LiveActivityRelay` |
| `App/DesktopMochi.swift` (779 l., `DesktopBotView`) | Mochi flotante en el escritorio | `SmokeCloudView(size: 120)` en el flotante | `AppDelegate`, `DesktopMochiLogic` |
| `App/DesktopMochiLogic.swift` (82 l., `DesktopSpace`, `DesktopPhase`) | Lógica del flotante | Reutilizar: la lógica no dibuja, solo posiciona | `DesktopMochi` |
| `App/MochiRoom.swift` (132 l., `enum MochiRoom`) | La habitación de Mochi | Rediseñar o borrar: la "habitación" era un cuadro con Mochi; la nube no vive en una habitación | `FlowHubRoom` (51 menciones a Mochi) |
| `App/FlowHubMochis.swift` (526 l., `HubLiveMochi`, `HubMochiScene`, `HubHero*`) | Mochis del Flow Hub | `SmokeCloudView` en `HubLiveMochi`; el resto (`HubHero`, tarjetas) no dibuja Mochi | `FlowHub` (cabecera: ya dice JESLY, sigue dibujando `HubLiveMochi`) |

Fuera del target Mac (NO en sesión 2, por separado):
`Sources/Phone/Mochi*.swift`, `Sources/Widgets/MochiLiveActivity.swift`,
`windows/mochi.html` + `windows/src/mochi/`, `android/.../mochi/` (10 archivos
Kotlin). Los tests `tests/DesktopMochiTests.swift`, `MochiRoomTests.swift`,
`MochiWardrobeTests.swift` y `scripts/test-desktop-mochi.sh`,
`scripts/test-mochi-room.sh` se borran o reescriben cuando caiga su archivo.

**Estado a medio camino (a propósito, sesión 1):** la cabecera del Flow Hub
ya dice `JESLY` (`FlowHub.swift:279`) pero sigue dibujando `HubLiveMochi`
justo encima. Se resuelve en la sesión 2 al conectar `SmokeCloudView` ahí.

## 3. Qué se cambió en esta sesión (además del personaje)

Solo renombres seguros, todos texto en pantalla o metadatos (diff verificado,
sin cambios de estructura):

| Archivo | Cambio |
| --- | --- |
| `NotchBuddy/project.yml` | `CFBundleName` del target principal: `Coucou` → `JESLY` (l. 140). `CFBundleDisplayName` de los 5 targets → `JESLY` (ll. 141, 234, 320, 402, 447). Bundle id, `PRODUCT_NAME` y entitlements SIN tocar |
| `NotchBuddy/Sources/App/AppDelegate.swift` | 5× `accessibilityDescription: "Coucou"` → `"JESLY"` (icono de la barra de menú) |
| `NotchBuddy/Sources/App/FlowHub.swift` | `win.title` → `"JESLY"`; `Text(verbatim: "Coucou")` → `"JESLY"` |
| `NotchBuddy/Sources/App/SettingsView.swift` | `Text("Coucou")` de la cabecera → `"JESLY"` |
| `NotchBuddy/Sources/App/WeeklyRecapView.swift` | `Text("Coucou")` de la imagen para compartir → `"JESLY"` |

Ningún test referencia esas cadenas (`grep '"Coucou"'` en `Tests/` y
`NotchBuddy/Tests`: 0 resultados), así que los renombres no rompen tests.

## 4. Qué NO se cambió (clasificación de la auditoría)

Medido 2026-11-27 (sin `.git`): `mochi` 3.939 ocurrencias en 400 archivos;
`coucou` 11.007 ocurrencias. Por carpeta: `android` 178 archivos,
`windows` 89, `NotchBuddy` 86, `docs` 12, `tests` 6, `scripts` 6,
`design` 5, `.github` 4, `linux` 3, `relay` 2. En `NotchBuddy/Sources`:
698 ocurrencias en 80 archivos Swift. Archivos con `mochi` en el nombre: 43.

### (b) Medio — sesión 2, con build en la Mac para verificar

- Renombres de tipos y archivos `Mochi*` (mapa §2) + `PillCatalog.swift`
  (sin menciones a Mochi hoy; las pills `jesly_*` llegan en Fase 3).
- `Localizable.xcstrings`: 314 `mochi` + 1.484 `coucou`. Solo los **valores**,
  nunca las claves (3 claves contienen "Mochi" y son la clave de búsqueda;
  cambiarlas rompe la lookup). Inglés primero; el resto de idiomas después,
  y las frases de activación (`"OK Coucou"`) junto con `WakePhrase.swift`.
- `whats-new.json`: 152 `mochi`. Es historial de versiones: decidir si se
  reescribe o se deja (las notas viejas hablan de Mochi porque entonces era Mochi).
- `PRODUCT_NAME` del target principal (`project.yml:178`, `Coucou` →
  `JeslyIsland`): NO se hizo porque `scripts/cloud-test-build.sh`,
  `scripts/dev-install.sh` y `scripts/release.sh` hardcodean `Coucou.app`.
  Cambiar el producto exige cambiar los 3 scripts en el mismo commit.
- Sonidos: 29 WAV (`Resources/sounds/`, 3,8 MB). Se borran cuando se confirme
  silencio por defecto; hoy el código los referencia por nombre.

### (c) Peligroso sin compilar — no tocar hasta tener un build verde en la Mac

- Bundle id `fr.louisraille.*` + 6 `.entitlements` + `bundleIdPrefix`:
  los contenedores CloudKit son de Louis Raillé.
- `HookServer.swift`: socket `nb.sock`, hook `nb-hook`, `supportDir`
  `NotchBuddy`, claves `coucou_kind` / `coucou_agent` del protocolo.
  Cambiarlas = reinstalar los hooks en `~/.claude/settings.json`.
- `project.pbxproj`: generado por XcodeGen, nunca se edita a mano.
- Targets App Store / Phone / Widgets / NotificationContent: sus bundle id,
  `PRODUCT_NAME`, esquema de URL `coucou://`, `COUCOU_APNS_ENV`.
- Frase de activación `"OK Coucou"` (`Voice/WakePhrase.swift`,
  `WakeSpotter.swift`, `VoiceEngine.swift`): cambiarla junto con los
  textos, nunca sola.
- `CloudKit` zoneName `"Coucou"` (`PhoneLink/CloudProbe.swift`,
  `SessionPublisher.swift`, `PhoneLink.swift`): es un identificador de datos,
  no un texto; cambiarlo huérfana los datos sincronizados.
- `CHANGELOG.md`: historia, no se reescribe.
- `NSError(domain: "Coucou", …)` en `HookServer.swift` (12×): dominio de
  error, no texto visible; dejar para la sesión del hook.

## 5. Sesión 2 — hecho 2026-11-27 (local, sin pushear, sin compilar)

1. ✅ **Nube conectada en un solo sitio: `HubLiveMochi`** (Flow Hub: cabecera,
   estados vacíos y notas). Ver §1. El resto queda para la sesión 3.
2. ❌ **NO se borraron `MochiOutfitDrawing.swift` ni `MochiWardrobe.swift`**,
   a propósito, pese a que el plan lo pedía: el grep exhaustivo demostró que
   NO se cumple la condición de borrado. `Outfit` tiene **95 referencias en
   7 archivos** (`AppState.resolvedOutfit` + `mochiOutfitSelection`,
   `BotEngine.setOutfit`/`outfit`/`drawOutfitBehind`/`drawOutfitFront`,
   `BotCanvasView`, `DesktopMochi`, `FlowHubMochis`, `IslandViewContent`
   con el selector de guardarropa ~l. 4715–4830, y los tests
   `tests/MochiWardrobeTests.swift` + `scripts/test-wardrobe.sh`).
   `drawOutfitBehindStatic`/`drawOutfitFrontStatic` (definidos en
   `MochiOutfitDrawing.swift`) tienen 6 llamadores en `BotEngine` e
   `IslandViewContent`. Borrar los archivos sin reescribir todo eso rompe
   el build con certeza. Sesión 3, con build en la Mac: convertir
   `setOutfit` en no-op, quitar el selector de guardarropa y `resolvedOutfit`,
   y solo entonces borrar los 2 archivos + sus tests.
3. ✅ **`Localizable.xcstrings`: 100 valores en inglés** `Coucou`/`Mochi` →
   `JESLY` (script línea a línea, `/tmp/fase2s2-xcstrings.py`; diff exacto:
   100 líneas cambiadas). Claves intactas (1.149), otros 15 idiomas intactos,
   JSON válido. Quedan 14 hits en inglés, todos intencionados: 3
   `Coucoudoro` (nombre de función), `whatsnew.botan` (historia),
   `whatsapp.autostart.hint` y `alert.hooks.body` (rutas reales
   `Application Support/Coucou`, `~/.claude/coucou/nb-hook`), 4 rutas de
   plugins (`~/.hermes/plugins/coucou/`, `~/.config/amp/plugins/coucou.ts`,
   `~/.copilot/hooks/coucou.json`, `~/.config/opencode/plugins/coucou.js`),
   y la frase de activación `« OK Coucou »` (2 claves + `voice.setting-web-desc`).
   Feo conocido: `voice.setting-web` dice ahora "Claude as JESLY's brain" —
   el texto es de la función de voz de Coucou; se corrige en Fase 4 cuando
   la voz pase a la API de JESLY. La clave `"Coucou"` no tiene localización
   `en` (solo ja/ko/th/zh-Hant): su valor es la propia clave y no se tocó.
4. ❌ **`PRODUCT_NAME` + 3 scripts: APLAZADO a la sesión 3.** Cambiar
   `Coucou` → `JeslyIsland` en `project.yml:178` exige cambiar
   `scripts/cloud-test-build.sh` (`APP=.../Coucou.app`,
   `PROFILE_NAME="Coucou Developer ID"`, `CONTAINER=iCloud.fr.louisraille.Coucou`),
   `scripts/dev-install.sh` (`BUILT=.../Coucou.app`, `TARGET=/Applications/Coucou.app`,
   `pgrep -x Coucou`) y `scripts/release.sh` (`APP`, `ZIP`, grep de
   entitlements `iCloud.fr.louisraille.Coucou`, título de release) — pero los
   dos primeros scripts dependen de la identidad de firmado y del contenedor
   iCloud de Louis Raillé, que NO cambian en esta fase (bundle id y
   entitlements intactos). Renombrar el producto sin su identidad de firmado
   es el cambio con más riesgo de romper el build en la nube; va junto con
   la decisión de bundle id, con build en la Mac para verificar.
5. ⏳ Sesión 3: build de la sesión 2 en la Mac; isla animada (`BotCanvasView`
   → nube) y flotante (`DesktopMochi` → `SmokeCloudView(size: 120)`);
   escenas `HubMochiScene`/`HubHero`; quitar `Outfit` y borrar los 2 archivos;
   `PRODUCT_NAME` + scripts; `AndroidLinkProtocol.swift:140` (nombre de
   instancia por defecto `"Coucou"` si el Mac no tiene nombre).

## 6. (antes §5) Sesión 2 — lista de trabajo original

## 7. Sesión 3 — hecho 2026-11-27 (local, SIN pushear, SIN compilar)

Sesión 2 verificada corriendo en la Mac de JC antes de empezar (13:20 AST,
pull Fast-forward a `5cc5fd0`, menú y ventana dicen JESLY, nube en Flow Hub).

### 7.1 Isla del notch → nube

- `NotchBuddy/Sources/App/BotCanvasView.swift`: `BotCanvasView` y
  `MiniBotCanvasView` ya no dibujan con `BotEngine`. Cuerpo nuevo:
  `GeometryReader` + `SmokeCloudView(size: min(ancho, alto))`; en la isla
  principal `listening: state.voiceActive` (sonríe al escuchar). API
  intacta (`state`, `particleOverhang`, `lookOriginOverride`, `paused`) para
  no tocar llamadores (`IslandRootView`, `IslandWindowController:1648`,
  `CornerIsland`, `CoucoudoroViews`, `FlowPill`, `SpotifyViews`,
  `IslandViewContent`). `paused` ahora devuelve `Color.clear` (antes no se
  dibujaba nada mientras Mochi estaba en el escritorio).
- Lo que se pierde con el cambio (sin equivalente en la nube): estados de
  ánimo (`MochiMood`), baile con música, morph de subida, emotes
  (slap/greet/blink/gulp/morph). La nube respira, parpadea y sigue el cursor.
  Los minis ahora animan a 60 fps (`SmokeCloudView` lo lleva hardcodeado)
  en vez de 30: vigilar CPU en la verificación en vivo.
- `BotEngine` sigue en el árbol pero ya no dibuja la isla. Lo siguen usando:
  escenas `HubMochiScene`/`HubHero`, `MochiStill`, `FlowHubRoom`, `FlowPill`.

### 7.2 Flotante → nube

- `NotchBuddy/Sources/App/DesktopMochi.swift`: `DesktopBotView` ahora es
  `SmokeCloudView(size: 120, listening: appState.voiceActive)` con el mismo
  hover scale 1.07. `engine: BotEngine` se mantiene como parámetro para no
  tocar al controlador, que sigue creándolo y usándolo para emotes y sonidos
  (`pop`/`peek`/`approve`): la nube no suena ni hace emotes, y el clic
  simple ya no tiene "slap" visible (el `engine.slap()` sigue existiendo
  pero no dibuja nada). Doble clic sigue volviendo a casa.
  `viewState.paused` ya no pausa el dibujo (la nube anima sola).
- Queda el nombre viejo en datos persistidos, a propósito: claves
  `UserDefaults` `desktopMochiX` / `desktopMochiY` / `mochiOnDesktop`
  (renombrarlas huérfana la posición guardada) y comentarios del controlador.

### 7.3 Guardarropa: selector quitado, archivos NO borrados

- `BotEngine.setOutfit` → **no-op**: fija `outfit = .none`,
  `outfitPresence = 0` e ignora los argumentos. Firma intacta para que los
  llamadores que quedan (`HubMochiScene`, controlador del flotante) sigan
  compilando. `outfitTarget` queda como variable muerta (solo se declaraba).
- `AppState`: quitados `mochiOutfitSelection`, `wardrobePreviewOutfit`,
  `resolvedOutfit`, `_seasonalCache` y la línea de init
  (`mochiOutfitSelection = Outfit.stored`). Grep después: **0 referencias**
  en todo el árbol.
- `IslandViewContent.swift`: `WardrobeView` es ahora un aviso ("JESLY no
  tiene ropa: la nube es la nube." + botón Volver). Borrados
  `OutfitPillView` y `drawOutfitIcon` (solo los usaba el grid). La ruta
  `.wardrobe`, el atajo ⌃⌥G y los handlers de `IslandWindowController`
  siguen y muestran el aviso.
- ❌ **NO se borraron `MochiOutfitDrawing.swift`, `MochiWardrobe.swift`,
  `tests/MochiWardrobeTests.swift` ni `scripts/test-wardrobe.sh`.**
  La condición del encargo (grep 0 tras el no-op + quitar el selector) **NO
  se cumple**: `Outfit` sigue referenciado en `FlowHubMochis.swift`
  (`HubMochiSpec.outfit` + `setOutfit` en las escenas `HubHero`, con outfits
  `.bow`, `.roundGlasses`, `.crown`, `.beanie`, `.sunglasses`, `.partyHat`,
  `.scarf`) y en `BotEngine.swift` (8 refs internas: `outfit`,
  `outfitPresence`, `drawOutfitBehind/Front`, tween `"outfitPresence"`),
  más los tests. Borrarlos ahora rompería el build con certeza.
  Para borrarlos (sesión 4, con build en la Mac): reemplazar o quitar las
  escenas `HubHero`/`HubMochiScene`, y destripar `BotEngine` (quitar
  `outfit`/`outfitPresence`/`drawOutfit*`/`outfitTarget`).

### 7.4 AndroidLinkProtocol

- `AndroidLinkProtocol.swift:140` (`instanceName`): nombre por defecto
  `"Coucou"` → `"JESLY"` si el Mac no tiene nombre (y su comentario).

### 7.5 Qué queda de Mochi y por qué

- Escenas Flow Hub `HubMochiScene` / `HubHero` (tropa que camina, con
  outfits): quedan para la sesión 4.
- `MochiRoom` / `FlowHubRoom`, `MochiStill` (Phone/Widgets), `MochiMood`,
  `BotEngine` en el árbol, 29 WAV, `whats-new.json`: intactos.
- `PRODUCT_NAME` + 3 scripts + bundle id: NO tocados (ver §8).

### 7.6 Archivos cambiados en esta sesión (6, solo estos)

| Archivo | Cambio |
|---|---|
| `NotchBuddy/Sources/App/BotCanvasView.swift` | Isla + minis → `SmokeCloudView` (−296/+~30 l.) |
| `NotchBuddy/Sources/App/DesktopMochi.swift` | Flotante → `SmokeCloudView(size: 120)`; 2× `setOutfit` quitadas del controlador |
| `NotchBuddy/Sources/CoucouKit/BotEngine.swift` | `setOutfit` → no-op |
| `NotchBuddy/Sources/App/IslandViewContent.swift` | `WardrobeView` → aviso; borrados `OutfitPillView` + `drawOutfitIcon` |
| `NotchBuddy/Sources/App/AppState.swift` | Quitadas `mochiOutfitSelection` / `wardrobePreviewOutfit` / `resolvedOutfit` / `_seasonalCache` |
| `NotchBuddy/Sources/App/AndroidLink/AndroidLinkProtocol.swift` | Nombre por defecto → `"JESLY"` |

Verificación sin compilar: balance llaves/paréntesis/corchetes 0 en los 6
archivos; grep `resolvedOutfit|mochiOutfitSelection|wardrobePreviewOutfit|
OutfitPillView|drawOutfitIcon` = 0 en todo el árbol (salvo un comentario);
`project.yml` sin tocar. **No afirmo que compile** — solo la Mac lo confirma.

## 8. Decisión pendiente de JC: PRODUCT_NAME + bundle id + firmado (NO tocado)

Nada de esto cambia en la sesión 3. Cuando JC decida, todo cambia **junto**,
en un solo lote, con build en la Mac para verificar.

### 8.1 PRODUCT_NAME: `Coucou` → `JeslyIsland` (project.yml:178)

Archivos que cambiarían en el mismo lote:

| Archivo | Qué hardcodea |
|---|---|
| `scripts/cloud-test-build.sh` | `APP=.../Coucou.app`, `PROFILE_NAME="Coucou Developer ID"`, `CONTAINER=iCloud.fr.louisraille.Coucou` |
| `scripts/dev-install.sh` | `BUILT=.../Coucou.app`, `TARGET=/Applications/Coucou.app`, `pgrep -x Coucou` |
| `scripts/release.sh` | `APP`, `ZIP`, grep de entitlements `iCloud.fr.louisraille.Coucou`, título de release |

Hoy el `.app` compilado se sigue llamando `Coucou.app` (display name `JESLY`).

### 8.2 Bundle id: `fr.louisraille.*` → `com.jesly.island`

Archivos que cambiarían en el mismo lote:

- `project.yml`: `bundleIdPrefix` (l. 3), `CFBundleIdentifier` +
  `PRODUCT_BUNDLE_IDENTIFIER` de los 5 targets.
- 6–8 `.entitlements` (`Resources/Coucou*.entitlements`): contenedores
  CloudKit `iCloud.fr.louisraille.*` → contenedores nuevos `com.jesly.*`,
  que hay que crear en la cuenta de desarrollador de JC.
- Keychain (grupo de acceso), esquema de URL `coucou://`, `COUCOU_APNS_ENV`.

### 8.3 Preguntas que solo JC puede responder

1. ¿Tiene cuenta de desarrollador Apple / Developer ID a nombre de JESLY
   para firmar el build, o se sigue en ad-hoc sin notarizar (aviso de macOS
   la primera vez)?
2. ¿Creamos contenedores CloudKit nuevos, o se deja iCloud apagado? (La
   sincronización con iPhone se re-piensa: la PWA de JESLY ya cubre iPhone
   sin CloudKit.)
3. ¿El `.app` final se llama `JeslyIsland.app` y vive en
   `/Applications/JESLY.app`?

Sin esas tres respuestas no se toca nada de §8.1–8.2: renombrar el producto
sin su identidad de firmado rompe el build en la nube y la notarización.

## 9. Sesión 4 — hecho 2026-11-27 (local, SIN pushear, SIN compilar)

Bug de JC en vivo (sesión 3 verificada, PID 10835): la nube **se ve cortada
en el notch plegado hasta abrir la isla**, y la app queda en **~45 % de CPU
en reposo**.

### 9.1 Geometría del notch plegado, medida en código (no adivinada)

- `IslandConst.notchHeight = 32` (fallback; en la Mac de JC es el
  `safeAreaTop` real, 32–36 pt), `notchWidth` fallback 184
  (`IslandTypes.swift:241-242`, `IslandScreenGeometry.swift`).
- `islandSize(.compact)` = `(nw + 160, nh)` = **(344, 32)**; `islandSize(.hidden)`
  = `(nw, nh)` = (184, 32) (`IslandWindowController.swift:2243`).
- `botPosition(.compact)` = (40, 16, diámetro 20, opacidad 1):
  `IslandRestingLayout.botDiameter = min(20, height − 6)`,
  `botCenterY = height / 2` (`IslandScreenGeometry.swift:34-40`).
- `BotPlacement`: `canvasSize = diámetro / 0.6 = 33,3`; frame de
  33,3 × (33,3 + 40 overhang) = 73,3, posicionado en
  `(40, 16 − 20 = −4)` en coords de la isla; `IslandContainer` enmascara
  `BotPlacement` a la altura de la isla (32 pt en plegada).
- **Cómo evitaba Mochi cortarse:** `BotEngine.draw` centra el cuerpo en
  `cy = H/2 + particleOverhang/2 + oy*R + R*0.06` (`BotEngine.swift:1117`)
  = 36,65 + 20 = 56,65 en coords del canvas → y ≈ 16 en la isla, centro
  exacto de la tira, cuerpo de 20 pt entre y 6–26, entero visible.
- **Por qué se cortaba la nube (sesión 3):** `BotCanvasView` centraba el
  cuadrado de 33,3 de `SmokeCloudView` en el frame de 73,3 → centro de la
  nube en y ≈ −4 en la isla; la nube mide ~24,4 pt de alto, así que
  ocupaba y ≈ −18…+7 y la máscara de 32 pt solo dejaba ver de 0 a ~7:
  el tercio de abajo. Al abrir, la isla mide 160 pt y no hay corte —
  exacto lo que JC describió ("cortado hasta que lo abro").

### 9.2 Arreglo (2 archivos, sin tocar `SmokeCharacter`)

- `BotCanvasView.swift`: la nube va **alineada ABAJO** del frame
  (`alignment: .bottom`), no al centro. Es la misma compensación de
  BotEngine con otra forma: centro = H − size/2 = size/2 + overhang, que
  es idéntico a H/2 + overhang/2. Con overhang 40: centro en y = 16, la
  nube (2,4–26,8) cabe entera en la tira de 32 pt. En expandida da el
  mismo centro que Mochi (`cy`), así que la vista abierta no cambia.
  La demostración vale para cualquier `nh` (16 → height/2), no solo 32.
  Ramas sin overhang (subida, `GhostBotView` cuadrado) no cambian:
  abajo = centro ahí.
- `SmokeCloudView.swift`: parámetro nuevo `compact: Bool = false`.
  Plegada corre a **30 fps** (`minimumInterval 0.9/30`, como
  `MochiFrameClock.interval`); abierta a 60 fps. `BotCanvasView` pasa
  `compact: state.mode != .expanded`; `MiniBotCanvasView` pasa
  `compact: true` siempre (las minis de Mochi eran 30 fps,
  `MochiFrameClock.miniFPS`). `DesktopMochi` (120 pt) y `FlowHubMochis`
  quedan a 60 fps: son vistas visibles, no el problema.
- `BotCanvasView` además **no anima cuando está oculta en el notch**:
  si `mode == .hidden` y no es esquina ni arrastre (`isDraggingBot`),
  devuelve `Color.clear` (BotPlacement ya la pone a opacidad 0).
  Excepciones a propósito: la baldosa en esquina (ahí `hidden` sí se
  ve) y el fantasma de arrastre `GhostBotView`.
- `paused` se sigue respetando (ya devolvía `Color.clear`).
- No se tocó `SmokeCharacter` (matemática), ni bundle id, entitlements,
  `HookServer`, `project.yml`, ni la isla actual de `Jesly-agent-ai`.

### 9.3 FPS por estado (después del arreglo)

| Estado | FPS de la nube |
|---|---|
| Isla abierta (expanded) | 60 |
| Isla plegada (compact / petit) | 30 |
| Isla oculta en el notch (hidden) | 0 (sin animar) |
| Baldosa en esquina (hidden, corner) | 30 |
| Minis (pills, esquina) | 30 |
| Flotante de escritorio, Flow Hub | 60 |

### 9.4 Archivos cambiados en esta sesión (2 + docs)

`SmokeCloudView.swift` (parámetro `compact`, intervalo 30/60),
`BotCanvasView.swift` (alineación abajo, `compact` por modo, sin
animar oculta, minis a 30). Balance 0 en los 2; `SmokeCloudView` tiene
valor por defecto en el parámetro nuevo, así que `DesktopMochi` y
`FlowHubMochis` compilan sin tocarse (verificado por grep).
**Sin compilar: solo la Mac lo confirma.**

## 10. Sesión 5 — hecho 2026-11-27 (local, SIN pushear, SIN compilar)

Sesión 4 verificada en vivo antes de empezar (13:38 AST: tras un BUILD
FAILED inicial por proyecto Xcode viejo y limpiar con Shift+Cmd+K, la
nube se ve bien completa en el notch cerrado).

### 10.1 Flow Hub sin Mochis: `HubHero` / `HubMochiScene` fuera

- `FlowHubMochis.swift` (531 → 338 l.): borrados `HubMochiSpec`,
  `HubMochiTroupe` (con su `Walker`) y `HubMochiScene` (la tropa que
  caminaba con `BotEngine.draw`, emotes y `poke`). `HubHero` queda como
  banda de color + título + subtítulo + acción, con su fondo de
  partículas (`HubHeroBackdrop` / `HubHeroLight`, que ya parecían nube de
  puntos) y sin escena: el `Spacer(minLength: 290/350)` que reservaba
  sitio para la tropa pasa a `Spacer()`. Su API no cambia
  (`page`/`title`/`subtitle`/`trailing`/`compact`): los 3 llamadores
  (`FlowHub.swift:254, 420`, `FlowHubNotes.swift:19`) no se tocaron.
- `HubHeroTheme` pasa a solo color (`of(page)` devuelve el mismo color
  por página que antes, sin `cast`); `theme.cast` ya no existe.
- `HubLiveMochi` pierde el parámetro `outfit` (el tipo `Outfit` muere
  en esta sesión); `FlowHubNotes.swift:207` deja de pasar
  `outfit: .roundGlasses`. `color` y `state` se quedan (la nube los
  ignora, pero son tipos que siguen existiendo).

### 10.2 `BotEngine` destripado del outfit

- Borrados: `outfit`, `outfitPresence`, `outfitTarget`, `setOutfit`
  (no-op desde la sesión 3), `drawOutfitBehind`, `drawOutfitFront`,
  `outfitFollowsRoll`, los casos `"outfitPresence"` de
  `setProperty`/`getProperty`, y el impulso centrífugo
  (`centrifugal` + `rollVel` + `prevRoll`, que solo existían por la
  ropa). `pumpkinColors` pasa a `false` (nunca se aplica ropa) y el
  `rigidRoll` de los ojos pasa a `+ roll` directo.
- `drawOutfitBehind`/`drawOutfitFront` ya eran código muerto: `draw()`
  nunca los llamaba (verificado por grep).

### 10.3 El hallazgo: `MochiOutfitDrawing.swift` NO era solo ropa

El archivo (1.464 l.) guardaba también la geometría compartida de
cabeza/ojos que `BotEngine.drawEyes` necesita: `MochiH`,
`EyeFrame`, `mEyeFrames` (y el shim `mochiEyePositions`). Borrarlo a
ciegas habría roto los ojos de Mochi en la habitación, las pills y el
resumen semanal. Solución: esa geometría se extrajo **verbatim** a un
archivo nuevo, `NotchBuddy/Sources/CoucouKit/MochiHeadGeometry.swift`
(verificado por `diff` contra las líneas 1–77 del original; solo se
dejaron fuera las constantes `kEXP` y `kACC_PITCH`, que solo usaban
los helpers 3D del outfit). El resto del archivo — `mochiOutfitPath`,
`outfitBodyTransform`, `drawOutfitFrontStatic`,
`drawOutfitBehindStatic` y todos los sombreros/gafas/bufandas — se fue
con él.

### 10.4 Archivos borrados (6 + 2 de tooling)

| Archivo | Por qué |
|---|---|
| `NotchBuddy/Sources/CoucouKit/MochiOutfitDrawing.swift` | Ropa; geometría extraída a `MochiHeadGeometry.swift` |
| `NotchBuddy/Sources/CoucouKit/MochiWardrobe.swift` | El tipo `Outfit` (enum, `seasonal`, `resolved`, `stored`) |
| `tests/MochiWardrobeTests.swift` | Tests del `Outfit` |
| `scripts/test-wardrobe.sh` | Corre esos tests (compila `MochiWardrobe.swift` + tests) |
| `scripts/RenderOutfits.swift` | Render de planchas de outfits; solo existía para la ropa |
| `scripts/render-outfits.sh` | Compila el render anterior (no estaba en CI) |

Además: `.github/workflows/build.yml` pierde el paso `Wardrobe tests`
(era el único sitio de CI que corría `test-wardrobe.sh`; sin ese paso
el CI fallaría buscando el script borrado). YAML validado.

### 10.5 Condición de borrado: CUMPLIDA en el ámbito Mac

Grep después del borrado (`Outfit`/`setOutfit`/`drawOutfit`,
`NotchBuddy/Sources` + `tests/` + `scripts/` + `.github/`): **0
referencias en código** — solo 2 comentarios de documento (el de
`HubLiveMochi`, que explica que el parámetro murió, y la cabecera de
`MochiHeadGeometry.swift`, que explica la extracción). Balance
llaves/paréntesis/corchetes 0 en los 5 Swift tocados; `HubHeroTheme`
sin `cast`; llamadores de `HubHero` intactos.
**Sin compilar: solo la Mac lo confirma.**

Lo que el grep NO cubre (ámbito fuera de esta sesión, a propósito):
Android (`android/.../mochi/outfit/`, su propio `Outfit` Kotlin) y
Windows (`windows/src/mochi/outfits.ts`, `wardrobe.ts`) tienen su
propia ropa y NO se tocaron. `CHANGELOG.md:441` es historia.
`Localizable.xcstrings` guarda valores muertos de nombres de ropa
("Party hat", etc.) — no se tocó el JSON. `project.pbxproj` (trackeado,
generado por XcodeGen) todavía referencia los 6 archivos borrados
hasta que JC corra `xcodegen` en su Mac (su flujo habitual) — ver §10.6.

### 10.6 Qué queda de Mochi y por qué

- `MochiRoom` / `FlowHubRoom`, `MochiStill` (Phone/Widgets),
  `MochiMood` (+ `MoodDrop`/`MoodHop`), `BotEngine` en el árbol
  (sigue dibujando a Mochi en la habitación, las pills y el resumen
  semanal), 29 WAV, `whats-new.json`: intactos, por decisión del
  encargo (no se tocan en esta sesión).
- `WardrobeView` sigue existiendo como aviso ("JESLY no tiene ropa")
  y la ruta `.wardrobe` + atajo ⌃⌥G + notificación
  `openWardrobeFromDesktop` siguen: son ruta, no ropa.
- `PRODUCT_NAME` + bundle id + firmado: NO tocados (ver §8).

### 10.7 Archivos cambiados en esta sesión

| Archivo | Cambio |
|---|---|
| `NotchBuddy/Sources/App/FlowHubMochis.swift` | Tropa fuera; `HubHero` solo banda; tema solo color; `HubLiveMochi` sin `outfit` (−221/+33 l.) |
| `NotchBuddy/Sources/CoucouKit/BotEngine.swift` | Destripe del outfit (−~90 l.) |
| `NotchBuddy/Sources/CoucouKit/MochiHeadGeometry.swift` | **Nuevo**: geometría de cabeza/ojos extraída verbatim |
| `NotchBuddy/Sources/App/FlowHubNotes.swift` | `HubLiveMochi` sin `outfit: .roundGlasses` |
| `NotchBuddy/Sources/App/IslandViewContent.swift` | Comentario del guardarropa sin mencionar `Outfit` |
| `.github/workflows/build.yml` | Paso `Wardrobe tests` eliminado |
| + 6 borrados (§10.4) | Ver tabla |

## 11. Fase 3, sesión 1 — cliente API + pill `jesly_propuestas` (2026-11-27, local, SIN pushear, SIN compilar)

Fase 2 verificada completa en la Mac de JC antes de empezar (sesiones 1–5
corriendo; última 14:09 AST, Running Coucou, 0 errores, Flow Hub sin Mochis).

### 11.1 Cliente portado (solo propuestas; chat/workflows/skills/voz en Fases 4–5)

Origen: `jeslyagent/Jesly-agent-ai`, `apps/island/Sources/JeslyIsland/Api/`,
HEAD `3e2a59db` (el `3e2a59d` corto no resuelve como ref en el conector;
el SHA completo es `3e2a59db612ac5c623d79ea601bcfe8768ce18fd`).

| Archivo nuevo en este fork | Origen | Qué cubre |
|---|---|---|
| `NotchBuddy/Sources/JeslyIsland/Api/JeslyAPIClient.swift` (169 l.) | mismo nombre | Transporte + errores + solo propuestas. Endpoints exactos como en la isla (verificado por grep contra el origen): `GET /v1/tasks?status=esperando_aprobacion&kind=propuesta`, `GET /v1/tasks?status=planificada&kind=propuesta`, `GET /v1/tasks?status=aplicada&kind=propuesta`, `POST /v1/tasks/:id/<acción>` con `ProposalAction.endpoint` (`approve`/`reject`/`discard`/`apply`/`revert`/`execute`). La decisión vale para el `task id` exacto: sin hook, sin fd de `nb-hook` abierto (diferencia con Coucou, documentada en el archivo). |
| `NotchBuddy/Sources/JeslyIsland/Api/JeslyModels.swift` (197 l.) | mismo nombre | `JeslyTask` (+ `availableActions` por estado), `ProposalAction`, `ChatResponse`, `ChatAttachment`, `JeslyWorkflow`, `JeslySkill`, `WakeStatus`. Los 4 últimos sin uso en esta sesión (llegan en Fases 4–5); son datos puros, no rompen nada. |
| `NotchBuddy/Sources/JeslyIsland/Api/ApiKeyStore.swift` (77 l.) | mismo nombre | Copia verbatim. Llavero servicio `com.jesly.island`, cuenta `jesly-api-key`; fallback a `JESLY_API_KEY` de entorno; sin clave la API local acepta igual. La clave nunca se hardcodea ni se registra en logs. |
| `NotchBuddy/Sources/JeslyIsland/Api/JeslyProposalsPoller.swift` (82 l.) | **Nuevo, sin origen** | Sondeo cada 5 s (como la isla) de `pendingProposals()`; publica `proposals`, `apiReachable`, `lastError`. Solo sondea con la pill activa y respetando `DemoEngine.isPollerPaused`. Cliente nuevo por sondeo (relee la clave del llavero cada vez). |

### 11.2 UNA diferencia deliberada con el origen: `ChatProvider` NO se porta

Coucou ya tiene un `enum ChatProvider` (`IslandTypes.swift:115`); dos tipos
con el mismo nombre en el mismo módulo no compilan. El `ChatProvider`
struct de la isla (lista de proveedores del router) se porta en la Fase 4
como **`JeslyChatProvider`**. Ningún método de esta sesión lo usa (verificado
por grep: solo Coucou tiene el tipo; en `JeslyModels.swift` solo aparece en
un comentario).

### 11.3 Poller básico: qué hace con la API apagada

No es un error que rompa nada: `apiReachable = false`, `lastError` guarda
el motivo (`serverUnreachable` → "La API de JESLY no responde en
127.0.0.1:3000…") y la lista anterior se conserva (una lista vieja es
mejor que un parpadeo a vacío cada 5 s). La pill muestra 0 propuestas
pendientes. El cliente nuevo por sondeo relee la clave del llavero cada
vez, así que pegar la clave en Ajustes (sesión 2) no exige reiniciar.

### 11.4 Pill registrada (solo registro + poller; la tarjeta va en la sesión 2)

- `PillCatalog.swift`: `.init(id: "jesly_propuestas", name: "JESLY",
  color: "#E8E0D0", category: .agent, subtitle: "Agent", source: .agent)`,
  tras `agent_claude-desktop`. Color hueso #E8E0D0 (halo de la nube).
  `source: .agent` es solo metadato del catálogo: los datos vienen del
  sondeo a la API, NO de un hook. Subtítulo `"Agent"` (clave existente;
  no hay clave `"Proposals"` en `xcstrings`, no se inventa una).
- `AppDelegate.swift` (`setupIsland`, tras `GithubPoller`):
  `JeslyProposalsPoller.shared.start()`. Ningún otro archivo de Coucou
  tocado: ni `ApprovalQueue`, ni `AskQuestion`, ni `ChatProvider`, ni
  `HookServer`, ni `project.yml`, ni `project.pbxproj`.
- La pill aparece en **Ajustes → Active pills** (categoría Agents),
  porque `SettingsView` lista `PillCatalog.available` por categoría.
  OJO: solo caben 4 pills activas y por defecto ya hay 4 (Resend, n8n,
  Vercel, GitHub): para activar `jesly_propuestas` hay que desactivar
  una. La tarjeta de Propuesta/Permiso NO existe todavía: la pill sin
  tarjeta no pone ninguna `AgentTask` en la isla. Eso es la sesión 2.

### 11.5 Verificación sin compilar (hecha)

Balance llaves/paréntesis/corchetes 0 en los 6 archivos (4 nuevos +
`PillCatalog.swift` + `AppDelegate.swift`); endpoints del cliente
idénticos a los de la isla (grep de las 3 queries + la acción);
sin colisión de nombres (`JeslyTask`, `JeslyWorkflow`, `JeslySkill`,
`WakeStatus`, `ChatResponse`, `ChatAttachment`, `ProposalAction`,
`JeslyAPIClient`, `ApiKeyStore` no existen en Coucou);
`project.yml` sin tocar (el grupo `Sources` ya incluye
`Sources/JeslyIsland/Api/`, como pasó con `Character/` en la Fase 2).
**No afirmo que compile** — solo la Mac lo confirma.

### 11.6 Para la sesión 2

Tarjeta Propuesta/Permiso reutilizando la UI de `ApprovalQueue` +
`AskQuestion.swift` con backend `proposalAction(taskId:)`; entrada de
la clave en Ajustes (`ApiKeyStore.save`); acciones por estado según
`JeslyTask.availableActions` (+ "Siempre" como regla revocable, mapa A
del plan). Riesgos que siguen: la API local apagada deja la pill vacía
(por diseño, §11.3); si JC cambia el grupo de acceso del llavero en
la Fase 6, revisar `ApiKeyStore` (el servicio `com.jesly.island` hoy
no depende del bundle id del build).

## 12. Fase 3, sesión 2 — tarjeta Propuesta/Permiso + clave en Ajustes + "Siempre" (2026-11-27, local, SIN pushear, SIN compilar)

### 12.1 Archivos nuevos (2)

- `NotchBuddy/Sources/JeslyIsland/JeslyProposalStore.swift`: `AlwaysRule`
  (porte verbatim de la isla actual, misma clave de UserDefaults
  `com.jesly.island.alwaysRules`, así que las reglas de la isla actual
  se leen igual) + `JeslyProposalStore` (`@MainActor`, singleton):
  observa las tres listas del poller, pone la primera propuesta en
  `current` (esperando → planificada → aplicada), `act(_:on:)` y
  `answerPermission(_:for:)` por `proposalAction(taskId:)` con el
  `task id` exacto, `applyAlwaysRules` (cada auto-aprobación pasa por
  `POST /v1/tasks/:id/approve` y queda en `autoApprovedLog`), y
  `syncIsland()` que abre/cierra la tarjeta. Nunca toca el hook.
- `NotchBuddy/Sources/JeslyIsland/Views/JeslyProposalCardView.swift`:
  `JeslyProposalView`, mismo cromo que `ApprovalView` (fondo ámbar,
  cabecera `AgentWho` con pill JESLY hueso, contador "1/N", botones
  píldora `PrimaryButton`/`SecondaryButton` en verbatim). El `task id`
  se captura al dibujar y el clic se ignora si la tarjeta ya pasó a
  la siguiente (igual que `shownId` en `ApprovalView`).

### 12.2 Botones por estado (`JeslyTask.availableActions`)

- esperando_aprobacion → **Permitir** (approve) / **Denegar** (reject) / **Siempre** (crea la regla agente+tipo Y aprueba esta propuesta).
- planificada con parche → **Aplicar** (apply) / **Descartar**.
- planificada sin parche → **Ejecutar** (execute) / **Descartar**.
- aplicada → **Revertir** (revert).
- La primera acción no destructiva es la primaria (hueso).

### 12.3 Cómo se abre la tarjeta (nuevo `IslandView.jeslyProposal`)

- `IslandTypes.swift`: caso nuevo `jeslyProposal` en el enum. No hay
  ningún `switch` exhaustivo sobre `IslandView` fuera de
  `IslandViewContent` (CoucoudoroController tiene `default`), y
  `IslandRootView` itera `allCases`, así que el caso nuevo se monta
  solo; `IslandViewContent` lo despacha a `JeslyProposalView()`.
- `JeslyProposalStore.syncIsland()`: con propuesta y sin permiso ni
  pregunta de Coucou en pantalla, abre la isla con `.hookExpand`
  (igual que las alertas de Coucou); si la isla ya está abierta en
  home/vacía/terminada/error, cambia la vista; si JC está en otra
  vista (chat, ajustes…), no se la roba — la tarjeta espera al
  siguiente sondeo. Sin propuestas y con la tarjeta abierta, vuelve
  a home/vacía. Si JC desactiva la pill con la tarjeta abierta, la
  tarjeta se cierra (el store también observa `activeIntegrations`).
- `AppDelegate.setupIsland`: `JeslyProposalStore.shared.start()`,
  junto al poller.

### 12.4 Poller ampliado (sesión 1, mismo archivo)

- `JeslyProposalsPoller` ahora trae las tres listas a la vez
  (`pending` + `planned` + `applied`, con `async let` como la isla
  actual): si una falla, fallan las tres y se conservan las listas
  anteriores. Con la API apagada no aparece ninguna tarjeta nueva y
  no hay errores; la pill muestra 0 propuestas.

### 12.5 Ajustes → JESLY (fila nueva en el menú, tras Agents)

- Clave de la API: `SecureField` + Guardar (`ApiKeyStore.save` al
  llavero `com.jesly.island`, cuenta `jesly-api-key`; vacío = borrar)
  + Borrar. Al guardar, `refreshNow()`: el siguiente sondeo ya usa
  la clave nueva sin reiniciar. Nunca en texto plano ni en logs.
  Muestra si la API local responde o no.
- Reglas "Siempre": lista agente · tipo con botón **Revocar** cada
  una; sin reglas, "cada propuesta pide permiso". Debajo, las últimas
  5 aprobadas solas por regla (auditoría).

### 12.6 Verificación sin compilar (hecha)

- Balance llaves/paréntesis/corchetes 0 (scanner Swift-aware con
  interpolación) en los 7 archivos nuevos/tocados; mis inserciones
  en `SettingsView`/`IslandViewContent` balanceadas en aislado.
- Cada acción pasa por `proposalAction(taskId: task.id)` (grep):
  `act` y auto-aprobación en el store; la vista solo llama al store.
- Sin referencias al hook en el camino de JESLY (solo menciones en
  comentarios de los archivos portados, explicando la diferencia).
- Sin colisión de nombres (`JeslyProposalStore`, `JeslyProposalView`,
  `AlwaysRule`, `PermissionAnswer` anidado). `project.yml` sin tocar
  (el glob `Sources` ya incluye `Sources/JeslyIsland/`).
- **No afirmo que compile** — solo la Mac lo confirma. Sospechosos
  si falla: el `switch` nuevo en `IslandViewContent`, el
  `CombineLatest3` del store, o el `AgentTask` sintético de la
  cabecera.

### 12.7 Riesgos y límites conocidos

- Si JC está en otra vista de la isla (chat, ajustes) cuando llega
  una propuesta, la tarjeta no se la roba: aparece en el siguiente
  sondeo (5 s) o al volver al home.
- Con la API apagada tras haber actuado, el poller conserva la lista
  vieja: el store guarda los ids decididos (`decidedIds`) para que
  la tarjeta no vuelva a mostrar una propuesta ya decidida; se
  limpian en el primer sondeo que llega bien.
- Una propuesta que casa con una regla se auto-aprueba en el sondeo;
  puede verse un instante en la tarjeta antes de que el sondeo
  siguiente la quite (igual que la isla actual).
- La tarjeta no pone badge en la pill (no hay `AgentTask` de JESLY
  en `state.tasks`): si la isla está en otra vista, la propuesta
  solo se ve al volver al home. Follow-up, no de esta sesión.

### 12.8 Para la sesión 3

- Tarjeta de sesión en vivo para JESLY (pasos + diff real del
  parche, mapa A del plan; no inventar pasos de terminal).
- Verificación/publicación en la tarjeta (Fase 4, mapa A):
  `POST /v1/tasks/:id/verify` y `/publish`.
- Pill `jesly_chat` + proveedor `JeslyChatProvider` (Fase 4, mapa D);
  `ChatProvider` de Coucou sigue sin tocarse.

## 13. Fase 3, sesión 3 — tarjeta de sesión en vivo JESLY (2026-11-27, local, SIN pushear, SIN compilar)

### 13.1 Hallazgo: NO hay endpoint nuevo — la isla tampoco usa `GET /v1/tasks/:id`

Verificado en la isla actual (`IslandHomeView.swift`, HEAD `3e2a59db`):
la "sesión en vivo" se deriva de las tres listas que ya sondea el
poller (`GET /v1/tasks?status=...&kind=propuesta`). Los pasos son
las tareas mismas (aplicadas = hechas, planificadas + en espera = en
curso) y el diff sale del `patch` de la primera tarea con parche.
Esta sesión porta esa lógica tal cual; ningún dato se inventa y
ningún paso de terminal se fabrica: si la API no da un paso o un
diff, esa parte no se muestra.

### 13.2 Archivo nuevo (1)

- `Views/JeslySessionCardView.swift` — `JeslySessionView` + porte
  verbatim de `PatchStats` (`JeslyPatchStats`/`JeslyPatchTicker`) y
  de los pasos (`JeslySessionStep`, `JeslyStepIcon`, `shortTime`
  HH:mm con los dos formateadores ISO8601 de la isla).
  Cromo de Coucou: `CardBackground(wash: nil)` como la tarjeta de
  sesión de Coucou, `PrimaryButton`/`SecondaryButton` verbatim,
  padding izquierdo 116 como `JeslyProposalView`.

### 13.3 Qué muestra la tarjeta y de dónde sale cada dato

- Cabecera "Sesión en vivo": punto hueso si `apiReachable`, gris si
  no; rama de la primera tarea activa ("rama X"); sin sesión:
  "Sin sesión activa" (API arriba) o "API local sin responder"
  (API apagada). Todo de las listas del poller.
- Contador de diff (archivo +N −M): del `patch` de la primera tarea
  con parche; cuenta líneas `+`/`-` sin las cabeceras `+++`/`---`;
  el archivo sale de la primera cabecera `+++` (o `---` si se borró).
- Pasos (máx. 4): aplicadas arriba con ✓, planificadas + en espera
  abajo con spinner; hora HH:mm de `updatedAt`. Sin tareas:
  "Nada en curso. Cuando un agente proponga algo, aparece aquí."
- Botones de la tarea en curso: sus `availableActions` (Aplicar /
  Ejecutar / Descartar / Revertir), primaria = primera no
  destructiva, por `store.act` con `shownId` capturado (igual que la
  sesión 2). Sin parche no hay contador de diff: no se inventa.

### 13.4 Cableado (3 archivos tocados)

- `CoucouKit/IslandTypes.swift`: caso nuevo `IslandView.jeslySession`
  (sin switch exhaustivo que romper; `IslandRootView` itera
  `allCases`; `HookServer.expandIfNeeded` y `VoiceWakeFilter` tienen
  `default`).
- `App/IslandViewContent.swift`: dispatch a `JeslySessionView()`.
- `JeslyIsland/JeslyProposalStore.swift`: `syncIsland` ahora elige
  por estado de `current` — esperando → `.jeslyProposal` (sesión 2,
  intacta); planificada/aplicada → `.jeslySession`. Puede cambiar
  entre las dos vistas JESLY cuando la isla está expandida; con la
  isla plegada abre con `.hookExpand` (el observador de
  `IslandWindowController` acepta cualquier `IslandView` como
  objeto, verificado). Cuando no queda nada, cierra las dos vistas.
  Cambio de comportamiento documentado: la rama planificada/aplicada
  de `JeslyProposalView` ya no se alcanza por `syncIsland` — sus
  botones viven ahora en la tarjeta de sesión. La tarjeta de
  permiso (Permitir/Denegar/Siempre) no cambia.

### 13.5 Verificación sin compilar (hecha)

- Balance llaves/paréntesis/corchetes **0** (scanner Swift-aware con
  interpolación) en los 4 archivos nuevos/tocados.
- Sin endpoint nuevo: grep — el archivo nuevo solo menciona en
  comentarios el endpoint de listas que ya existe; no hay
  `GET /v1/tasks/:id`, no hay pasos ni diffs hardcodeados.
- Sin hook en el camino de JESLY: solo menciones en comentarios y
  `.hookExpand` (el mecanismo legítimo de Coucou para abrir la isla,
  igual que la sesión 2).
- Sin colisión de nombres (`JeslySessionView`, `JeslyPatchTicker`,
  `JeslyPatchStats` no existen en Coucou). `project.yml` sin tocar
  (el glob `Sources` ya incluye `Sources/JeslyIsland/`).
- **No afirmo que compile** — solo la Mac lo confirma. Sospechosos
  si falla: el `switch` nuevo en `IslandViewContent`, el caso nuevo
  en `IslandTypes`, o el `syncIsland` reescrito del store.

### 13.6 Riesgos y límites conocidos

- Con la API apagada no aparece ninguna tarjeta nueva ni hay errores
  (mismo comportamiento que las sesiones 1–2).
- Si JC está en otra vista de la isla (chat, ajustes) cuando empieza
  una tarea, la tarjeta no se la roba: aparece en el siguiente
  sondeo (5 s) o al volver al home.
- Los pasos se derivan de las listas del poller, no de un log de
  ejecución: una tarea recién decidida puede verse un instante como
  "en curso" hasta el siguiente sondeo bueno (igual que la isla).
- La tarjeta no pone badge en la pill (sigue sin haber `AgentTask`
  de JESLY en `state.tasks`). Follow-up, no de esta sesión.
- Verificación/publicación (`POST /v1/tasks/:id/verify`, `/publish`)
  NO están en esta sesión: eso es Fase 4.

### 13.7 Para la Fase 4

- Verificación/publicación en la tarjeta (mapa A):
  `POST /v1/tasks/:id/verify` y `/publish`.
- Pill `jesly_chat` + proveedor `JeslyChatProvider` (mapa D);
  `ChatProvider` de Coucou sigue sin tocarse.
- Voz "Oye JESLY" (mapa E) y ojos (mapa C).

## §14. FASE 4, SESIÓN 1 — Verificar/Publicar + chat (proveedor y pill)

### 14.1 Qué se hizo

- `JeslyAPIClient`: `chat(message:provider:attachments:)` (porte
  verbatim de la isla, `POST /v1/chat`) + `verify(taskId:)` y
  `publish(taskId:)` nuevos.
- `JeslyModels`: `JeslyChatProvider` (porte verbatim del struct
  `ChatProvider` de la isla, renombrado — el enum de Coucou ya usa
  ese nombre) + `JeslyVerificationReport` /
  `JeslyVerificationCheck` / `JeslyPublishRecord`.
- `JeslyProposalStore`: `verify(task:)` y `publish(task:)`, con
  `lastVerification` / `lastPublish` publicados para la tarjeta.
- `JeslySessionView`: botones **Verificar** y **Publicar** solo
  cuando la tarea está en `aplicada`; el feedback muestra el
  resumen del informe o del registro.
- `PillCatalog`: pill `jesly_chat` (categoría `.ai`, color hueso
  `#E8E0D0`, `source: .agent`). `SettingsView` (hint de la fila):
  JESLY no pide clave — sin esa guarda pediría la de OpenAI.

### 14.2 Verificación/publicación: evidencia, no invento

- Los endpoints NO los usa el cliente de la isla actual, pero
  EXISTEN en el servidor del mismo repo, HEAD `3e2a59db`:
  `apps/api/src/routes/tasks.ts:779` (`POST /v1/tasks/:id/verify`)
  y `:868` (`POST /v1/tasks/:id/publish`); plan v2 §8/§9.
- Solo tareas en `aplicada` y kind `propuesta` (409 si no).
  `verify` exige `checks` no vacío (400 si falta): se mandan las
  comprobaciones locales por defecto del propio servidor
  (`publish.ts: defaultChecks`, caso sin cloud: health a
  `127.0.0.1:3000/health` y a `127.0.0.1:3003`). `publish` sin
  cuerpo usa los defaults del servidor, que detectan si el cambio
  toca `cloud/` y verifican contra lo desplegado.
- Un veredicto con fallos es 200, no excepción: `passed` false y
  la tarjeta muestra qué falló. `publish.status` es `publicada` /
  `parcial` / `fallida`, con `failedAt` (`push`/`deploy`/`verify`)
  y `error`. Nunca se fusiona a main.

### 14.3 El chat en esta sesión

- Transporte listo: `JeslyAPIClient.chat` + `JeslyChatProvider.all`
  (ollama-local, freellmapi, groq, gemini, openrouter) + pill
  `jesly_chat` en Ajustes → Active pills → "AI for the chat".
  Sin modelo fijo: el router elige y la respuesta trae el modelo
  real (`ChatResponse.model`), igual que la isla.
- Sin API no hay chat y no hay errores: el cliente lanza
  `serverUnreachable` y la vista de chat (sesión 2) lo muestra
  como "API local sin responder", igual que las tarjetas.
- La vista de chat con el selector de proveedor y el historial
  llega en la Fase 4, sesión 2. Esta sesión es el cimiento:
  proveedor + transporte + pill.

### 14.4 Verificación sin compilar (hecha)

- Balance llaves/paréntesis/corchetes **0** (scanner Swift-aware
  con interpolación anidada; la primera pasada dio falsos
  positivos por ternarios con strings dentro de `\(...)`, y la
  segunda con pila de estados los dejó en 0) en los 6 archivos
  nuevos/tocados.
- `verify`/`publish` usan el `task id` exacto (grep); un solo
  `enum ChatProvider` (Coucou) + un solo `struct
  JeslyChatProvider` (grep); pill `jesly_chat` en el catálogo
  (grep); sin hook en el camino de JESLY (solo comentarios).
- `project.yml` sin tocar en esta sesión.
- **No afirmo que compile** — solo la Mac lo confirma.
  Sospechosos si falla: los modelos nuevos con valores por defecto
  en `JeslyModels`, o los botones nuevos en `JeslySessionView`.

### 14.5 Riesgos y límites conocidos

- `verify` manda las comprobaciones locales por defecto: si la
  tarea toca `cloud/`, el botón correcto es Publicar (el servidor
  calcula solo las comprobaciones desplegadas). Verificar una
  tarea de cloud con checks locales puede dar verde en local y no
  decir nada de lo desplegado.
- La pill `jesly_chat` aún no abre ninguna vista de chat: eso es
  la sesión 2. Activarla solo la registra.
- Con la API apagada, Verificar/Publicar fallan con el mensaje
  "La API de JESLY no responde…", igual que el resto de acciones.
- Sin badge en la pill (sigue sin haber `AgentTask` de JESLY en
  `state.tasks`).

### 14.6 Para la Fase 4, sesión 2

- Vista de chat JESLY en la isla: selector de proveedor
  (`JeslyChatProvider.all`), historial, modelo real de la
  respuesta, entrada de texto; sin API, "API local sin responder".
- Voz "Oye JESLY" (mapa E) y ojos (mapa C) quedan para después.

## §15. FASE 4, SESIÓN 2 — Vista de chat JESLY (2026-11-27, local, SIN pushear, SIN compilar)

### 15.1 Qué se hizo

- Vista de chat `JeslyChatView` (`Views/JeslyChatView.swift`, nueva):
  selector de proveedor (chip que cicla), historial, entrada de
  texto y envío por `JeslyAPIClient.chat`. Cromo reutilizado de
  `PromptView` (fondo `CardBackground(wash: .indigo)`, lista con
  `ScrollViewReader` que baja sola, fila de entrada con
  `SendButtonStyle`, mismo padding); mensajes con el formato de la
  isla actual (`ChatView`, HEAD `3e2a59db`): "Tú" / "JESLY" y debajo
  de cada respuesta de JESLY el modelo REAL que respondió
  (`ChatResponse.model`, con el proveedor: "groq ·
  openai/gpt-oss-20b"), nunca uno inventado. Si la respuesta no trae
  modelo, la fila no muestra ninguno.
- Store `JeslyChatStore` (`JeslyChatStore.swift`, nuevo, singleton
  `@MainActor` como `JeslyProposalStore`): el historial vive ahí,
  no en la vista, para no perderse al cambiar de vista. `send`
  llama a `chat(message:provider:)` con el proveedor elegido
  (nil = Automático) y guarda proveedor y modelo reales de cada
  respuesta. El proveedor elegido persiste en UserDefaults
  (`com.jesly.island.chatProvider`).
- Apertura desde la pill `jesly_chat` por las dos vías de Coucou:
  botón "Chat with JESLY" en la tarjeta de la pill
  (`IntegrationCardView`, sin puerta de `isConfigured` — JESLY no
  pide clave) y la flecha ↗ (`openAgentTarget`: `case "jesly_chat":
  state.view = .jeslyChat`). Caso nuevo `IslandView.jeslyChat` +
  dispatch en `IslandViewContent`.
- La tarjeta de la pill ya no miente: `statusLabel` devuelve
  "Ready · no setup needed" para `jesly_chat` (antes caía en "Key
  not configured": `isConfigured` es false por defecto y
  `ChatProvider(pillID:)` es nil para esta pill).

### 15.2 Qué pasa con la API apagada

Sin errores en la interfaz. Antes del primer envío la vista dice
claro que la API no responde en 127.0.0.1:3000 y cómo arrancarla
(`scripts/arrancar-todo.sh`); si el envío falla, la respuesta es el
mensaje de la isla actual ("No pude hablar con la API. Revisa que
esté arrancada.") y el motivo queda en `lastError` bajo la entrada.

### 15.3 Qué NO se hizo en esta sesión

- Sin zona para soltar archivos (ojos, mapa C) ni micrófono (voz,
  mapa E): la vista no manda adjuntos. Sin workflows ni
  habilidades (Fase 5). Sin tocar bundle id, entitlements,
  `HookServer`, `PillCatalog` ni `project.pbxproj`.
- Las tarjetas de Propuesta/Permiso y Sesión en vivo quedan
  intactas: `syncIsland` no roba la vista de chat (`.jeslyChat` no
  está en su lista de vistas que puede reemplazar) y solo cierra
  `.jeslyProposal`/`.jeslySession`.

### 15.4 Verificación sin compilar (hecha)

- Balance llaves/paréntesis/corchetes **0** en los 5 archivos
  nuevos/tocados (escáner por líneas; la primera pasada dio un
  falso +1 por la interpolación anidada
  `"\(... "\(provider) · \(model)")"` y el trazado por línea lo
  dejó en 0; el HEAD sin tocar da el mismo artefacto en los
  archivos grandes, así que se comparó contra el HEAD).
- El chat usa `JeslyChatProvider` (grep): ningún uso del
  `ChatProvider` de Coucou en el camino de JESLY; un solo `enum
  ChatProvider` en todo el módulo. Sin respuestas hardcodeadas
  (grep: sin TODO/lorem; el único texto de error es el de la isla
  actual, que se muestra como mensaje, no como respuesta
  inventada).
- `project.yml` sin tocar en esta sesión.
- **No afirmo que compile** — solo la Mac lo confirma.
  Sospechosos si falla: `JeslyChatView` (usa `CardBackground`,
  `TypingDotsView` y `SendButtonStyle` de Coucou, como
  `PromptView`) o el `switch` nuevo en `IslandViewContent`.

### 15.5 Riesgos y límites conocidos

- El historial de chat no persiste entre arranques (solo vive en
  el store en memoria, como el de Coucou).
- Sin badge en la pill (sigue sin haber `AgentTask` de JESLY en
  `state.tasks`): con la isla en otra vista, un mensaje nuevo no
  avisa.
- La vista no roba otras vistas de la isla: si JC está en ajustes
  o en una tarjeta, el chat se abre solo al tocar la pill.

### 15.6 Para la Fase 4, sesión 3

- Voz "Oye JESLY" (mapa E: demonio Vosk + `GET
  /v1/voice/wake/status` + modo voz con interrupción) y ojos
  (mapa C: soltar archivo → `POST /v1/chat` con attachments).

## §16. FASE 4, SESIÓN 3 — Voz "Oye JESLY" + ojos (2026-11-27, local, SIN pushear, SIN compilar)

### 16.1 El endpoint de wake SÍ existe (con evidencia)

- `GET /v1/voice/wake/status` existe en el servidor, HEAD
  `3e2a59db`: `apps/api/src/routes/voice.ts:57` → `getWakeStatus`
  (`apps/api/src/voice/wake.ts`). El demonio vive aparte
  (`services/wake-word/daemon.py`, Vosk local) y expone su estado
  en `127.0.0.1:3004/status`, con timeout de 2 s. Respuesta:
  `{listening, state: "listening"|"heard"|"thinking"|"speaking"|
  "stopped"|null, engine: "vosk"|"openwakeword"|null,
  uptimeSeconds, wakeCount, error}`. Demonio caído = listening
  false con 200, nunca 500.
- El demonio hace el ciclo completo DEL LADO DEL SERVIDOR
  (`services/wake-word/cycle.py`: STT → chat → TTS) cuando oye
  "Oye JESLY". La app NO graba cuando el demonio oye la frase:
  eso lo hace el demonio solo. La app solo sondea el estado cada
  5 s (`JeslyVoiceStore`, igual que `IslandStore.refreshWake` en
  la isla) y lo muestra. Sin demonio ni API, "Escucha en pausa".

### 16.2 Archivos nuevos/cambiados

- NUEVO `JeslyIsland/Voice/VoiceTalker.swift`: porte verbatim de
  la isla actual (grabar 16 kHz mono → `POST /v1/voice/transcribe`
  multipart → `POST /v1/chat` → `POST /v1/voice/synthesize`,
  recortado a 1800 caracteres → reproducir WAV). `interrupt()`
  corta la voz y la grabación a la vez. El audio vive solo en
  memoria y se descarta. Sin sonidos de Mochi: la nube no suena
  (decisión JC); aquí solo suena la voz sintetizada de JESLY.
- NUEVO `JeslyIsland/JeslyVoiceStore.swift`: singleton `@MainActor`
  que sondea `wakeStatus` cada 5 s (`.down` por defecto) y es dueño
  del `VoiceTalker`. Se arranca en `AppDelegate.setupIsland`.
- `Api/JeslyAPIClient.swift`: `wakeStatus()`, `transcribe()` y
  `synthesize()` (porte verbatim del cliente de la isla actual).
- `CoucouKit/PillCatalog.swift`: pill `jesly_voz` (categoría
  `.agent`, color hueso `#E8E0D0`, `source: .agent`). Los ojos NO
  tienen pill: son la zona de soltar archivos del chat, como en
  la isla actual.
- `JeslyIsland/JeslyChatStore.swift`: `send(_:attachments:)` y
  `visionBadge` ("Vio: proveedor / modelo") en el mensaje;
  `appendVoiceExchange` mete el intercambio de voz en el
  historial (sin modelo: el talker solo guarda el texto).
- `JeslyIsland/Views/JeslyChatView.swift`: indicador del demonio
  (punto hueso + "Oye JESLY" + `WakeStatus.displayText`), botón
  del micrófono (micrófono / grabando en hueso / ■ para
  interrumpir / spinner pensando), zona de soltar archivos con
  borde punteado + fila de adjuntos + avisos, `.onDrop(of:
  [.image, .movie])` en toda la vista.
- `App/AppDelegate.swift`: `JeslyVoiceStore.shared.start()` junto
  al poller de propuestas.

### 16.3 Cómo se activa la voz y cómo se interrumpe

- Siempre activa (demonio): decir "Oye JESLY" en voz alta; el
  demonio responde solo por el altavoz. La isla solo muestra el
  estado ("Te escuchó — pensando…", "Hablando…").
- Manual (micrófono en el chat): tocar el micrófono → graba;
  tocarlo de nuevo → transcribe, pregunta y habla. Mientras
  JESLY habla, tocar ■ la interrumpe en mitad de la frase. Si
  falla, el motivo claro queda en la línea de estado, nunca un
  error que rompa la interfaz.
- El permiso de micrófono ya existe en el fork
  (`project.yml`: `NSMicrophoneUsageDescription` en 3 targets);
  lo pide macOS al empezar a grabar, igual que el dictado Flow.
  Sin permisos nuevos.

### 16.4 Cómo se suelta un archivo y qué formato lleva

- Arrastrar una imagen o un video a la vista de chat (o a la
  zona punteada): se ve en la fila de adjuntos y se manda con el
  mensaje por `POST /v1/chat` con `attachments: [{kind,
  mediaType, data(base64)}]`, formato exacto de la isla actual.
  Límites del servidor, validados antes de enviar: imágenes
  10 MB, videos 50 MB, máx. 4 adjuntos y 1 video por mensaje.
  Sin texto, el mensaje es "Mira este adjunto y dime qué ves.".
  La respuesta muestra "Vio: proveedor / modelo" debajo.

### 16.5 Qué pasa con la API apagada

Nada nuevo y sin errores, mismo comportamiento que las sesiones
anteriores: el sondeo deja el estado en `.down` ("Escucha en
pausa"), el micrófono muestra el motivo claro al intentar grabar
y los adjuntos fallan con el mensaje de error de la isla actual.

### 16.6 Verificación sin compilar (hecha)

- Balance llaves/paréntesis/corchetes 0 (escáner Swift-aware con
  interpolación) en los archivos nuevos/tocados; la voz usa el
  endpoint real de la isla (`GET /v1/voice/wake/status`, grep) y
  los adjuntos el formato real de `POST /v1/chat` (grep).
- `project.yml` sin tocar en esta sesión. **No afirmo que
  compile** — solo la Mac lo confirma. Sospechosos si falla:
  `VoiceTalker` (AVFoundation) o `JeslyChatView` (UTType, drop).

### 16.7 Riesgos y límites conocidos

- El demonio Vosk corre fuera de la app: si no está arrancado
  (`services/wake-word/`), la escucha siempre activa no existe y
  la isla solo muestra "Escucha en pausa". La app no arranca el
  demonio.
- El intercambio de voz queda en el historial sin modelo (el
  talker no lo guarda); el chat escrito sí muestra el modelo real.
- El historial no persiste entre arranques. Sin badge en la pill.
- Sin workflows ni habilidades (Fase 5).

### 16.8 Para la Fase 5

Workflows, habilidades y recordatorios (mapas B y F); decidir qué
pills de Coucou quedan (Flow, Mail, música, WhatsApp, demo,
semanal).

## §17. FASE 5, SESIÓN 1 — Workflows, habilidades y recordatorios

### 17.1 Qué se hizo

- Cliente: `workflows()`, `runWorkflow(id:)`, `setWorkflowEnabled(id:enabled:)`,
  `deleteWorkflow(id:)`; `skills()`, `testSkill/approveSkill/rejectSkill/uninstallSkill(id:)`;
  `reminders()`, `createReminder(text:)`, `silenceReminder(id:)`, `deleteReminder(id:)`.
  Se añadió el helper `sendVoid` (rutas sin cuerpo útil), porte verbatim de la isla.
- Modelo nuevo `JeslyReminder` (forma exacta de `ReminderView` en
  `personal/reminders.ts`); los comentarios "sin uso" de `JeslyWorkflow`/`JeslySkill`
  pasan a Fase 5.
- Store nuevo `JeslyWorkflowsStore` (singleton `@MainActor`, sondeo cada 15 s como la
  isla, best-effort) + `JeslySkillAction`.
- Vistas nuevas `JeslyWorkflowsView`, `JeslySkillsView`, `JeslyRemindersView`, porte de
  `WorkflowsSkillsViews.swift` de la isla (la de recordatorios sigue su mismo estilo;
  la isla no tiene vista propia de recordatorios, llegan por chat).
- Ajustes → JESLY: tres GroupBox nuevos (Workflows, Habilidades, Recordatorios) tras
  las reglas "Siempre". Arranque en `AppDelegate.setupIsland`.
- **Corrección tras la verificación de JC (2026-11-27 19:01 AST):** la fila JESLY
  solo existía en la ventana de Ajustes suelta; en el Flow window (`FlowHub`),
  que es el que JC usa, `HubPage` no tenía caso `jesly` y la sección era
  inalcanzable. Se añadió el caso `jesly` (`FlowHub.swift`: enum, `notchPages`
  tras `.agents`, `settingsSection` → "jesly", título "JESLY", `cloud.fill`) y
  su color hueso `#E8E0D0` en `HubHeroTheme.of` (`FlowHubMochis.swift`, switch
  exhaustivo). La fila JESLY aparece ahora en el menú NOTCH del Flow window,
  entre Agentes y Chat.

### 17.2 Endpoints (todos existen, con evidencia)

- Workflows (`routes/workflows.ts`, HEAD `3e2a59db`): `GET /v1/workflows`,
  `POST /v1/workflows/:id/run` (202), `PATCH /v1/workflows/:id { enabled }`,
  `DELETE /v1/workflows/:id`.
- Habilidades (`routes/skills.ts`): `GET /v1/skills`,
  `POST /v1/skills/:id/test|approve|reject|uninstall`. Instalar desde manifiesto es
  follow-up: `POST /v1/skills/install` existe, pero la isla aún no sube manifiestos.
- Recordatorios (`routes/reminders.ts`): `POST /v1/reminders { text }` → 201
  `{ reminder, confirmation, push_configured }`, `GET /v1/reminders`,
  `POST /v1/reminders/:id/silence`, `DELETE /v1/reminders/:id`.

### 17.3 Qué se ve y dónde

- Ajustes → JESLY → "JESLY — Workflows": nombre + horario, Ejecutar / Pausar-Reanudar /
  Borrar. Ejecutar crea una tarea: su progreso se ve en la tarjeta de sesión en vivo.
- "JESLY — Habilidades": nombre + estado + versión + descripción; Probar (en_revision o
  instalada), Aprobar/Rechazar (en_revision), Desinstalar (instalada).
- "JESLY — Recordatorios": campo en lenguaje natural + Crear; cada uno con fecha, estado
  (pendiente/disparado/silenciado), Hecho y Borrar. La confirmación del último creado
  muestra fecha y hora completas.
- Con la API apagada las tres listas quedan vacías y se muestra el motivo, sin errores.

### 17.4 Hallazgo: no hay endpoint "hecho"

Un recordatorio ES un workflow programado de un solo disparo con el marcador
`[recordatorio]`; silenciarlo desactiva el workflow para que no suene más. Por eso el
botón "Hecho" llama a `POST /v1/reminders/:id/silence`. No se inventó otra ruta.

### 17.5 Verificación sin compilar (hecha)

- Balance llaves/paréntesis/corchetes 0 (escáner Swift-aware con interpolación) en los
  6 archivos nuevos/tocados.
- Cada endpoint usado existe en la isla actual y en el servidor (grep contra el cliente
  de la isla y contra `routes/workflows.ts`, `routes/skills.ts`, `routes/reminders.ts`).
- Sin colisión de nombres (`JeslyWorkflowsStore`, `JeslyWorkflowsView`, `JeslySkillsView`,
  `JeslyRemindersView`, `JeslyReminder`, `JeslySkillAction`).
- `project.yml` sin tocar en esta sesión. **No afirmo que compile** — solo la Mac lo
  confirma. Sospechosos si falla: `JeslyWorkflowsSkillsViews.swift` o el store nuevo.

### 17.6 Riesgos y límites conocidos

- Las tres listas se refrescan cada 15 s; un run recién lanzado tarda un sondeo en
  aparecer como tarea en curso (igual que la isla).
- El historial de recordatorios disparados/silenciados se lista igual que los
  pendientes: la API no filtra por estado.
- Sin badge en la pill. Sin instalar habilidades desde manifiesto (follow-up).
- La decisión de qué pills de Coucou quedan (Flow, Mail, música, WhatsApp, demo,
  semanal) NO se tomó en esta sesión: va con JC después.

### 17.7 Para la Fase 5, sesión 2

Decidir con JC qué pills de Coucou quedan y quitar o dejar las demás; investigación
profunda (`POST /v1/investigar`) y cuentas conectadas (mapa F resto); resumen diario.

## §18. FASE 5, SESIÓN 2 — Investigación profunda, cuentas conectadas, resumen diario

### 18.1 Qué se hizo

- **Investigación profunda** (desde el chat de JESLY): botón de lupa junto
  al micrófono que activa el modo investigar; el envío va por
  `POST /v1/investigar` en vez de por el chat (con adjuntos no hay
  investigación: cae al chat normal). La isla actual no tiene este
  botón: su agente investiga con la herramienta interna
  (`investigar_profundo`); aquí la investigación se pide explícita
  y el informe llega con sus fuentes como enlaces que se pueden abrir.
  Mientras investiga se ve "Investigando en la web… puede tardar unos
  segundos." (tarda más que un chat: varias búsquedas + descarga de
  páginas). Modelos nuevos `JeslyResearchResult`, `JeslyResearchSource`,
  `JeslyFailedPage`; el mensaje de chat guarda el informe entero
  (`JeslyChatMessage.research`).
- **Cuentas conectadas** (solo lectura): GroupBox nuevo "JESLY — Cuentas
  conectadas" en Ajustes → JESLY (proveedor, cuenta, scopes, expira).
  Sin cuentas, el texto dice que se conectan desde el servidor.
  Conectar no se hace desde la isla: Google es OAuth con redirect y
  GitHub pide un token fine-grained de solo lectura.
- **Resumen diario**: GroupBox nuevo "JESLY — Resumen diario" en
  Ajustes → JESLY. Vista previa con "Ver el de hoy" (texto compuesto
  + contadores + fuentes sin leer), programar por hora ("8:00") y
  Apagar. El resumen programado ES un workflow ("Resumen diario —
  buenos días", marcador `[resumen-diario]`): su hora se deriva de
  la lista de workflows (cron `M H * * *`), nunca se inventa.
- Store `JeslyWorkflowsStore`: `accounts`, `dailyDigest`, `digestHour`
  + `refreshAccounts()` / `refreshDailyDigest()` en el sondeo de 15 s
  y acciones `scheduleDailyDigest(hour:)` / `deleteDailyDigest()`.

### 18.2 Endpoints (todos existen, con evidencia)

Montados en `apps/api/src/index.ts` (digest :153, investigar :158,
cuentas :160), HEAD del scaffold = isla actual:

- Investigación (`routes/investigar.ts`): `POST /v1/investigar
  { pregunta, provider? }` → 200 `{ respuesta, fuentes: [{ titulo,
  url, fecha, fechaPublicacion, verificada, fragmento }],
  fechaConsulta, consultas, paginasFallidas, fuente, provider?,
  model? }`. 400 sin pregunta o >1000 caracteres; 503 sin acceso a
  la web (nunca una respuesta inventada). `fuente` es "modelo" (el
  router sintetizó) o "extractiva" (sin router o el modelo falló).
  `MAX_PAGES = 8` (`research/deep-research.ts`).
- Cuentas (`routes/cuentas.ts`): `GET /v1/cuentas` → `{ cuentas }`
  (`accounts/store.ts`: `PublicAccount`: proveedor, cuenta, scopes,
  expira, conectado, actualizado; sin tokens). Sin cuentas, lista
  vacía; sin base de datos, 503. Conectar/desconectar quedan fuera
  de esta sesión por decisión (no por falta de endpoint: existen
  `POST /v1/cuentas/:proveedor/conectar|desconectar`).
- Resumen (`routes/digest.ts`): `GET /v1/resumen-diario` →
  `{ digest, propuestas, pendientes, workflows_hoy, recuerdos,
  errores }`; `POST /v1/resumen-diario { hora }` → 201/200
  `{ workflow, hora, push_configured }` (crea o actualiza el
  workflow "Resumen diario — buenos días", `DIGEST_WORKFLOW_NAME`);
  `DELETE /v1/resumen-diario` → `{ deleted: true }` (404 si no hay
  ninguno). 400 sin hora o con formato distinto de HH:MM; 503 sin
  base de datos.

### 18.3 Dónde se ve y qué pasa con la API apagada

- Chat de JESLY (isla): lupa junto al micrófono; con el modo activo
  el campo dice "Investiga en la web…". La respuesta trae el informe
  en formato fijo + la línea "Investigación · modelo/extractiva ·
  N fuentes · M verificadas · YYYY-MM-DD" + cada fuente como enlace
  (✓ verificada / ! no verificada) + cuántas páginas no se pudieron
  leer. Sin modelo (extractiva) no hay línea de modelo, como en el
  chat normal. Sin API: "No pude investigar. La API de JESLY no
  responde…" como mensaje de JESLY, sin romper la interfaz.
- Ajustes → JESLY: "JESLY — Cuentas conectadas" y "JESLY — Resumen
  diario" tras "JESLY — Recordatorios". Con la API apagada las dos
  secciones muestran el motivo, sin errores; el resumen programado
  no muestra hora (no hay workflow en la lista).

### 18.4 Inventario de pills de Coucou en el fork (para decidir con JC)

Fuente única: `PillCatalog.all` (`CoucouKit/PillCatalog.swift`), 33
pills. **Fase 5, sesión 3 (2026-11-27): las 24 marcadas "Quitar"
se quitaron del catálogo y de todo sitio que las referenciaba;
quedan 9 pills: 3 de JESLY + 6 condicionales, pendientes de la
confirmación de JC.**
"Equivalente JESLY" es lo que la isla actual ya tiene (su propio
`PillCatalog.swift` en `apps/island`). Las pills de servicio de
Coucou se alimentan por n8n: sin feed configurado no muestran nada.

| Pill | Qué hace | Equivalente JESLY | Recomendación |
|---|---|---|---|
| VS Code (`integration_claude`) | Vigila sesiones de Claude Code en VS Code | No (JESLY no vigila terminales) | Quedarse solo si JC usa Claude Code en VS Code |
| Cursor (`agent_cursor`) | Vigila sesiones de Cursor | No | Quedarse solo si JC usa Cursor |
| Antigravity (`agent_antigravity`) | Vigila sesiones de Antigravity | No | Quitada en Fase 5 sesión 3 (2026-11-27) — quitar (JC no lo usa) |
| Codex (`agent_codex`) | Vigila sesiones de Codex | No | Quedarse solo si JC usa Codex |
| Gemini CLI (`agent_gemini`) | Vigila sesiones de Gemini CLI | No | Quedarse solo si JC lo usa |
| Copilot CLI (`agent_copilot`) | Vigila sesiones de Copilot | No | Quitada en Fase 5 sesión 3 (2026-11-27) — quitar |
| Muse Code (`agent_muse`) | Vigila sesiones de Muse | No | Quitada en Fase 5 sesión 3 (2026-11-27) — quitar |
| OpenCode (`agent_opencode`) | Vigila sesiones de OpenCode | No | Quitada en Fase 5 sesión 3 (2026-11-27) — quitar |
| Amp (`agent_amp`) | Vigila sesiones de Amp | No | Quitada en Fase 5 sesión 3 (2026-11-27) — quitar |
| Hermes (`agent_hermes`) | Vigila sesiones de Hermes | No | Quitada en Fase 5 sesión 3 (2026-11-27) — quitar |
| Claude Desktop (`agent_claude-desktop`) | Sesiones de la app Claude Desktop | No (el cerebro de JESLY es FreeLLMAPI/Ollama/Groq/Gemini/OpenRouter por la API) | Quitada en Fase 5 sesión 3 (2026-11-27) — quitar |
| JESLY (`jesly_propuestas`) | Propuestas esperando aprobación | Sí, es JESLY | **Quedarse** |
| JESLY Voz (`jesly_voz`) | Estado "Oye JESLY" + micrófono | Sí, es JESLY | **Quedarse** |
| Anthropic (`ai_anthropic`) | Chat directo con Anthropic | Sí: JESLY Chat (router por la API) | Quitada en Fase 5 sesión 3 (2026-11-27) — quitar (el cerebro ya cubre; evita llaves que JESLY no necesita) |
| Google AI (`ai_google`) | Chat directo con Google AI | Sí: JESLY Chat (Gemini entra por el router) | Quitada en Fase 5 sesión 3 (2026-11-27) — quitar |
| OpenAI (`ai_openai`) | Chat directo con OpenAI | Sí: JESLY Chat | Quitada en Fase 5 sesión 3 (2026-11-27) — quitar |
| Ollama (`ai_ollama`) | Chat directo con Ollama local | Sí: JESLY Chat (ollama-local es proveedor del router) | Quitada en Fase 5 sesión 3 (2026-11-27) — quitar |
| LM Studio (`ai_lmstudio`) | Chat directo con LM Studio | Sí: JESLY Chat | Quitada en Fase 5 sesión 3 (2026-11-27) — quitar |
| JESLY Chat (`jesly_chat`) | Chat con JESLY por la API | Sí, es JESLY | **Quedarse** |
| Resend (`integration_resend`) | Email transaccional | No | Quitada en Fase 5 sesión 3 (2026-11-27) — quitar (JC no lo usa; la API no lo expone) |
| n8n (`integration_n8n`) | Estado de n8n | No | Quitada en Fase 5 sesión 3 (2026-11-27) — quitar, salvo que quede alguna pill alimentada por n8n |
| Vercel (`integration_vercel`) | Estado de deploys en Vercel | No (la isla lo tiene "próximamente") | Quedarse solo si se cablea el feed de n8n; si no, es adorno |
| GitHub (`integration_github`) | Estado de GitHub | Parcial: cuentas conectadas (PRs y build por la API) | Quedarse solo si se cablea el feed; el resto ya lo da Cuentas conectadas |
| Notion (`integration_notion`) | Estado de Notion | No | Quitada en Fase 5 sesión 3 (2026-11-27) — quitar |
| Cal.com (`integration_calcom`) | Estado de Cal.com | No | Quitada en Fase 5 sesión 3 (2026-11-27) — quitar |
| Stripe (`integration_stripe`) | Estado de Stripe | No | Quitada en Fase 5 sesión 3 (2026-11-27) — quitar |
| Apple Music (`integration_music`) | Música en la isla (Mochi bailaba) | No (la nube no baila ni suena) | Quitada en Fase 5 sesión 3 (2026-11-27) — quitar |
| Spotify (`integration_spotify`) | Música en la isla | No | Quitada en Fase 5 sesión 3 (2026-11-27) — quitar |
| Mail (`integration_mail`) | Agente de correo (buscar, leer, responder, reglas) | Parcial: cuentas conectadas leen Gmail | Quitada en Fase 5 sesión 3 (2026-11-27) — quitar por ahora: responder y reglas duplican lo que JESLY ya lee por la API y piden su propia configuración; se revisita si JC quiere responder correo desde la isla |
| WhatsApp (`integration_whatsapp`) | WhatsApp en la isla (gateway GOWA local) | No (la isla lo tiene "próximamente — bot §16") | Quitada en Fase 5 sesión 3 (2026-11-27) — quitar (pide un gateway local que JC no corre) |
| Crypto (`integration_crypto`) | Portfolio cripto | No | Quitada en Fase 5 sesión 3 (2026-11-27) — quitar |
| Coucoudoro (`integration_coucoudoro`) | Temporizador trabajo/descanso local | No | Quitada en Fase 5 sesión 3 (2026-11-27) — quitar (extra local sin coste, pero fuera del producto) |
| Portfolio (`integration_portfolio`) | Portfolio de inversiones | No | Quitada en Fase 5 sesión 3 (2026-11-27) — quitar |

Resumen del inventario tras la Fase 5, sesión 3: quedan 3
incondicionales (las de JESLY) + 6 condicionales (VS Code, Cursor,
Codex, Gemini CLI si JC los usa; GitHub y Vercel si se cablea su
feed) y se quitaron 24. Las pills de agente solo muestran sesiones
si los hooks están instalados, y eso es Fase 6 (conflicto de hooks:
solo una app dueña de `~/.claude/settings.json`).

**No son pills** (features aparte, no están en `PillCatalog`):

- **Flow** (Dictado, Notetaker, Estadísticas, Diccionario,
  Fragmentos, Estilos): páginas del Flow window. Dictado:
  quedarse (dictar en cualquier app, offline con Parakeet; distinto
  del modo voz de JESLY, que es chat por voz). Notetaker: decidir
  con JC (graba llamadas, pide micro). El resto son utilidades
  locales sin coste: quedarse.
- **Modo demo** (`DemoEngine`): recorrido guionado, nada en disco.
  Quitar del producto final (JC ya conoce la app); útil solo para
  enseñarla.
- **Resumen semanal** (lunes, imagen para compartir): no se porta;
  lo sustituye el resumen diario de JESLY (esta sesión).

### 18.5 Verificación sin compilar (hecha)

- Balance llaves/paréntesis/corchetes 0 (escáner Swift-aware con
  interpolación) en los 7 archivos nuevos/tocados.
- Cada endpoint usado existe en el servidor y está montado
  (`apps/api/src/index.ts`: digest :153, investigar :158, cuentas
  :160); las formas de respuesta se verificaron contra
  `routes/investigar.ts`, `routes/cuentas.ts`, `routes/digest.ts`,
  `research/deep-research.ts` y `accounts/store.ts`.
- Sin colisión de nombres (todos los tipos `Jesly*` nuevos aparecen
  solo en definición + uso; `researchButton`, `sendResearch`,
  `digestHour` sin choques con Coucou).
- `project.yml` sin tocar en esta sesión. **No afirmo que compile**
  — solo la Mac lo confirma. Sospechosos si falla:
  `Views/JeslyChatView.swift` (enlaces de fuentes, botón de
  investigar) o `Views/JeslyWorkflowsSkillsViews.swift` (vistas
  nuevas de cuentas y resumen).

### 18.6 Riesgos y límites conocidos

- La investigación tarda: varias búsquedas + descarga de páginas;
  la vista lo dice mientras espera, pero no hay cancelación (el
  `POST` sigue hasta responder o fallar).
- Preguntas de más de 1000 caracteres fallan con 400 del servidor;
  la vista no recorta ni avisa antes de enviar.
- El resumen diario se refresca cada 15 s con el resto de Ajustes
  → JESLY; es una consulta barata a Postgres, no un agente.
- Conectar una cuenta (OAuth de Google, token de GitHub) sigue sin
  UI: es trabajo de servidor, no de esta sesión.
- La decisión de pills se tomó y se aplicó en la sesión 3: las 24
  se quitaron; las 6 condicionales quedan pendientes de la
  confirmación de JC (¿usa Claude Code en VS Code, Cursor, Codex,
  Gemini CLI? ¿se cablea el feed de GitHub/Vercel por n8n?).

### 18.7 Hecho en la Fase 5, sesión 3 (2026-11-27)

Las 24 pills se quitaron del catálogo (`PillCatalog.all` pasa de 33
a 9) y de todo sitio que las referenciaba: activas por defecto,
ajustes (GroupBoxes de hooks, hints, Coucoudoro, búsqueda),
`IslandViewContent` (tarjetas, botones, `openAgentTarget`,
`statusDot`/`statusLabel`, `isHooks`), `HookServer` (ruta de
permisos y `validateAgent` rechazan los agentes quitados; la rama
`agy_pre_tool` responde "ask" sin tarjeta; borrados
`agyApprovalGate` y `processAgyApproval`), controladores (sin
maquinaria de pill; Mail sigue sondeando mientras Mail corre, para
las páginas del Flow window; Música/Spotify siguen el seguimiento
para la voz; Crypto/Portfolio quedan sin sondeo en vivo) y
`ServiceDetailRunner`/`ServicePublisher` (solo quedan
Vercel/GitHub). Borrados 9 archivos exclusivos de pills quitadas:
`StripePoller`, `CalcomPoller`, `NotionPoller`, `ResendPoller`,
`ClaudeDesktopChatWatcher`, `CoucoudoroEngine`,
`CoucoudoroController`, `CoucoudoroViews`,
`Tests/CoucoudoroEngineTests`. Verificación sin compilar: balance
0 en los 28 archivos tocados; grep final con 0 hits de los 24 ids
en `Sources` y `Tests` (salvo este documento, que es la
especificación); las 3 de JESLY y las 6 condicionales siguen
presentes. **Sin compilar: solo la Mac lo confirma.**

### 18.8 Para la Fase 6

Verificación en vivo de la sesión 3 en la Mac de JC (pull +
`xcodegen` + build); conectar cuentas desde la isla si JC lo pide
(OAuth Google / token GitHub); conflicto de hooks (solo una app
dueña de `~/.claude/settings.json`; no instalar los hooks de
Coucou hasta entonces). Pendientes sueltos: quitar el paso
"Wardrobe tests" de `.github/workflows/build.yml` en el remoto
(la App de GitHub no puede, 403); responder las 3 decisiones de
`PRODUCT_NAME`/bundle id (firmado, CloudKit, nombre del `.app`);
los instaladores de hooks de los agentes quitados siguen en el
código como funciones sin uso desde Ajustes (limpieza posterior);
`AgyPermissionRules` queda sin uso tras borrar `agyApprovalGate`.

## §19. FASE 6, SESIÓN 1 — Plan de verificación en vivo + conflicto de hooks

### 19.1 El conflicto de hooks: hallazgos (medidos, no supuestos)

1. **La isla actual de JESLY NO instala hooks.** Búsqueda en todo
   `jeslyagent/Jesly-agent-ai` (HEAD de trabajo, conector GitHub):
   0 referencias a `settings.json`, a `.claude`, a `nb-hook` y a
   `claude` en `apps/island/`. La isla solo habla con su API por
   HTTP. **No hay conflicto fork ↔ isla actual.** Las dos pueden
   correr a la vez: comparten la API (`127.0.0.1:3000`) y la clave
   del llavero (`com.jesly.island`, la misma, solo lectura), y ven
   las mismas propuestas. Dos matices: las reglas "Siempre" son por
   app (UserDefaults distintos por bundle id), así que una regla
   creada en el fork no auto-aprueba en la isla y viceversa; y si
   las dos están abiertas, conviene actuar solo en una para no
   confundirse (aprobar en una se refleja en la otra en el sondeo
   de 5 s).
2. **El conflicto real es fork ↔ Coucou original.** El fork todavía
   usa las rutas EXACTAS de upstream (renombre aplazado, ver
   FORK-NOTAS.md): support dir `Application Support/NotchBuddy`,
   socket `nb.sock`, script `nb-hook`, entradas en
   `~/.claude/settings.json` (+ `~/.gemini/settings.json` y
   `~/.config/muse/settings.json`). Tres mecanismos silenciosos:
   - **Robo de socket al arrancar.** `HookServer.start()` llama a
     `installHookScript()` y `serverThread()` hace `removeItem` del
     socket y vuelve a enlazarlo. La última app que arranca se queda
     con TODOS los eventos de Claude Code y la otra queda ciega, sin
     ningún aviso.
   - **Reescritura del script en cada arranque.** `start()` escribe
     `nb-hook` + `nb-hook.py` en el support dir compartido. Si el
     relay embebido del fork diverge alguna vez del de upstream, las
     dos apps se pisan el script en cada arranque.
   - **`settings.json` no distingue dueña.** El fork y Coucou
     original escriben el mismo comando nb-hook; `claudeHooksInstalled()`
     devuelve true para cualquiera de las dos. Instalar desde el fork
     con los hooks de Coucou puestos es un no-op en el archivo, pero
     el socket pasa al fork al arrancar.
3. **Las funciones de JESLY no necesitan hooks.** Propuestas, chat,
   voz, ojos, workflows, habilidades, recordatorios, investigación,
   cuentas y resumen van por la API, nunca por nb-hook. Los hooks
   solo alimentan las pills de sesiones CLI (VS Code, Cursor,
   Codex, Gemini CLI). Sin hooks instalados, JESLY funciona
   completo y las pills CLI simplemente no ven sesiones.

### 19.2 Solución propuesta (decisión de JC)

- **A. Recomendada: hooks APAGADOS por defecto en el fork.** No
  instalar los hooks de Claude (ni Gemini/Codex) hasta que JC
  confirme que vigila sesiones de terminal en el fork. JESLY
  funciona completo sin ellos. Si un día los quiere, los instala
  desde Ajustes → Agents con la guarda de abajo, cerrando antes
  Coucou original.
- **B. Renombrar las rutas a `jesly-*` (sesión posterior).**
  `jesly-hook`, `jesly.sock`, `~/.claude/jesly/`, support dir
  `JeslyIsland`. Entonces fork y Coucou podrían coexistir como
  dueños distintos — PERO Claude Code dispararía AMBOS hooks por
  evento (dos entradas en `settings.json`) y un permiso podría
  responderse dos veces o en carrera. No se recomienda sin probarlo;
  la regla de una sola dueña seguiría mandando.
- **C. Traspaso explícito.** "Hacerse dueña" desde la alerta de
  instalación: se instalan los hooks del fork y se cierra la otra
  app. Es la opción A con el fork como dueña.

**Lo implementado en esta sesión (sin instalar ningún hook):**
- Guarda del socket en `HookServer.serverThread()`: antes de borrar
  y enlazar `nb.sock`, sondea si un servidor vivo ya responde; si
  responde, NO toma el socket (log + marca en UserDefaults
  `jeslySocketTakenByOtherApp`, que se limpia en cada arranque).
  Un archivo huérfano (dueño caído) rechaza la conexión y se sigue
  el camino de siempre.
- Alerta al instalar en `SettingsView.installHooks()`: si
  `settings.json` ya tiene entradas nb-hook y no las instaló este
  fork (marca propia `jeslyForkHooksInstalled`, que se pone al
  instalar y se quita al desinstalar), muestra la alerta "Los hooks
  ya tienen dueña" con las dos opciones (Mantener la otra app /
  Hacerse dueña). Sin la marca no se puede distinguir por contenido.
- Aviso visible en Ajustes → Agents (sección Claude): si al
  arrancar el socket ya lo tenía otra app, muestra que este fork no
  ve las sesiones de Claude Code y que hay que cerrar la otra app y
  reiniciar el fork. Sin este aviso la pill diría "instalado" y no
  llegaría ningún evento.
- Archivos: `App/HookServer.swift` (guarda + marca),
  `App/SettingsView.swift` (alerta + aviso + marca de dueña).
  Verificación sin compilar: balance 0 en los 2 (escáner
  Swift-aware; el -6 de paréntesis de `HookServer.swift` es ruido
  del escáner, idéntico en el archivo base upstream); sin
  referencias rotas (grep). **Sin compilar: solo la Mac lo
  confirma.** Los instaladores de Gemini/Codex/Muse comparten el
  mismo nb-hook y el mismo socket, así que la guarda del socket los
  cubre en el mecanismo; sus alertas propias quedan como follow-up.

### 19.3 Plan de verificación en vivo (API arrancada)

Hasta ahora TODAS las verificaciones fueron con la API apagada (0
propuestas sin errores). Esta es la primera con la API arrancada.
Orden de los pasos: stack → pill activa → crear propuestas →
permiso → aplicar → verificar/publicar → chat → voz → ojos →
workflows/habilidades/recordatorios → investigar → cuentas/resumen
→ limpieza. Un paso por vez; si uno falla, se anota y se sigue con
el siguiente, no se salta al final.

**Pre-requisitos.** Fork en el HEAD de esta sesión (pull +
`xcodegen` + Shift+Cmd+K + Cmd+B + Cmd+R, bloque de siempre). La
isla actual de JESLY cerrada durante la prueba (no por conflicto,
sino para no actuar dos veces sobre la misma propuesta). Coucou
original cerrado si lo usa (si no, el fork no recibe sesiones CLI;
con la guarda nueva, el fork NO le roba el socket y lo avisa en
Ajustes → Agents). Repo JESLY en la Mac: `~/Downloads/jesly-ia`
(la carpeta de siempre; si ya cambió el remoto al repo nuevo, es
la misma carpeta). Docker Desktop abierto.

**Paso 0 — Clave para los curl.** Desde la raíz del repo:
`KEY=$(grep '^JESLY_API_KEY=' .env | cut -d= -f2)`. Si el `.env`
tiene la clave, TODOS los `/v1/*` exigen
`-H "Authorization: Bearer $KEY"` (401 sin ella); si no tiene
clave, `/v1` queda abierto solo en localhost y se omite la
cabecera. La misma clave es la que el fork lee del llavero
(`com.jesly.island`, ya guardada en Ajustes → JESLY en la Fase 3):
si el fork muestra "API no responde" con la API arriba, lo primero
es comprobar que la clave del llavero coincide con la del `.env`.

**Paso 1 — Arrancar el stack.** Desde la raíz del repo:
`bash scripts/arrancar-todo.sh`. Levanta Postgres (5433, Docker;
el compose dice 5432 pero la copia local de JC lo tiene en 5433),
Ollama nativo (11434), API (3000), STT (3001), TTS (3002) y Web
(3003). Debe terminar con la tabla y TODO ARRIBA (exit 0). Si algo
sale FALLO, mirar `logs/<servicio>.log`. Comprobar:
`curl -s http://127.0.0.1:3000/health` → `{"ok":true}`; y
`curl -s http://127.0.0.1:3000/v1/system/status -H "Authorization: Bearer $KEY"`
para ver qué proveedores están `up` (Ollama debe estar `up` para
el chat automático).

**Paso 2 — Activar la pill JESLY.** En el fork: Ajustes → Active
pills → activar JESLY (`jesly_propuestas`). Las activas por defecto
son solo Vercel + GitHub (2 de 4 huecos), así que no hay que
desactivar nada. El sondeo solo corre con la pill activa: sin ella,
la pill muestra 0 propuestas aunque la API tenga. Debe verse 0
propuestas (todavía no hay ninguna).

**Paso 3 — Crear 4 propuestas reales.** Desde la raíz del repo,
con el `KEY` del paso 0. La primera CON parche (camino principal),
las otras tres SIN parche (para Ejecutar, Denegar y Siempre).
Plantilla (guardar en `/tmp/propuesta-fork.json` y enviar con
`curl -s -X POST http://127.0.0.1:3000/v1/tasks -H "Authorization: Bearer $KEY" -H 'Content-Type: application/json' -d @/tmp/propuesta-fork.json`):
`{"title":"Prueba en vivo del fork (Fase 6): añadir nota de verificación","kind":"propuesta","agent_id":"mac","proposal":"Crear el archivo docs/verificacion-fork-2026-11-27.md con una línea que marca la verificación en vivo del fork JESLY Island (Fase 6). No toca código ni configuración.","patch":"--- /dev/null\n+++ b/docs/verificacion-fork-2026-11-27.md\n@@ -0,0 +1 @@\n+Verificación en vivo del fork JESLY Island — Fase 6, 2026-11-27.\n"}`.
Debe responder 201 con la tarea (anotar su `id`). Un 400 es el
parche inválido o un campo mal formado, no un fallo del fork. Las
otras tres: mismo JSON cambiando `title` y `proposal` y SIN la
clave `patch` ("Propuesta B: escribir la misma nota sin parche",
"Propuesta C: denegar esta propuesta de prueba", "Propuesta D:
probar la regla Siempre"). Comprobar en el fork que la pill JESLY
marca 4 (puede tardar un sondeo de 5 s).

**Paso 4 — Tarjeta de permiso (propuesta A).** En ≤5 s la isla
muestra la tarjeta de permiso de la propuesta A: título, agente
`mac`, botones Permitir / Denegar / Siempre. Si no aparece: volver
al home y esperar un sondeo; comprobar con
`curl -s "http://127.0.0.1:3000/v1/tasks?status=esperando_aprobacion&kind=propuesta" -H "Authorization: Bearer $KEY"`
que la API la tiene. Tocar **Permitir**. Debe verse: la tarjeta
pasa a sesión en vivo (paso 5). Si toca Denegar por error, la
propuesta pasa a cancelada y hay que crear otra (paso 3).

**Paso 5 — Aplicar + sesión en vivo (propuesta A).** La tarjeta de
sesión en vivo muestra "Sesión en vivo", la rama
`jarvis-test/<id-corto>` y el diff real (archivo +1 −0) con los
pasos. Tocar **Aplicar**. Debe verse: la tarea pasa a aplicada.
Comprobar en la terminal (repo JESLY):
`git branch --list 'jarvis-test/*'` muestra la rama;
`ls ~/.cache/jarvis/worktrees/<id-corto>/docs/verificacion-fork-2026-11-27.md`
existe; y el checkout principal NO tiene el archivo
(`test -f docs/verificacion-fork-2026-11-27.md` en la raíz del repo
debe dar que no existe). Si Aplicar responde 400, leer el motivo:
la tarea queda en planificada (p. ej. fallo de git) y no es un
fallo de la tarjeta.

**Paso 6 — Verificar y Publicar (propuesta A, aplicada).** En la
tarjeta: **Verificar** (el fork manda las comprobaciones locales
por defecto: health de 127.0.0.1:3000 y 127.0.0.1:3003) → debe
verse el resumen del veredicto; un veredicto con fallos llega como
200 con el informe, no como error. **Publicar** → empuja la rama
de prueba a GitHub y NUNCA fusiona a main. Comprobar:
`git branch -r --list 'origin/jarvis-test/*'` muestra la rama, y en
github.com/jeslyagent/Jesly-agent-ai existe la rama
`jarvis-test/<id-corto>`. **Revertir** → borra rama + worktree:
`git branch --list 'jarvis-test/*'` vacío y
`~/.cache/jarvis/worktrees/<id-corto>` ya no existe. La tarea queda
en revertida.

**Paso 7 — Chat con modelo real.** Abrir el chat de JESLY (pill
`jesly_chat` → "Chat with JESLY" o la flecha ↗). Enviar: "Hola,
¿qué modelo eres?". Debe verse la respuesta con "proveedor ·
modelo" REAL debajo (p. ej. `ollama-local · qwen3:8b`). Probar el
chip de proveedor (Automático → Ollama → FreeLLMAPI → Groq →
Gemini → OpenRouter): FreeLLMAPI solo responde si su contenedor
Docker está arrancado (puerto 3101, no lo levanta
`arrancar-todo.sh`); si no está, el router usa otro proveedor y la
insignia muestra el que respondió de verdad. Sin ningún proveedor
arriba, el chat muestra el error claro de la isla: es el
comportamiento esperado, no un fallo del fork.

**Paso 8 — Voz.** a) **Micrófono manual:** en el chat, tocar el
micrófono, hablar, y comprobar que transcribe (STT 3001), responde
por chat y suena la voz (TTS 3002); tocar ■ para interrumpir.
b) **"Oye JESLY":** en otra terminal, desde la raíz del repo:
`bash scripts/arrancar-wake-word.sh` (comprueba la salud de
API/STT/TTS antes de arrancar; log en `logs/wake-word.log`).
Decir "Oye JESLY" a distancia normal → pitido → hablar → respuesta
por voz. La isla muestra el estado del demonio ("Escuchando" /
"Escucha en pausa"). La primera vez macOS pide permiso de
micrófono para la Terminal: pulsar Permitir (si se denegó:
Ajustes del Sistema → Privacidad y seguridad → Micrófono →
Terminal). Parar con `bash scripts/parar-wake-word.sh`. Si el
demonio no está instalado en la Mac (sin venv ni modelo Vosk), este
apartado se salta y se anota como pendiente: la isla muestra
"Escucha en pausa" y nada se rompe.

**Paso 9 — Ojos.** Arrastrar una imagen (p. ej. una captura) a la
zona punteada del chat y enviar. Debe verse la insignia "Vio:
proveedor / modelo". Límites del servidor (validados antes de
enviar): imágenes 10 MB, vídeos 50 MB, máx. 4 adjuntos y 1 vídeo
por mensaje. Un archivo mayor se rechaza antes de enviar.

**Paso 10 — Workflows, habilidades, recordatorios.** Ajustes →
JESLY. **Workflows:** la lista carga (incluye "Resumen diario —
buenos días" si está programado). Ejecutar uno: crea una tarea y
su progreso se ve en la tarjeta de sesión en vivo. Probar
Pausar/Reanudar y Borrar en uno de prueba. **Habilidades:** la
lista carga; si hay alguna "en revisión", Probar / Aprobar /
Rechazar; si hay instalada, Desinstalar. Lista vacía = válido si
JC no tiene habilidades instaladas (instalar desde manifiesto aún
no lo soporta la isla). **Recordatorios:** escribir "Recuérdame en
2 minutos que revise la prueba del fork" → Crear → aparece con
fecha y estado pendiente → **Hecho** → estado silenciado (el botón
llama a silenciar el workflow, no hay endpoint "hecho"). Opcional:
esperar los 2 minutos y comprobar que suena.

**Paso 11 — Investigación profunda.** En el chat, tocar la lupa:
el campo dice "Investiga en la web…". Preguntar algo con respuesta
en la web (p. ej. "¿Qué avances hubo en computación cuántica en
2026?"). Debe llegar el informe con las fuentes como enlaces (✓
verificada / ! no verificada) y la línea "Investigación ·
modelo/extractiva · N fuentes · M verificadas · fecha". No se
puede cancelar en vuelo; más de 1000 caracteres responde 400 del
servidor.

**Paso 12 — Cuentas conectadas y resumen diario.** Ajustes →
JESLY. **Cuentas conectadas:** muestra Google/GitHub con scopes y
expiración si JC las conectó; lista vacía = esperado si nunca las
conectó desde la isla (conectarlas no es parte de esta prueba).
**Resumen diario:** "Ver el de hoy" → vista previa con contadores;
programar una hora → el workflow "Resumen diario — buenos días"
aparece en la lista de Workflows con su horario; Apagar → lo borra
(404 si no había ninguno).

**Paso 13 — Limpieza.** En Ajustes → JESLY, **Revocar** la regla
"Siempre" creada en la propuesta D (si no, seguirá auto-aprobando
propuestas del agente `mac`). Parar el demonio de voz
(`bash scripts/parar-wake-word.sh`) y, si quiere, todo el stack
(`bash scripts/parar-todo.sh`). Anotar los ids de las 4 propuestas
y su estado final (A: revertida tras publicar; B: aplicada por
ejecutar o planificada si el agente no escribió nada; C:
cancelada; D: aprobada por Siempre + regla revocada). Mandar el
resultado: qué pasos pasaron y cuáles fallaron, con el mensaje
exacto que se vio.

### 19.4 Si algo no se ve (diagnóstico rápido)

- Pill JESLY en 0 con la API arriba → la pill no está activa
  (paso 2) o la clave del llavero no coincide con el `.env` (401:
  el sondeo marca `apiReachable = false` con el motivo).
- La tarjeta no aparece → esperar un sondeo (5 s) o volver al
  home; la tarjeta no roba otras vistas. Comprobar la propuesta con
  el curl del paso 4.
- Aplicar 400 → leer el motivo en la tarjeta o en `logs/api.log`:
  la tarea queda en planificada.
- Chat sin respuesta → `curl /v1/system/status`: ningún proveedor
  `up` (Ollama apagado o sin modelo `qwen3:8b`).
- "Escucha en pausa" → el demonio Vosk no corre (paso 8b).
- Sesiones CLI (VS Code/Cursor/Codex/Gemini) vacías con los hooks
  instalados → otra app es dueña del socket (aviso en Ajustes →
  Agents, §19.2); cerrar la otra app y reiniciar el fork.
- BUILD FAILED con errores fantasma tras el pull → `xcodegen` +
  Shift+Cmd+K antes de tocar código (lección de la Fase 2).

### 19.5 Para la Fase 6, sesión 2

Aplicar la decisión de JC sobre los hooks (§19.2): si es la A,
nada más (quizá la misma alerta en los instaladores de
Gemini/Codex/Muse, que comparten nb-hook y socket); si es la B,
la sesión de renombre a `jesly-*` (con su prueba de coexistencia);
si es la C, verificar el traspaso en vivo (instalar desde el fork
con Coucou corriendo → alerta → hacerse dueña → Coucou deja de
ver sesiones). Probar la guarda del socket en vivo (arrancar el
fork con Coucou corriendo → aviso en Ajustes → Agents y el fork no
roba el socket). Pendientes sueltos: quitar el paso "Wardrobe
tests" de `.github/workflows/build.yml` en el remoto (la App no
puede, 403); las 3 decisiones de `PRODUCT_NAME`/bundle id; los
instaladores de hooks de los agentes quitados siguen en el código
como funciones sin uso desde Ajustes (limpieza posterior).

## §20. FASE 6, SESIÓN 2 — Decisión A: hooks apagados por defecto

Decisión de JC (2026-11-27): **A — hooks apagados por defecto**. JESLY
funciona completo sin hooks; solo se instalan si JC pulsa Instalar
explícitamente en Ajustes → Agents.

### 20.1 Auditoría de caminos de arranque (veredicto por camino)

- `AppDelegate.setupIsland()` → `HookServer.shared.start()` (único
  arranque del servidor): **INSTALABA SOLO** — llamaba a
  `installHookScript()` en cada arranque (no App Store) y reescribía
  nb-hook/nb-hook.py en el dir compartido aunque JC nunca hubiera
  instalado hooks en el fork. **GUARDA AÑADIDA:** el script solo se
  escribe si este fork es el dueño (`HookServer.jeslyForkOwnsHooks`,
  marca `jeslyForkHooksInstalled` en UserDefaults, que pone
  `confirmInstall()` y quita `uninstallHooks()`). Sin la marca, el
  fork no toca nada compartido al arrancar. La guarda del socket de
  la sesión 1 sigue corriendo igual (no robar nb.sock si otra app
  viva lo tiene).
- Instaladores manuales de Claude / Gemini / Antigravity / Codex /
  Copilot / Muse (`write*Hooks()` en `HookServer.swift`, solo
  llamados desde los botones de confirmar de Ajustes tras ver el
  diff): **NO INSTALAN SOLOS**. Se quedan como están, salvo que
  ahora cada uno escribe el script nb-hook al confirmar (antes lo
  garantizaba `start()`; sin eso, una instalación manual en una
  máquina nueva apuntaría a un script inexistente). El camino App
  Store (`installAndWriteClaudeHooksAppStore`) ya escribía script +
  settings en un solo paso; sin cambios.
- StatusLine (`installStatusLine` / `writeStatusLine`): solo botones
  manuales en Ajustes. Sin cambios.
- Onboarding / primera ejecución: no existe ningún flujo que toque
  hooks (sin `firstLaunch` ni onboarding en el código). Sin cambios.
- Activar una pill de agente: no instala hooks (ninguna llamada a
  instalar fuera de Ajustes). Sin cambios.
- Botón "Update hooks" (`hooksNeedUpdate`): manual, solo lectura
  hasta que JC pulsa. Sin cambios.

### 20.2 Texto visible nuevo

Ajustes → Agents, arriba del cuadro de Claude Code: "Hooks apagados
por defecto: JESLY funciona completo sin ellos. Nada se instala solo
al arrancar — usa Instalar solo si quieres vigilar sesiones de
terminal (Claude Code, Cursor, Codex, Gemini CLI) en la isla."

### 20.3 Cambios de código

- `App/HookServer.swift`: marca de dueña unificada aquí
  (`jeslyForkHooksOwnerKey` / `jeslyForkOwnsHooks`, antes duplicada
  en `SettingsView`); guarda en `start()`; `installHookScript()` al
  inicio de los 6 `write*Hooks()`.
- `App/SettingsView.swift`: la marca vieja (`jeslyForkOwnsClaudeHooks`
  / `Self.jeslyForkHooksOwnerKey`) pasa a leer `HookServer`; texto
  nuevo en `agentsSection`.
- Verificación sin compilar: balance 0 en los 2 archivos (el -6 de
  paréntesis de `HookServer.swift` es ruido del escáner, idéntico en
  el archivo base upstream); 0 restos de la marca vieja; los únicos
  llamadores de `installHookScript()` son `start()` (con guarda) y
  los 6 `write*Hooks()` manuales; `start()` solo se llama desde
  `AppDelegate.setupIsland()`. **Sin compilar: solo la Mac lo
  confirma.** Sospechosos si falla: la guarda de `start()` o el
  texto nuevo de `agentsSection`.

### 20.4 Para cerrar la Fase 6

La verificación en vivo de 14 pasos (§19.3), que corre JC en su Mac
con la API arrancada, más probar la guarda en vivo (arrancar el fork
con Coucou corriendo → aviso en Ajustes → Agents, el fork no roba el
socket ni reescribe el script; instalar desde el fork → alerta "Los
hooks ya tienen dueña"). Pendientes sueltos: quitar el paso "Wardrobe
tests" de `.github/workflows/build.yml` en el remoto (la App no
puede, 403); las 3 decisiones de `PRODUCT_NAME`/bundle id.

## §21. FASE 6 — CORRECCIÓN: `plan` es lista en el servidor, texto en el modelo

### 21.1 Bug confirmado en vivo (2026-11-27)

Durante la verificación en vivo de 14 pasos (§19.3), la tarjeta de
permiso nunca apareció aunque la API tenía 4 propuestas en
`esperando_aprobacion` (verificado por curl: A `bd3a05f2`, B
`28f62b0f`, C `1ed2617f`, D `3ab0da36`). La clave sí estaba guardada
en el llavero (33 caracteres medidos), el stack estaba todo arriba
y el sondeo está bien cableado. La causa era el modelo, no la clave
ni el sondeo.

Evidencia del servidor (`apps/api/src/routes/tasks.ts`, repo
`jeslyagent/Jesly-agent-ai`):

- Línea 71: `plan: unknown;`
- Línea 210: `const plan = Array.isArray(req.body?.plan) ? req.body.plan : [];`
- Línea 282: `JSON.stringify(plan)` (se guarda como lista JSON)

El curl real devuelve `"plan":[]`. Pero el fork declaraba en
`JeslyModels.swift:27` `public var plan: String?`. JSONDecoder no
puede decodificar un array como `String?`: fallaba TODA la
respuesta `TasksResponse`, el poller marcaba `apiReachable=false`,
las listas quedaban vacías, la pill marcaba 0 y la tarjeta no
salía. Es la primera vez que la API devuelve tareas reales; con la
API apagada nunca se vio.

### 21.2 Corrección (1 archivo)

Solo `NotchBuddy/Sources/JeslyIsland/Api/JeslyModels.swift`:
`JeslyTask` gana un `init(from:)` personalizado y un
`decodePlan(from:)` privado. `plan` sigue siendo `String?` por
fuera — `JeslyProposalCardView.swift:119` no se toca.
Decodificación: texto directo → tal cual; lista de textos →
unidos por líneas; cualquier otra forma (lista de objetos, null,
ausente) → nil, sin fallar. El resto de campos se decodifica igual
que antes; `encode(to:)` sigue sintetizado y no hay
construcciones por miembros de `JeslyTask` en el código.

Casos razonados contra el JSON real:

- Tarea A real (`bd3a05f2`, `"plan":[]`, `"result":null`) → `plan`
  nil; la tarea entra en la lista y la tarjeta puede abrirse.
- `"plan":["Crear el archivo","Añadir la línea"]` →
  `"Crear el archivo\nAñadir la línea"`.
- `"plan":"Revisar y aplicar el parche"` → el mismo texto.

Verificación sin compilar: balance 0 en `JeslyModels.swift`
(escáner Swift-aware); `task.plan` sigue siendo `String?` en toda
la UI. **Sin compilar: solo la Mac lo confirma.** Sospechoso si
falla: el `init(from:)` personalizado o el `decodePlan`.

### 21.3 Hallazgo pendiente (otro repo)

La isla actual (`jeslyagent/Jesly-agent-ai`,
`apps/island/Sources/JeslyIsland/Api/JeslyModels.swift`, HEAD
`3e2a59db`) tiene el mismo modelo portado verbatim y por tanto el
mismo bug. Anotado en `FORK-NOTAS.md`; la corrección en ese repo
es trabajo aparte.

### 21.4 Para retomar la verificación en vivo

Tras el pull + build en la Mac de JC, la verificación de 14 pasos
(§19.3) se retoma en el **paso 4** (tarjeta de permiso): la pill
JESLY debe marcar **4** y la tarjeta de la propuesta A debe
abrirse sola. Las 4 propuestas siguen en `esperando_aprobacion`
en la API; no hay que recrearlas.

## §22. FASE 6 — CORRECCIÓN: crash al abrir la tarjeta, `viewLayouts` sin entradas JESLY

### 22.1 Crash confirmado en vivo (2026-11-27)

La app compiló y corrió, el sondeo ya trae las 4 propuestas (la
corrección del `plan` funcionó), pero al abrir la tarjeta la app
se cae. Captura de JC (depurador de Xcode):

- `Thread 1: Fatal error: Unexpectedly found nil while unwrapping an Optional value`
- `NotchBuddy/Sources/App/IslandRootView.swift:526`: el `!` sobre
  `IslandConst.viewLayouts[view]`
- Estado en el depurador: `mode = expanded`, `view = jeslyProposal`.

### 22.2 Causa

`IslandConst.viewLayouts` (`CoucouKit/IslandTypes.swift:244`) NO
tiene entradas para NINGUNA de las tres vistas JESLY
(`.jeslyProposal`, `.jeslySession`, `.jeslyChat` — casos en
`IslandTypes.swift:21-23`). El `!` revienta en cuanto la isla
intenta dibujar una de ellas en modo expandido. Hay un segundo
`!` igual en `IslandWindowController.swift:2257` (`islandSize`,
mismo `case .expanded`). Las Fases 3–4 se "verificaron" con la
API apagada, así que la tarjeta nunca llegó a dibujarse y el
hueco no se vio.

Por qué el chat (Fase 4 s2, verificado "listo" por JC) no se cayó
antes, si tampoco tenía entrada: **no se puede establecer por el
código.** Las tres vistas comparten exactamente el mismo camino
(`IslandViewContent` → `state.view` → `BotPlacement` e
`islandSize`, ambos bajo `mode == .expanded`), así que no hay
razón a nivel de código por la que `.jeslyChat` sobreviviera y
`.jeslyProposal` no. Lo más plausible es circunstancial (que el
modo no fuera `.expanded` cuando JC miró el chat en esas
sesiones), pero eso no se puede comprobar desde el código ni
desde las confirmaciones previas. Queda anotado como no
establecido, no como hecho.

### 22.3 Corrección (3 archivos)

`CoucouKit/IslandTypes.swift`: tres entradas nuevas en
`viewLayouts` tras `.question`, con el layout de `.approval`
como base (height 160, botX 62, botY nil, botDiameter 56,
agentMode .column) — la tarjeta de permiso copia el cromo de
`ApprovalView` y la de sesión y el chat son tarjetas del mismo
tipo — y helper nuevo `IslandConst.layout(for:)`: `viewLayouts[view]
?? viewLayouts[.overview] ?? ViewLayout(...)` con los valores
literales de `.overview`. Una vista sin entrada cae al layout de
`.overview` en vez de reventar.

`App/IslandRootView.swift:526` y
`App/IslandWindowController.swift:2257`:
`IslandConst.viewLayouts[view]!` →
`IslandConst.layout(for: view)`. Ninguna otra lógica se toca.

Verificación sin compilar: balance 0 en los 3 archivos
(escáner Swift-aware); grep: no queda ningún
`viewLayouts[...]!` en el árbol; los dos sitios de llamada usan
`layout(for: view)`. **Sin compilar: solo la Mac lo confirma.**
Sospechoso si falla: el helper `layout(for:)` o las entradas
nuevas del diccionario.

### 22.4 Para retomar la verificación en vivo

Tras el pull + build en la Mac de JC, la verificación de 14 pasos
(§19.3) se retoma en el **paso 4** (tarjeta de permiso): la pill
JESLY debe marcar **4** y la tarjeta de la propuesta A debe
abrirse sola **sin caerse**. Las 4 propuestas siguen en
`esperando_aprobacion` en la API; no hay que recrearlas.

## §23. FASE 6 — CORRECCIÓN: tarjeta de sesión recortada (altura 160) + spinners eternos

### 23.1 Queja de JC en vivo (2026-11-27)

La tarjeta de permiso funcionó (paso 4 PASS) y JC tocó Siempre
en D: la isla pasó a la tarjeta de sesión en vivo. Queja textual:
"Se queda cargando y no se ve bien porque se esconde en la isla.
Hay que modificarlo." En la captura se ven la cabecera y las 4
filas de pasos, pero los botones (Aplicar/Ejecutar) quedan
cortados fuera de la isla.

### 23.2 Defecto 1: altura 160, medida

El layout de `.jeslySession` era height 160, copiado de
`.approval`. Medida del contenido real de `JeslySessionView`
(VStack spacing 8, padding vertical 4+4): cabecera ~16 + 4 filas
× 26 (= 104) + fila de botones ~29 + top 4 + gaps 40 = ~201 en
planificada; aplicada añade 2ª fila (+41) = ~242; más feedback
(+27) = ~269. Cromo fijo de la isla (top 8 + cabecera 34 +
bottom 10) = 52, así que la ventana necesita 253 / 294 / 321.
La tarjeta vive en el marco fijo de 98 pt de `IslandRootView` y
el desborde solo lo recorta la ventana, así que subir la altura
es lo que deja verla entera; `botY` nil sigue auto-centrando y
no rompe `botPosition` ni `islandSize`. **Altura elegida: 330**
(área útil 278, cubre aplicada + feedback con margen).
`.jeslyProposal` no se toca (se vio entera) ni `.jeslyChat` (su
lista es un `ScrollView`, no se recorta).

### 23.3 Defecto 2: spinners eternos en los pasos

`JeslyStepIcon` giraba un `ProgressView` en cada paso en curso,
que puede estar así minutos: se leía como "se queda cargando".
Ahora el paso en curso es un **anillo hueco estático** (mismo
círculo que el terminado, vacío, sin animación). El `ProgressView`
de `working` (acción real en vuelo) se queda.

### 23.4 Para retomar la verificación en vivo

Tras el pull + build en la Mac de JC, la verificación se retoma
en el **paso 5** (Aplicar en la propuesta A): la tarjeta de
sesión debe mostrar las 4 filas Y los botones completos, sin
spinners girando en los pasos. D, C y B ya fueron decididas por
JC; A sigue en planificada con su parche.

## §24. FASE 6 — CORRECCIÓN: chat recortado (altura 160) + lista de mensajes invisible

### 24.1 Queja de JC en vivo (2026-11-27)

Pasos 5-6 cerrados (Aplicar y Revertir PASS). JC abrió el chat
real de JESLY y dijo, textual: "Se ve cortado, se pierden algunas
cosas y el chat, la barra del chat también se pierde. Ajusta todo
para que se vea correctamente." En la captura, con altura 160, se
ven los chips ("Automático", "Oye JESLY · Escucha en pausa"), el
aviso de API y la zona de soltar archivos; la barra de entrada
queda cortada en el borde inferior y el área de mensajes no se ve.
El aviso "La API de JESLY no responde en 127.0.0.1:3000" es
estado del servidor, no parte de esta corrección.

### 24.2 Defecto 1: altura 160, medida

Contenido fijo de `JeslyChatView` (VStack spacing 6, paddings
12+14+10): chips ~22 + zona de soltar ~31 + fila de entrada ~44
+ gaps 18 + paddings 36 = ~151; sin mensajes el aviso (~30)
suma ~181. Cromo fijo de la isla = 52. Con mensajes, el área
útil debe dejar ~120 pt para la lista: 151 + 120 + 52 = 323.
**Altura elegida: 330** (igual que la sesión): área útil 278,
~127 pt de mensajes; con adjuntos o error la lista se estrecha
pero sigue visible y con scroll.

### 24.3 Defecto 2: la lista se aplasta a 0 sin `isTall`

La altura sola NO basta: la lista es un `ScrollView` con
`maxHeight: .infinity` dentro del marco fijo de 98 pt de
`IslandRootView`, donde se aplasta a 0 — los mensajes serían
invisibles aunque la ventana fuera más alta. `.jeslyChat` se
declara vista "alta" en el `isTall` de `IslandRootView`, como
`.prompt` (el otro chat): el marco se vuelve flexible y la lista
llena el área útil. Las altas inactivas colapsan (minHeight 0),
igual que `.prompt`. `botY` nil sigue auto-centrando; no rompe
`botPosition` ni `islandSize`.

### 24.4 Tarjeta de permiso: 160 → 200

`.jeslyProposal` se vio entera en vivo, pero medida con la línea
de feedback se recorta: ~127 sin feedback, ~146 con feedback,
contra área útil 108. **Subida a 200** (área útil 148, cubre 2
líneas + feedback). El contenido va centrado, se ve igual.

### 24.5 Para retomar la verificación en vivo

Tras el pull + build en la Mac de JC, la verificación se retoma
en el **paso 7** (chat: "Hola, ¿qué modelo eres?" con proveedor
Automático): el chat debe mostrar chips + aviso + zona de soltar
+ mensajes + barra de entrada completa, sin nada cortado.
