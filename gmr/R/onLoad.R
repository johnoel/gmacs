#' On load hook
#'
#' This is a load hook that is called by R when the package is loaded. This
#' should not be exported
#' 
.onLoad <- function(libname, pkgname)
{
  cat("\n")
  cat("==============================================\n")
  cat("Gmacs stock assessment plotting library\n")
  cat(gmr.version())
  cat("For help ask someone who cares\n")
  cat("==============================================\n")
  cat("\n")
}

