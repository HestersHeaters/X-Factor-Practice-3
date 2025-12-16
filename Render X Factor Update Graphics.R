# =====================================================================
# File: Render X Factor Update Graphics.R
# Purpose: One-click runner for Teams/Hitters/Pitchers with HTML baselines
#          (per-sheet, stored in build/baselines/)
# =====================================================================

# --- Load renv and the main creation script ---------------------------
if (file.exists("renv/activate.R")) source("renv/activate.R", local = TRUE)

main_candidates <- c(
  "Create X Factor Update Graphics.R",
  "R/Create X Factor Update Graphics.R"
)

loaded <- FALSE
for (cand in main_candidates) {
  if (file.exists(cand)) {
    source(cand, chdir = TRUE, local = TRUE)
    if (!exists("run_with_excel", mode = "function", inherits = TRUE)) {
      stop(sprintf("Loaded '%s' but could not find run_with_excel().", cand))
    }
    message(sprintf("✓ Loaded main script: %s", cand))
    loaded <- TRUE
    break
  }
}
if (!loaded) {
  stop(paste(
    "Could not find your main creation script.",
    "Expected one of:",
    paste(paste0("  - ", main_candidates), collapse = "\n"),
    sep = "\n"
  ))
}

# ------------------------------ Utils --------------------------------
ensure_dir <- function(p) if (!dir.exists(p)) dir.create(p, recursive = TRUE, showWarnings = FALSE)

ask_yesno <- function(title) {
  i <- menu(c("Yes","No"), title = title)
  if (i == 0) stop("Cancelled.")
  i == 1
}

detect_png_backend <- function() {
  # informational only
  if (requireNamespace("chromote", quietly = TRUE)) {
    ch <- tryCatch(chromote::find_chrome(), error = function(e) NULL)
    if (!is.null(ch)) return("chromote")
  }
  if (requireNamespace("webshot2", quietly = TRUE) && nzchar(Sys.which("phantomjs"))) return("webshot2")
  if (requireNamespace("webshot2", quietly = TRUE)) return("webshot2(no phantomjs)")
  "none"
}

# Friendly noun for filenames/folders
kind_noun <- function(kind) {
  k <- tolower(kind)
  if (k %in% c("teams","standings")) "Team"
  else if (k == "hitters") "Hitters"
  else if (k == "pitchers") "Pitchers"
  else tools::toTitleCase(k)
}

# Safe path component (keep spaces; strip slashes/colons/control chars)
safe_component <- function(x) {
  x <- gsub("[/\\\\:]+", "-", x)
  x <- gsub("[[:cntrl:]]+", "", x)
  trimws(x)
}

# Prompt to select a sheet EVERY time (by design)
pick_sheet_for <- function(xlsx, title = "Select a sheet:") {
  sheets <- readxl::excel_sheets(xlsx)
  cat("Available sheets (exact names):\n")
  for (i in seq_along(sheets)) cat(sprintf("[%d] %s\n", i, sheets[i]))
  idx <- menu(sheets, title = title)
  if (idx < 1) stop("No sheet selected.")
  sheets[idx]
}

# ----------------------- Workbook defaults (repo) --------------------
default_workbook_for <- function(kind) {
  root <- "data"
  k <- tolower(kind)
  if (k == "teams")    return(file.path(root, "Team Data - X Factor Update.xlsx"))
  if (k == "hitters")  return(file.path(root, "Hitter Data - X Factor Update.xlsx"))
  if (k == "pitchers") return(file.path(root, "Pitcher Data - X Factor Update.xlsx"))
  NULL
}

resolve_workbook_for <- function(kind) {
  x <- default_workbook_for(kind)
  if (!is.null(x) && file.exists(x)) return(x)
  message(sprintf("Default workbook for '%s' not found at: %s", kind, x %||% "<NULL>"))
  message("Please choose the workbook manually …")
  p <- file.choose()
  if (!file.exists(p)) stop("Selected Excel file does not exist.")
  p
}
`%||%` <- function(a,b) if (!is.null(a)) a else b

