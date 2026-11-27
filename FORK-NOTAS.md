# FORK-NOTAS.md — JESLY Island (fork de Coucou), Fase 1

Fecha: 2026-11-27. Estado: **base limpia local, SIN publicar, SIN integrar JESLY todavía.**

Origen: `Louis-CFM/coucou`, clon `--depth 1`, commit `202082ee0204bbc4fb78d8178cea3f0c6fcc34e4`,
versión `0.6.2` (24-nov-2026, `CFBundleVersion 28`). Código MIT; nombre, Mochi, icono,
sonidos y media © Louis Raillé (`LICENSE-ASSETS.md`).

## Medidas reales (depth 1)

| Medida | Valor |
| --- | --- |
| Total en disco (con `.git`) | 60 MB |
| Árbol de trabajo (sin `.git`) | 39 MB |
| `.git` (depth 1, 1 commit) | 21 MB |
| Archivos totales | 1.374 |
| Archivos Swift | 301 (84.646 líneas) |
| — `NotchBuddy/Sources` | 233 archivos (75.415 líneas) |
| — `tests/` + `NotchBuddy/Tests` | 68 archivos (8.018 líneas en `tests/`) |
| Kotlin (Android) | 266 archivos (31.251 líneas) |
| Rust (Windows/Tauri) | 97 archivos |
| `NotchBuddy/` | 15 MB (Resources 6,8 MB; Sources 3,7 MB; PhoneAssets 2,5 MB; Assets 1,3 MB) |
| `docs/` | 8,0 MB (de ellos `docs/media` 7,7 MB, 22 archivos) |
| `design/` | 3,1 MB (40 archivos) |
| `windows/` | 5,9 MB · `android/` 6,3 MB · `relay/` 84 KB · `scripts/` 324 KB |

Alcance del renombre (sin `.git`): `coucou` aparece 10.990 veces en 770 archivos;
`mochi` 3.909 veces en 397 archivos; `fr.louisraille` 105 veces; `NotchBuddy` 326 veces.
No es un buscar-reemplazar: la mayoría son identificadores, claves de localización
(16 idiomas) y nombres de tipos.

## Lo que SE hizo en esta fase

1. Clon `--depth 1` en `~/workspace/coucou-fork/`. No se hizo clon completo
   (1.211 commits): para medir y planear basta el depth 1; el historial completo
   solo agrandaría el `.git`.
2. **Remote `origin` eliminado** (editando `.git/config` directamente, sin correr
   git dentro del repo — ver nota de seguridad abajo). `git push` / `fetch` ya no
   tienen a dónde ir. La sección `[branch "main"]` aún dice `remote = origin`,
   pero ese remoto no existe: es inofensivo y se reescribirá al crear el remoto real.
3. Renombres mínimos y seguros (solo lo visible, nada de identificadores):
   - `README.md`: título `# JESLY Island — fork de Coucou` + banner de fork Fase 1.
   - `NotchBuddy/project.yml` línea 141: `CFBundleDisplayName: Coucou` → `JESLY`
     (solo el target principal; los otros 4 `CFBundleDisplayName` — líneas 234, 320,
     402, 447, targets AppStore/Phone/Widgets/Notification — siguen en Coucou).
4. Nada más. No se borró ningún archivo, no se tocó código Swift, no se compiló.

## Lo que NO se hizo (a propósito)

- No se creó repo remoto ni se pusheó nada a GitHub.
- No se borró Mochi: borrar a ciegas rompería el build (86 archivos Swift en
  `Sources` + `tests` mencionan `mochi`; el personaje está entrelazado con
  `MochiRoom`, `DesktopMochi`, `MochiWardrobe`, estados de ánimo y sonidos).
- No se cambió el bundle id (`fr.louisraille.NotchBuddy`, `project.yml:142,177`,
  `bundleIdPrefix: fr.louisraille`, línea 3). NO es obvio ni seguro: los
  entitlements Cloud (`CoucouCloud.entitlements`, `CoucouAppStoreCloud.entitlements`)
  referencian contenedores CloudKit de Louis Raillé; cambiar el id sin tocarlos
  rompería la compilación Cloud y el acceso a Keychain/iCloud.
