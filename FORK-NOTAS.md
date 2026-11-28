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

## FASE 2, SESIÓN 5 — Flow Hub sin Mochis + outfit borrado (2026-11-27, local, SIN pushear, SIN compilar)

Sesión 4 verificada en vivo antes de empezar (13:38 AST: tras BUILD FAILED
por proyecto Xcode viejo y limpiar con Shift+Cmd+K, la nube se ve completa
en el notch cerrado).

### 1. Flow Hub sin Mochis

- `FlowHubMochis.swift` (531 → 338 l.): borrados `HubMochiSpec`,
  `HubMochiTroupe` (+ `Walker`) y `HubMochiScene` (tropa que caminaba con
  `BotEngine.draw`, emotes y `poke`). `HubHero` queda como banda de color +
  título + subtítulo + acción, con su fondo de partículas (que ya parecían
  nube de puntos); el `Spacer(minLength: 290/350)` que reservaba sitio a la
  tropa pasa a `Spacer()`. API intacta: los 3 llamadores no se tocaron.
- `HubHeroTheme`: solo color por página (mismos colores, sin `cast`).
- `HubLiveMochi`: sin parámetro `outfit`; `FlowHubNotes.swift:207` deja de
  pasar `outfit: .roundGlasses`.

### 2. BotEngine destripado del outfit

Borrados `outfit`, `outfitPresence`, `outfitTarget`, `setOutfit` (no-op
desde sesión 3), `drawOutfitBehind`, `drawOutfitFront` (ya eran código
muerto: `draw()` nunca los llamaba), `outfitFollowsRoll`, los casos
`"outfitPresence"` de `setProperty`/`getProperty`, y el impulso
centrífugo (`centrifugal` + `rollVel` + `prevRoll`). `pumpkinColors` →
`false`; ojos con `+ roll` directo (sin `rigidRoll`).

### 3. Hallazgo: MochiOutfitDrawing.swift NO era solo ropa

El archivo guardaba también la geometría de cabeza/ojos que
`BotEngine.drawEyes` necesita (`MochiH`, `EyeFrame`, `mEyeFrames`).
Borrarlo a ciegas habría roto los ojos de Mochi. La geometría se extrajo
verbatim a `NotchBuddy/Sources/CoucouKit/MochiHeadGeometry.swift`
(verificado por `diff` contra las líneas 1–77 del original; fuera solo
`kEXP` y `kACC_PITCH`, que solo usaban los helpers 3D del outfit).

### 4. Archivos borrados (6 + 2 de tooling)

`MochiOutfitDrawing.swift`, `MochiWardrobe.swift` (tipo `Outfit`),
`tests/MochiWardrobeTests.swift`, `scripts/test-wardrobe.sh`,
`scripts/RenderOutfits.swift`, `scripts/render-outfits.sh` (render de
planchas de outfits, fuera de CI). Además `.github/workflows/build.yml`
pierde el paso `Wardrobe tests` (único sitio de CI que corría ese script;
YAML validado).

### 5. Condición de borrado: CUMPLIDA en el ámbito Mac

Grep `Outfit`/`setOutfit`/`drawOutfit` en `NotchBuddy/Sources` + `tests/`
+ `scripts/` + `.github/`: **0 en código** (solo 2 comentarios de
documento). Balance 0 en los 5 Swift tocados. **Sin compilar: solo la
Mac lo confirma.**

Fuera del grep (a propósito, no tocado): ropa de Android (Kotlin) y
Windows (TS), `CHANGELOG.md:441` (historia), valores muertos de nombres
de ropa en `Localizable.xcstrings`, y `project.pbxproj` (trackeado,
generado por XcodeGen) que todavía referencia los 6 borrados hasta que
JC corra `xcodegen` en su Mac — imprescindible en la verificación, junto
con Shift+Cmd+K (lección de la sesión 4).

### 6. Qué queda de Mochi

`MochiRoom`/`FlowHubRoom`, `MochiStill`, `MochiMood`, `BotEngine`
(sigue dibujando a Mochi en habitación, pills y resumen semanal), 29 WAV,
`whats-new.json`: intactos por decisión del encargo. `WardrobeView`
sigue como aviso y la ruta `.wardrobe` sigue existiendo. `PRODUCT_NAME`
+ bundle id + firmado: NO tocados (ver README-FASE2 §8).

---

## FASE 3, SESIÓN 1 — cliente API + pill `jesly_propuestas` (2026-11-27, local, SIN pushear, SIN compilar)

Fase 2 verificada completa en la Mac de JC antes de empezar (sesiones 1–5
corriendo; última 14:09 AST, Running Coucou, 0 errores, Flow Hub sin Mochis).

### 1. Cliente portado (origen: isla actual, HEAD `3e2a59db`)

`jeslyagent/Jesly-agent-ai`, `apps/island/Sources/JeslyIsland/Api/`
(el `3e2a59d` corto no resuelve como ref en el conector; SHA completo
`3e2a59db612ac5c623d79ea601bcfe8768ce18fd`).

- `NotchBuddy/Sources/JeslyIsland/Api/JeslyAPIClient.swift` (nuevo, 169 l.):
  transporte + errores + **solo propuestas**. Endpoints exactos como en la
  isla (grep contra el origen): `GET /v1/tasks?status=esperando_aprobacion&kind=propuesta`,
  `GET /v1/tasks?status=planificada&kind=propuesta`,
  `GET /v1/tasks?status=aplicada&kind=propuesta`,
  `POST /v1/tasks/:id/<acción>` (`approve`/`reject`/`discard`/`apply`/`revert`/`execute`).
  La decisión vale para el `task id` exacto, sin hook (documentado en el archivo).
  Chat, workflows, habilidades y voz NO se portan en esta sesión (Fases 4–5).
- `NotchBuddy/Sources/JeslyIsland/Api/JeslyModels.swift` (nuevo, 197 l.):
  `JeslyTask` (+ `availableActions`), `ProposalAction`, `ChatResponse`,
  `ChatAttachment`, `JeslyWorkflow`, `JeslySkill`, `WakeStatus`. Los 4 últimos
  sin uso hasta Fases 4–5; son datos puros.
- `NotchBuddy/Sources/JeslyIsland/Api/ApiKeyStore.swift` (nuevo, 77 l.):
  copia verbatim. Llavero servicio `com.jesly.island`, cuenta `jesly-api-key`;
  fallback `JESLY_API_KEY`; sin clave la API local acepta igual. Clave nunca
  hardcodeada ni en logs. Nota: el servicio de llavero es solo un nombre de
  clave y no depende del bundle id del build (hoy `fr.louisraille.NotchBuddy`),
  así que la clave guardada por la isla actual se lee igual desde el fork.
- `NotchBuddy/Sources/JeslyIsland/Api/JeslyProposalsPoller.swift` (nuevo, 82 l.):
  sondeo cada 5 s de `pendingProposals()`; publica `proposals`,
  `apiReachable`, `lastError`. Solo sondea con la pill activa
  (`activeIntegrations` contiene `jesly_propuestas`) y respetando
  `DemoEngine.isPollerPaused`. Cliente nuevo por sondeo (relee la clave
  del llavero cada vez). Con la API apagada: `apiReachable = false`,
  `lastError` con el motivo, lista anterior conservada — la pill muestra
  0 propuestas, sin error que rompa nada.

### 2. `ChatProvider` NO se porta (colisión de nombres, deliberado)

Coucou ya tiene `enum ChatProvider` (`IslandTypes.swift:115`). El struct
de la isla con ese nombre se porta en la Fase 4 como `JeslyChatProvider`.
Ningún método de esta sesión lo usa. Verificado por grep.

### 3. Pill registrada

- `PillCatalog.swift`: `jesly_propuestas`, nombre `JESLY`, color `#E8E0D0`
  (hueso, halo de la nube), categoría `.agent`, subtítulo `"Agent"`
  (clave existente; no hay `"Proposals"` en `xcstrings`), `source: .agent`
  (metadato; los datos vienen del sondeo, no de un hook).
- `AppDelegate.swift` (`setupIsland`, tras `GithubPoller`):
  `JeslyProposalsPoller.shared.start()`.
