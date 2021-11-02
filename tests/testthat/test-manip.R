test_that("writing impac objects works", {

  set.seed(122222)

  png_file <- withr::local_file("test_write.png")

  circle_gen <- function(i) imager::draw_circle(
    imager::imfill(500, 500, val = c(0, 0, 0, 0)),
    250, 250, radius = runif(1, 150, 250),
    color = matrix(grDevices::col2rgb(sample(grDevices::rainbow(100), 1), alpha = TRUE), nrow = 1)
  )

  imp <- impac(circle_gen,
               width = 400, height = 400,
               max_images = 10, bg = "white")

  impac_write(imp, png_file)

  ## can we load it
  expect_success(expect_s3_class(pngit <- imager::load.image(png_file), "cimg"))
  ## does it look right
  expect_snapshot_file(png_file, "circles_save.png")
})

test_that("recovering impac objects works", {

  set.seed(156756722)

  circle_gen <- function(i) {
    if(i == 5) {
      stop("An error occurs here!")
    }
    imager::draw_circle(
      imager::imfill(500, 500, val = c(0, 0, 0, 0)),
      250, 250, radius = runif(1, 150, 250),
      color = matrix(grDevices::col2rgb(sample(grDevices::rainbow(100), 1), alpha = TRUE), nrow = 1)
    )
  }

  impac_clear_cache()

  expect_error(imp <- impac_recover(),
               "Sorry, there is no packed image canvas currently cached.")

  expect_error(imp <- impac(circle_gen,
               width = 400, height = 400,
               max_images = 5, bg = "white"),
               "An error occurs here!")

  imp2 <- impac_recover()

  expect_s3_class(imp2, "impac")
  expect_length(imp2$meta$x, 4)

  impac_write(imp2, tfile <- withr::local_tempfile(fileext = ".png"))
  expect_snapshot_file(tfile, "interrupted_circles.png")

})

test_that("recovering impac objects works", {

  set.seed(9856)

  circle_gen <- function(i) {
    imager::draw_circle(
      imager::imfill(500, 500, val = c(0, 0, 0, 0)),
      250, 250, radius = runif(1, 150, 250),
      color = matrix(grDevices::col2rgb(sample(grDevices::rainbow(100), 1), alpha = TRUE), nrow = 1)
    )
  }

  imp <- impac(circle_gen,
               width = 400, height = 400,
               max_images = 3)

  imp2 <- impac_resume(imp)

  expect_s3_class(imp2, "impac")
  expect_length(imp2$meta$x, 6)

  impac_write(imp2, tfile <- withr::local_tempfile(fileext = ".png"))
  expect_snapshot_file(tfile, "resumed_circles.png")

})
