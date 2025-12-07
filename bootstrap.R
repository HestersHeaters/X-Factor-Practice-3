# =====================================================================
# File: bootstrap.R  (repo root)
# Purpose: One-time setup so collaborators avoid macOS CLT/R mismatch issues.
# Usage: source("bootstrap.R")  once per machine
# =====================================================================

message("▶ Bootstrapping project …")

# Ensure renv & activate project library
if (!requireNamespace("renv", quietly = TRUE)) install.packages("renv")
if (file.exists("renv/activate.R")) source("renv/activate.R")

# Prefer binaries during restore (avoids compilers on macOS)
options(pkgType = "binary")
Sys.setenv(R_REMOTES_NO_ERRORS_FROM_WARNINGS = "true")

# macOS CLT sanity check (informational)
is_macos <- identical(tolower(Sys.info()[["sysname"]]), "darwin")
if (is_macos) {
  has_clt <- tryCatch({
    p <- suppressWarnings(system("xcode-select -p", intern = TRUE))
    is.character(p) && length(p) >= 1 && nzchar(p[1])
  }, error = function(e) FALSE)
  if (!has_clt) {
    message("\n⚠️  macOS Command Line Tools appear missing.")
    message("   In Terminal run:  xcode-select --install")
  }
}

# Restore packages pinned in renv.lock
message("▶ renv::restore() …")
renv::restore(prompt = FALSE)

# Ensure PNG backend (chromote recommended)
if (!requireNamespace("chromote", quietly = TRUE)) {
  message("▶ Installing 'chromote' (PNG backend) …")
  install.packages("chromote")
}

message("\n✅ Bootstrap complete.\nNext: source('Render X Factor Update Graphics.R')\n")