- La pill aparece en Ajustes → Active pills (categoría Agents). OJO: solo
  caben 4 activas y por defecto ya hay 4 (Resend, n8n, Vercel, GitHub):
  para activar `jesly_propuestas` hay que desactivar una. Sin tarjeta
  (sesión 2) la pill no pone ninguna `AgentTask` en la isla.
- NO tocados: `ApprovalQueue`, `AskQuestion`, `ChatProvider`, voz, ojos,
  workflows, bundle id, entitlements, `HookServer`, `project.yml`,
  `project.pbxproj`.

### 4. Verificación sin compilar (hecha)

Balance 0 en los 6 archivos; endpoints idénticos a la isla; sin colisión
de nombres; `project.yml` sin tocar (el grupo `Sources` ya incluye
`Sources/JeslyIsland/Api/`). **Sin compilar: solo la Mac lo confirma.**

### 5. Para la sesión 2

Tarjeta Propuesta/Permiso (UI de `ApprovalQueue` + `AskQuestion.swift`,
backend `proposalAction(taskId:)`); entrada de la clave en Ajustes
(`ApiKeyStore.save`); acciones por estado según `availableActions`
(+ "Siempre" como regla revocable). Riesgos: API apagada = pill vacía
(por diseño); si la Fase 6 cambia el grupo de acceso del llavero,
revisar `ApiKeyStore`.

## FASE 3, SESIÓN 2 — tarjeta Propuesta/Permiso + clave en Ajustes + "Siempre" (2026-11-27, local, SIN pushear, SIN compilar)

### 1. Archivos nuevos (2)

- `NotchBuddy/Sources/JeslyIsland/JeslyProposalStore.swift`: `AlwaysRule`
  (verbatim de la isla actual, misma clave UserDefaults) +
  `JeslyProposalStore` (singleton @MainActor): `current` (primera
  propuesta: esperando → planificada → aplicada), `act` /
  `answerPermission` por `proposalAction(taskId:)` con el task id
  exacto, `applyAlwaysRules` (auto-aprobación por endpoint real +
  `autoApprovedLog`), `syncIsland()` (abre/cierra la tarjeta).
- `NotchBuddy/Sources/JeslyIsland/Views/JeslyProposalCardView.swift`:
  `JeslyProposalView`, mismo cromo que `ApprovalView` (fondo ámbar,
  `AgentWho` JESLY hueso, "1/N", botones píldora en verbatim). El
  task id se captura al dibujar; el clic se ignora si la tarjeta ya
  pasó a la siguiente.

### 2. Botones por estado

- esperando → Permitir / Denegar / Siempre (crea la regla y aprueba esta).
- planificada con parche → Aplicar / Descartar; sin parche → Ejecutar / Descartar.
- aplicada → Revertir. Primaria = primera no destructiva.

### 3. Cableado

- `IslandTypes.swift`: caso nuevo `IslandView.jeslyProposal` (sin
  switch exhaustivo que romper; `IslandRootView` itera `allCases`).
- `IslandViewContent.swift`: dispatch a `JeslyProposalView()`.
- `AppDelegate.setupIsland`: `JeslyProposalStore.shared.start()`.
- `JeslyProposalsPoller`: ahora trae las tres listas a la vez; con la
  API apagada no hay tarjeta nueva ni errores (0 propuestas).
- `SettingsView`: fila JESLY (tras Agents) con clave API (SecureField
  + Guardar/Borrar al llavero `com.jesly.island`, `refreshNow()` sin
  reiniciar) y reglas "Siempre" con Revocar + últimas 5 auto-aprobadas.

### 4. Verificación sin compilar (hecha)

Balance 0 en los 7 archivos (scanner con interpolación); cada acción
pasa por `proposalAction(taskId: task.id)`; sin hook en el camino de
JESLY; sin colisión de nombres; `project.yml` sin tocar. **Sin
compilar: solo la Mac lo confirma.**

### 5. Para la sesión 3

Tarjeta de sesión en vivo (pasos + diff real, sin inventar pasos de
terminal); verificación/publicación en la tarjeta (Fase 4);
pill `jesly_chat` + `JeslyChatProvider` (Fase 4). Riesgos: la tarjeta
no roba otras vistas (aparece al volver al home o en el siguiente
sondeo); sin badge en la pill; con la API apagada tras actuar, los
ids decididos se guardan hasta el primer sondeo bueno.

## FASE 3, SESIÓN 3 — tarjeta de sesión en vivo JESLY (2026-11-27, local, SIN pushear, SIN compilar)

### 1. Hallazgo: sin endpoint nuevo

La isla actual (`IslandHomeView.swift`, HEAD `3e2a59db`) deriva la
sesión en vivo de las tres listas ya sondeadas
(`GET /v1/tasks?status=...&kind=propuesta`); NO usa
`GET /v1/tasks/:id`. Pasos = tareas (aplicadas hechas, planificadas
+ en espera en curso); diff = `patch` de la primera tarea con
parche, contado de verdad. Nada inventado, ningún paso de terminal
fabricado.

### 2. Archivos nuevos/cambiados

- Nuevo: `Views/JeslySessionCardView.swift` (`JeslySessionView` +
  porte verbatim de `PatchStats` y de los pasos/hora de la isla;
  cromo Coucou: `CardBackground(wash: nil)`, botones píldora
  verbatim, padding 116).
- `IslandTypes.swift`: caso `IslandView.jeslySession`.
- `IslandViewContent.swift`: dispatch a `JeslySessionView()`.
- `JeslyProposalStore.swift`: `syncIsland` elige por estado —
  esperando → `.jeslyProposal` (sesión 2 intacta);
  planificada/aplicada → `.jeslySession`, que lleva los mismos
  botones de esa tarea (Aplicar/Ejecutar/Descartar/Revertir).
  La rama planificada/aplicada de `JeslyProposalView` ya no se
  alcanza por `syncIsland`; sus botones viven en la sesión.

### 3. Qué muestra y de dónde sale

Cabecera "Sesión en vivo" + rama ("rama X" / "Sin sesión activa" /
"API local sin responder") + diff real (archivo +N −M, sin contar
cabeceras `+++`/`---`); pasos máx. 4 (✓ aplicadas, spinner en
curso, HH:mm de `updatedAt`); sin tareas: "Nada en curso…".
Con la API apagada: nada nuevo, sin errores.

### 4. Verificación sin compilar (hecha)

Balance 0 en los 4 archivos (scanner con interpolación); sin
endpoint nuevo ni datos hardcodeados (grep); sin hook en el camino
de JESLY (solo comentarios y `.hookExpand`, como la sesión 2); sin
colisión de nombres; `project.yml` sin tocar. **Sin compilar: solo
la Mac lo confirma.**

### 5. Para la Fase 4

Verificación/publicación en la tarjeta (`POST /v1/tasks/:id/verify`,
`/publish`); pill `jesly_chat` + `JeslyChatProvider`; voz "Oye
JESLY"; ojos. Riesgos: la tarjeta no roba otras vistas; pasos
derivados de las listas (una tarea recién decidida puede verse un
instante en curso); sin badge en la pill.

## FASE 4, SESIÓN 1 — Verificar/Publicar + chat (proveedor y pill)

### 1. Archivos nuevos/cambiados

- `JeslyIsland/Api/JeslyAPIClient.swift`: `chat()` (porte verbatim
  de la isla) + `verify(taskId:)` y `publish(taskId:)` nuevos.
- `JeslyIsland/Api/JeslyModels.swift`: `JeslyChatProvider` (porte
  verbatim del struct de la isla, renombrado) +
  `JeslyVerificationReport` / `JeslyVerificationCheck` /
  `JeslyPublishRecord`.
- `JeslyIsland/JeslyProposalStore.swift`: `verify(task:)` y
  `publish(task:)` + `lastVerification` / `lastPublish`.
- `JeslyIsland/Views/JeslySessionCardView.swift`: botones Verificar
  y Publicar solo si la tarea está en `aplicada`, con feedback del
  resumen.
- `CoucouKit/PillCatalog.swift`: pill `jesly_chat` (`.ai`, hueso).
- `App/SettingsView.swift`: guarda en el hint — JESLY no pide clave
  (sin ella pediría la de OpenAI).
- Docs: `README-FASE2.md` §14.

### 2. Verificación/publicación: evidencia

