# R Portfolio — X-Factor Update Graphics

MLB visuals (**Teams / Hitters / Pitchers**) from Excel → **HTML + PNG**.  
Offline-stable (local Quicksand font + local team logos). Deterministic rendering with optional drift baselines.

---

## Quick Start

```r
# one-time per machine
source("bootstrap.R")

# normal usage (menus)
source("Render X Factor Update Graphics.R")
```

If bootstrap flags issues, it prints ✅/❌ items with exact fixes (e.g., macOS Command Line Tools, PNG backend, data files).

---

## What changed at a glance (Original → Current)

- **Parameterized builders**: single engine now handles *any* league/division/sheet (no hard-coded NL/AL or divisions).
- **Menu-driven runner**: one script (`Render X Factor Update Graphics.R`) orchestrates Teams/Hitters/Pitchers, single/all divisions, and sheet selection.
- **Deterministic session**: fixed seed/locale/timezone for identical visuals across machines.
- **Reproducible env**: `renv.lock` + `.Rprofile` auto-activation; optional CI smoke test.
- **Baseline integrity**: HTML hash baselines per kind/league/division (`build/baselines/`) with drift detection + write/update prompts.
- **Robust rendering**: auto-detects `chromote`/`webshot2`, enforces timeouts, normalizes PNG to exact canvas, adds inner keyline.
- **Offline-ready assets**: local MLB logos with URL fallback; local Quicksand font embedding (falls back to Google Fonts if needed).
- **Cleaner visuals**: consistent headers/borders/padding; logo column labels; performance heat fills; legends; ellipsis for long names.
- **Safer I/O**: explicit Excel inputs under `data/`; consistent outputs under `outputs/…`; helper utilities for file safety.
- **Maintainable design**: modular functions, clearer naming, better error messages.

> Want the narrative diffs? See `build/diff/INDEX.md`.

---

## Project Structure

```
Create X Factor Update Graphics.R         # core engines + run_with_excel()
Render X Factor Update Graphics.R         # interactive runner (menus + baselines)
bootstrap.R                               # one-time setup; runs preflight automatically
preflight.R                               # local checks & fix guidance
R Portfolio.Rproj
.Rprofile                                 # auto-activates renv
renv.lock
renv/
├─ activate.R
└─ settings.json
build/
└─ baselines/
   └─ baseline_<kind>_<LG>_<DIV>.txt      # e.g., baseline_teams_AL_E.txt
assets/
└─ mlb/
   └─ <team>.png                          # e.g., ari.png, wsh.png
Quicksand font/
├─ Quicksand-VariableFont_wght.ttf
└─ ...
data/
├─ Hitter Data - X Factor Update.xlsx
├─ Pitcher Data - X Factor Update.xlsx
└─ Team Data - X Factor Update.xlsx
outputs/                                   # ignored by git (rendered PNG/HTML)
.github/
└─ workflows/
   └─ restore-smoke.yml                    # CI: restore + parse on macOS/Windows
```

---

## Requirements

- **R** 4.3.x (lockfile built on **4.3.2**; 4.3 is fine)
- **Packages** (installed via `renv::restore()`):  
  `dplyr`, `purrr`, `tidyr`, `gt`, `readxl`, `glue`, `withr`, `R.utils`, `magick`, `rlang`, `digest`  
  Optional: `base64enc` (offline font embedding)
- **PNG backend (choose one):**  
  **Recommended:** `chromote` (auto-installed by bootstrap)  
  Alternative: `webshot2` + `webshot2::install_phantomjs()`

macOS may need **Xcode Command Line Tools** for any source builds:
```bash
xcode-select --install
```

---

## Setup

`.Rprofile` auto-activates `renv`.

```r
# one-time per machine
source("bootstrap.R")  # installs/activates renv, restores packages, ensures PNG backend, runs preflight
```

Manual (if preferred):

```r
install.packages("renv")
if (file.exists("renv/activate.R")) source("renv/activate.R")
renv::restore()
install.packages("chromote")  # or webshot2; then webshot2::install_phantomjs()
source("preflight.R")
```

---

## How to Run

### Interactive (menus + sheet prompt + baselines)

```r
source("Render X Factor Update Graphics.R")
```

You’ll choose:
- **Kind:** Teams / Hitters / Pitchers / ALL  
- **Scope:** single division or AL/NL × W/E/C  
- **Sheet:** prompted every run  
- **Baselines:** enforce and/or write per kind/league/division

**Outputs:**
```
outputs/<kind>/<Noun> <Sheet Name>/
  <LG> <DIV> <Noun> <Sheet Name>.html
  <LG> <DIV> <Noun> <Sheet Name>.png
```
`<Noun>` is `Team | Hitters | Pitchers`.

### Direct call (non-interactive)

```r
source("Create X Factor Update Graphics.R")
run_with_excel(
  input_xlsx  = "data/Team Data - X Factor Update.xlsx",
  sheet       = "July 2025",
  league      = "AL", division = "E",
  kind        = "teams",
  output_png  = "outputs/teams/Team July 2025/AL E Team July 2025.png",
  output_html = "outputs/teams/Team July 2025/AL E Team July 2025.html",
  baseline    = "build/baselines/baseline_teams_AL_E.txt"  # or NA_character_
)
```

---

## Baselines (Drift Detection)

- Files: `build/baselines/baseline_<kind>_<LG>_<DIV>.txt` (sheet-agnostic).
- **Enforce:** compare current HTML hash vs baseline → error on drift.  
- **Write/Update:** after approving current output as canonical (runner prompts).

---

## Fonts & Logos

- **Logos:** uses `assets/mlb/*.png` if present; otherwise falls back to ESPN URLs.  
- **Quicksand:** if `Quicksand font/` exists **and** `base64enc` is installed, HTML embeds the font (offline). Otherwise uses Google Fonts.

---

## CI (macOS + Windows)

Workflow: `.github/workflows/restore-smoke.yml`
- Pins **R 4.3**.
- Asserts lockfile R matches (major.minor).
- Runs `bootstrap.R` and parses both scripts (sanity check).

Optional badge (replace `OWNER/REPO`):
```markdown
![Restore & Smoke](https://github.com/OWNER/REPO/actions/workflows/restore-smoke.yml/badge.svg)
```

---

## Troubleshooting

- **Restore hangs on macOS:** run `xcode-select --install`, then re-run `source("bootstrap.R")`.  
- **No PNG backend:** `install.packages("chromote")` (or `webshot2`; then `webshot2::install_phantomjs()`).  
- **Missing inputs:** place the three Excel files under `data/` with exact names (see preflight).  
- **Baseline drift:** if intentional, update baseline; else investigate data/assets/package changes.

---

## Original vs Current

- **Original snapshot (branch):** `Original---7.10.25`
- **Current:** `main`

**Deletions view (main → original)** — shows files the originals branch removed relative to current:  
➡️ _paste your URL_ `https://github.com/<USER>/<REPO>/compare/main...Original---7.10.25`

**Additions view (original → main)** — shows what’s been added/refactored since the original snapshot:  
➡️ _paste your URL_ `https://github.com/<USER>/<REPO>/compare/Original---7.10.25...main`

**Narrative diffs (skimmable)**  
See `build/diff/INDEX.md` for change summaries and optional side-by-side HTML diffs.

---

## License
Noncommercial — see [LICENSE](./LICENSE) (PolyForm Noncommercial 1.0.0).

