#' Save packed image mosaic
#'
#' @param x
#' @param file
#' @param quality
#'
#' @return
#' @export
#'
#' @examples
impac_write <- function(x, file, quality = 0.7) {
  if(!inherits(x, "impac")) {
    stop("Not an impac object. Write failed.")
  } else {
    imager::save.image(x$image, file, quality)
  }
  return(invisible(x))
}

#' Function to resume an image packing where it left off
#'
#' @param x An `impac` object created from a previous run of `impac`.
#' Can also be left blank in which case this function attempts to recover
#' the latest `impac` run from the cache (see [impac_recover()] for details).
#' @param ... Other arguments to be passed to [impac()]. By default, original
#' arguments from the original call used to make `x` will be used. Passing an
#' argument here will override the original arguments.
#'
#' @return An `impac` object
#' @export
#'
#' @examples
impac_resume <- function(x = NULL,
                         ...) {

  new_args <- list(...)

  if(is.null(x)) {
    x <- impac_recover()
  }
  override_args <- intersect(names(new_args), names(x$args))

  x$args[override_args] <- new_args[override_args]

  x$args <- lapply(x$args, function(y) eval(y, attr(x, "env")))

  resumed <- do.call(impac, c(x$args, list(start_image = x)))
  return(resumed)
}


#' Function to try and rescue
#'
#' @return
#' @export
#'
#' @examples
impac_recover <- function() {
  if(!is.null(impac_env$saved_image)) {
    saved <- list(image = impac_env$saved_image, meta = impac_env$meta, args = impac_env$latest_args)
  } else {
    stop("Sorry, there is no packed image canvas currently cached.")
  }
  class(saved) <- "impac"
  return(saved)
}

#' Clear any cached `impac` objects
#'
#' @return No return value
#' @export
#'
#' @examples
#' impac_clear_cache()
impac_clear_cache <- function() {
  impac_env$saved_image <- NULL
  impac_env$meta <- NULL
  impac_env$latest_args <- NULL
}
