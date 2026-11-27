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