- No se renombraron targets (`NotchBuddy`, `CoucouAppStore`, `CoucouPhone`),
  ni archivos (`Coucou.entitlements`, `CoucouKit`, `Coucoudoro*`), ni `PRODUCT_NAME`.
- No se tocó Windows / Linux / Android / `relay/` (fuera de alcance: solo Mac).
- No se intentó compilar en esta VM: no hay toolchain Swift aquí.

## Archivos de Mochi / sonido / icono QUE HAY QUE REEMPLAZAR (no borrar aún)

Según `LICENSE-ASSETS.md`: nombre "Coucou"/"Mochi", el personaje, el icono de la app
y de la barra de menú, los sonidos y las imágenes/GIF/videos de `docs/media/` y `design/`.

| Qué | Dónde | Tamaño / nº |
| --- | --- | --- |
| Sonidos (28 WAV + `greeting.wav` = 29) | `NotchBuddy/Resources/sounds/` | 3,8 MB |
| Icono app + icono barra de menú | `NotchBuddy/Assets.xcassets/AppIcon.appiconset/`, `MenuBarIcon.imageset/` | 1,3 MB (Assets total) |
| Iconos iPhone (variantes de color) | `NotchBuddy/PhoneAssets.xcassets/` | 2,5 MB |
| Habitación de Mochi | `NotchBuddy/Assets.xcassets/Room/MochiRoom*.imageset` | — |
| Media demo / Botan | `docs/media/` (22 archivos), `design/` (40 archivos) | 7,7 MB + 3,1 MB |
| Copias en Android/Windows | `android/app/src/main/res/`, `windows/` (p. ej. `windows/mochi.html`, `windows/src/mochi/`) | — |
| Código del personaje | `Sources/CoucouKit/Mochi*.swift` (5), `Sources/App/DesktopMochi*.swift`, `MochiRoom.swift`, `FlowHubMochis.swift`, `Sources/Phone/Mochi*.swift`, `Sources/Widgets/MochiLiveActivity.swift` | 43 rutas con `mochi` en el nombre |
| Tests del personaje | `tests/DesktopMochiTests.swift`, `MochiRoomTests.swift`, `MochiWardrobeTests.swift`, `scripts/test-desktop-mochi.sh`, `scripts/test-mochi-room.sh` | — |

Reemplazo previsto: la nube de puntos blanca de JESLY (portar
`Sources/JeslyIsland/Character/` — `SmokeCharacter.swift` + `SmokeCloudView.swift` —
desde `jeslyagent/Jesly-agent-ai`, `apps/island/`). Sonidos: JESLY no tiene sonidos
propios; decisión pendiente: silencio por defecto o sonidos nuevos.

## Renombres pendientes (con ubicación exacta)

- `project.yml`: `bundleIdPrefix: fr.louisraille` (l. 3) → `com.jesly`;
  `CFBundleIdentifier: fr.louisraille.NotchBuddy` (l. 142) y
  `PRODUCT_BUNDLE_IDENTIFIER` (l. 177) → `com.jesly.island`;
  `PRODUCT_NAME: Coucou` (l. 178) → `JeslyIsland`; `CFBundleName` (l. 140);
  los 4 `CFBundleDisplayName` restantes (ll. 234, 320, 402, 447);
  nombre del proyecto/target `NotchBuddy` (l. 1, 65, 117) — solo junto con
  el renombre de los archivos `.entitlements` (`Resources/Coucou*.entitlements`,
  8 archivos) y de la carpeta `Sources/CoucouKit` si se decide.
- `HookServer.swift`: `supportDir` `NotchBuddy` → `JeslyIsland`,
  socket `nb.sock` → `jesly.sock`, hook `nb-hook` → `jesly-hook`,
  ruta `~/.claude/coucou/` → `~/.claude/jesly/` (solo si se mantiene el
  soporte a Claude Code; ver plan).