# ----------------------- Baseline (per sheet, HTML) -------------------
baseline_path_for <- function(league, division, kind, sheet) {
  k <- tolower(kind)
  if (k == "standings") k <- "teams"
  file.path("build", "baselines",
            sprintf("baseline_%s_%s_%s_%s.txt",
                    k, toupper(league), toupper(division), safe_component(sheet)))
}

# One-time migration (old flat baselines -> build/baselines/)
migrate_old_baselines_flat <- function(build_dir = "build") {
  src <- build_dir
  dst <- file.path(build_dir, "baselines")
  ensure_dir(dst)
  if (!dir.exists(src)) return(invisible(FALSE))
  olds <- list.files(src, pattern = "^baseline_.*\\.txt$", full.names = TRUE)
  if (!length(olds)) return(invisible(FALSE))
  moved <- 0L
  for (f in olds) {
    base <- basename(f)
    tgt  <- file.path(dst, base)
    if (!file.exists(tgt)) {
      file.rename(f, tgt)
      moved <- moved + 1L
    }
  }
  if (moved) message(sprintf("↪ Migrated %d baseline file(s) to %s", moved, dst))
  invisible(TRUE)
}

# Local HTML baseline writer if Create didn't define one
if (!exists("write_html_baseline", mode = "function")) {
  compute_sha256 <- function(path) digest::digest(file = path, algo = "sha256")
  write_html_baseline <- function(rendered_html, baseline_path) {
    dir.create(dirname(baseline_path), recursive = TRUE, showWarnings = FALSE)
    sha <- compute_sha256(rendered_html)
    writeLines(sha, baseline_path)
    invisible(sha)
  }
}

# Ensure standard dirs exist + migrate old baselines once
ensure_dir("build"); ensure_dir("outputs"); ensure_dir("build/drift")
ensure_dir(file.path("build","baselines"))
migrate_old_baselines_flat("build")

# ------------------------------- Menu --------------------------------
kind_idx <- menu(c("Teams","Hitters","Pitchers","ALL"), title = "Select table type:")
if (kind_idx < 1) stop("No table type selected.")
kinds <- switch(kind_idx,
                c("teams"),
                c("hitters"),
                c("pitchers"),
                c("teams","hitters","pitchers"))

scope <- menu(c("Single division", "All six divisions"), title = "Render scope:")
if (scope < 1) stop("No scope selected.")

results <- list()