- NO los usa el cliente de la isla, pero SÍ existen en el servidor
  del mismo repo, HEAD `3e2a59db`: `apps/api/src/routes/tasks.ts:779`
  (`verify`) y `:868` (`publish`); plan v2 §8/§9. Solo `aplicada`
  (409 si no). `verify` exige `checks` no vacío (400 si falta): se
  mandan los defaults locales del servidor (health 3000 + 3003).
  `publish` sin cuerpo usa los defaults del servidor (detecta
  `cloud/`). Veredicto con fallos = 200, no excepción. Nunca se
  fusiona a main.

### 3. El chat en esta sesión

- Transporte + proveedor + pill: `JeslyAPIClient.chat`,
  `JeslyChatProvider.all` (5 proveedores), pill `jesly_chat` en
  Ajustes → Active pills → "AI for the chat". Sin modelo fijo: el
  router elige. Sin API no hay chat y no hay errores. La vista de
  chat con selector e historial es la sesión 2.

### 4. Verificación sin compilar (hecha)

Balance 0 en los 6 archivos (scanner con interpolación anidada);
`verify`/`publish` con task id exacto (grep); un solo enum
`ChatProvider` + un solo struct `JeslyChatProvider` (grep); pill en
el catálogo (grep); sin hook en el camino de JESLY (solo
comentarios). `project.yml` sin tocar. **Sin compilar: solo la Mac
lo confirma.**

### 5. Para la Fase 4, sesión 2

Vista de chat JESLY (selector de proveedor, historial, modelo
real); voz "Oye JESLY" y ojos después. Riesgos: `verify` con checks
locales no dice nada de lo desplegado si la tarea toca `cloud/` —
ahí el botón correcto es Publicar; la pill `jesly_chat` aún no abre
vista; sin badge en la pill.

## FASE 4, SESIÓN 2 — Vista de chat JESLY (2026-11-27, local, SIN pushear, SIN compilar)

### 1. Qué se hizo

- `JeslyChatView` nueva (`Views/JeslyChatView.swift`): selector de
  proveedor (chip que cicla: Automático → Ollama → FreeLLMAPI →
  Groq → Gemini → OpenRouter), historial, entrada y envío por
  `JeslyAPIClient.chat`. Cromo de `PromptView` de Coucou. Debajo de
  cada respuesta de JESLY, el modelo REAL (`ChatResponse.model` +
  proveedor), nunca inventado.
- `JeslyChatStore` nuevo (singleton `@MainActor`): historial en el
  store, no en la vista; proveedor elegido persistido en
  UserDefaults (`com.jesly.island.chatProvider`); sin API, el envío
  falla con el mensaje claro de la isla actual.
- Apertura por las dos vías de Coucou: botón "Chat with JESLY" en
  la tarjeta de la pill (sin puerta de `isConfigured`: no pide
  clave) y la flecha ↗ (`openAgentTarget`). Caso nuevo
  `IslandView.jeslyChat` + dispatch.
- La tarjeta de la pill ya no dice "Key not configured":
  `statusLabel` devuelve "Ready · no setup needed" para
  `jesly_chat` (antes caía ahí porque `isConfigured` es false por
  defecto y `ChatProvider(pillID:)` es nil).

### 2. Qué pasa con la API apagada

Nada roto: la vista lo dice claro antes del primer envío
(127.0.0.1:3000 + cómo arrancar la API) y si el envío falla la
respuesta es el mensaje de la isla actual. Sin errores en la
interfaz.

### 3. Qué NO se hizo

Sin ojos (soltar archivos) ni micrófono/voz; sin workflows ni
habilidades; sin tocar bundle id, entitlements, `HookServer`,
`PillCatalog` ni `project.pbxproj`. Tarjetas de permiso y sesión
intactas: `syncIsland` no roba la vista de chat.

### 4. Verificación sin compilar (hecha)

Balance 0 en los 5 archivos (escáner por líneas; falso +1 inicial
por interpolación anidada, comparado contra el HEAD); el chat usa
`JeslyChatProvider`, ningún uso del `ChatProvider` de Coucou en el
camino de JESLY (grep); sin respuestas hardcodeadas (grep).
`project.yml` sin tocar. **Sin compilar: solo la Mac lo
confirma.** Sospechosos: `JeslyChatView` o el switch nuevo en
`IslandViewContent`.

### 5. Para la Fase 4, sesión 3

Voz "Oye JESLY" (mapa E) y ojos (mapa C: soltar archivo →
`POST /v1/chat` con attachments). Riesgos: el historial no
persiste entre arranques; sin badge en la pill.

## FASE 4, SESIÓN 3 — Voz "Oye JESLY" + ojos (2026-11-27, local, SIN pushear, SIN compilar)

### 1. El endpoint de wake SÍ existe (con evidencia)

`GET /v1/voice/wake/status` en el servidor, HEAD `3e2a59db`:
`apps/api/src/routes/voice.ts:57` → `getWakeStatus`
(`apps/api/src/voice/wake.ts`). Demonio Vosk aparte
(`services/wake-word/daemon.py`) en `127.0.0.1:3004/status`,
timeout 2 s. Respuesta: `{listening, state, engine, uptimeSeconds,
wakeCount, error}`; caído = listening false con 200, nunca 500.
El demonio hace el ciclo STT → chat → TTS del lado del servidor
(`services/wake-word/cycle.py`) cuando oye "Oye JESLY": la app NO
graba cuando el demonio oye la frase, solo sondea el estado cada
5 s y lo muestra.

### 2. Archivos nuevos/cambiados

- NUEVO `JeslyIsland/Voice/VoiceTalker.swift`: porte verbatim de
  la isla (grabar 16 kHz mono → transcribe → chat → synthesize,
  recortado a 1800 → reproducir WAV). `interrupt()` corta voz y
  grabación. Audio solo en memoria. Sin sonidos de Mochi.
- NUEVO `JeslyIsland/JeslyVoiceStore.swift`: sondea `wakeStatus`
  cada 5 s (`.down` por defecto), dueño del talker. Arranque en
  `AppDelegate.setupIsland`.
- `Api/JeslyAPIClient.swift`: `wakeStatus()`, `transcribe()`,
  `synthesize()` (verbatim de la isla).
- `CoucouKit/PillCatalog.swift`: pill `jesly_voz` (`.agent`,
  hueso). Los ojos NO tienen pill: son la zona de soltar del chat.
- `JeslyIsland/JeslyChatStore.swift`: `send(_:attachments:)`,
  `visionBadge` ("Vio: proveedor / modelo"),
  `appendVoiceExchange` (historial de voz sin modelo).
- `JeslyIsland/Views/JeslyChatView.swift`: indicador del demonio,
  micrófono (grabar / ■ interrumpir / spinner), zona de soltar
  con borde punteado + fila de adjuntos, `.onDrop([.image,
  .movie])`. Límites: imágenes 10 MB, videos 50 MB, máx. 4
  adjuntos y 1 video; formato `attachments: [{kind, mediaType,
  data(base64)}]`, exacto de la isla.
- Permiso de micrófono: ya existe en `project.yml` (3 targets).
  Sin permisos nuevos.

### 3. Verificación sin compilar (hecha)

Balance 0 en los archivos nuevos/tocados (escáner Swift-aware);
la voz usa el endpoint real de la isla (grep) y los adjuntos el
formato real de `POST /v1/chat` (grep). `project.yml` sin tocar.
**Sin compilar: solo la Mac lo confirma.** Sospechosos:
`VoiceTalker` (AVFoundation) o `JeslyChatView` (UTType, drop).

### 4. Para la Fase 5

Workflows, habilidades y recordatorios (mapas B y F); decidir qué
pills de Coucou quedan. Riesgos: el demonio no lo arranca la app;
el intercambio de voz queda sin modelo en el historial.

## FASE 5, SESIÓN 1 — Workflows, habilidades y recordatorios

### 1. Qué se hizo

- `JeslyIsland/Api/JeslyAPIClient.swift`: `sendVoid` + workflows (`workflows`,
  `runWorkflow`, `setWorkflowEnabled`, `deleteWorkflow`), habilidades (`skills`,
  `testSkill`, `approveSkill`, `rejectSkill`, `uninstallSkill`) y recordatorios
  (`reminders`, `createReminder`, `silenceReminder`, `deleteReminder`).
- `JeslyIsland/Api/JeslyModels.swift`: modelo nuevo `JeslyReminder` (forma exacta
  de `ReminderView`); comentarios "sin uso" de `JeslyWorkflow`/`JeslySkill` a Fase 5.
