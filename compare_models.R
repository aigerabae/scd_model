# Usage: Rscript compare_models.R <your_run_dir> <saenko_SCD_All_dir>
# Example: Rscript compare_models.R SCD_100rep SCD_All
suppressMessages(library(readxl))
args <- commandArgs(trailingOnly = TRUE)
mine_dir <- args[1]; his_dir <- args[2]

read_params <- function(f) {
  x <- suppressMessages(as.data.frame(read_excel(f, sheet = "Model_parameters", col_names = FALSE)))
  p <- setNames(as.character(x[[2]]), x[[1]])
  # coefficient table sits under the "Coefficient | Variable" header row
  h <- which(x[[1]] == "Coefficient")
  coefs <- if (length(h)) {
    cf <- x[(h[1] + 1):nrow(x), 1:2]
    cf <- cf[!is.na(cf[[2]]), ]
    setNames(as.numeric(cf[[1]]), cf[[2]])
  } else numeric(0)
  list(p = p, coefs = coefs)
}

analyses <- c(Analysis1 = "SCD", Analysis2 = "SCM", Analysis3 = "IHD")
keys <- c("Seed", "Repeats", "Stringency", "LambdaRule", "FinalAlpha", "FinalLambda",
          "FinalThreshold", "FinalNumberOfPredictors", "FinalTrainingAUC", "FinalTrainingMCC",
          "FinalTrainingSensitivity", "FinalTrainingSpecificity", "FinalTrainingPrecision",
          "FinalTrainingF1")

for (a in names(analyses)) {
  cat("\n==========", a, "(", analyses[a], ") ==========\n")

  log_f <- file.path(mine_dir, paste0("log_", a, ".txt"))
  if (file.exists(log_f)) {
    lg <- readLines(log_f, warn = FALSE)
    errs <- grep("error|halted|killed", lg, ignore.case = TRUE, value = TRUE)
    cat("Errors in log:", if (length(errs)) paste("\n  ", errs) else "none", "\n")
    td <- grep("^Time difference", lg, value = TRUE)
    cat("Module timings:", paste(sub("Time difference of ", "", td), collapse = " | "), "\n")
  }
  n_inter <- length(list.files(file.path(mine_dir, a), pattern = paste0("^", a, "_[0-9]+x5_.*\\.xlsx$")))
  cat("Intermediate Module1 files:", n_inter, "(expected 8)\n")

  mf <- file.path(mine_dir, a, paste0("Model_", a, ".xlsx"))
  hf <- file.path(his_dir, paste0("Model_", a, "_", analyses[a], ".xlsx"))
  if (!file.exists(mf)) { cat("MISSING:", mf, "\n"); next }
  if (!file.exists(hf)) { cat("MISSING:", hf, "\n"); next }
  m <- read_params(mf); h <- read_params(hf)

  tab <- data.frame(Parameter = keys, Mine = m$p[keys], Saenko = h$p[keys], row.names = NULL)
  num <- suppressWarnings(cbind(as.numeric(tab$Mine), as.numeric(tab$Saenko)))
  tab$Match <- ifelse(!is.na(num[, 1]) & !is.na(num[, 2]),
                      ifelse(abs(num[, 1] - num[, 2]) < 1e-6, "yes", "NO"),
                      ifelse(tab$Mine == tab$Saenko, "yes", "NO"))
  print(tab, right = FALSE)

  gm <- names(m$coefs)[names(m$coefs) != "(Intercept)"]
  gh <- names(h$coefs)[names(h$coefs) != "(Intercept)"]
  cat("\nPredictors: mine", length(gm), "| Saenko", length(gh), "| shared", length(intersect(gm, gh)), "\n")
  if (length(setdiff(gm, gh))) cat("  Only in mine:  ", paste(setdiff(gm, gh), collapse = ", "), "\n")
  if (length(setdiff(gh, gm))) cat("  Only in Saenko:", paste(setdiff(gh, gm), collapse = ", "), "\n")
  shared <- intersect(names(m$coefs), names(h$coefs))
  if (length(shared)) {
    d <- max(abs(m$coefs[shared] - h$coefs[shared]))
    cat("  Max |coefficient difference| on shared terms:", signif(d, 3), "\n")
  }
}
cat("\nAll 'yes' + identical predictors = exact reproduction of Saenko's models on this machine.\n")