- `Localizable.xcstrings`: todas las cadenas con "Coucou" / "Mochi" /
  "OK Coucou" (16 idiomas) → "JESLY" / "Oye JESLY".
- `Casks/coucou.rb` (Homebrew), `linux/arch/coucou.desktop`,
  `docs/` (`index.html`, `privacy.html`, `terms.html`, `legal.html`).

## Nota de seguridad (check de ejecución)

La salida del `git clone` disparó un check de riesgo de ejecución en este entorno.
Por eso en esta fase NO se corrió ningún comando git dentro del repo (ni `status`,
`log`, `diff`, `fetch`, `remote`), NO se ejecutó ningún script de `scripts/`,
NO se compiló nada y NO se copió ningún archivo del fork a otro repo, a `~`,
a config ni al PATH. Solo se leyó texto plano (lectura de archivos, `find`/`du`/
`grep`/`wc` de medición) y se editaron 3 archivos de texto (`README.md`,
`project.yml`, `.git/config`). Si JC autoriza seguir, el trabajo Swift se hace
en su Mac, no aquí.

## Para probar la base en la Mac de JC (sin repo remoto todavía)

```bash
git clone --depth 1 https://github.com/Louis-CFM/coucou.git ~/Downloads/jesly-island
cd ~/Downloads/jesly-island
# Quitar el remoto para no pushear por accidente al repo de Louis:
git remote remove origin
brew install xcodegen
cd NotchBuddy && xcodegen && open NotchBuddy.xcodeproj
# En Xcode: Product > Run (Cmd+R). Requisitos: macOS 15+, Xcode 16+.
```

Eso compila Coucou original (con Mochi). La base local de esta VM (`~/workspace/coucou-fork/`)
tiene solo los 2 renombres de arriba; para llevarla a la Mac hace falta primero
crear el repo remoto (pregunta pendiente: cuenta `jeslyagent` o `NEXORA16-admin` —
ver plan) o pasar la carpeta por otro medio que JC autorice.

---

## FASE 2, SESIÓN 1 — 2026-11-27 (sin pushear, sin compilar)

**Repo remoto ya existe:** JC lo creó en la web, `jeslyagent/jesly-island`, y la
Fase 1 se pusheó y se verificó (commit `62ced5b2`). Esta sesión trabaja sobre
la base local; NADA de esta sesión está pusheado todavía.

### Auditoría Mochi (medido de nuevo, sin `.git`)

- `mochi`: **3.939 ocurrencias en 400 archivos** (Fase 1 decía 3.909/397; la
  diferencia es este mismo archivo `FORK-NOTAS.md`).
- `coucou`: **11.007 ocurrencias**.
- Por carpeta: `android` 178 archivos, `windows` 89, `NotchBuddy` 86,
  `docs` 12, `tests` 6, `scripts` 6, `design` 5, `.github` 4, `linux` 3,
  `relay` 2. En `NotchBuddy/Sources`: 698 ocurrencias en 80 archivos Swift.
- Archivos con `mochi` en el nombre: 43. `Localizable.xcstrings`: 314 `mochi`
  + 1.484 `coucou`. `whats-new.json`: 152 `mochi`. `PillCatalog.swift`: 0
  menciones a Mochi. Ningún test referencia la cadena `"Coucou"`.

### Cambios de esta sesión

1. `NotchBuddy/project.yml`: `CFBundleName` del target principal `Coucou` →
   `JESLY` (l. 140) y `CFBundleDisplayName` de los 5 targets → `JESLY`
   (ll. 141, 234, 320, 402, 447). Bundle id, `PRODUCT_NAME` y entitlements SIN tocar.
2. Cadenas visibles (Mac, target principal): `AppDelegate.swift` 5×
   `accessibilityDescription`, `FlowHub.swift` título + cabecera,
   `SettingsView.swift` cabecera, `WeeklyRecapView.swift` imagen para compartir:
   `"Coucou"` → `"JESLY"`.