- `JeslyIsland/JeslyWorkflowsStore.swift` (nuevo): singleton `@MainActor`, sondeo
  cada 15 s como la isla, best-effort; `JeslySkillAction`.
- `JeslyIsland/Views/JeslyWorkflowsSkillsViews.swift` (nuevo): `JeslyWorkflowsView`,
  `JeslySkillsView`, `JeslyRemindersView` (porte de la isla; la de recordatorios
  sigue su estilo, la isla no tiene vista propia).
- `App/SettingsView.swift`: tres GroupBox en la sección JESLY (Workflows,
  Habilidades, Recordatorios). `App/AppDelegate.swift`: `JeslyWorkflowsStore.shared.start()`.

### 2. Endpoints (todos existen, con evidencia)

- Workflows `routes/workflows.ts`: `GET /v1/workflows`, `POST /v1/workflows/:id/run`,
  `PATCH /v1/workflows/:id { enabled }`, `DELETE /v1/workflows/:id`.
- Habilidades `routes/skills.ts`: `GET /v1/skills`, `POST /v1/skills/:id/test|approve|reject|uninstall`.
  Instalar desde manifiesto es follow-up (`POST /v1/skills/install` existe, la isla
  aún no sube manifiestos).
- Recordatorios `routes/reminders.ts`: `POST /v1/reminders { text }` → 201,
  `GET /v1/reminders`, `POST /v1/reminders/:id/silence`, `DELETE /v1/reminders/:id`.
- Hallazgo: no hay endpoint "hecho". El botón "Hecho" llama a silence (desactiva el
  workflow para que no suene más). No se inventó otra ruta.

### 3. Verificación sin compilar (hecha)

Balance 0 en los 6 archivos nuevos/tocados (escáner Swift-aware); cada endpoint usado
existe en la isla y en el servidor (grep); sin colisión de nombres. `project.yml` sin
tocar. **Sin compilar: solo la Mac lo confirma.** Sospechosos:
`JeslyWorkflowsSkillsViews.swift` o el store nuevo.

### 4. Para la Fase 5, sesión 2

Decidir con JC qué pills de Coucou quedan (Flow, Mail, música, WhatsApp, demo,
semanal) y quitar o dejar las demás; investigación profunda (`POST /v1/investigar`) y
cuentas conectadas; resumen diario. Riesgos: el run tarda un sondeo en verse como
tarea en curso; sin instalar habilidades desde manifiesto.

### 5. Corrección tras la verificación de JC (2026-11-27 19:01 AST)

JC compiló bien pero no veía las secciones en la ventana que él usa. Causa real:
la fila JESLY solo existía en la ventana de Ajustes suelta (`SettingsView`); la
ventana que JC usa es el Flow window (`FlowHub`), cuyo menú NO tenía caso `jesly`
en `HubPage`, así que la sección era inalcanzable desde ahí (su `forSettings`
caía en `.general`). Corrección: caso `jesly` nuevo en `HubPage`
(`FlowHub.swift`: enum, `notchPages` tras `.agents`, `settingsSection` → "jesly",
título "JESLY", símbolo `cloud.fill`) + color hueso `#E8E0D0` en
`HubHeroTheme.of` (`FlowHubMochis.swift`, switch exhaustivo — sin ese caso no
compila). El `default:` de la vista de página ya renderiza
`SettingsView(embeddedSection: "jesly")`. Ahora la fila JESLY aparece en el
menú NOTCH del Flow window, entre Agentes y Chat.

## FASE 5, SESIÓN 2 — Investigación profunda, cuentas conectadas, resumen diario

### 1. Archivos nuevos/cambiados (7, sin push)

- `Api/JeslyModels.swift`: `JeslyResearchSource`, `JeslyFailedPage`,
  `JeslyResearchResult`, `JeslyConnectedAccount`, `JeslyDailyDigest`,
  `JeslyDigestWorkflowToday`, `JeslyDigestScheduleResponse`.
- `Api/JeslyAPIClient.swift`: `investigate(pregunta:provider:)`,
  `connectedAccounts()`, `dailyDigest()`, `scheduleDailyDigest(hour:)`,
  `deleteDailyDigest()`.
- `JeslyChatStore.swift`: modo investigar (`researchMode`,
  `researching`, `toggleResearchMode()`, `sendResearch(_:)`); el
  mensaje guarda el informe (`JeslyChatMessage.research`).
- `Views/JeslyChatView.swift`: botón de lupa junto al micrófono,
  indicador "Investigando en la web…", fuentes como enlaces con su
  fecha y verificación.
- `JeslyWorkflowsStore.swift`: `accounts`, `dailyDigest`,
  `digestHour` + refrescos en el sondeo de 15 s; acciones
  `scheduleDailyDigest(hour:)` / `deleteDailyDigest()`.
- `Views/JeslyWorkflowsSkillsViews.swift`: `JeslyAccountsView`,
  `JeslyDailyDigestView`.
- `App/SettingsView.swift`: GroupBox "JESLY — Cuentas conectadas" y
  "JESLY — Resumen diario" tras "JESLY — Recordatorios".
- Docs: `README-FASE2.md` §18 (con el inventario completo de pills)
  y esta sección.

### 2. Endpoints (todos existen y están montados, con evidencia)

`apps/api/src/index.ts`: digest :153, investigar :158, cuentas :160.
- `POST /v1/investigar { pregunta, provider? }` → 200 `{ respuesta,
  fuentes, fechaConsulta, consultas, paginasFallidas, fuente,
  provider?, model? }`; 400 sin pregunta o >1000 caracteres; 503 sin
  web. `fuente` "modelo" o "extractiva". `MAX_PAGES = 8`.
- `GET /v1/cuentas` → `{ cuentas }` (PublicAccount, sin tokens).
  Solo lectura: conectar/desconectar existen en el servidor pero no
  se cablean aquí (OAuth con redirect / token fine-grained).
- `GET /v1/resumen-diario` (vista previa), `POST /v1/resumen-diario
  { hora }` → 201/200 (crea o actualiza el workflow "Resumen diario
  — buenos días"), `DELETE /v1/resumen-diario` (apagar, 404 si no hay
  ninguno). La hora del resumen se deriva del workflow programado
  (cron `M H * * *`), nunca se inventa.

### 3. Hallazgos

- La isla actual NO tiene botón de investigar ni vista de cuentas ni
  de resumen: su agente investiga con la herramienta interna, su
  pill "Correo" es "Próximamente — cuentas conectadas (§11)" y el
  resumen llega por chat/push. Todo lo de esta sesión es UI nueva
  en el fork sobre endpoints que ya existían.
- El resumen programado ES un workflow: se ve en la lista de
  workflows con su horario.
- La investigación no se puede cancelar en vuelo; preguntas de más
  de 1000 caracteres fallan con 400 del servidor.

### 4. Inventario de pills (resumen; la tabla completa está en README-FASE2.md §18.4)

33 pills en `PillCatalog.all`. Recomendación: quedarse 3
incondicionales (jesly_propuestas, jesly_voz, jesly_chat) + 6
condicionales (VS Code, Cursor, Codex, Gemini CLI si JC los usa;
GitHub y Vercel si se cablea su feed de n8n) + quitar 24 (el resto
de agentes CLI, los 5 chats directos de Coucou, Resend/n8n/Notion/
Cal.com/Stripe, música, Mail, WhatsApp, Crypto, Coucoudoro,
Portfolio). No son pills: Flow (Dictado quedarse, Notetaker a
decidir), modo demo (quitar del producto final), resumen semanal
(no se porta: lo sustituye el resumen diario). **Aplicado en la
Fase 5, sesión 3 (ver abajo): las 24 se quitaron; las 6
condicionales quedan pendientes de la confirmación de JC.**

### 5. Verificación sin compilar (hecha)

Balance 0 en los 7 archivos (escáner Swift-aware); cada endpoint
existe en el servidor y está montado; formas de respuesta
verificadas contra las rutas y los tipos TS; sin colisión de
nombres. `project.yml` sin tocar. **Sin compilar: solo la Mac lo
confirma.** Sospechosos: `JeslyChatView.swift` o
`JeslyWorkflowsSkillsViews.swift`.

