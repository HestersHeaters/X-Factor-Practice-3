# =====================================================================
# File: bootstrap.R  (repo root)
# Purpose: One-time setup; restores deps, ensures PNG backend, runs preflight.
# =====================================================================

message("▶ Bootstrapping project …")

# Use a CRAN repo if none is set (why: some R installs lack default repos)
repos <- getOption("repos")
if (is.null(repos) || isTRUE(is.na(repos)) || identical(repos, c(CRAN="@CRAN@"))) {
  options(repos = c(CRAN = "https://cloud.r-project.org"))
}

# Ensure renv and activate
if (!requireNamespace("renv", quietly = TRUE)) install.packages("renv")
if (file.exists("renv/activate.R")) {
  source("renv/activate.R")
} else {
  message("⚠️ renv/activate.R not found. Proceeding without project isolation.")
}

# Prefer binaries on macOS/Windows to avoid compilers
sys <- tolower(Sys.info()[["sysname"]])
if (sys %in% c("darwin","windows")) options(pkgType = "binary")
Sys.setenv(R_REMOTES_NO_ERRORS_FROM_WARNINGS = "true")

# macOS CLT heads-up (why: source builds may require CLT)
if (identical(sys, "darwin")) {
  has_clt <- tryCatch({
    p <- suppressWarnings(system("xcode-select -p", intern = TRUE))
    is.character(p) && length(p) >= 1 && nzchar(p[1])
  }, error = function(e) FALSE)
  if (!has_clt) message("ℹ️ macOS: install Command Line Tools → run in Terminal: xcode-select --install")
}

# Restore deps with clear failure
message("▶ renv::restore() …")
restored <- tryCatch({
  renv::restore(prompt = FALSE); TRUE
}, error = function(e) {
  message("❌ renv::restore failed: ", conditionMessage(e))
  message("   Hints: match R ", sub('^(\\d+\\.\\d+).*','\\1', try(jsonlite::fromJSON("renv.lock")$R$Version, silent = TRUE)),
          " on this machine; on macOS ensure CLT: xcode-select --install")
  FALSE
})
if (!restored) stop("Aborting bootstrap due to restore failure.")

# Ensure PNG backend (prefer chromote; else webshot2 + PhantomJS)
ensure_phantom <- function() {
  ok <- FALSE
  if (requireNamespace("webshot2", quietly = TRUE)) {
    # webshot2::install_phantomjs() is idempotent; try quietly
    try(webshot2::install_phantomjs(), silent = TRUE)
    ok <- nzchar(Sys.which("phantomjs"))
  }
  ok
}

if (!requireNamespace("chromote", quietly = TRUE)) {
  message("▶ Installing 'chromote' (PNG backend) …")
  try(install.packages("chromote"), silent = TRUE)
}
if (!requireNamespace("chromote", quietly = TRUE)) {
  if (!requireNamespace("webshot2", quietly = TRUE)) {
    message("▶ Installing 'webshot2' (fallback backend) …")
    try(install.packages("webshot2"), silent = TRUE)
  }
  if (!ensure_phantom()) {
    message("ℹ️ If PNG export later fails, install PhantomJS manually via:")
    message("   webshot2::install_phantomjs()  # in R")
  }
}

message("▶ Running preflight checks …")
try({ if (file.exists("preflight.R")) source("preflight.R") }, silent = TRUE)
message("✅ Bootstrap complete. Next: source('Render X Factor Update Graphics.R')")