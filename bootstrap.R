# =====================================================================
# File: bootstrap.R  (repo root)
# Purpose: One-click setup for this project on any machine.
# - Uses CRAN binaries when possible
# - Forces webshot2 + PhantomJS renderer (stable across machines)
# - Restores renv library
# - Runs preflight at the end
# =====================================================================

message("▶ Bootstrapping project …")

# 1) Set a CRAN mirror if none is configured (some R installs have @CRAN@)
repos <- getOption("repos")
if (is.null(repos) || isTRUE(is.na(repos)) || identical(repos, c(CRAN = "@CRAN@"))) {
  options(repos = c(CRAN = "https://cloud.r-project.org"))
}

# 2) Prefer binaries on macOS/Windows (avoids compiling from source)
sys <- tolower(Sys.info()[["sysname"]])
if (sys %in% c("darwin", "windows")) options(pkgType = "binary")

# 3) Ensure renv is available and activate this project
if (file.exists("renv/activate.R")) {
  # Vendored renv (preferred for reproducibility)
  source("renv/activate.R")
} else {
  if (!requireNamespace("renv", quietly = TRUE)) install.packages("renv")
  renv::activate(".")
}

# 4) Prefer modern renderer: webshot2 + chromote + Chrome
if (!requireNamespace("webshot2", quietly = TRUE)) renv::install("webshot2")
if (!requireNamespace("chromote", quietly = TRUE)) renv::install("chromote")

# Sanity check for Chrome
has_chrome <- tryCatch(!is.null(chromote::find_chrome()), error = function(e) FALSE)
if (!has_chrome) {
  message("ℹ️ Chrome/Chromium not detected. Install Google Chrome, then re-run bootstrap.")
}

# DO NOT hard-stop on PhantomJS anymore
# Legacy fallback (optional): webshot + PhantomJS
if (!requireNamespace("webshot", quietly = TRUE)) {
  # only used if you later want PhantomJS; NOT required
  # renv::install("webshot"); webshot::install_phantomjs()
}


# 5) macOS CLT heads-up (source builds may require CLT)
if (identical(sys, "darwin")) {
  has_clt <- tryCatch({
    p <- suppressWarnings(system("xcode-select -p", intern = TRUE))
    is.character(p) && length(p) >= 1 && nzchar(p[1])
  }, error = function(e) FALSE)
  if (!has_clt) message("ℹ️ macOS: Command Line Tools not detected. If any source builds fail, run: xcode-select --install")
}

# 6) Restore renv library (no prompts; fail fast if something’s wrong)
message("▶ renv::restore() …")
restored <- tryCatch({
  renv::restore(prompt = FALSE)
  TRUE
}, error = function(e) {
  message("❌ restore: ", conditionMessage(e))
  FALSE
})
if (!restored) stop("Aborting: renv::restore() failed.")

# 7) Run preflight (optional but helpful)
if (file.exists("preflight.R")) {
  message("▶ Running preflight …")
  try(source("preflight.R"), silent = TRUE)
}

message("✅ Bootstrap complete. Next: source('Render X Factor Update Graphics.R')")