# ----------------------------- Execute -------------------------------
if (scope == 1) {
  lg <- c("AL", "NL")[menu(c("AL","NL"), title = "Select league:")]
  if (is.na(lg)) stop("No league selected.")
  dv <- c("W", "E", "C")[menu(c("W","E","C"), title = "Select division:")]
  if (is.na(dv)) stop("No division selected.")
  tag <- paste0(lg, "_", dv)
  
  for (kind in kinds) {
    xlsx <- resolve_workbook_for(kind)
    sheet_choice <- pick_sheet_for(xlsx, sprintf("Select a sheet for %s:", kind))
    
    noun   <- kind_noun(kind)
    folder <- file.path("outputs", tolower(kind), paste(noun, sheet_choice))
    ensure_dir(folder)
    
    file_stub <- sprintf("%s %s %s %s", lg, dv, noun, sheet_choice)
    file_stub_safe <- safe_component(file_stub)
    
    out_png  <- file.path(folder, paste0(file_stub_safe, ".png"))
    out_html <- file.path(folder, paste0(file_stub_safe, ".html"))
    
    bfile    <- baseline_path_for(lg, dv, kind, sheet_choice)  # per kind/LG/DIV/SHEET
    use_base <- file.exists(bfile) && ask_yesno(
      sprintf("Enforce baseline for %s [%s]? (%s)", kind, tag, bfile))
    
    run_with_excel(
      input_xlsx  = xlsx,
      sheet       = sheet_choice,
      league      = lg,
      division    = dv,
      kind        = kind,
      output_png  = out_png,
      output_html = out_html,
      baseline    = if (use_base) bfile else NA_character_
    )
    
    wrote <- ask_yesno(sprintf("Write/Update baseline for %s [%s] now?", kind, tag))
    if (wrote) write_html_baseline(out_html, bfile)
    
    results[[length(results)+1L]] <- data.frame(
      kind = kind, league = lg, division = dv,
      workbook = normalizePath(xlsx, FALSE),
      sheet = sheet_choice,
      png  = normalizePath(out_png,  FALSE),
      html = normalizePath(out_html, FALSE),
      baseline = normalizePath(bfile, FALSE),
      baseline_exists = file.exists(bfile),
      enforced = use_base,
      wrote_baseline = wrote,
      stringsAsFactors = FALSE
    )
  }
  
} else {
  leagues   <- c("AL","NL")
  divisions <- c("W","E","C")
  
  # Collect sheet choice once per kind (always prompt)
  kind_cfgs <- lapply(kinds, function(kind) {
    xlsx <- resolve_workbook_for(kind)
    sheet_choice <- pick_sheet_for(xlsx, sprintf("Select a sheet for %s:", kind))
    noun   <- kind_noun(kind)
    folder <- file.path("outputs", tolower(kind), paste(noun, sheet_choice))
    ensure_dir(folder)
    list(kind=kind, xlsx=xlsx, sheet=sheet_choice, noun=noun, folder=folder)
  })
  
  enforce_all <- ask_yesno("Enforce existing baselines for ALL divisions (where present)?")
  write_all   <- ask_yesno("Write/Update baselines for ALL divisions after rendering?")
  
  for (cfg in kind_cfgs) {
    kind <- cfg$kind; xlsx <- cfg$xlsx; sheet_choice <- cfg$sheet; noun <- cfg$noun; folder <- cfg$folder
    for (lg in leagues) for (dv in divisions) {
      tag <- paste0(lg, "_", dv)
      
      file_stub <- sprintf("%s %s %s %s", lg, dv, noun, sheet_choice)
      file_stub_safe <- safe_component(file_stub)
      out_png  <- file.path(folder, paste0(file_stub_safe, ".png"))
      out_html <- file.path(folder, paste0(file_stub_safe, ".html"))
      
      bfile    <- baseline_path_for(lg, dv, kind, sheet_choice)
      use_base <- enforce_all && file.exists(bfile)
      
      status <- "ok"; note <- NA_character_
      res_try <- try({
        run_with_excel(
          input_xlsx  = xlsx,
          sheet       = sheet_choice,
          league      = lg,
          division    = dv,
          kind        = kind,
          output_png  = out_png,
          output_html = out_html,
          baseline    = if (use_base) bfile else NA_character_
        )
      }, silent = TRUE)
      
      if (inherits(res_try, "try-error")) {
        status <- "drift_or_error"; note <- as.character(res_try)
      } else if (write_all) {
        write_html_baseline(out_html, bfile)
      }
      
      results[[length(results)+1L]] <- data.frame(
        kind = kind, league = lg, division = dv,
        workbook = normalizePath(xlsx, FALSE),
        sheet = sheet_choice,
        png  = normalizePath(out_png,  FALSE),
        html = normalizePath(out_html, FALSE),
        baseline = normalizePath(bfile, FALSE),
        baseline_exists = file.exists(bfile),
        enforced = use_base,
        wrote_baseline = if (write_all) TRUE else NA,
        status = status,
        note = note,
        stringsAsFactors = FALSE
      )
    }
  }
}

if (length(results)) {
  res <- do.call(rbind, results); rownames(res) <- NULL; print(res)
}
cat("\n=== Done ===\nBackend:", detect_png_backend(), "\n")
