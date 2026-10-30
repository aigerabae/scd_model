# Stability check: compare two runs of the same analysis.
# Usage: Rscript compare_runs.R <model_file_run_A.xlsx> <model_file_run_B.xlsx>
# Example: Rscript compare_runs.R runA/Analysis3/Model_Analysis3.xlsx runB/Analysis3/Model_Analysis3.xlsx
suppressMessages(library(readxl))
args <- commandArgs(trailingOnly = TRUE)

read_params <- function(f) {
  x <- suppressMessages(as.data.frame(read_excel(f, sheet = "Model_parameters", col_names = FALSE)))
  p <- setNames(as.character(x[[2]]), x[[1]])
  h <- which(x[[1]] == "Coefficient")
  coefs <- if (length(h)) {
    cf <- x[(h[1] + 1):nrow(x), 1:2]
    cf <- cf[!is.na(cf[[2]]), ]
    setNames(as.numeric(cf[[1]]), cf[[2]])
  } else numeric(0)
  list(p = p, coefs = coefs)
}

# Which module each parameter comes from, so a mismatch points to the module responsible
keys <- c(Seed = "-", Repeats = "-", Stringency = "Module 1-3", LambdaRule = "Module 1-3",
          FinalThreshold = "Module 1", FinalAlpha = "Module 4", FinalLambda = "Module 4",
          FinalNumberOfPredictors = "Module 4-5", FinalTrainingAUC = "Module 5",
          FinalTrainingMCC = "Module 5", FinalTrainingSensitivity = "Module 5",
          FinalTrainingSpecificity = "Module 5", FinalTrainingPrecision = "Module 5",
          FinalTrainingF1 = "Module 5")

A <- read_params(args[1]); B <- read_params(args[2])
k <- names(keys)
tab <- data.frame(Parameter = k, From = unname(keys), RunA = A$p[k], RunB = B$p[k], row.names = NULL)
num <- suppressWarnings(cbind(as.numeric(tab$RunA), as.numeric(tab$RunB)))
tab$Same <- ifelse(!is.na(num[, 1]) & !is.na(num[, 2]),
                   ifelse(abs(num[, 1] - num[, 2]) < 1e-9, "yes", "NO"),
                   ifelse(tab$RunA == tab$RunB, "yes", "NO"))
print(tab, right = FALSE)

ga <- setdiff(names(A$coefs), "(Intercept)"); gb <- setdiff(names(B$coefs), "(Intercept)")
cat("\nPredictors: run A", length(ga), "| run B", length(gb), "| shared", length(intersect(ga, gb)), "\n")
if (length(setdiff(ga, gb))) cat("  Only in A:", paste(setdiff(ga, gb), collapse = ", "), "\n")
if (length(setdiff(gb, ga))) cat("  Only in B:", paste(setdiff(gb, ga), collapse = ", "), "\n")
sh <- intersect(names(A$coefs), names(B$coefs))
if (length(sh)) cat("  Max |coefficient difference|:", signif(max(abs(A$coefs[sh] - B$coefs[sh])), 3), "\n")

cat("\nVERDICT:", if (all(tab$Same == "yes") && setequal(ga, gb)) "STABLE - runs are identical" else
  "NOT STABLE - see rows marked NO and the 'From' column", "\n")