### 6. Para la Fase 5, sesión 3

Aplicar la decisión de pills de JC (quitar las que diga, con sus
borrados y verificación); conectar cuentas desde la isla si JC lo
pide; resto del mapa F si queda algo; luego Fase 6 (verificación en
vivo + conflicto de hooks).

### 6. Corrección tras BUILD FAILED de JC (2026-11-27 19:23 AST)

1 error, 8 warnings (los warnings son viejos, no de JESLY). Error:
`Stored property 'workflow' of 'Sendable'-conforming struct
'JeslyDigestScheduleResponse'` — `JeslyDigestScheduleResponse` es `Sendable`
y guarda `workflow: JeslyWorkflow`, pero `JeslyWorkflow` no era `Sendable`.
Corrección: `JeslyWorkflow: Codable, Identifiable, Equatable, Sendable`
(todas sus propiedades son `String?`/`Bool?`, así que es seguro).

## Fase 5, sesión 3 — Quitar las 24 pills (2026-11-27, sin pushear)

Quitar = sacar del catálogo y de todo sitio que las referencie, sin
dejar referencias rotas. Verificación sin compilar: balance 0 en
los 28 archivos tocados (escáner Swift-aware); grep final con 0
hits de los 24 ids en `NotchBuddy/Sources` y `NotchBuddy/Tests`
(salvo `README-FASE2.md` §18.4, que es la especificación); las 3
de JESLY y las 6 condicionales siguen presentes en `PillCatalog`.
**Sin compilar: solo la Mac lo confirma.**

### Pills quitadas (24)

Otros agentes CLI: `agent_antigravity`, `agent_copilot`,
`agent_muse`, `agent_opencode`, `agent_amp`, `agent_hermes`,
`agent_claude-desktop`. Chats directos de Coucou: `ai_anthropic`,
`ai_google`, `ai_openai`, `ai_ollama`, `ai_lmstudio`. Servicios:
`integration_resend`, `integration_n8n` (solo la pill; el poller
sigue alimentando `n8nRuns` para el Flow window),
`integration_notion`, `integration_calcom`, `integration_stripe`,
`integration_music`, `integration_spotify`, `integration_mail`,
`integration_whatsapp`, `integration_crypto`,
`integration_coucoudoro`, `integration_portfolio`.

### Pills que quedan (9)

3 de JESLY: `jesly_propuestas`, `jesly_voz`, `jesly_chat`.
6 condicionales, pendientes de la confirmación de JC:
`integration_claude` (VS Code), `agent_cursor`, `agent_codex`,
`agent_gemini`, `integration_vercel`, `integration_github`.

### Archivos cambiados (28)

- `CoucouKit/PillCatalog.swift`: 24 entradas quitadas de `all`.
- `CoucouKit/IslandTypes.swift`: `ChatProvider.pillID` e
  `init?(pillID:)` sin los 5 casos `ai_*`.
- `App/AppState.swift`: activas por defecto solo vercel + github.
- `App/Voice/EntityResolver.swift`: alias de voz quitados.
- `App/FlowHubRoom.swift`: `isPlan` sin Antigravity; "Always"
  solo vetado para Codex.
- `App/DemoEngine.swift`: rotación solo `integration_vercel`.
- `CoucouKit/ServiceSnapshot.swift`: `phoneServices` solo
  github + vercel.
- `Widgets/CoucouWidgets.swift`: `regulars` solo
  github/vercel/codex.
- `Widgets/TeamConfiguration.swift`: casos de enum quitados
  (antigravity, stripe, resend, calcom, n8n, notion).
- `App/N8nPoller.swift`: quitado el bloque que actualizaba la
  tarea de n8n; el poller sigue alimentando `n8nRuns`.
- `App/Voice/IntentParser.swift`: destino de música por nombre
  "spotify"/"apple music"; `musicServicePillIds` vacío.
- `App/IslandViewContent.swift`: casos de `openAgentTarget`,
  tarjeta de aprobación, ramas "Open Claude", `openClaudeDesktopApp`,
  switches `isConfigured`/`openURL`/`statusDot`/`statusLabel`,
  `isHooks`, helpers de datos (`n8nHasActivity`, `resendHasData`,
  `stripeHasData`, `calcomHasData`, `notionHasData`, `musicIsActive`,
  `mailHasData`, `isSpotify`), tarjetas y botones de los servicios
  quitados, `pill()` y `hideJumpButton`.
- `App/HookServer.swift`: `validateAgent` rechaza los agentes
  quitados (con `removedAgentNames`); la ruta de permisos les
  responde "ask" en su terminal; la rama `agy_pre_tool` responde
  "ask" sin tarjeta; borrados `agyApprovalGate` y
  `processAgyApproval`; casos de `handledNote`/`waitingNote`;
  cláusula de `agent_claude-desktop`; bloque de plataforma de
  Hermes. Se dejan `agyApprovalsKey`, `agyApprovalHookTimeout` y
  los instaladores de hooks (los `@State` de Ajustes aún los
  referencian; limpieza posterior).
- `App/SettingsView.swift`: 6 GroupBoxes de hooks de agentes
  quitados, `ClaudeDesktopChatSettingsSection`, sección y ajustes
  de Coucoudoro, hints de `pillRow`, clave `ai_*` del chat.
- Controladores (sin borrar enteros: sus funciones viven fuera de
  la pill): `MusicController` y `SpotifyController` siguen el
  seguimiento para la voz, sin `pillId`/`isPillActive`/`syncTaskName`;
  `MailController` sondea mientras Mail corre (páginas del Flow
  window); `WhatsAppController` arranca solo con el ajuste y sus
  helpers de insignia quedan vacíos; `CryptoController` y
  `PortfolioController` quedan sin sondeo en vivo (`refresh()` por
  llamada sigue sirviendo). Vistas: colores literales en
  `CryptoViews`/`PortfolioViews`, `"Integration"` en
  `SpotifyViews`, sin aviso de slot en `WhatsAppViews`.
- `App/PhoneLink/ServiceDetailRunner.swift`: casos y funciones
  `stripe`/`resend`/`calcom`/`n8n`/`notion` quitados; quedan
  vercel/github.
- `App/PhoneLink/ServicePublisher.swift`: funciones `stripe`/
  `resend`/`calcom`/`n8n`/`notion` quitadas; `all(from:)` solo
  github + vercel.
- `App/AppDelegate.swift`: arranques de los pollers/watcher/
  controlador borrados.
- `App/SettingsSearch.swift`: 6 entradas de agentes quitados y
  palabras clave de Coucoudoro quitadas.

### Archivos borrados (9, exclusivos de una pill quitada)

`StripePoller.swift`, `CalcomPoller.swift`, `NotionPoller.swift`,
`ResendPoller.swift`, `ClaudeDesktopChatWatcher.swift`,
`CoucoudoroEngine.swift`, `CoucoudoroController.swift`,
`CoucoudoroViews.swift`, `Tests/CoucoudoroEngineTests.swift`.
Justificación: cada uno solo servía a su pill; nada más los
referenciaba salvo comentarios (`AppState`, `VoiceDataSources`) y
los campos de clave de API en Ajustes, que se quedan (son claves,
no pills).

### Qué NO se tocó

Bundle id, entitlements, `project.pbxproj`, modo demo, `ChatProvider`
(como enum se queda; solo perdió su mapeo a pills), `MochiRoom`,
`MochiMood`, `BotEngine`, WAV, `whats-new.json`, `PRODUCT_NAME`,
nada de JESLY, nada de Windows/Linux/Android. Los campos de clave
de API (Stripe, Resend, Cal.com, Notion) siguen en Ajustes →
Integrations aunque sus pills ya no existan.

### Qué debe verse tras verificar

Ajustes → Active pills: solo 9 pills — 3 de JESLY
(`jesly_propuestas`, `jesly_voz`, `jesly_chat`) + 6 condicionales
(VS Code, Cursor, Codex, Gemini CLI, Vercel, GitHub). Las
activas por defecto son solo Vercel y GitHub. Con la API apagada
nada cambia: las pills de JESLY muestran 0 propuestas sin
errores, como antes.

### Pendiente

Verificación en la Mac de JC (pull + `xcodegen` + Shift+Cmd+K +
Cmd+B + Cmd+R). Si BUILD SUCCEEDED: sesión verificada; luego
Fase 6 (verificación en vivo + conflicto de hooks).

