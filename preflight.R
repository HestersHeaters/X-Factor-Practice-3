# =====================================================================
# File: preflight.R  (repo root)
# Purpose: Local environment checks with actionable fixes.
# =====================================================================

cat("== R Portfolio Preflight ==\n")
ok <- TRUE
fail <- function(msg) { cat("❌ ", msg, "\n", sep = ""); ok <<- FALSE }
pass <- function(msg) { cat("✅ ", msg, "\n", sep = "") }

# 1) R version vs renv.lock (major.minor)
want <- tryCatch({
  if (!requireNamespace("jsonlite", quietly = TRUE)) install.packages("jsonlite", quiet = TRUE)
  jsonlite::fromJSON("renv.lock")$R$Version
}, error = function(e) NA_character_)

if (is.na(want)) {
  fail("Could not read R version from renv.lock.")
} else {
  have_mm <- paste0(R.version$major, ".", strsplit(R.version$minor, "[.]")[[1]][1])
  want_mm <- sub("^(\\d+\\.\\d+).*", "\\1", want)
  if (have_mm == want_mm) pass(sprintf("R version OK: have %s, lockfile %s", have_mm, want))
  else fail(sprintf("R version mismatch: have %s, lockfile %s. Install R %s.x.", have_mm, want, want_mm))
}

# 2) renv presence + activation (check library paths)
renv_present <- requireNamespace("renv", quietly = TRUE) && file.exists("renv/activate.R")
if (!renv_present) {
  fail("renv not ready. Run: install.packages('renv'); then source('bootstrap.R').")
} else {
  # Activated if a project library path is first .libPaths()
  act <- any(grepl("renv/library", normalizePath(.libPaths(), winslash = "/"), fixed = TRUE))
  if (act) pass("renv active.") else fail("renv not active. Restart session or source('.Rprofile').")
}

# 3) macOS CLT (only on macOS)
is_macos <- identical(tolower(Sys.info()[["sysname"]]), "darwin")
if (is_macos) {
  has_clt <- tryCatch({
    p <- suppressWarnings(system("xcode-select -p", intern = TRUE))
    is.character(p) && length(p) >= 1 && nzchar(p[1])
  }, error = function(e) FALSE)
  if (has_clt) pass("macOS Command Line Tools detected.")
  else fail("macOS CLT missing. In Terminal: xcode-select --install (then re-run preflight).")
} else {
  pass("Non-macOS system—CLT not required.")
}

# 4) PNG backend (chromote OR webshot2+PhantomJS)
backend_ok <- FALSE
if (requireNamespace("chromote", quietly = TRUE)) {
  pass("PNG backend: chromote installed.")
  backend_ok <- TRUE
} else if (requireNamespace("webshot2", quietly = TRUE)) {
  ph <- nzchar(Sys.which("phantomjs"))
  if (ph) { pass("PNG backend: webshot2 + PhantomJS found.") ; backend_ok <- TRUE }
  else fail("webshot2 installed but PhantomJS missing. In R: webshot2::install_phantomjs()")
} else {
  fail("No PNG backend. Install in R: install.packages('chromote') or 'webshot2'")
}

# 5) Required Excel inputs
inputs <- c(
  "data/Team Data - X Factor Update.xlsx",
  "data/Hitter Data - X Factor Update.xlsx",
  "data/Pitcher Data - X Factor Update.xlsx"
)
missing <- inputs[!file.exists(inputs)]

if (length(missing) == 0) {
  pass("Excel inputs found in data/.")
} else {
  fail(paste0(
    "Missing Excel files:\n  - ",
    paste(basename(missing), collapse = "\n  - "),
    "\nPlace them under data/ with these exact names."
  ))
}

# 6) Assets / Fonts presence (+ optional base64enc)
if (dir.exists("assets/mlb")) pass("Team logos present (assets/mlb).") else fail("assets/mlb/ missing (will fallback to web logos).")
if (dir.exists("Quicksand font")) pass("Quicksand font folder present.") else fail("Quicksand font/ missing (Google Fonts fallback).")
if (requireNamespace("base64enc", quietly = TRUE)) pass("base64enc present (offline font embedding).") else cat("ℹ️ base64enc not installed (optional; fonts will use Google Fonts).\n")

# Summary
if (ok) {
  cat("\n🎉 Preflight passed.\nNext:\n  source('Render X Factor Update Graphics.R')\n")
} else {
  cat("\n⚠️  Preflight failed. Fix the ❌ items above, then re-run:\n  source('preflight.R')\n")
}