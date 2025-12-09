# Teams — Narrative Change Summary

- Original: `original/X Factor Update Team Code - 7.10.25.R`
- Current:  `Create X Factor Update Graphics.R`

## Size & Structure
- Lines: 252 → 707 (nonblank: 223 → 665; comments: 17 → 21)
- Functions: 1 → 22 (avg len: 195 → 31.1, max len: 195 → 169)

## Package Changes
- Added:
  -   digest      # baseline hashes
  -   dplyr
  -   else if (webshot2, quietly = TRUE)) "webshot2"
  -   glue
  -   gt
  -   has_b64 <- base64enc, quietly = TRUE)
  -   has_chromote <- chromote, quietly = TRUE)
  -   has_webshot2 <- webshot2, quietly = TRUE)
  -   if (chromote, quietly = TRUE)) "chromote"
  -   magick      # normalize_png, keyline
  -   purrr
  -   R.utils     # withTimeout
  -   readxl
  -   rlang
  -   tidyr
  -   withr
- Removed:
  - dplyr
  - gt
  - htmltools
  - purrr
  - webshot2

## New Capabilities (Current vs Original)
- [x] Parameterized league/division (no hard-coded divisions)
- [x] Deterministic session (locale, timezone, seed)
- [x] Baseline hashing & drift enforcement
- [x] Local logos (offline) with URL fallback
- [x] Local Quicksand font embedding (offline)
- [ ] Chromote backend support
- [ ] Webshot2 support
- [x] PNG normalization to exact canvas
- [x] Inner keyline border
- [x] Render timeout protection
- [ ] Menu-driven runner / sheet picker

## Notable Hard-coding Removed / Safer Patterns
- [x] Removed hard-coded League/Division constants
- [x] Replaced ESPN-only logos with local+fallback strategy

## Rendering & Assets (Signals found)
- Original: espn_logos, google_font_quicksand, chromote_usage, webshot_usage, hardcoded_division
- Current:  deterministic_session, baseline_hashing, local_logos, espn_logos, google_font_quicksand, base64_font_embed, chromote_usage, webshot_usage, png_normalization, keyline, timeout_enforced, parameterized_league_div

## Notes
- Feature presence is detected via fixed-string probes (no regex).
- For exact line-by-line changes, open the side-by-side HTML diff or GitHub Compare.
