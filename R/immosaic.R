#' Make a packed image mosaic
#'
#' A simple greedy algorithm tries to pack as many images
#' into a larger image as possible, taking into account
#' transparency, if available (recommended).
#'
#' @param im Can be either a character vector of image
#' file names (format must be compatible with [imager::load.image()]),
#' a list of [`imager::cimg`] objects, or a function that generates
#' an image when evaluated. The function can take a single argument,
#' which is the current iteration of the packing algorithm. Can also
#' be specified as an `rlang` style lambda syntax (see [rlang::as_function()]).
#' @param width Width in pixels of produced image
#' @param height Height in pixels of produced image
#' @param mask An optional masking image.
#' @param weights Vector of Weights to apply to each image. Higher weighted
#' images will  be packed first and so will tend to be larger. This vector
#' will be recycled.
#' @param preferred An alternate way to specify images to pack first, as
#' a character vector of names or file names (only works if `im` is a
#' vector of image file name or a list of [`imager::cimg`] objects).
#' @param max_num_tries Maximum number of times to try packing an image
#' onto the canvas before giving up.
#' @param scales A vector of starting scaling factors to randomly choose
#' from for each image.
#' @param scale_fun An function that takes three arguments,
#' which correspond to the current vector of scaling factors, the current
#' iteration of the algorithm, and the count of the number of packed images
#' so far, respectively (e.g. `f(s, i, c)`), and returns a new vector of
#' scaling factors to use.
#' @param max_images The maximum number of images to pack before stopping.
#' @param min_scale The minimum scale factor to use. If the algorithm
#' generates a scale factor this small (via `scale_fun`), packing will stop.
#' @param bg The background colour for the campus, default: "transparent"
#' @param show_every Show the intermediate packed image after every
#' `show_every` images are packed. Set to 0 to not show intermediates.
#' @param progress Should progress be printed as the algorithm runs?
#' @param ... Further arguments passed on the `im`, if it is function.
#'
#' @return A packed image mosaic, as a [`imager::cimg`] object.
#' @export
#'
#' @importFrom imager %inr%
#' @importFrom grDevices col2rgb
#' @importFrom stats runif
#'
#' @examples
#' plot(
#'   immosaic(
#'     function(i) imager::draw_circle(
#'       imager::imfill(500, 500, val = c(0, 0, 0, 0)),
#'       250, 250, radius = runif(1, 150, 250),
#'       color = matrix(grDevices::col2rgb(sample(grDevices::rainbow(100), 1), alpha = TRUE), nrow = 1)
#'     ),
#'     width = 400, height = 400,
#'     max_images = 10, bg = "white",
#'   )$image
#' )
immosaic <- function(im, width = 1024, height = 800,
                     mask = NULL,
                     weights = NULL,
                     preferred = NULL,
                     max_num_tries = 100,
                     scales = c(rep(0.5, 2), rep(0.25, 4), rep(0.15, 8)),
                     scale_fun = function(s, i, c) {
                       if(c < (i * 0.5)) {
                          mscale <- min(s)
                          c(s, rep(mscale / 2, floor(1 / mscale)))
                       } else {
                         scales
                       }
                     },
                     max_images = 1000,
                     min_scale = 0.05,
                     bg = "transparent",
                     show_every = 25,
                     progress = TRUE,
                     ...) {


  bg_col <- as.vector(col2rgb(bg)) / 255
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

  if(rlang::is_formula(im)) {
    im <- rlang::as_function(im)
  }

  if(!rlang::is_function(im)) {
    if(rlang::is_list(im)) {
      if(!all(sapply(im, class) == "cimg")) {
        stop("If im is a list, it must be a list of cimg objects (see imager documentation for details).")
      }
      im_type <- "cimgs"
    } else {
      if(!rlang::is_character(im)) {
        stop("If im is a vector it must be a character vector of file names.")
      }
      im_type <- "filenames"
    }
    num_images <- length(im)
  } else {
    num_images <- max_images
    im_type <- "function"
  }

  if(!is.null(preferred) & is.null(weights)) {
    if(!rlang::is_vector(preferred) & !(rlang::is_integer(preferred) | rlang::is_integer(preferred))) {
      rlang::abort("If preferred is specified it must be a character vector of filenames or an integer vector of indices")
    }
    weights <- rep(0.001, num_images)
    if(im_type == "filenames" & rlang::is_character(preferred)) {
      names(weights) <- im
    }
    weights[preferred] <- 1
    num_preferred <- length(preferred)
  } else {
    num_preferred <- floor(0.2 * num_images)
  }

  if(is.null(weights)) {
    weights <- rep(1, num_images)
  }

  if(im_type != "function") {
    im <- sample(im, prob = weights)
  }

  image_map <- data.frame(NULL)
  count <- 0

  if(progress) {
    total <- ifelse(im_type == "function", "?", as.character(num_images))
    format <- paste0(":spin (:current/", total, " images packed. Packing at :tick_rate images per second. Time elapsed: :elapsedfull")
    pr <- progress::progress_bar$new(format = format, total = NA)
  }

  for(i in seq_len(num_images)) {

    if(im_type == "filenames") {
      img <- imager::load.image(im[[i]])
      img <- convert_to_rgba(img)
    }
    if(im_type == "cimgs") {
      img <- im[[i]]
    }
    if(im_type == "function") {
      img <- im(i, ...)
      if(rlang::is_list(img)) {
        meta <- img[-1]
        img <- img[[1]]
      } else {
        meta <- NULL
      }
      #img <- im(i)
    }

    success <- FALSE
    for(j in seq_len(max_num_tries)) {

      x <- runif(1, 0, width)
      y <- runif(1, 0, height)
      scale <- sample(scales, 1)

      if(i <= num_preferred) {
        scale <- min(1, scale * 2)
      }

      w <- as.integer(imager::width(img) * scale)
      h <- as.integer(imager::height(img) * scale)

      if(w < 3 | h < 3) {
        next
      }

      if((x < (w * 0.5)) | (x > (imager::width(canvas) - w * 0.5))) {
        next
      }
      if((y < (h * 0.5)) | (y > (imager::height(canvas) - h * 0.5))) {
        next
      }

      resized_img = imager::resize(img, w, h, interpolation_type = 6)
      resized_img <- imager::imchange(resized_img, ~ . < 0, ~ 0)
      resized_img <- imager::imchange(resized_img, ~ . > 1, ~ 1)

      w <- imager::width(resized_img)
      h <- imager::height(resized_img)

      xmin <- as.integer(max(1, x - 0.5 * w))
      ymin <- as.integer(max(1, y - 0.5 * h))
      xr <- c(xmin, xmin + w - 1L)
      yr <- c(ymin, ymin + h - 1L)

      sub_mask <- mask[xr[1]:xr[2], yr[1]:yr[2], , , drop = FALSE]
      img_mask <- imager::channel(resized_img, 4)

      composite <- any(imager::parmin(list(sub_mask, img_mask)) > 0)

      if(composite) {
        if(progress) {
          pr$tick(0)
        }
        next
      }

      ## paste image into canvas
      new_img <- imager::add(list(canvas[xr[1]:xr[2], yr[1]:yr[2], , , drop = FALSE], resized_img))
      canvas[xr[1]:xr[2], yr[1]:yr[2], , ] <- new_img
      ## regenerate mask
      mask <- imager::channel(canvas, 4)
      success <- TRUE
      dat <- do.call(data.frame, c(list(x = x, y = y, scale = scale, image = i), meta))
      image_map <- rbind(image_map, dat)

      break

    }

    if(success) {
      count <- count + 1
      if(progress) {
        pr$tick()
      }
      if(show_every != 0) {
        if(count %% show_every == 0) {
          if(bg != "transparent") {
            plot(imager::flatten.alpha(canvas, bg = bg))
          } else {
            plot(canvas)
          }
        }
      }
      im_env$saved_image <- canvas
    }

    scales <- scale_fun(scales, i, count)

    mscale = min(scales)
    if(mscale < min_scale) {
      message("Packing stopped since not enough empty space is left.")
      break;
    }

  }

  if(bg != "transparent") {
    canvas <- imager::flatten.alpha(canvas, bg = bg)
  }

  if(progress) {
    pr$terminate()
  }

  return(list(image = canvas, meta = image_map))

}
