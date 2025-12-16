# =====================================================================
# File: bootstrap.R  (repo root)
# Purpose: Stable restore across Macs (fix 'package not available' / later)
# =====================================================================

message("▶ Bootstrapping project …")

# 1) Reliable CRAN mirror (Posit PPM) + robust download method
options(repos = c(CRAN = "https://packagemanager.posit.co/cran/latest"))
options(download.file.method = "libcurl")

# 2) macOS: allow source fallback if binary missing
sys <- tolower(Sys.info()[["sysname"]])
if (identical(sys, "darwin")) {
  options(pkgType = "both")          # try binary, then source
  Sys.setenv(CURL_SSL_BACKEND = "secure-transport")
}

# 3) Ensure renv; activate project
if (file.exists("renv/activate.R")) {
  source("renv/activate.R")
} else {
  if (!requireNamespace("renv", quietly = TRUE)) install.packages("renv")
  renv::activate(".")
}

# 4) Restore; rebuild if needed (handles 'later not available' by compiling)
message("▶ renv::restore(rebuild = TRUE) …")
ok <- tryCatch({
  renv::restore(prompt = FALSE, rebuild = TRUE)
  TRUE
}, error = function(e) {
  message("❌ restore failed: ", conditionMessage(e))
  FALSE
})

# Optional targeted retry for notorious deps if restore errored
if (!ok) {
  pkgs <- c("later", "curl")
  message("▶ Targeted retry (source) for: ", paste(pkgs, collapse = ", "))
  try(renv::install(pkgs, rebuild = TRUE), silent = TRUE)
  ok <- tryCatch({ renv::restore(prompt = FALSE, rebuild = TRUE); TRUE }, error = function(e) FALSE)
}
if (!ok) stop("Aborting: renv::restore() failed after retry.")

# 5) PNG backend: modern path (webshot2 + chromote + Chrome)
if (!requireNamespace("webshot2", quietly = TRUE)) renv::install("webshot2")
if (!requireNamespace("chromote", quietly = TRUE)) renv::install("chromote")
has_chrome <- tryCatch(!is.null(chromote::find_chrome()), error = function(e) FALSE)
if (!has_chrome) message("ℹ️ Chrome/Chromium not detected. Install Google Chrome for PNG export.")

# 6) macOS CLT note (only needed when building from source)
if (identical(sys, "darwin")) {
  has_clt <- tryCatch({
    p <- suppressWarnings(system("xcode-select -p", intern = TRUE))
    is.character(p) && length(p) >= 1 && nzchar(p[1])
  }, error = function(e) FALSE)
  if (!has_clt) message("ℹ️ If source builds fail, run in Terminal: xcode-select --install")
}

# 7) Preflight
if (file.exists("preflight.R")) {
  message("▶ Running preflight …")
  try(source("preflight.R"), silent = TRUE)
}

message("✅ Bootstrap complete. Next: source('Render X Factor Update Graphics.R')")
