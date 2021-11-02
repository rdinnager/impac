test_that("impac produces the same image", {

  set.seed(3717)

  imager::save.image(
    impac(
      function(i) imager::draw_circle(
        imager::imfill(500, 500, val = c(0, 0, 0, 0)),
        250, 250, radius = runif(1, 150, 250),
        color = matrix(grDevices::col2rgb(sample(grDevices::rainbow(100), 1), alpha = TRUE), nrow = 1)
      ),
      width = 400, height = 400,
      max_images = 10, bg = "white"
    )$image,
    path <- withr::local_tempfile(fileext = ".png")
  )

  expect_snapshot_file(path, "circles.png")

})

test_that("adding metadata works", {


  x <- impac(
      function(i) {
        ccol <- sample(grDevices::rainbow(100), 1)
        list(imager::draw_circle(
          imager::imfill(500, 500, val = c(0, 0, 0, 0)),
          250, 250, radius = runif(1, 150, 250),
          color = matrix(grDevices::col2rgb(ccol, alpha = TRUE), nrow = 1)
        ),
        color = ccol)},
      width = 400, height = 400,
      max_images = 10, bg = "white"
    )

  expect_identical(colnames(x$meta), c("x", "y", "scale", "image", "color"))
  expect_type(x$meta$color, "character")

})
