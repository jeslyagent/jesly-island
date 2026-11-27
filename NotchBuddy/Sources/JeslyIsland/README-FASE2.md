# README-FASE2 — JESLY Island, Fase 2 sesiones 1–2

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
