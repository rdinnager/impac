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
                     scales = c(rep(0.5, 2), rep(0.25, 4), rep(0.15, 8)),
                     scale_fun = function(i, s, c) {
                       if(c < (i * 0.5)) {
                          mscale <- min(s)
                          c(s, rep(mscale / 2, floor(1 / mscale)))
                       } else {
                         scales
                       }
                     },
                     max_images = 2000,
                     min_scale = 0.05,
                     bg = "transparent",
                     show_every = 25,
                     ...) {


  bg_col <- as.vector(col2rgb(bg)) / 255
  canvas <- imager::imfill(x = width, y = height,
                           val = c(bg_col, 0))

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

  image_map <- data.frame(x = NA, y = NA, image = NA)
  count <- 0

  total <- ifelse(im_type == "function", "?", as.character(num_images))
  format <- paste0(":spin (:current/", total, " images packed. Packing at :tick_rate images per second. Time elapsed: :elapsedfull")
  pr <- progress::progress_bar$new(format = format, total = NA)

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
      #img <- im(i)
    }

    success <- FALSE
    for(j in seq_len(max_num_tries)) {

      needs_resize <- FALSE

      x <- floor(runif(1, 0, width))
      y <- floor(runif(1, 0, height))
      scale <- sample(scales, 1)

      if(i <= num_preferred) {
        scale <- min(1, scale * 2)
      }

      w <- floor(imager::width(img) * scale)
      h = floor(imager::height(img) * scale)
      if(w %% 2 == 0) w <- w + 1
      if(h %% 2 == 0) h <- h + 1

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

      wh <- round(0.5 * w)
      hh <- round(0.5 * h)
      xr <- c(x - wh, x + wh)
      yr <- c(y - hh, y + hh)

      pset <- imager::imeval(mask, ~ x %inr% xr & y %inr% yr)

      sub_mask <- imager::crop.bbox(mask, pset)
      img_mask <- channel(resized_img, 4)

      if(any(dim(img_mask)[1:2] != dim(sub_mask)[1:2])) {
        needs_resize <- TRUE
        img_mask <- imager::resize(img_mask, imager::width(sub_mask), imager::height(sub_mask),
                                   interpolation_type = 6)
      }

      composite <- any(imager::parmin(list(sub_mask, img_mask)) > 0)

      if(composite) {
        pr$tick(0)
        next
      }

      ## paste image into canvas
      if(needs_resize) {
        resized_img <- imager::resize(resized_img, imager::width(sub_mask), imager::height(sub_mask))
      }
      new_img <- imager::add(list(imager::crop.bbox(canvas, pset), resized_img))
      canvas[pset] <- new_img
      ## regenerate mask
      mask <- imager::channel(canvas, 4)
      success <- TRUE
      image_map <- rbind(image_map, c(x = x, y = y, image = i))

      break

    }

    if(success) {
      count <- count + 1
      pr$tick()
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

    scales <- scale_fun(i, scales, count)

    mscale = min(scales)
    if(mscale < min_scale) {
      message("Packing stopped since not enough empty space is left.")
      break;
    }

  }

  if(bg != "transparent") {
    canvas <- imager::flatten.alpha(canvas, bg = bg)
  }

  pr$terminate()

  return(list(image = canvas, meta = image_map))

}