3. Personaje portado, byte a byte, sin adaptar el código:
   `NotchBuddy/Sources/JeslyIsland/Character/SmokeCharacter.swift` (74 l.) y
   `SmokeCloudView.swift` (140 l.), desde `jeslyagent/Jesly-agent-ai`
   `apps/island/Sources/JeslyIsland/Character/` HEAD `3e2a59d`. El target los
   compila solo (grupo `Sources` en `project.yml`). **No están conectados:**
   ninguna vista los usa todavía. Detalle y mapa de reemplazo en
   `NotchBuddy/Sources/JeslyIsland/README-FASE2.md`.
4. `PRODUCT_NAME` NO se cambió: `scripts/cloud-test-build.sh`,
   `scripts/dev-install.sh` y `scripts/release.sh` hardcodean `Coucou.app`;
   va junto con esos 3 scripts en la sesión 2.
5. `Localizable.xcstrings` NO se tocó: hay que cambiar solo valores, nunca
   claves, y la frase `"OK Coucou"` va junto con `WakePhrase.swift`.
6. Bundle id, entitlements, `HookServer` (socket/hook/protocolo),
   `project.pbxproj`, zona CloudKit `"Coucou"`, `CHANGELOG.md`: NO tocados,
   clasificados peligrosos sin compilar (ver README-FASE2 §4).

### Para la sesión 2

Ver `NotchBuddy/Sources/JeslyIsland/README-FASE2.md` §5: build de la sesión 1
en la Mac, conectar `SmokeCloudView` en isla / flotante / Flow Hub, borrar
`MochiOutfitDrawing.swift` (1.464 l.) y `MochiWardrobe.swift`, xcstrings en
inglés, `PRODUCT_NAME` + 3 scripts, verificación en vivo.

---

## FASE 2, SESIÓN 2 — 2026-11-27 (local, SIN pushear, SIN compilar)

Sesión 1 verificada en vivo antes de empezar esta: BUILD SUCCEEDED 12:28 AST,
app Running Coucou, abre desde Aplicaciones y queda abierta sin Xcode
(commit remoto `55708958`).

### 1. Nube conectada en UN solo sitio: `HubLiveMochi`

- `NotchBuddy/Sources/App/FlowHubMochis.swift:215`: el cuerpo de
  `HubLiveMochi` pasa de `HubMochiScene` (mini Mochi vía `BotEngine`) a
  `SmokeCloudView(size: size)`. API intacta (`color`, `size`, `state`,
  `outfit`) para no tocar llamadores; `color` y `outfit` se ignoran (nube
  blanca, sin ropa). Heredan la nube: `FlowHub.swift:277` (cabecera, 28 pt),
  `HubEmptyState` (54 pt), `FlowHubNotes.swift:207` (54 pt, outfit
  `.roundGlasses` ignorado). `BotState` no tiene caso `.listening`, así que
  la sonrisa de escucha no se usa aquí todavía.
- Verificación sin compilar: balance de llaves/paréntesis/corchetes 0 en
  `FlowHubMochis.swift`; `project.yml` YAML válido (5 targets).

### 2. NO se borraron `MochiOutfitDrawing.swift` ni `MochiWardrobe.swift`

El grep exhaustivo demostró que NO se cumple la condición de borrado del
encargo. `Outfit`: 95 referencias en 7 archivos (`AppState`,
`BotEngine.setOutfit` + `drawOutfitBehind/Front`, `BotCanvasView`,
`DesktopMochi`, `FlowHubMochis`, `IslandViewContent` con el selector de
guardarropa, más `tests/MochiWardrobeTests.swift` y
`scripts/test-wardrobe.sh`). `drawOutfit*Static`: 6 llamadores. Borrarlos
sin reescribir todo eso rompe el build con certeza. Queda para la sesión 3
con build en la Mac (ver README-FASE2 §5.2).

### 3. `Localizable.xcstrings`: 100 valores en inglés → JESLY

