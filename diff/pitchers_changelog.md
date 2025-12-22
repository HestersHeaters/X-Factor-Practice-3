# Pitchers — Narrative Change Summary

- Original: `original/X Factor Update Pitcher Code - 7.10.25.R`
- Current:  `Create X Factor Update Graphics.R`

## Size & Structure
- Lines: 228 → 1006 (nonblank: 207 → 928; comments: 17 → 20)
- Functions: 3 → 31 (avg len: 61 → 31.7, max len: 135 → 249)

## Package Changes
- Added:
  - base64enc
  - chromote
  - digest
  - glue
  - magick
  - purrr
  - R.utils
  - readxl
  - webshot
  - withr
- Removed:
  - stringr
  - sysfonts
- Unchanged:
  - dplyr
  - gt
  - rlang
  - tidyr
  - webshot2

## Capabilities — New
- [x] Parameterized league/division (no hard-coded divisions)
- [x] Deterministic session (locale, timezone, seed)
- [x] Baseline hashing & drift enforcement
- [x] Local logos (offline) with URL fallback
- [x] Local Quicksand font embedding (offline)
- [x] Chromote backend support
- [x] Webshot/Webshot2 support
- [x] PNG normalization to exact canvas
- [x] Inner keyline border
- [x] Render timeout protection
- [x] Menu-driven runner / sheet picker

## Capabilities — Retained
- (none)

## Capabilities — Removed
- (none)

## Notable Hard-coding Removed / Safer Patterns
- [x] Removed hard-coded League/Division constants
- [x] Replaced ESPN-only logos with local+fallback strategy

## Rendering & Assets (Signals found)
- Original: espn_logos, google_font_quicksand, hardcoded_division
- Current:  deterministic_session, renv_integration, baseline_hashing, local_logos, espn_logos, google_font_quicksand, base64_font_embed, chromote_usage, webshot_usage, png_normalization, keyline, timeout_enforced, parameterized_league_div, menu_runner

## Notes
- Feature presence is detected via fixed-string probes (no regex).
- For exact line-by-line changes, open the side-by-side HTML diff or GitHub Compare.
