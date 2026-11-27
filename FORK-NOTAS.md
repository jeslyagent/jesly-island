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
