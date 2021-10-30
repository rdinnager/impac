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
imm_write <- function(x, file, quality = 0.7) {
  if(!inherits(x, "impac")) {
    stop("Not an immosaic object. Write failed.")
  } else {
    imager::save.image(x$image, file, quality)
  }
  return(invisible(x))
}