### 7. Corrección tras BUILD FAILED de JC (2026-11-27 20:00 AST)

2 errores en `IslandViewContent`, ambos "Expected expression" en
`AgentPillsView.pill(_:)`: al quitar las ramas de Coucoudoro/Música/Spotify
quedaron dos `else {` huérfanos sin `if` previo (uno por rama `#if
!APPSTORE` / `#else`). Corrección: quitar los dos `else {` y dejar el
`AgentPill` directo. Balance 0 verificado tras la corrección; no quedaba
ningún otro `else {` huérfano en los archivos tocados.

### 8. Corrección tras BUILD FAILED de JC (2026-11-27 20:02 AST)

2 errores en `HookServer`, ambos "Cannot find 'isCopilotRequest' /
'isMuseRequest' in scope": al quitar las definiciones de esos dos flags
(agentes Copilot y Muse ya no existen) quedó su único uso en el timeout de
seguridad de la cola de permisos. Corrección: timeout fijo de 115 s, sin la
rama de 110 s que era solo para esos dos agentes.

## FASE 6, SESIÓN 1 — Plan de verificación en vivo + conflicto de hooks (2026-11-27, local, SIN pushear, SIN compilar)

Fase 5 verificada completa en la Mac de JC antes de empezar (sesión 3:
24 pills quitadas, quedan 9; HEAD remoto `0650ee9b`). El plan completo
y ordenado está en `README-FASE2.md` §19; aquí el resumen.

### 1. El conflicto de hooks: hallazgos

- **La isla actual NO instala hooks.** Búsqueda en todo
  `jeslyagent/Jesly-agent-ai`: 0 referencias a `settings.json`,
  `.claude`, `nb-hook` o `claude` en `apps/island/`. Solo habla con
  su API por HTTP. **No hay conflicto fork ↔ isla actual**: pueden
  correr a la vez (misma API, misma clave de llavero, mismas
  propuestas); solo las reglas "Siempre" son por app (UserDefaults
  distintos), y conviene actuar solo en una para no confundirse.
- **El conflicto real es fork ↔ Coucou original.** El fork usa las
  rutas EXACTAS de upstream (renombre aplazado): support dir
  `NotchBuddy`, socket `nb.sock`, script `nb-hook`, entradas en
  `~/.claude/settings.json` (+ Gemini y Muse). Tres mecanismos
  silenciosos: (1) **robo de socket al arrancar** — `start()` borra
  y re-enlaza `nb.sock`, la última app que arranca se queda con
  todos los eventos; (2) **reescritura del script en cada arranque**
  — `installHookScript()` escribe `nb-hook`/`nb-hook.py` en el dir
  compartido; (3) **`settings.json` no distingue dueña** — el fork
  y Coucou escriben el mismo comando, `claudeHooksInstalled()` da
  true para cualquiera.
- **JESLY no necesita hooks.** Todo va por la API; los hooks solo
  alimentan las pills de sesiones CLI (VS Code, Cursor, Codex,
  Gemini CLI).

### 2. Solución propuesta (decisión de JC)

- **A. Recomendada: hooks APAGADOS por defecto.** No instalarlos
  hasta que JC confirme que vigila sesiones de terminal en el fork.
- **B. Renombrar a `jesly-*`** (sesión posterior): `jesly-hook`,
  `jesly.sock`, `~/.claude/jesly/`. Pero Claude Code dispararía
  AMBOS hooks por evento (dos entradas) y un permiso podría
  responderse dos veces: no recomendado sin probarlo.
- **C. Traspaso explícito:** "Hacerse dueña" desde la alerta,
  cerrando la otra app.

### 3. Código implementado en esta sesión (sin instalar hooks)

- `App/HookServer.swift`: guarda del socket en `serverThread()` —
  antes de borrar y enlazar `nb.sock`, sondea si un servidor vivo
  ya responde; si responde, NO toma el socket (log + marca
  `jeslySocketTakenByOtherApp` en UserDefaults, limpia en cada
  arranque). Archivo huérfano = se sigue el camino de siempre.
  Clave `socketTakenKey`.
- `App/SettingsView.swift`: alerta "Los hooks ya tienen dueña" en
  `installHooks()` si `settings.json` ya tiene nb-hook y no lo
  instaló este fork (marca propia `jeslyForkHooksInstalled`: se
  pone al instalar, se quita al desinstalar); aviso visible en
  Ajustes → Agents cuando el socket lo tenía otra app al arrancar.
- Verificación sin compilar: balance 0 en los 2 archivos (el -6 de
  paréntesis de `HookServer.swift` es ruido del escáner, idéntico en
  el archivo base upstream); sin referencias rotas (grep).
  **Sin compilar: solo la Mac lo confirma.** Los instaladores de
  Gemini/Codex/Muse comparten nb-hook y socket: la guarda del
  socket los cubre en el mecanismo; sus alertas propias quedan
  como follow-up.

### 4. Plan de verificación en vivo (resumen)

Detalle completo en `README-FASE2.md` §19.3. Stack con
`bash scripts/arrancar-todo.sh` (Postgres 5433, Ollama 11434, API
3000, STT 3001, TTS 3002, Web 3003); activar la pill JESLY;
crear 4 propuestas por `POST /v1/tasks` (A con parche que crea
`docs/verificacion-fork-2026-11-27.md`, B/C/D sin parche;
`agent_id: "mac"`, clave Bearer del `.env` si existe); Permitir →
Aplicar (rama `jarvis-test/<id-corto>`, worktree en
`~/.cache/jarvis/worktrees/<id-corto>`, main intacto) → Verificar
(checks locales 3000+3003) → Publicar (push de la rama, nunca
merge a main) → Revertir (borra rama + worktree); chat con modelo
real; voz manual + demonio Vosk (`arrancar-wake-word.sh`); ojos
(soltar imagen, insignia "Vio: proveedor / modelo"); workflows /
habilidades / recordatorios; lupa de investigación; cuentas y
resumen diario; limpieza (revocar la regla "Siempre", parar el
demonio y el stack).

### 5. Para la Fase 6, sesión 2

Aplicar la decisión de JC (§2); probar la guarda en vivo (fork con
Coucou corriendo → aviso en Ajustes → Agents, sin robo de socket;
instalar → alerta → hacerse dueña). Pendientes sueltos: quitar el
paso "Wardrobe tests" de `.github/workflows/build.yml` (403); las 3
decisiones de `PRODUCT_NAME`/bundle id; instaladores de hooks de
agentes quitados como código muerto (limpieza posterior).

## FASE 6, SESIÓN 2 — Decisión A: hooks apagados por defecto (2026-11-27)

Decisión de JC: **A — hooks apagados por defecto**. Sin push, sin compilar.

### 1. Auditoría de caminos de arranque

- `AppDelegate.setupIsland()` → `HookServer.shared.start()` (único
  arranque): **INSTALABA SOLO** — `installHookScript()` en cada
  arranque reescribía nb-hook/nb-hook.py en el dir compartido aunque
  JC nunca hubiera instalado hooks en el fork. **GUARDA AÑADIDA:**
  el script solo se escribe si `HookServer.jeslyForkOwnsHooks`
  (marca `jeslyForkHooksInstalled`, que pone `confirmInstall()` y
  quita `uninstallHooks()`). La marca vivía duplicada en
  `SettingsView`; ahora vive solo en `HookServer` y Ajustes la lee
  de ahí. La guarda del socket de la sesión 1 sigue igual.
- Instaladores manuales Claude/Gemini/Antigravity/Codex/Copilot/
  Muse (`write*Hooks()`): **NO INSTALAN SOLOS** — solo desde los
  botones de confirmar de Ajustes tras ver el diff. Se quedan como
  están, salvo que cada uno escribe ahora el script nb-hook al
  confirmar (antes lo garantizaba `start()`; sin eso, una
  instalación manual en máquina nueva apuntaría a un script
  inexistente). App Store ya escribía script + settings en un paso.
- StatusLine, botón "Update hooks", activar pills: manuales o solo
  lectura. Onboarding/primera ejecución que toque hooks: no existe.
  Sin cambios en ninguno.

### 2. Texto visible nuevo

