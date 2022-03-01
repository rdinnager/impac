#' @keywords internal
#' @aliases impac-package
"_PACKAGE"

# The following block is used by usethis to automatically manage
# roxygen namespace tags. Modify with care!
## usethis namespace: start
## usethis namespace: end
NULL

impac_exec_env <- new.env()

.onLoad <- function(libname, pkgname) {
  impac_exec_env$run_impac <- .run_impac
  impac_exec_env$space_left <- .space_left
}
