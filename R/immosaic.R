#' Make a packed image mosaic
#'
#' A simple greedy algorithm tries to pack as many images
#' into a larger image as possible, taking into account
#' transparency, if available (recommended).
#'
#' @param im Can be either a character vector of image
#' file names (format must be compatible with [imager::load.image()]),
#' a list of [`imager::cimg`] objects, or a function that generates
#' an image when evaluated. Tje function can take a single argument,
#' which is the current iteration of the packing algorithm. Can also
#' be specified as an `rlang` style lambda syntax (see [rlang::as_function()]).
#' @param width Width in pixels of produced image
#' @param height Height in pixels of produced image
#' @param mask An optional masking image.
#' @param weights
#' @param preferred
#' @param max_num_tries
#' @param scales
#' @param scale_fun
#'
#' @return
#' @export
#'
#' @examples
immosaic <- function(im, width = 1024, height = 800,
                     mask = NULL,
                     weights = NULL,
                     preferred = NULL,
                     max_num_tries = 100,
                     scales = c(0.5, 0.5) + (0.25) * 4 + (0.15) * 8,
                     scale_fun = NULL,
                     bg = "white") {

  canvas <- imager::imfill(x = width, y = height,
                           val = c(0, 0, 0, 0))

  if(!is.null(mask)) {

    if(inherits(mask, "character")) {
      mask <- imager::load.image(mask)
    }

    canvas <- imager::resize(canvas,
                             width(mask),
                             height(mask))
    mask <- mask %>%
      imager::grayscale() %>%
      imager::threshold(0.5)

  } else {

    mask <- imager::channel(canvas, 4)

  }

  count <- 0

}