Ajustes → Agents, arriba del cuadro de Claude Code: "Hooks apagados
por defecto: JESLY funciona completo sin ellos. Nada se instala solo
al arrancar — usa Instalar solo si quieres vigilar sesiones de
terminal (Claude Code, Cursor, Codex, Gemini CLI) en la isla."

### 3. Verificación sin compilar (hecha)

Balance 0 en `HookServer.swift` y `SettingsView.swift` (el -6 de
paréntesis de `HookServer.swift` es ruido del escáner, idéntico en
el archivo base upstream); 0 restos de la marca vieja
(`jeslyForkOwnsClaudeHooks` / `Self.jeslyForkHooksOwnerKey`);
`installHookScript()` solo se llama desde `start()` (con guarda) y
los 6 `write*Hooks()` manuales; `start()` solo se llama desde
`AppDelegate.setupIsland()`. **Sin compilar: solo la Mac lo
confirma.** Sospechosos: la guarda de `start()` o el texto nuevo.

### 4. Para cerrar la Fase 6

Verificación en vivo de 14 pasos (README-FASE2.md §19.3) con la API
arrancada, que corre JC en su Mac; probar la guarda en vivo (fork
con Coucou corriendo → aviso, sin robo de socket ni reescritura del
script; instalar → alerta "Los hooks ya tienen dueña"). Pendientes
sueltos: quitar el paso "Wardrobe tests" de `.github/workflows/build.yml`
(403); las 3 decisiones de `PRODUCT_NAME`/bundle id.

## FASE 6 — CORRECCIÓN: `plan` es lista en el servidor, texto en el modelo (2026-11-27, sin pushear, sin compilar)

### 1. Bug confirmado en vivo

Durante la verificación en vivo de 14 pasos (§19.3), la tarjeta de
permiso nunca apareció aunque la API tenía 4 propuestas en
`esperando_aprobacion` (verificado por curl: A `bd3a05f2`, B
`28f62b0f`, C `1ed2617f`, D `3ab0da36`). La clave sí estaba guardada
en el llavero (33 caracteres medidos con `security … | wc -c`), el
stack estaba todo arriba y el sondeo está bien cableado
(`AppDelegate.setupIsland` arranca poller + store). La causa era el
modelo, no la clave ni el sondeo.

### 2. Evidencia del servidor

`apps/api/src/routes/tasks.ts` (repo `jeslyagent/Jesly-agent-ai`):

- Línea 71: `plan: unknown;`
- Línea 210: `const plan = Array.isArray(req.body?.plan) ? req.body.plan : [];`
- Línea 282: `JSON.stringify(plan)` (se guarda como lista JSON)

El curl real devuelve `"plan":[]`. Pero el fork declaraba en
`NotchBuddy/Sources/JeslyIsland/Api/JeslyModels.swift:27`
`public var plan: String?`. JSONDecoder no puede decodificar un
array como `String?`: fallaba TODA la respuesta `TasksResponse`,
el poller marcaba `apiReachable=false`, las listas quedaban vacías,
la pill marcaba 0 y la tarjeta no salía. Es la primera vez que la
API devuelve tareas reales; con la API apagada nunca se vio.

### 3. Corrección (1 archivo)

Solo `NotchBuddy/Sources/JeslyIsland/Api/JeslyModels.swift`:
`JeslyTask` gana un `init(from:)` personalizado y un
`decodePlan(from:)` privado. `plan` sigue siendo `String?` por
fuera — `JeslyProposalCardView.swift:119` (`if let plan = task.plan,
!plan.isEmpty { return plan }`) no se toca. Decodificación:

- Texto directo → tal cual.
- Lista de textos → unidos por líneas (`\n`).
- Cualquier otra forma (lista de objetos, null, ausente) → nil,
  sin fallar.

El resto de campos se decodifica igual que antes (id, title,
status, kind obligatorios; plan, result, agentId, proposal, patch,
branch, commitSha, createdAt, updatedAt opcionales; el decoder
sigue usando `convertFromSnakeCase` en `JeslyAPIClient`).
`encode(to:)` sigue sintetizado (nada codifica un `JeslyTask` en
el fork) y no hay construcciones por miembros de `JeslyTask` en
el código (grep: 0), así que el `init(from:)` personalizado no
rompe ningún llamador.

Casos razonados contra el JSON real (simulados, misma lógica):

- Tarea A real (`bd3a05f2`, `"plan":[]`, `"result":null`) → `plan`
  nil; el resto decodifica igual que antes. La tarea entra en la
  lista y la tarjeta puede abrirse.
- `"plan":["Crear el archivo","Añadir la línea"]` →
  `"Crear el archivo\nAñadir la línea"`.
- `"plan":"Revisar y aplicar el parche"` → el mismo texto.
- Extra: lista de objetos o `plan` ausente → nil.

### 4. Hallazgo pendiente (OTRO REPO, no se corrige aquí)

La isla actual (`jeslyagent/Jesly-agent-ai`,
`apps/island/Sources/JeslyIsland/Api/JeslyModels.swift`, HEAD
`3e2a59db`) tiene el mismo modelo portado verbatim y por tanto el
mismo bug: su `plan: String?` también romperá al decodificar las
tareas reales. Anotado aquí; la corrección en ese repo es trabajo
aparte.

### 5. Verificación sin compilar (hecha)

Balance llaves/paréntesis/corchetes **0** en `JeslyModels.swift`
(escáner Swift-aware); `task.plan` sigue siendo `String?` en toda
la UI (único uso: `JeslyProposalCardView.swift:119`, sin tocar).
**Sin compilar: solo la Mac lo confirma.** Sospechoso si falla:
el `init(from:)` personalizado (p. ej. `CodingKeys` sintetizado)
o el `decodePlan`.

### 6. Para retomar la verificación en vivo

Tras el pull + build en la Mac de JC, la verificación de 14 pasos
(§19.3) se retoma en el **paso 4** (tarjeta de permiso): la pill
JESLY debe marcar **4** y la tarjeta de la propuesta A debe
abrirse sola. Las 4 propuestas siguen en `esperando_aprobacion`
en la API; no hay que recrearlas.

## FASE 6 — CORRECCIÓN: crash al abrir la tarjeta, `viewLayouts` sin entradas JESLY (2026-11-27, sin pushear, sin compilar)

### 1. Crash confirmado en vivo (2026-11-27)

La app compiló y corrió, el sondeo ya trae las 4 propuestas (la
corrección del `plan` funcionó), pero al abrir la tarjeta la app
se cae. Captura de JC (depurador de Xcode):

- `Thread 1: Fatal error: Unexpectedly found nil while unwrapping an Optional value`
- `NotchBuddy/Sources/App/IslandRootView.swift:526`: `let layout = IslandConst.viewLayouts[view]!`
- Estado en el depurador: `mode = expanded`, `view = jeslyProposal`.

### 2. Causa

`IslandConst.viewLayouts`
(`NotchBuddy/Sources/CoucouKit/IslandTypes.swift:244`) NO tiene
entradas para NINGUNA de las tres vistas JESLY
(`.jeslyProposal`, `.jeslySession`, `.jeslyChat` — casos
declarados en `IslandTypes.swift:21-23`). El `!` revienta en
cuanto la isla intenta dibujar una de ellas en modo expandido.
Hay un segundo `!` igual en
`NotchBuddy/Sources/App/IslandWindowController.swift:2257`
(`islandSize`, mismo `case .expanded`).

Las Fases 3–4 se "verificaron" con la API apagada, así que la
tarjeta nunca llegó a dibujarse y el hueco no se vio.

Por qué el chat (Fase 4 s2, verificado "listo" por JC) no se cayó
antes, si tampoco tenía entrada: **no se puede establecer por el
código, y no se inventa una razón.** Lo establecido es que las
tres vistas comparten exactamente el mismo camino:
`IslandViewContent` (caso → vista) → `state.view` →
`BotPlacement` (`IslandRootView.swift:406`) e `islandSize`
(`IslandWindowController.swift:1233/1490/1627`), y los dos `!`
están bajo `mode == .expanded`. No hay ninguna razón a nivel de
código por la que `.jeslyChat` sobreviviera y `.jeslyProposal`
no. Lo más plausible es circunstancial (que en esas sesiones el
modo no fuera `.expanded` cuando JC miró el chat), pero eso no
se puede comprobar desde el código ni desde las confirmaciones
previas, que no dejan constancia de la isla expandida sobre la
vista de chat. Queda anotado como no establecido.

