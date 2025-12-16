# =====================================================================
# File: bootstrap.R  (repo root)
# Purpose: Self-contained first-run: renv boot → restore → PNG backend → preflight
# =====================================================================

message("▶ Bootstrapping …")

# tiny helper used a few times
`%||%` <- function(a,b) if (!is.null(a)) a else b

# Stable repos + prefer binaries on macOS/Windows
options(
  repos = c(CRAN = "https://packagemanager.posit.co/cran/2024-12-01"),
  pkgType = if (tolower(Sys.info()[["sysname"]]) %in% c("darwin","windows")) "binary" else getOption("pkgType","source"),
  install.packages.check.source = "no",
  download.file.method = "libcurl",
  timeout = 900
)
Sys.setenv(
  RENV_CONFIG_PAK_ENABLED = "FALSE",
  RENV_CONFIG_PROMPT = "FALSE",
  RENV_CONFIG_REPOS_OVERRIDE = "https://packagemanager.posit.co/cran/2024-12-01",
  RENV_CONFIG_INSTALL_FROM_BINARY = "TRUE",
  RENV_DOWNLOAD_METHOD = "curl"
)

# Load vendored renv if present; else install and activate
if (file.exists("renv/activate.R")) {
  source("renv/activate.R")  # prefers renv/renv-*/ if vendored
} else {
  if (!requireNamespace("renv", quietly = TRUE)) install.packages("renv")
  renv::activate(".")
}

# macOS CLT heads-up (why: compilers if source fallback happens)
if (tolower(Sys.info()[["sysname"]]) == "darwin") {
  has_clt <- tryCatch({
    p <- suppressWarnings(system("xcode-select -p", intern = TRUE))
    is.character(p) && length(p) >= 1 && nzchar(p[1])
  }, error = function(e) FALSE)
  if (!has_clt) message("ℹ️ macOS: install Command Line Tools: xcode-select --install")
}

# in bootstrap.R, BEFORE renv::restore()
`%||%` <- function(a,b) if (!is.null(a)) a else b

lock_v8_version <- function() {
  if (!file.exists("renv.lock")) return(NULL)
  tryCatch(jsonlite::fromJSON("renv.lock")$Packages$V8$Version, error = function(e) NULL)
}

ensure_v8 <- function(ver = lock_v8_version()) {
  if (is.null(ver)) return(invisible(TRUE))
  if (requireNamespace("V8", quietly = TRUE) &&
      as.character(utils::packageVersion("V8")) == ver) return(invisible(TRUE))
  op <- getOption("repos"); old <- getOption("pkgType")
  options(repos = c(jeroen = "https://jeroen.r-universe.dev",
                    CRAN   = "https://packagemanager.posit.co/cran/2024-12-01"),
          pkgType = "both")
  if (!requireNamespace("remotes", quietly = TRUE)) install.packages("remotes")
  try(remotes::install_version("V8", version = ver, upgrade = "never"), silent = TRUE)
  options(pkgType = old %||% "binary", repos = op)
  invisible(requireNamespace("V8", quietly = TRUE) &&
              as.character(utils::packageVersion("V8")) == ver)
}

ensure_v8()
# then call renv::restore(prompt = FALSE)


# Restore (retry once because renv may restart on first call)
restore_once <- function() tryCatch({ renv::restore(prompt = FALSE); TRUE },
                                    error = function(e) { message("❌ restore: ", conditionMessage(e)); FALSE })
message("▶ renv::restore() …")
ok <- restore_once(); if (!ok) { message("▶ retry restore …"); ok <- restore_once() }
if (!ok) stop("Aborting: renv::restore() failed.")

# Ensure PNG backend: chromote preferred; else webshot2 (+ PhantomJS)
ensure_phantom <- function() {
  if (!requireNamespace("webshot2", quietly = TRUE)) return(FALSE)
  try(webshot2::install_phantomjs(), silent = TRUE)  # idempotent
  nzchar(Sys.which("phantomjs"))
}
if (!requireNamespace("chromote", quietly = TRUE)) {
  message("▶ Installing 'chromote' (PNG backend) …")
  try(install.packages("chromote"), silent = TRUE)
}
if (!requireNamespace("chromote", quietly = TRUE)) {
  if (!requireNamespace("webshot2", quietly = TRUE)) {
    message("▶ Installing 'webshot2' (fallback PNG backend) …")
    try(install.packages("webshot2"), silent = TRUE)
  }
  if (!ensure_phantom()) message("ℹ️ If PNG export fails later, run webshot2::install_phantomjs()")
}

# Diagnostics only (does not mutate)
if (file.exists("preflight.R")) {
  message("▶ Running preflight …")
  try(source("preflight.R"), silent = TRUE)  # why: quick signal without blocking
}

message("✅ Bootstrap complete. Next: source('Render X Factor Update Graphics.R')")