Script `/tmp/fase2s2-xcstrings.py` (edición línea a línea, solo valores `en`).
Diff exacto 100 líneas. Claves intactas (1.149), otros 15 idiomas intactos,
JSON válido. Quedan 14 hits en inglés, todos intencionados: 3 `Coucoudoro`
(nombre de función), `whatsnew.botan` (historia), rutas reales
(`~/.claude/coucou/nb-hook`, `Application Support/Coucou`, 4 rutas de
plugins), y la frase de activación `« OK Coucou »` (intacta, con
`WakePhrase.swift`). Feo conocido: `voice.setting-web` dice "Claude as
JESLY's brain" — se corrige en Fase 4 con la voz por API.

### 4. `PRODUCT_NAME` + 3 scripts: APLAZADO a la sesión 3

`cloud-test-build.sh`, `dev-install.sh` y `release.sh` dependen de la
identidad de firmado y del contenedor iCloud de Louis Raillé
(`PROFILE_NAME="Coucou Developer ID"`, `iCloud.fr.louisraille.Coucou`,
`pgrep -x Coucou`), que no cambian en esta fase. Renombrar el producto sin
su identidad de firmado es el cambio con más riesgo de romper el build en
la nube. Va junto con la decisión de bundle id, con build en la Mac.

### 5. Qué queda de Mochi y por qué

- Isla animada: `BotCanvasView` / `MiniBotCanvasView` (`IslandRootView`,
  `IslandWindowController:1648`, `CornerIsland`) siguen con `BotEngine`.
- Flotante: `DesktopMochi.swift` sigue con `BotEngine` + outfits.
- Escenas Flow Hub: `HubMochiScene` / `HubHero` (tropa que camina) siguen
  con `BotEngine.draw`; `MochiRoom`, `MochiStill` (Phone/Widgets),
  `MochiMood`, sonidos 29 WAV, `whats-new.json`: intactos.
- `AndroidLinkProtocol.swift:140`: nombre de instancia por defecto
  `"Coucou"` si el Mac no tiene nombre (sesión 3).

---

## FASE 2, SESIÓN 3 — 2026-11-27 (local, SIN pushear, SIN compilar)

Sesión 2 verificada corriendo en la Mac de JC antes de empezar (13:20 AST,
pull Fast-forward a `5cc5fd0`, menú y ventana dicen JESLY, nube en Flow Hub).

### 1. Isla del notch → nube

- `NotchBuddy/Sources/App/BotCanvasView.swift`: `BotCanvasView` y
  `MiniBotCanvasView` ya no dibujan con `BotEngine`: `GeometryReader` +
  `SmokeCloudView(size: min(ancho, alto))`, `listening: state.voiceActive`
  en la principal. API intacta para no tocar llamadores (`IslandRootView`,
  `IslandWindowController:1648`, `CornerIsland`, `CoucoudoroViews`,
  `FlowPill`, `SpotifyViews`, `IslandViewContent`). `paused` → `Color.clear`.
- Se pierde sin equivalente en la nube: estados de ánimo, baile con música,
  morph de subida, emotes (slap/greet/blink/gulp). Los minis animan ahora a
  60 fps en vez de 30 (vigilar CPU en vivo).
- `BotEngine` sigue en el árbol pero ya no dibuja la isla.

### 2. Flotante → nube

- `NotchBuddy/Sources/App/DesktopMochi.swift`: `DesktopBotView` =
  `SmokeCloudView(size: 120, listening: appState.voiceActive)` + hover 1.07.
  `engine` se mantiene como parámetro; el controlador sigue creándolo para
  emotes/sonidos, que ya no se ven ni se oyen. Doble clic sigue volviendo a
  casa. `viewState.paused` ya no pausa el dibujo.
- Claves `UserDefaults` `desktopMochiX/Y` + `mochiOnDesktop` NO renombradas
  (dato persistido: renombrar huérfana la posición guardada).

### 3. Guardarropa: selector quitado, archivos NO borrados

- `BotEngine.setOutfit` → no-op (`outfit = .none`, `outfitPresence = 0`).
- `AppState`: quitados `mochiOutfitSelection`, `wardrobePreviewOutfit`,
  `resolvedOutfit`, `_seasonalCache` y la línea de init. Grep después: 0 refs.