### 3. Corrección (3 archivos, solo esto)

`NotchBuddy/Sources/CoucouKit/IslandTypes.swift`:

- Tres entradas nuevas en `viewLayouts`, tras `.question`, con
  el layout de `.approval` como base (height 160, botX 62,
  botY nil, botDiameter 56, agentMode .column): la tarjeta de
  permiso copia el cromo de `ApprovalView`, y la de sesión y el
  chat son tarjetas del mismo tipo.
  - `.jeslyProposal` (Fase 3), `.jeslySession` (Fase 3,
    sesión 3), `.jeslyChat` (Fase 4, sesión 2), cada una con su
    comentario de fase como hacen las demás.
- Helper nuevo `IslandConst.layout(for:)` tras el diccionario:
  `viewLayouts[view] ?? viewLayouts[.overview] ?? ViewLayout(...)`
  con los valores literales de `.overview`. Una vista sin entrada
  usa el layout de `.overview` (que siempre existe) en vez de
  reventar; el último `??` es inalcanzable en la práctica y
  existe solo para no dejar ningún `!` en la búsqueda.

`NotchBuddy/Sources/App/IslandRootView.swift:526` y
`NotchBuddy/Sources/App/IslandWindowController.swift:2257`:
`IslandConst.viewLayouts[view]!` → `IslandConst.layout(for: view)`.
Ninguna otra lógica de esos archivos se toca.

### 4. Verificación sin compilar (hecha)

Balance llaves/paréntesis/corchetes **0** en los 3 archivos
(escáner Swift-aware); grep: no queda ningún `viewLayouts[...]!`
en el árbol (el único `viewLayouts[` que queda es el del helper,
con `??`); los dos sitios de llamada usan `layout(for: view)`.
**Sin compilar: solo la Mac lo confirma.** Sospechoso si falla:
el helper `layout(for:)` o las entradas nuevas del diccionario.

### 5. Para retomar la verificación en vivo

Tras el pull + build en la Mac de JC, la verificación de 14 pasos
(§19.3) se retoma en el **paso 4** (tarjeta de permiso): la pill
JESLY debe marcar **4** y la tarjeta de la propuesta A debe
abrirse sola **sin caerse**. Las 4 propuestas siguen en
`esperando_aprobacion` en la API; no hay que recrearlas.

## FASE 6 — CORRECCIÓN: tarjeta de sesión recortada (altura 160) + spinners eternos en los pasos (2026-11-27, sin pushear, sin compilar)

### 1. Queja de JC en vivo (2026-11-27, verificación Fase 6)

La tarjeta de permiso FUNCIONÓ (paso 4 PASS: "JESLY necesita
permiso 1/4", D primero). JC tocó Siempre en D y la isla pasó a
la tarjeta de sesión en vivo (`JeslySessionView`). Su queja,
textual: "Se queda cargando y no se ve bien porque se esconde en
la isla. Hay que modificarlo." Captura: se ven la cabecera
("Sesión en vivo", diff +1 −0) y las 4 filas de pasos, pero los
botones de abajo (Aplicar/Ejecutar) quedan cortados fuera de la
isla.

### 2. Defecto 1: altura 160, medida

El layout de `.jeslySession` en `IslandConst.viewLayouts`
(`NotchBuddy/Sources/CoucouKit/IslandTypes.swift`) era height
160, copiado de `.approval`. Pero la tarjeta de sesión lleva
cabecera + hasta 4 filas de pasos + botones (+ feedback), mucho
más alta que 160.

Medida del contenido real de `JeslySessionView` (VStack spacing
8, padding vertical 4+4; botón = texto 12.5 pt + padding
vertical 7+7 ≈ 29 pt):

- Cabecera: texto 13 pt ≈ 16.
- Fila de paso: texto 13 pt ≈ 16 + padding vertical 5+5 = 26.
  ×4 = 104.
- Fila de botones: ~29 + padding top 4 = 33.
- Gaps (spacing 8): planificada 5 gaps = 40; aplicada 6 = 48.
- Padding vertical del VStack: 8.

Totales y altura de ventana necesaria (cromo fijo de la isla:
padding top 8 + cabecera 34 + padding bottom 10 = 52):

- Planificada (4 pasos + 1 fila de botones): ~201 → ≥ 253.
- Aplicada (4 pasos + 2 filas de botones): ~242 → ≥ 294.
- Aplicada + línea de feedback (+27): ~269 → ≥ 321.

Detalle de geometría que importa: `islandSize` (modo
`.expanded`) devuelve `layout.height` tal cual, y la tarjeta
vive en el marco fijo de 98 pt de `IslandRootView` (solo
`.prompt`, `.mail`, `.whatsNew` y `.overview` en esquina son
"altas" y flexibles); el desborde del marco NO se recorta ahí,
solo lo recorta la ventana, y el contenido queda centrado en el
área útil (altura − 52). Por eso con 160 se veían cabecera y
filas pero los botones quedaban fuera, y por eso subir la altura
de la ventana es lo que deja ver la tarjeta entera. `botY` nil
(auto-centrado) sigue igual: la altura no rompe `botPosition`
(usa `islandH` para centrar) ni `islandSize`. `.jeslyProposal`
NO se toca (la tarjeta de permiso se vio entera y bien).
`.jeslyChat` tampoco: su lista de mensajes es un `ScrollView`
con `maxHeight: .infinity` y la fila de entrada queda siempre
abajo — el chat no se recorta, desplaza.

Altura elegida: **330** (área útil 278). Cubre aplicada +
feedback (~269) con ~9 pt de margen. Solo el spinner de
`working` (transitorio, una fracción de segundo, redundante con
los botones deshabilitados) podría recortarse; no es estado
estable. Nota para un lote posterior: lo limpio sería declarar
`.jeslySession` vista "alta" en el `isTall` de `IslandRootView`
(como `.mail`/`.whatsNew`) en vez de fijar la altura a mano;
esta sesión se limitó a `IslandTypes.swift` +
`JeslySessionCardView.swift` por encargo.

### 3. Defecto 2: spinners eternos en los pasos

`JeslyStepIcon` (al final de `JeslySessionCardView.swift`)
dibujaba un `ProgressView` girando en TODOS los pasos en curso
(planificados + en espera). Como esos pasos pueden estar así
minutos, JC lo leía como "se queda cargando". Corrección: el
paso en curso ahora es un **anillo hueco ESTÁTICO** — el círculo
del ZStack (relleno transparente, borde `#6B7079`), sin nada
dentro, mismo estilo que el círculo de los pasos terminados
pero vacío, sin animación. El `ProgressView` pequeño de
`working` (`JeslySessionView`, acción real en vuelo:
Aplicar/Ejecutar/Verificar/Publicar) SE QUEDA: ese sí es carga
real y debe verse.

### 4. Archivos tocados (solo 2)

- `NotchBuddy/Sources/CoucouKit/IslandTypes.swift`:
  `.jeslySession` height 160 → **330** (mismo botX/botY/
  botDiameter/agentMode), con el desglose de la medida en el
  comentario. `.jeslyProposal` y `.jeslyChat` intactas en 160.
- `NotchBuddy/Sources/JeslyIsland/Views/JeslySessionCardView.swift`:
  `JeslyStepIcon` sin `ProgressView` (anillo hueco estático) +
  comentario en la cabecera del archivo ("(spinner)" →
  "(anillo hueco estático)").

### 5. Verificación sin compilar (hecha)

Balance llaves/paréntesis/corchetes **0** en los 2 archivos
(escáner Swift-aware); grep: queda UN solo `ProgressView()` en
`JeslySessionCardView.swift` (línea 163, el de `working`); en
`JeslyStepIcon` no queda ninguno. **Sin compilar: solo la Mac
lo confirma.** Sospechoso si falla: la altura nueva o el icono.

### 6. Para retomar la verificación en vivo

Tras el pull + build en la Mac de JC, la verificación de 14
pasos (§19.3) se retoma en el **paso 5** (Aplicar en la
propuesta A): la tarjeta de sesión debe mostrar las 4 filas Y
los botones completos, sin spinners girando en los pasos. Las
propuestas D (Siempre), C (Denegar) y B (Permitir) ya fueron
decididas por JC; A sigue en planificada con su parche.
