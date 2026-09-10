#!/usr/bin/env Rscript
#
# Merge a set of keys into an RStudio preferences file, in place.
#
#   Rscript merge-prefs.R <rstudio-prefs.json> <keys-to-set.json>
#
# RStudio owns rstudio-prefs.json and rewrites it wholesale on exit, so the file
# may already hold settings that matter - pane layout, project paths, whatever
# the server administrator seeded. Only the keys present in the second file are
# touched; everything else is preserved byte-for-byte in meaning.
#
# Written in R rather than Python because R is guaranteed present on an RStudio
# Server, whereas the python3 on PATH may be a stub or a locked-down build.

args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 2L) {
  cat("usage: merge-prefs.R <rstudio-prefs.json> <keys-to-set.json>\n", file = stderr())
  quit(status = 2L)
}
prefs_path <- args[[1L]]
want_path  <- args[[2L]]

if (!requireNamespace("jsonlite", quietly = TRUE)) {
  cat("jsonlite is required. In R:  install.packages(\"jsonlite\")\n", file = stderr())
  quit(status = 1L)
}

# simplifyVector = FALSE keeps everything as plain lists. Without it jsonlite
# turns JSON arrays into atomic vectors and nested objects into data frames,
# which then round-trip back out with the wrong shape.
read_json_object <- function(path, what) {
  out <- tryCatch(
    jsonlite::fromJSON(path, simplifyVector = FALSE),
    error = function(e) {
      cat(sprintf("%s is not valid JSON; refusing to overwrite it (%s)\n",
                  what, conditionMessage(e)), file = stderr())
      quit(status = 1L)
    }
  )
  if (!is.list(out)) {
    cat(sprintf("%s is not a JSON object; refusing to overwrite it\n", what),
        file = stderr())
    quit(status = 1L)
  }
  out
}

want <- read_json_object(want_path, want_path)

# A missing prefs file is normal on a fresh account; a corrupt one is not, and
# read_json_object above stops rather than silently discarding it.
prefs <- if (file.exists(prefs_path)) read_json_object(prefs_path, prefs_path) else list()

changed <- names(want)[vapply(
  names(want),
  function(k) !identical(prefs[[k]], want[[k]]),
  logical(1L)
)]

for (k in names(want)) prefs[[k]] <- want[[k]]

# auto_unbox keeps length-1 values as scalars ("x" not ["x"]). Lists of length 1
# still render as arrays, so busy_exclusion_list survives even if trimmed to one
# entry - which is why the input is read as lists rather than vectors.
json <- jsonlite::toJSON(prefs, auto_unbox = TRUE, pretty = 4, null = "null")

# Write through a temp file in the same directory, then rename, so an
# interrupted run cannot leave RStudio with a truncated preferences file.
tmp <- paste0(prefs_path, ".tmp")
dir.create(dirname(prefs_path), recursive = TRUE, showWarnings = FALSE)
writeLines(json, tmp, useBytes = TRUE)
if (!file.rename(tmp, prefs_path)) {
  unlink(tmp)
  cat(sprintf("cannot write %s\n", prefs_path), file = stderr())
  quit(status = 1L)
}

if (length(changed)) {
  cat(paste0("      set ", changed, collapse = "\n"), "\n", sep = "")
} else {
  cat("      (already current)\n")
}