- `IslandViewContent.swift`: `WardrobeView` → aviso ("JESLY no tiene ropa:
  la nube es la nube." + Volver). Borrados `OutfitPillView` y
  `drawOutfitIcon`. Ruta `.wardrobe`, atajo ⌃⌥G y handlers siguen y muestran
  el aviso.
- ❌ **NO se borraron `MochiOutfitDrawing.swift`, `MochiWardrobe.swift`,
  `tests/MochiWardrobeTests.swift` ni `scripts/test-wardrobe.sh`**: la
  condición (grep 0) NO se cumple. `Outfit` sigue en `FlowHubMochis.swift`
  (escenas `HubHero` con `.bow`, `.roundGlasses`, `.crown`, etc.) y en
  `BotEngine` (8 refs internas). Para borrarlos (sesión 4): reemplazar o
  quitar `HubHero`/`HubMochiScene` y destripar `BotEngine`.

### 4. AndroidLinkProtocol

- Nombre de instancia por defecto `"Coucou"` → `"JESLY"`.

### 5. PRODUCT_NAME + bundle id: NO tocados

Decisión pendiente de JC documentada en `README-FASE2.md` §8: firmado
Developer ID, contenedores CloudKit nuevos o iCloud apagado, y nombre final
del `.app`. Sin esas respuestas no se toca nada.

### 6. Qué queda de Mochi

- Escenas `HubMochiScene`/`HubHero` (Flow Hub), `MochiRoom`/`FlowHubRoom`,
  `MochiStill` (Phone/Widgets), `BotEngine` en el árbol, 29 WAV,
  `whats-new.json`: intactos, quedan para la sesión 4.

### 7. Archivos cambiados (6)

`BotCanvasView.swift`, `DesktopMochi.swift`, `BotEngine.swift`
(`setOutfit` no-op), `IslandViewContent.swift`, `AppState.swift`,
`AndroidLink/AndroidLinkProtocol.swift`. Balance 0 en los 6; grep de lo
quitado = 0. **Sin compilar: solo la Mac lo confirma.**

## FASE 2, SESIÓN 4 — nube cortada en el notch + CPU (2026-11-27, local, SIN pushear, SIN compilar)

Bug de JC en vivo: nube cortada en el notch plegado hasta abrir la isla,
y ~45 % de CPU en reposo.

### 1. Geometría medida (no adivinada)

Isla plegada 344×32 pt (`notchHeight` 32 fallback, `notchWidth` 184).
`BotPlacement`: canvas 33,3 × 73,3 (40 de overhang) en (40, −4);
máscara de 32 pt. Mochi compensaba con `cy = H/2 + overhang/2` → y=16.
La nube de la sesión 3 iba centrada → centro en y≈−4, solo se veía de
0 a ~7 pt (el tercio de abajo). Al abrir (160 pt) no hay corte.

### 2. Arreglo

- `SmokeCloudView.swift`: parámetro `compact` — 30 fps plegada, 60
  abierta (intervalo `0.9/fps`, como `MochiFrameClock`).
- `BotCanvasView.swift`: nube alineada ABAJO del frame (misma
  compensación que BotEngine: centro en y=16, nube 2,4–26,8 dentro de
  la tira de 32); `compact` según `mode != .expanded`; minis a 30 fps;
  oculta en notch no anima (`Color.clear`, salvo esquina y arrastre).
- Sin tocar `SmokeCharacter`, bundle id, entitlements, `HookServer`,
  `project.yml` ni la isla actual.

### 3. FPS por estado

Abierta 60, plegada 30, oculta en notch 0, baldosa en esquina 30,
minis 30, flotante/Flow Hub 60.

### 4. Archivos cambiados (2)

`SmokeCloudView.swift`, `BotCanvasView.swift` (+ docs). Balance 0 en
los 2; llamadores viejos (`DesktopMochi`, `FlowHubMochis`) intactos por
el valor por defecto. **Sin compilar: solo la Mac lo confirma.**
